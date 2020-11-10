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

function updatelinesegments!(linesegments, lines)
    empty!(linesegments)
    for line in lines
        for (x,y) in zip(line[1:end - 1], line[2:end])
            push!(linesegments, x => y)
        end
    end
end

struct Arduino
    c::ReentrantLock
    sp::SerialPort
    lines::Vector{CircularBuffer{Point2f0}}
    linesegments::Node{Vector{Pair{Point2f0, Point2f0}}}
    function Arduino(sp)
        lines = Vector{CircularBuffer{Point2f0}}(undef, 3)
        for i in 1:3
            lines[i] = CircularBuffer{Point2f0}(history)
            for j in 1:history
                push!(lines[i], Point2f0(j/fps, 0.0))
            end
        end
        linesegments = Node(Pair{Point2f0, Point2f0}[])
        updatelinesegments!(linesegments[], lines)
        c = ReentrantLock()
        new(c, sp, lines, linesegments)
    end
end

function sample!(a::Arduino)
    tss = lock(a.c) do 
        sp_flush(a.sp, SP_BUF_INPUT)
        encode(a.sp, UInt8(0))
        decode(a.sp) 
    end
    for (line, ts) in zip(a.lines, Iterators.partition(tss, 4))
        t = toint(ts)
        rpm = getrpm(t)
        y = gety(line, rpm)
        xy = Point2f0(gettime(), y)
        push!(line, xy)
    end
    updatelinesegments!(a.linesegments[], a.lines)
    a.linesegments[] = a.linesegments[]
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
    empty!(a.linesegments.listeners)
    scene, layout = layoutscene(0)
    ax = layout[1,1] = LAxis(scene, xlabel = "Time (s)", ylabel = "RPM", title = "Fans")
    linesegments!(ax, a.linesegments, color =  repeat([:red, :green, :blue], inner = history - 1))
    on(a.linesegments) do ps
        xmin = minimum(first ∘ first ∘ first, Iterators.partition(ps, history - 1))
        xmax = maximum(first ∘ last ∘ last, Iterators.partition(ps, history - 1))
        ax.targetlimits[] = FRect2D(xmin, 0, xmax - xmin, top_rpm)
    end
    rpm = lift(a.linesegments) do ps
        round(Int, mean(last ∘ last ∘ last, Iterators.partition(ps, history - 1)))
    end
    slider_s = Slider(1:255, pwm)
    dom = md"""
    $scene
    Speed setting: $pwm $slider_s 

    RPM (μ): $rpm
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8082)
