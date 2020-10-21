import LibSerialPort
using AbstractPlotting, WGLMakie, JSServe
Base.readuntil(a::JSServe.HTTP.ConnectionPool.Transaction, b::T, c::U) where {T<:Function, U<:Real} = JSServe.readuntil(a, b, c)
handler(session, request) = scatter(rand(5))
app = JSServe.Application(handler, "0.0.0.0", 8000)
