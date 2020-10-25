using LibSerialPort, COBS
using DataStructures
using AbstractPlotting, WGLMakie, JSServe, Markdown
using AbstractPlotting.MakieLayout
using JSServe: Slider
markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

function toint(msg)
    y = zero(UInt32)
    for c in msg
        y <<= 8
        y += c
    end
    return y
end

top_rpm = 11_500 + 1_150
t4 = 60e6/4
shortest_t = t4/1.1top_rpm
longest_t = 100_000

function getrpm(ts)
    t = toint(ts)
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

updateys!(_, ::Nothing) = nothing
updateys!(ys, y) = push!(ys, y)

port = only(get_port_list())
baudrate = 115200
sp = LibSerialPort.open(port, baudrate)

buffer = 10
ys = CircularBuffer{Float64}(buffer)
history = 100
line = Node(CircularBuffer{Point2f0}(history))
c = ReentrantLock()
reading = @async while isopen(sp)
    ts = lock(c) do 
        decode(sp)
    end
    y = getrpm(ts)
    updateys!(ys, y)
    xy = Point2f0(time(), mean(ys))
    push!(line[], xy)
    line[] = line[]
    sleep(1/30)
end

pwm = Node(zero(UInt8))
on(pwm) do i
    lock(c) do 
        encode(sp, i)
    end
end


function handler(session, request)
    scene, layout = layoutscene(0)
    ax = layout[1,1] = LAxis(scene, xlabel = "Time (s)", ylabel = "RPM", title = "Fan 1")
    lines!(ax, line, color = :blue)
    on(line) do xys
        xmin = first(xys[1])
        xmax = first(xys[end])
        ax.targetlimits[] = FRect2D(xmin, 0, xmax - xmin, top_rpm)
    end
    rpm = lift(line) do xys
        round(Int, last(last(xys)))
    end
    slider_s = Slider(0:255, pwm)
    dom = md"""
    $scene
    Speed setting: $(slider_s.value) $slider_s RPM: $rpm
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)
