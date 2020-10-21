using LibSerialPort, COBS
using AbstractPlotting, JSServe, Markdown
using JSServe: Slider
markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

port = only(get_port_list())
baudrate = 115200
sp = LibSerialPort.open(port, baudrate)

function handler(session, request)
    slider_s = Slider(0:255)
    on(slider_s) do i
        encode(sp, i)
    end
    dom = md"""
    Speed: $slider_s
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)

