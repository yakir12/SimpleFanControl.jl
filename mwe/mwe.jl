using AbstractPlotting, WGLMakie, JSServe

n = 5
line = Node(rand(n))
function sample()
    line[] = rand(n)
    line[] = line[]
end

reading = @async while true
    cond = Condition()
    Timer(x->notify(cond), 1/30)
    t = @async sample()
    wait(cond)
    wait(t)
    sleep(0)
end

handler(session, request) = lines(line)

app = JSServe.Application(handler, "0.0.0.0", 8000)

