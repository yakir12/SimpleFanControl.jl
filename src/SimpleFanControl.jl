module SimpleFanControl


using LibSerialPort, COBS
function toint(msg)
    result = zero(UInt32)
    for c in msg
        result <<= 8
        result += c
    end
    result
end
port = only(get_port_list())
baudrate = 115200
sp = LibSerialPort.open(port, baudrate)


using AbstractPlotting, WGLMakie, JSServe, Markdown
using JSServe: Slider

markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

signal = Node(zero(Float32))
@async while true
    t = toint(decode(sp))
    signal[] = t == 0 ? zero(Float32) : Float32(6e6/4t)
    sleep(1/15)
end


function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        encode(sp, i)
    end
    h = timeseries(signal, history = 30)
    dom = md"""
    $h

    Speed: $slider_s
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)






JSServe.Application((a,b) -> scatter(4), "0.0.0.0", 8000)






using AbstractPlotting, WGLMakie, JSServe, Markdown
using JSServe: Slider

markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

signal = Node(zero(Float32))

function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        println(i)
    end
    speed = lift(x -> x[], slider_s)

    h = timeseries(signal, history = 30)
    dom = md"""
    $h

    Speed: $slider_s

    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)

@async while true
    t = rand()
    signal[] = t == 0 ? 0.0 : 6e6/4t
    sleep(1/15)
end







using AbstractPlotting, WGLMakie, JSServe, Markdown
using JSServe: Slider

markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

signal = Node(zero(Float32))

function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        encode(sp, i)
    end
    speed = lift(x -> x[], slider_s)
    h = timeseries(signal, history = 30)

    dom = md"""
    $h

    Speed control   $(speeds)   $speed

    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)






















end


using AbstractPlotting, WGLMakie, JSServe
handler(a, b) = scatter(1:4)
app = JSServe.Application(handler, "0.0.0.0", 8000)


using AbstractPlotting, WGLMakie, JSServe
signal = Node(zero(Float32))
handler(a, b) = timeseries(signal, history = 30)
app = JSServe.Application(handler, "0.0.0.0", 8000)


@async while true
    signal[] = 100rand(Float32)
    sleep(1/15)
end



using AbstractPlotting, WGLMakie, JSServe
using AbstractPlotting.MakieLayout
using DataStructures

signal = Node(zero(Float32))
line = Node(CircularBuffer{Point2f0}(30))
push!(line[], zero(Point3f0))
on(signal) do y
    x = line[][end][1] + 1
    push!(line[], Point2f0(x, y))
    AbstractPlotting.update_limits!(scene)
    AbstractPlotting.update!(scene)
end
scene, layout = layoutscene(0)
ax = layout[1,1] = LAxis(scene)
lines!(ax, line)
ylims!(ax, 0, 1)

@async while true
    signal[] = rand(Float32)
    sleep(1/30)
end
handler(session, request) = scene
app = JSServe.Application(handler, "0.0.0.0", 8000)

