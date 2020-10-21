### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 032cb34e-13b0-11eb-0c89-f3ee9ef0175f
using LibSerialPort, COBS, PlutoUI, AbstractPlotting, WGLMakie

# ╔═╡ ee342e94-13b0-11eb-2b33-efdac65a578f
import Pkg; Pkg.add(["COBS", "PlutoUI", "AbstractPlotting", "WGLMakie"])

# ╔═╡ 5673eb22-13b4-11eb-1c43-cb693f7a44b6
Pkg.add(name="LibSerialPort", rev="master")

# ╔═╡ 7fad639a-13b1-11eb-1ce9-4157899b768f
port = only(get_port_list())

# ╔═╡ 7fada75e-13b1-11eb-074b-db27807fc606
baudrate = 115200

# ╔═╡ 7fb45376-13b1-11eb-2986-75dbf701a3d3
sp = LibSerialPort.open(port, baudrate)

# ╔═╡ 7ae388ee-13b1-11eb-001b-0bcef4960180
md"""
$(@bind a PlutoUI.Slider(0:255))
"""

# ╔═╡ f582d05a-13b1-11eb-27b3-ad4302a17c6e
encode(sp, a)

# ╔═╡ e88b926a-13b1-11eb-20df-89d133b41a6a
function toint(msg)
    result = zero(UInt32)
    for c in msg
        result <<= 8
        result += c
    end
    result
end

# ╔═╡ 6db02932-13b3-11eb-3338-eb5a54e7d1a5
signal = Node(0.0)

# ╔═╡ 13c79b70-13b4-11eb-1611-15b327e9577e
@async while true
    t = toint(decode(sp))
    signal[] = t == 0 ? 0.0 : 6e6/4t
    sleep(1/30)
end


# ╔═╡ 3fdf6176-13b3-11eb-3d9d-11dee7a78063
begin
	h = timeseries(signal, history = 30, resolution = (500, 200))
	ylims!(h, 0, 1000)
	h
end

# ╔═╡ Cell order:
# ╠═ee342e94-13b0-11eb-2b33-efdac65a578f
# ╠═5673eb22-13b4-11eb-1c43-cb693f7a44b6
# ╠═032cb34e-13b0-11eb-0c89-f3ee9ef0175f
# ╠═7fad639a-13b1-11eb-1ce9-4157899b768f
# ╠═7fada75e-13b1-11eb-074b-db27807fc606
# ╠═7fb45376-13b1-11eb-2986-75dbf701a3d3
# ╠═7ae388ee-13b1-11eb-001b-0bcef4960180
# ╠═f582d05a-13b1-11eb-27b3-ad4302a17c6e
# ╠═e88b926a-13b1-11eb-20df-89d133b41a6a
# ╠═6db02932-13b3-11eb-3338-eb5a54e7d1a5
# ╠═13c79b70-13b4-11eb-1611-15b327e9577e
# ╠═3fdf6176-13b3-11eb-3d9d-11dee7a78063
