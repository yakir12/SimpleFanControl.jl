# module SimpleFanControl


using LibSerialPort, COBS, OnlineStats
using AbstractPlotting, WGLMakie, JSServe, Markdown
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

port = only(get_port_list())
baudrate = 115200
sp = LibSerialPort.open(port, baudrate)

top_rpm = 11_500
t4 = 60e6/4
shortest_t = t4/1.1top_rpm
longest_t = 13000

win = MovingWindow(10, Float32)#StatLag(Mean(Float32), 10)#
rpm = Node(zero(Float32))
olds = Node(zero(UInt8))
news = Node(zero(UInt8))
@async while true
    flush(sp)
    ts = decode(sp)
    t = toint(ts)
    if iszero(t)
        fit!(win, zero(Float32)) 
    elseif shortest_t < t < longest_t
        fit!(win, Float32(t4/t)) 
    end
    rpm[] = mean(value(win))#mean(win.stat)
    if news[] ≠ olds[]
        encode(sp, news[])
        olds[] = news[]
    end
    sleep(1/30)
end

function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        news[] = UInt8(i)
    end
    h = timeseries(rpm)
    dom = md"""
    $h

    Speed: $slider_s $(map(Int, news))
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)

# end


