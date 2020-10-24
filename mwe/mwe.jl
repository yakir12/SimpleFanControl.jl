using OnlineStats
using DataStructures, Dates
using AbstractPlotting, WGLMakie, JSServe, Markdown
using AbstractPlotting.MakieLayout
using JSServe: Slider
markdown_css = JSServe.Asset(JSServe.dependency_path("markdown.css"))

c = ReentrantLock()
t = Node(0.0)
reading = @async while true
    t[] = lock(c) do 
        rand()
    end
    sleep(0.1)
end

history = 100
line = Node(CircularBuffer{Float64}(history))
foreach(_ -> push!(line[], rand()), 1:history)

on(t) do y
    push!(line[], y)
    line[] = line[]
end

sv = Node(0)
on(sv) do i
    println(i)
end

function handler(session, request)
    s = Slider(0:255, sv)
    scene, layout = layoutscene(0)
    ax = layout[1,1] = LAxis(scene, xlabel = "Time (s)", ylabel = "RPM", title = "Fan 1")
    lines!(ax, line, color = :blue)
    dom = md"""
    $scene
    slider: $s
    """
    return JSServe.DOM.div(markdown_css, dom)
end

app = JSServe.Application(handler, "0.0.0.0", 8000)
