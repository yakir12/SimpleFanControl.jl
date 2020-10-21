# module SimpleFanControl


using LibSerialPort, COBS
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


signal = Node(zero(Float32))
# @async while true
#     t = toint(decode(sp))
#     signal[] = t == 0 ? zero(Float32) : Float32(6e6/4t)
#     sleep(1/30)
# end


function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        encode(sp, i)
    end
    speed = map(slider_s) do i
        i
    end
    # h = timeseries(signal, history = 30)
    dom = md"""

    Speed: $slider_s $speed
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)

# end
