-- Dev tool, not part of the plugin: run inside Studio (as a ModuleScript) while tools/bridge.py
-- is running. Sends terrain voxels and part models to the bridge so tools/render_blender.py can
-- draw the README and website art from real plugin output.
--   Dump.terrain("alp.vox", Vector3.new(-256, -40, -256), Vector3.new(256, 200, 256))
--   Dump.parts("kule.parts", model)
local Http = game:GetService("HttpService")
local URL = "http://127.0.0.1:8767/dump/"
local URL_EK = "http://127.0.0.1:8767/append/"

local Dump = {}

-- Voxels as run-length columns along Y: "material:occupancy255:count,..." one line per (x, z).
function Dump.terrain(ad, mn, mx)
	local reg = Region3.new(mn, mx):ExpandToGrid(4)
	local mats, occ = workspace.Terrain:ReadVoxels(reg, 4)
	local size = mats.Size
	local adlar, sira = {}, {}
	local satirlar = table.create(size.X * size.Z)
	for x = 1, size.X do
		local mxs, oxs = mats[x], occ[x]
		for z = 1, size.Z do
			local runs = {}
			local sonM, sonO, n = nil, nil, 0
			for y = 1, size.Y do
				local m = mxs[y][z]
				local mi = sira[m]
				if not mi then
					table.insert(adlar, m.Name)
					mi = #adlar
					sira[m] = mi
				end
				local o = math.floor(oxs[y][z] * 255 + 0.5)
				if m == Enum.Material.Air then o = 0 end
				if mi == sonM and o == sonO then
					n += 1
				else
					if sonM then table.insert(runs, sonM .. ":" .. sonO .. ":" .. n) end
					sonM, sonO, n = mi, o, 1
				end
			end
			table.insert(runs, sonM .. ":" .. sonO .. ":" .. n)
			table.insert(satirlar, table.concat(runs, ","))
		end
		if x % 16 == 0 then task.wait() end
	end
	local alt = reg.CFrame.Position - reg.Size / 2
	local baslik = Http:JSONEncode({
		x0 = alt.X, y0 = alt.Y, z0 = alt.Z,
		nx = size.X, ny = size.Y, nz = size.Z, res = 4,
		materials = adlar,
		water = { workspace.Terrain.WaterColor.R, workspace.Terrain.WaterColor.G, workspace.Terrain.WaterColor.B },
	})
	-- Studio posts are limited to 1 MB: send the first block, then append the rest
	local parca, boy, toplam, ilk = { baslik }, #baslik, 0, true
	local function gonder()
		local govde = table.concat(parca, "\n") .. "\n"
		Http:PostAsync((ilk and URL or URL_EK) .. ad, govde, Enum.HttpContentType.TextPlain)
		toplam += #govde
		ilk = false
		parca, boy = {}, 0
	end
	for _, s in ipairs(satirlar) do
		if boy + #s > 800000 then gonder() end
		table.insert(parca, s)
		boy += #s + 1
	end
	if #parca > 0 then gonder() end
	return "saved " .. toplam .. " bytes"
end

-- Every BasePart under root: shape, cframe (12 numbers), size, color, material, transparency.
function Dump.parts(ad, kok)
	local liste = {}
	for _, p in ipairs(kok:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.98 then
			local sekil = "Block"
			if p:IsA("Part") then sekil = p.Shape.Name elseif p:IsA("WedgePart") then sekil = "Wedge"
			elseif p:IsA("CornerWedgePart") then sekil = "CornerWedge" end
			table.insert(liste, {
				s = sekil,
				cf = { p.CFrame:GetComponents() },
				size = { p.Size.X, p.Size.Y, p.Size.Z },
				c = { p.Color.R, p.Color.G, p.Color.B },
				m = p.Material.Name,
				t = p.Transparency,
				l = (p:FindFirstChildWhichIsA("Light") ~= nil) and 1 or 0,
			})
		end
	end
	return Http:PostAsync(URL .. ad, Http:JSONEncode(liste), Enum.HttpContentType.TextPlain)
end

return Dump
