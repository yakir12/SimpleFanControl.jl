# module SimpleFanControl


using LibSerialPort, COBS, OnlineStats
using DataStructures, Dates
using AbstractPlotting, WGLMakie, JSServe, Markdown
using AbstractPlotting.MakieLayout
using JSServe: Slider
markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

function toint(msg)
    result = zero(UInt32)
    for c in msg
        result <<= 8
        result += c
    end
    result
end


function mymean(v)
    x = 0.0
    y = 0.0
    for (i,j) in v
        x += Dates.value(i - Time(0))*1e-9
        y += j
    end
    n = length(v)
    n == 0 ? (x, y) : (x/n, y/n)
end

t₀ = time()

totime(s) = Time(0, 0, 0) + Millisecond(round(Int, 1000(s - t₀)))

port = only(get_port_list())
baudrate = 115200
sp = LibSerialPort.open(port, baudrate)

c = ReentrantLock()
t = Node((Time(0), zero(UInt32)))
reading = @async while isopen(sp)
    ts = lock(c) do 
        decode(sp)
    end
    t[] = (totime(time()), toint(ts))
    sleep(0)
end

win = MovingTimeWindow(Millisecond(250); timetype = Time, valtype=Float64)
top_rpm = 11_500 + 1_150
t4 = 60e6/4
shortest_t = t4/1.1top_rpm
longest_t = 100_000
rpm = lift(t) do (x, y)
    if iszero(y)
        fit!(win, (x, rand()))
    elseif shortest_t < y < longest_t
        fit!(win, (x, t4/y)) 
    end
    mymean(value(win))
end

history = 100
line = Node(CircularBuffer{Point2{Float64}}(history))
foreach(_ -> push!(line[], rand(Point2{Float64})), 1:history)
rect = Node(FRect2D(0, 0, 1, top_rpm))

on(rpm) do (x, y)
    push!(line[], Point2{Float64}(x, y))
    xmin, xmax = extrema(first, line[])
    rect[] = FRect2D(xmin, 0, xmax - xmin, top_rpm)
    line[] = line[]
end

rpmtxt = lift(rpm) do (_, y)
    string(round(Int, y))
end

function handler(session, request)
    scene, layout = layoutscene(0)
    ax = layout[1,1] = LAxis(scene)
    slider_s = Slider(0:255)
    s = lift(string, slider_s)
    on(slider_s) do i
        lock(c) do 
            encode(sp, UInt8(i))
        end
    end
    lines!(ax, line)
    AbstractPlotting.connect!(rect, ax.targetlimits)
    dom = md"""
    $scene
    Speed setting: $s $slider_s RPM: $rpmtxt
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)



    # scene, layout = layoutscene(0)
    # ax = layout[1,1:3] = LAxis(scene)
    # layout[2,1] = LText(scene, "Speed setting")
    # slider_s = layout[2,2] = LSlider(scene, range = 0:255, startvalue = 19)
    # layout[2,3] = LText(scene, lift(string, slider_s.value))
    # on(slider_s.value) do i
    #     lock(c)
    #     encode(sp, UInt8(i))
    #     unlock(c)
    # end
    # lines!(ax, line)
    # AbstractPlotting.connect!(rect, ax.targetlimits)
    # dom = md"""
    # $scene
    # """
    # return JSServe.DOM.div(markdown_css, dom)
