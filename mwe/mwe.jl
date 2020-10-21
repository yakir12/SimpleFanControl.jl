import LibSerialPort
using JSServe
# Base.readuntil(a::JSServe.HTTP.ConnectionPool.Transaction, b::T, c::U) where {T<:Function, U<:Real} = JSServe.readuntil(a, b, c)
handler(session, request) = ""
app = JSServe.Application(handler, "0.0.0.0", 8000)
