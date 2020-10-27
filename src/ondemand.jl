using LibSerialPort, COBS, Statistics
using DataStructures
using AbstractPlotting, WGLMakie, JSServe, Markdown
using AbstractPlotting.MakieLayout
using JSServe: Slider
markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

top_rpm = 11_500 + 1_150
t4 = 60e6/4
shortest_t = t4/1.1top_rpm
longest_t = 100_000
fps = 30
baudrate = 115200
history = 50
t₀ = time()

gettime() = time() - t₀

function toint(msg)
    y = zero(UInt32)
    for c in msg
        y <<= 8
        y += c
    end
    return y
end

function getrpm(t)
    if iszero(t)
        0.0
    elseif 0 < t ≤ shortest_t
        nothing
    elseif shortest_t < t ≤ longest_t
        t4/t
    else
        0.0
    end
end

last2 = last ∘ last

gety(line, ::Nothing) = last2(line)
gety(_, y) = y

struct Arduino
    c::ReentrantLock
    sp::SerialPort
    line::Observable{CircularBuffer{Point2f0}}
    function Arduino(sp)
        line = Node(CircularBuffer{Point2f0}(history))
        for i in 1:history
            push!(line[], Point2f0(i/fps, 0.0))
        end
        c = ReentrantLock()
        new(c, sp, line)
    end
end

function sample!(a::Arduino)
    ts = lock(a.c) do 
        sp_flush(a.sp, SP_BUF_INPUT)
        encode(a.sp, UInt8(0))
        decode(a.sp) 
    end
    t = toint(ts)
    rpm = getrpm(t)
    y = gety(a.line[], rpm)
    xy = Point2f0(gettime(), y)
    push!(a.line[], xy)
    a.line[] = a.line[]
end

port = only(get_port_list())
sp = LibSerialPort.open(port, baudrate)

a = Arduino(sp)

reading = @async while isopen(sp)
    cond = Condition()
    Timer(x->notify(cond), 1/fps)
    t = @async sample!(a)
    wait(cond)
    wait(t)
end

pwm = Node(1)
on(pwm) do i
    lock(a.c) do 
        encode(a.sp, UInt8(i))
    end
end


function handler(session, request)
    scene, layout = layoutscene(0)
    ax = layout[1,1] = LAxis(scene, xlabel = "Time (s)", ylabel = "RPM", title = "Fan 1")
    lines!(ax, a.line, color = :blue)
    on(a.line) do xys
        xmin = first(xys[1])
        xmax = first(xys[end]) + 1
        ax.targetlimits[] = FRect2D(xmin, 0, xmax - xmin, top_rpm)
    end
    rpm = lift(a.line) do xys
        round(Int, last(last(xys)))
    end
    slider_s = Slider(1:255, pwm)
    dom = md"""
    $scene
    Speed setting: $pwm $slider_s RPM: $rpm
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)
