-- SWEAX TERRAIN — YapiSus: small props (18): torches, crates, tents, fences and more.
-- SÜS & PROP kütüphanesi (sahneyi dolduran küçük detaylar)
-- SÖZLEŞME: fn(kok, cf, o) -> Model. cf = tabanın MERKEZİ (yapı +Y yönünde büyür, -Z ön yüzü).
-- o = {olcek, tohum, rnd, yosun, yikik, isik, renkTas, renkKoyu, renkYosun}
-- KURALLAR: yalnız Part (MeshPart/Union yok), hepsi Anchored, rastgelelik SADECE o.rnd üzerinden
-- (aynı tohum → birebir aynı prop), parça sayısı düşük (6-45) çünkü bunlar onlarca kez konur.
-- Işıklar o.isik=false ise eklenmez (performans / gündüz sahne).
local M = {}

-- ---------- ortak palet ----------
local AHSAP = Color3.fromRGB(104, 74, 46)
local AHSAP_KOYU = Color3.fromRGB(74, 52, 32)
local DEMIR = Color3.fromRGB(88, 88, 92)
local PAS = Color3.fromRGB(122, 74, 44)
local BEZ = Color3.fromRGB(168, 152, 120)
local ATES = Color3.fromRGB(255, 148, 42)
local KOMUR = Color3.fromRGB(38, 36, 36)

-- ---------- iskelet ----------
local function yeniModel(kok, ad, cf)
	local m = Instance.new("Model")
	m.Name = ad
	m.Parent = kok
	m:SetAttribute("SweaxStructure", ad)
	return m
end

-- p(model, boyut, cfYerel, renk, malzeme, ekler) — cfYerel TABAN CF'ye görelidir
local function p(m, taban, boyut, yerel, renk, mat, ekler)
	local part = Instance.new("Part")
	part.Size = boyut
	part.CFrame = taban * yerel
	part.Color = renk
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if ekler then
		for k, v in pairs(ekler) do part[k] = v end
	end
	part.Parent = m
	return part
end

local function yuvarla(part, sekil)
	part.Shape = sekil or Enum.PartType.Cylinder
	return part
end

local function bitir(m, o, ad)
	local ilk = m:FindFirstChildWhichIsA("BasePart")
	if ilk then m.PrimaryPart = ilk end
	m:SetAttribute("SweaxSeed", o.tohum)
	m:SetAttribute("SweaxStructure", ad or m.Name)
	return m
end

-- yosun lekeleri: taş yüzeylere rastgele yeşil ince plakalar
local function yosunLekesi(m, taban, o, merkez, yayilim, adet)
	if o.yosun <= 0.02 then return end
	local n = math.floor(adet * o.yosun + 0.5)
	for _ = 1, n do
		local dx = o.rnd:NextNumber(-yayilim.X, yayilim.X)
		local dz = o.rnd:NextNumber(-yayilim.Z, yayilim.Z)
		local dy = o.rnd:NextNumber(-yayilim.Y, yayilim.Y)
		p(m, taban, Vector3.new(o.rnd:NextNumber(0.4, 1.3), 0.12, o.rnd:NextNumber(0.4, 1.3)),
			CFrame.new(merkez.X + dx, merkez.Y + dy, merkez.Z + dz), o.renkYosun, Enum.Material.Grass)
	end
end

-- ateş ışığı + parıltı (o.isik kapalıysa yalnız görsel kalır)
local function atesIsigi(part, o, menzil, guc)
	if not o.isik then return end
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 174, 92)
	l.Range = menzil or 16
	l.Brightness = guc or 2.2
	l.Shadows = false
	l.Parent = part
end

-- ==================================================================
-- 1. MEŞALE — duvar/zemin meşalesi (maden aydınlatması)
-- ==================================================================
local function mesale(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Mesale", cf)
	local egim = math.rad(o.rnd:NextNumber(-8, 8))
	-- sap
	p(m, cf, Vector3.new(0.22 * s, 2.2 * s, 0.22 * s),
		CFrame.new(0, 1.1 * s, 0) * CFrame.Angles(0, 0, egim), AHSAP_KOYU, Enum.Material.Wood)
	-- kömürleşmiş uç
	p(m, cf, Vector3.new(0.3 * s, 0.3 * s, 0.3 * s),
		CFrame.new(0, 2.2 * s, 0) * CFrame.Angles(0, 0, egim), KOMUR, Enum.Material.Slate)
	-- alev (üç kademeli koni etkisi)
	local a1 = p(m, cf, Vector3.new(0.46 * s, 0.5 * s, 0.46 * s), CFrame.new(0, 2.5 * s, 0), ATES, Enum.Material.Neon,
		{ CanCollide = false, Transparency = 0.12 })
	p(m, cf, Vector3.new(0.3 * s, 0.42 * s, 0.3 * s), CFrame.new(0, 2.82 * s, 0), Color3.fromRGB(255, 214, 120),
		Enum.Material.Neon, { CanCollide = false, Transparency = 0.25 })
	atesIsigi(a1, o, 20 * s, 2.4)
	-- taş kaide
	p(m, cf, Vector3.new(0.9 * s, 0.3 * s, 0.9 * s), CFrame.new(0, 0.15 * s, 0), o.renkTas, Enum.Material.Slate)
	return bitir(m, o, "Mesale")
end

-- ==================================================================
-- 2. FENER DİREĞİ — demir direk + camlı fener
-- ==================================================================
local function fenerDiregi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "FenerDiregi", cf)
	p(m, cf, Vector3.new(1.6 * s, 0.4 * s, 1.6 * s), CFrame.new(0, 0.2 * s, 0), o.renkTas, Enum.Material.Slate)
	p(m, cf, Vector3.new(0.3 * s, 6.2 * s, 0.3 * s), CFrame.new(0, 3.3 * s, 0), DEMIR, Enum.Material.Metal)
	-- kol
	p(m, cf, Vector3.new(1.5 * s, 0.22 * s, 0.22 * s), CFrame.new(0.7 * s, 6.3 * s, 0), DEMIR, Enum.Material.Metal)
	-- fener gövdesi
	local cam = p(m, cf, Vector3.new(0.85 * s, 1.0 * s, 0.85 * s), CFrame.new(1.35 * s, 5.7 * s, 0),
		Color3.fromRGB(255, 206, 128), Enum.Material.Neon, { Transparency = 0.2 })
	p(m, cf, Vector3.new(1.0 * s, 0.2 * s, 1.0 * s), CFrame.new(1.35 * s, 6.28 * s, 0), DEMIR, Enum.Material.Metal)
	p(m, cf, Vector3.new(1.0 * s, 0.2 * s, 1.0 * s), CFrame.new(1.35 * s, 5.14 * s, 0), DEMIR, Enum.Material.Metal)
	atesIsigi(cam, o, 26 * s, 2.0)
	yosunLekesi(m, cf, o, Vector3.new(0, 0.34 * s, 0), Vector3.new(0.7 * s, 0.05, 0.7 * s), 3)
	return bitir(m, o, "FenerDiregi")
end

-- ==================================================================
-- 3. SANDIK — ahşap kasa (tekli ya da istifli)
-- ==================================================================
local function sandik(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Sandik", cf)
	local adet = o.rnd:NextInteger(1, 4)
	local konum = {
		Vector3.new(0, 0, 0),
		Vector3.new(2.3, 0, 0.4),
		Vector3.new(0.3, 2.1, 0.2),
		Vector3.new(-2.1, 0, -0.5),
	}
	for i = 1, adet do
		local k = konum[i] * s
		local don = CFrame.Angles(0, o.rnd:NextNumber(-0.5, 0.5), 0)
		local yat = (o.yikik > 0.5 and i > 1 and o.rnd:NextNumber() < 0.3) and CFrame.Angles(o.rnd:NextNumber(-0.2, 0.2), 0, o.rnd:NextNumber(-0.2, 0.2)) or CFrame.new()
		local mer = CFrame.new(k.X, k.Y + 1 * s, k.Z) * don * yat
		p(m, cf, Vector3.new(2 * s, 2 * s, 2 * s), mer, AHSAP, Enum.Material.WoodPlanks)
		-- demir bantlar
		p(m, cf, Vector3.new(2.08 * s, 0.22 * s, 2.08 * s), mer * CFrame.new(0, 0.6 * s, 0), DEMIR, Enum.Material.Metal)
		p(m, cf, Vector3.new(2.08 * s, 0.22 * s, 2.08 * s), mer * CFrame.new(0, -0.6 * s, 0), DEMIR, Enum.Material.Metal)
		-- kapak çizgisi
		p(m, cf, Vector3.new(2.06 * s, 0.12 * s, 2.06 * s), mer * CFrame.new(0, 0.86 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	end
	return bitir(m, o, "Sandik")
end

-- ==================================================================
-- 4. VARİL — paslı metal varil grubu
-- ==================================================================
local function varil(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Varil", cf)
	local adet = o.rnd:NextInteger(1, 3)
	for i = 1, adet do
		local a = o.rnd:NextNumber(0, math.pi * 2)
		local d = (i == 1) and 0 or o.rnd:NextNumber(1.6, 2.6) * s
		local x, z = math.cos(a) * d, math.sin(a) * d
		local yatik = (o.yikik > 0.4 and o.rnd:NextNumber() < o.yikik * 0.6)
		local renk = o.rnd:NextNumber() < 0.5 and PAS or Color3.fromRGB(72, 96, 74)
		if yatik then
			local mer = CFrame.new(x, 0.85 * s, z) * CFrame.Angles(0, o.rnd:NextNumber(0, 6.28), math.rad(90))
			yuvarla(p(m, cf, Vector3.new(2.4 * s, 1.7 * s, 1.7 * s), mer, renk, Enum.Material.CorrodedMetal))
			p(m, cf, Vector3.new(2.46 * s, 1.82 * s, 1.82 * s), mer, DEMIR, Enum.Material.Metal, { Transparency = 1 })
		else
			local mer = CFrame.new(x, 1.2 * s, z) * CFrame.Angles(0, 0, math.rad(90))
			yuvarla(p(m, cf, Vector3.new(2.4 * s, 1.7 * s, 1.7 * s), mer, renk, Enum.Material.CorrodedMetal))
			-- kuşaklar
			for _, dy in ipairs({ -0.6, 0.6 }) do
				yuvarla(p(m, cf, Vector3.new(0.18 * s, 1.8 * s, 1.8 * s),
					CFrame.new(x, 1.2 * s + dy * s, z) * CFrame.Angles(0, 0, math.rad(90)), DEMIR, Enum.Material.Metal))
			end
		end
	end
	return bitir(m, o, "Varil")
end

-- ==================================================================
-- 5. AHŞAP DESTEK — maden tüneli tahkimatı (kapı kemeri)
-- ==================================================================
local function ahsapDestek(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "AhsapDestek", cf)
	local en, yuk = 6 * s, 7 * s
	for _, yon in ipairs({ -1, 1 }) do
		local egim = o.yikik * o.rnd:NextNumber(-0.06, 0.06)
		p(m, cf, Vector3.new(0.8 * s, yuk, 0.8 * s),
			CFrame.new(yon * en / 2, yuk / 2, 0) * CFrame.Angles(0, 0, egim), AHSAP, Enum.Material.Wood)
		-- payanda
		p(m, cf, Vector3.new(0.5 * s, 2.4 * s, 0.5 * s),
			CFrame.new(yon * (en / 2 - 0.9 * s), yuk - 1.2 * s, 0) * CFrame.Angles(0, 0, yon * math.rad(38)),
			AHSAP_KOYU, Enum.Material.Wood)
	end
	-- üst kiriş
	p(m, cf, Vector3.new(en + 1.6 * s, 0.85 * s, 1.0 * s), CFrame.new(0, yuk + 0.4 * s, 0), AHSAP, Enum.Material.Wood)
	p(m, cf, Vector3.new(en + 0.4 * s, 0.5 * s, 0.7 * s), CFrame.new(0, yuk + 1.0 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	-- taş temeller
	for _, yon in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(1.6 * s, 0.5 * s, 1.6 * s), CFrame.new(yon * en / 2, 0.25 * s, 0), o.renkTas, Enum.Material.Slate)
	end
	yosunLekesi(m, cf, o, Vector3.new(0, 0.5 * s, 0), Vector3.new(en / 2, 0.2 * s, 0.6 * s), 5)
	return bitir(m, o, "AhsapDestek")
end

-- ==================================================================
-- 6. İSKELE — çok katlı ahşap iskele
-- ==================================================================
local function iskele(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Iskele", cf)
	local kat = o.rnd:NextInteger(2, 3)
	local en, boy, katYuk = 7 * s, 5 * s, 4.2 * s
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			p(m, cf, Vector3.new(0.45 * s, katYuk * kat, 0.45 * s),
				CFrame.new(sx * en / 2, katYuk * kat / 2, sz * boy / 2), AHSAP, Enum.Material.Wood)
		end
	end
	for k = 1, kat do
		local y = katYuk * k
		-- döşeme tahtaları
		local tahta = 5
		for i = 1, tahta do
			local t = (i - 0.5) / tahta - 0.5
			p(m, cf, Vector3.new(en + 0.6 * s, 0.26 * s, boy / tahta * 0.92),
				CFrame.new(0, y - 0.13 * s, t * boy), i % 2 == 0 and AHSAP or AHSAP_KOYU, Enum.Material.WoodPlanks)
		end
		-- çapraz destekler
		for _, sz in ipairs({ -1, 1 }) do
			p(m, cf, Vector3.new(math.sqrt(en * en + katYuk * katYuk), 0.3 * s, 0.3 * s),
				CFrame.new(0, y - katYuk / 2, sz * boy / 2) * CFrame.Angles(0, 0, math.atan2(katYuk, en)),
				AHSAP_KOYU, Enum.Material.Wood)
		end
		-- korkuluk (en üst kat)
		if k == kat then
			for _, sz in ipairs({ -1, 1 }) do
				p(m, cf, Vector3.new(en + 0.6 * s, 0.22 * s, 0.22 * s),
					CFrame.new(0, y + 1.2 * s, sz * boy / 2), AHSAP, Enum.Material.Wood)
			end
		end
	end
	-- merdiven
	local basamak = math.floor(katYuk / (0.9 * s))
	for i = 1, basamak do
		p(m, cf, Vector3.new(1.8 * s, 0.2 * s, 0.5 * s),
			CFrame.new(en / 2 + 1.0 * s, (i - 0.3) * 0.9 * s, boy / 2 - i * 0.55 * s), AHSAP_KOYU, Enum.Material.Wood)
	end
	return bitir(m, o, "Iskele")
end

-- ==================================================================
-- 7. CEVHER YIĞINI — renkli cevher blokları yığını
-- ==================================================================
local CEVHER_RENK = {
	{ ad = "Komur", renk = Color3.fromRGB(42, 42, 44), mat = Enum.Material.Slate },
	{ ad = "Demir", renk = Color3.fromRGB(196, 168, 140), mat = Enum.Material.Metal },
	{ ad = "Bakir", renk = Color3.fromRGB(196, 112, 62), mat = Enum.Material.Metal },
	{ ad = "Altin", renk = Color3.fromRGB(238, 196, 62), mat = Enum.Material.Metal },
	{ ad = "Elmas", renk = Color3.fromRGB(104, 226, 226), mat = Enum.Material.Glass },
	{ ad = "Zumrut", renk = Color3.fromRGB(60, 200, 110), mat = Enum.Material.Glass },
}

local function cevherYigini(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "CevherYigini", cf)
	local tur = CEVHER_RENK[o.rnd:NextInteger(1, #CEVHER_RENK)]
	m:SetAttribute("Cevher", tur.ad)
	local n = o.rnd:NextInteger(9, 16)
	for i = 1, n do
		local a = o.rnd:NextNumber(0, math.pi * 2)
		local d = o.rnd:NextNumber(0, 2.2) * s
		local y = math.max(0.4, 1.6 - d / (2.4 * s) * 1.2) * o.rnd:NextNumber(0.6, 1.1) * s
		local b = o.rnd:NextNumber(0.7, 1.35) * s
		local kaya = o.rnd:NextNumber() < 0.45
		p(m, cf, Vector3.new(b, b * 0.85, b),
			CFrame.new(math.cos(a) * d, y * 0.5, math.sin(a) * d)
				* CFrame.Angles(o.rnd:NextNumber(-0.4, 0.4), o.rnd:NextNumber(0, 6.28), o.rnd:NextNumber(-0.4, 0.4)),
			kaya and o.renkTas or tur.renk, kaya and Enum.Material.Slate or tur.mat)
	end
	return bitir(m, o, "CevherYigini")
end

-- ==================================================================
-- 8. MOLOZ YIĞINI — kırık taş / kaya döküntüsü
-- ==================================================================
local function molozYigini(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "MolozYigini", cf)
	local n = o.rnd:NextInteger(12, 22)
	for _ = 1, n do
		local a = o.rnd:NextNumber(0, math.pi * 2)
		local d = o.rnd:NextNumber(0, 3.4) * s
		local b = o.rnd:NextNumber(0.5, 1.8) * s
		local koyu = o.rnd:NextNumber() < 0.35
		p(m, cf, Vector3.new(b, b * o.rnd:NextNumber(0.4, 0.8), b * o.rnd:NextNumber(0.7, 1.3)),
			CFrame.new(math.cos(a) * d, b * 0.3, math.sin(a) * d)
				* CFrame.Angles(o.rnd:NextNumber(-0.5, 0.5), o.rnd:NextNumber(0, 6.28), o.rnd:NextNumber(-0.5, 0.5)),
			koyu and o.renkKoyu or o.renkTas, Enum.Material.Slate)
	end
	yosunLekesi(m, cf, o, Vector3.new(0, 0.3 * s, 0), Vector3.new(3 * s, 0.4 * s, 3 * s), 7)
	return bitir(m, o, "MolozYigini")
end

-- ==================================================================
-- 9. KAMP ATEŞİ — taş halka + odun + alev + oturma kütükleri
-- ==================================================================
local function kampAtesi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "KampAtesi", cf)
	-- taş halka
	for i = 1, 9 do
		local a = (i / 9) * math.pi * 2 + o.rnd:NextNumber(-0.1, 0.1)
		local b = o.rnd:NextNumber(0.7, 1.1) * s
		p(m, cf, Vector3.new(b, b * 0.7, b),
			CFrame.new(math.cos(a) * 2.2 * s, b * 0.35, math.sin(a) * 2.2 * s) * CFrame.Angles(0, a, 0),
			o.renkTas, Enum.Material.Slate)
	end
	-- odunlar (çapraz)
	for i = 1, 4 do
		local a = (i / 4) * math.pi
		p(m, cf, Vector3.new(3.2 * s, 0.4 * s, 0.4 * s),
			CFrame.new(0, 0.4 * s, 0) * CFrame.Angles(0, a, math.rad(o.rnd:NextNumber(-14, 14))),
			AHSAP_KOYU, Enum.Material.Wood)
	end
	-- kor + alev
	p(m, cf, Vector3.new(1.6 * s, 0.3 * s, 1.6 * s), CFrame.new(0, 0.28 * s, 0), Color3.fromRGB(210, 92, 30),
		Enum.Material.Neon, { Transparency = 0.3, CanCollide = false })
	local alev = p(m, cf, Vector3.new(1.3 * s, 1.6 * s, 1.3 * s), CFrame.new(0, 1.2 * s, 0), ATES,
		Enum.Material.Neon, { Transparency = 0.15, CanCollide = false })
	p(m, cf, Vector3.new(0.8 * s, 1.0 * s, 0.8 * s), CFrame.new(0, 2.1 * s, 0), Color3.fromRGB(255, 226, 140),
		Enum.Material.Neon, { Transparency = 0.35, CanCollide = false })
	atesIsigi(alev, o, 34 * s, 3.2)
	-- oturma kütükleri
	local kutuk = o.rnd:NextInteger(2, 3)
	for i = 1, kutuk do
		local a = o.rnd:NextNumber(0, math.pi * 2)
		yuvarla(p(m, cf, Vector3.new(1.3 * s, 1.5 * s, 1.5 * s),
			CFrame.new(math.cos(a) * 4.2 * s, 0.75 * s, math.sin(a) * 4.2 * s) * CFrame.Angles(0, 0, math.rad(90)),
			AHSAP, Enum.Material.Wood))
	end
	return bitir(m, o, "KampAtesi")
end

-- ==================================================================
-- 10. ALET STANDI — kazma/kürek rafı
-- ==================================================================
local function aletStandi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "AletStandi", cf)
	-- raf
	for _, sx in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(0.35 * s, 4.2 * s, 0.35 * s), CFrame.new(sx * 1.8 * s, 2.1 * s, 0), AHSAP, Enum.Material.Wood)
	end
	p(m, cf, Vector3.new(4.2 * s, 0.3 * s, 0.5 * s), CFrame.new(0, 4.0 * s, 0), AHSAP, Enum.Material.Wood)
	p(m, cf, Vector3.new(4.2 * s, 0.3 * s, 0.5 * s), CFrame.new(0, 1.6 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	-- kazmalar
	local n = o.rnd:NextInteger(2, 3)
	for i = 1, n do
		local x = (-1 + (i - 0.5) * (2 / n)) * 1.4 * s
		local egim = math.rad(o.rnd:NextNumber(-7, 7))
		p(m, cf, Vector3.new(0.22 * s, 3.6 * s, 0.22 * s),
			CFrame.new(x, 1.9 * s, -0.35 * s) * CFrame.Angles(0, 0, egim), AHSAP_KOYU, Enum.Material.Wood)
		-- kazma başı (T)
		p(m, cf, Vector3.new(1.7 * s, 0.34 * s, 0.34 * s),
			CFrame.new(x, 3.6 * s, -0.35 * s) * CFrame.Angles(0, 0, egim + math.rad(o.rnd:NextNumber(-6, 6))),
			DEMIR, Enum.Material.Metal)
		p(m, cf, Vector3.new(0.45 * s, 0.5 * s, 0.42 * s),
			CFrame.new(x, 3.5 * s, -0.35 * s) * CFrame.Angles(0, 0, egim), AHSAP, Enum.Material.Wood)
	end
	return bitir(m, o, "AletStandi")
end

-- ==================================================================
-- 11. TABELA — ahşap yön/uyarı tabelası
-- ==================================================================
local function tabela(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Tabela", cf)
	p(m, cf, Vector3.new(0.4 * s, 4.4 * s, 0.4 * s), CFrame.new(0, 2.2 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	local pano = p(m, cf, Vector3.new(5.2 * s, 2.4 * s, 0.3 * s), CFrame.new(0, 3.9 * s, 0), AHSAP, Enum.Material.WoodPlanks)
	-- çerçeve
	for _, dy in ipairs({ -1.05, 1.05 }) do
		p(m, cf, Vector3.new(5.4 * s, 0.24 * s, 0.36 * s), CFrame.new(0, (3.9 + dy) * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	end
	-- yazı
	local yazilar = { "MADEN", "DİKKAT!", "TÜNEL →", "OCAK", "GİRİŞ" }
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(520, 240)
	sg.LightInfluence = 1
	sg.Parent = pano
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.LuckiestGuy
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(40, 26, 16)
	tl.Text = yazilar[o.rnd:NextInteger(1, #yazilar)]
	tl.Parent = sg
	-- taş kaide
	p(m, cf, Vector3.new(1.5 * s, 0.5 * s, 1.5 * s), CFrame.new(0, 0.25 * s, 0), o.renkTas, Enum.Material.Slate)
	return bitir(m, o, "Tabela")
end

-- ==================================================================
-- 12. ÇADIR — madenci kamp çadırı
-- ==================================================================
local function cadir(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "Cadir", cf)
	local en, boy, yuk = 7 * s, 8 * s, 5 * s
	-- iki eğik yüz
	for _, sx in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(0.28 * s, math.sqrt((en / 2) ^ 2 + yuk ^ 2), boy),
			CFrame.new(sx * en / 4, yuk / 2, 0) * CFrame.Angles(0, 0, sx * math.atan2(en / 2, yuk)),
			BEZ, Enum.Material.Fabric)
	end
	-- sırt direği
	p(m, cf, Vector3.new(0.3 * s, 0.3 * s, boy + 1.2 * s), CFrame.new(0, yuk, 0), AHSAP_KOYU, Enum.Material.Wood)
	-- arka kapak (üçgen yerine iki plaka)
	p(m, cf, Vector3.new(en * 0.62, yuk * 0.62, 0.2 * s), CFrame.new(0, yuk * 0.3, boy / 2), BEZ, Enum.Material.Fabric)
	-- gergi kazıkları
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			p(m, cf, Vector3.new(0.16 * s, 0.9 * s, 0.16 * s),
				CFrame.new(sx * (en / 2 + 1.4 * s), 0.4 * s, sz * boy / 2.6) * CFrame.Angles(0, 0, sx * 0.3),
				AHSAP_KOYU, Enum.Material.Wood)
			p(m, cf, Vector3.new(0.1 * s, 3.2 * s, 0.1 * s),
				CFrame.new(sx * (en / 2 + 0.7 * s), 1.9 * s, sz * boy / 2.6) * CFrame.Angles(0, 0, sx * math.rad(38)),
				Color3.fromRGB(120, 110, 92), Enum.Material.Fabric)
		end
	end
	return bitir(m, o, "Cadir")
end

-- ==================================================================
-- 13. ÇİT / BARİYER — kazı alanı sınırı
-- ==================================================================
local function citHatti(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "CitHatti", cf)
	local bolme = o.rnd:NextInteger(3, 5)
	local aralik = 5 * s
	for i = 0, bolme do
		local x = (i - bolme / 2) * aralik
		local kirik = (o.rnd:NextNumber() < o.yikik * 0.35)
		local egim = kirik and math.rad(o.rnd:NextNumber(-24, 24)) or math.rad(o.rnd:NextNumber(-3, 3))
		p(m, cf, Vector3.new(0.42 * s, 4 * s, 0.42 * s),
			CFrame.new(x, 2 * s, 0) * CFrame.Angles(0, 0, egim), AHSAP, Enum.Material.Wood)
	end
	for i = 1, bolme do
		local x = (i - 0.5 - bolme / 2) * aralik
		if not (o.rnd:NextNumber() < o.yikik * 0.3) then
			for _, dy in ipairs({ 1.4, 3.1 }) do
				p(m, cf, Vector3.new(aralik + 0.2 * s, 0.3 * s, 0.24 * s),
					CFrame.new(x, dy * s, 0) * CFrame.Angles(0, 0, math.rad(o.rnd:NextNumber(-2, 2))),
					AHSAP_KOYU, Enum.Material.Wood)
			end
		end
	end
	return bitir(m, o, "CitHatti")
end

-- ==================================================================
-- 14. DİNAMİT SANDIĞI — kırmızı çubuklar + uyarı
-- ==================================================================
local function dinamitSandigi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "DinamitSandigi", cf)
	p(m, cf, Vector3.new(3 * s, 1.8 * s, 2.2 * s), CFrame.new(0, 0.9 * s, 0), AHSAP_KOYU, Enum.Material.WoodPlanks)
	p(m, cf, Vector3.new(3.1 * s, 0.2 * s, 2.3 * s), CFrame.new(0, 1.75 * s, 0), DEMIR, Enum.Material.Metal)
	-- kapak açık: içeride dinamitler
	for i = 1, 5 do
		yuvarla(p(m, cf, Vector3.new(1.6 * s, 0.34 * s, 0.34 * s),
			CFrame.new(-0.9 * s + (i - 1) * 0.42 * s, 1.9 * s, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)),
			Color3.fromRGB(178, 44, 40), Enum.Material.Fabric))
	end
	-- fitil
	p(m, cf, Vector3.new(0.1 * s, 0.7 * s, 0.1 * s), CFrame.new(0.35 * s, 2.3 * s, 0), Color3.fromRGB(210, 190, 140), Enum.Material.Fabric)
	-- uyarı plakası
	p(m, cf, Vector3.new(1.2 * s, 1.0 * s, 0.1 * s), CFrame.new(0, 1.0 * s, -1.16 * s), Color3.fromRGB(232, 190, 40), Enum.Material.SmoothPlastic)
	return bitir(m, o, "DinamitSandigi")
end

-- ==================================================================
-- 15. SU KOVASI & OLUK — ahşap oluk + kova
-- ==================================================================
local function suOlugu(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "SuOlugu", cf)
	local uzun = 9 * s
	-- oluk gövdesi
	p(m, cf, Vector3.new(uzun, 0.3 * s, 2.2 * s), CFrame.new(0, 1.2 * s, 0), AHSAP, Enum.Material.Wood)
	for _, sz in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(uzun, 1.0 * s, 0.3 * s), CFrame.new(0, 1.6 * s, sz * 1.1 * s), AHSAP, Enum.Material.Wood)
	end
	-- su
	p(m, cf, Vector3.new(uzun - 0.4 * s, 0.5 * s, 1.9 * s), CFrame.new(0, 1.6 * s, 0),
		Color3.fromRGB(64, 132, 196), Enum.Material.Glass, { Transparency = 0.35, CanCollide = false })
	-- ayaklar
	for _, sx in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(0.4 * s, 1.2 * s, 1.9 * s), CFrame.new(sx * (uzun / 2 - 0.8 * s), 0.6 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	end
	-- kova
	local kx = (uzun / 2 + 1.6 * s) * (o.rnd:NextNumber() < 0.5 and -1 or 1)
	yuvarla(p(m, cf, Vector3.new(1.4 * s, 1.5 * s, 1.5 * s), CFrame.new(kx, 0.7 * s, 0.6 * s) * CFrame.Angles(0, 0, math.rad(90)),
		DEMIR, Enum.Material.Metal))
	yosunLekesi(m, cf, o, Vector3.new(0, 1.0 * s, 0), Vector3.new(uzun / 2, 0.4 * s, 1.0 * s), 5)
	return bitir(m, o, "SuOlugu")
end

-- ==================================================================
-- 16. ODUN YIĞINI — kesilmiş kütükler
-- ==================================================================
local function odunYigini(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "OdunYigini", cf)
	local satir = o.rnd:NextInteger(2, 4)
	for r = 1, satir do
		local adet = math.max(1, 5 - r)
		for i = 1, adet do
			local x = (i - (adet + 1) / 2) * 1.15 * s
			local y = (r - 0.5) * 1.05 * s
			yuvarla(p(m, cf, Vector3.new(3.4 * s, 1.0 * s, 1.0 * s),
				CFrame.new(x, y, o.rnd:NextNumber(-0.15, 0.15) * s) * CFrame.Angles(0, math.rad(90), math.rad(90)),
				o.rnd:NextNumber() < 0.4 and AHSAP_KOYU or AHSAP, Enum.Material.Wood))
		end
	end
	-- yan destek kazıklar
	for _, sx in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(0.3 * s, satir * 1.2 * s, 0.3 * s),
			CFrame.new(sx * 3.0 * s, satir * 0.6 * s, 0), AHSAP_KOYU, Enum.Material.Wood)
	end
	return bitir(m, o, "OdunYigini")
end

-- ==================================================================
-- 17. EL ARABASI — devrik ya da dolu
-- ==================================================================
local function elArabasi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "ElArabasi", cf)
	local devrik = o.rnd:NextNumber() < o.yikik * 0.5
	local taban = devrik and CFrame.new(0, 0.9 * s, 0) * CFrame.Angles(math.rad(o.rnd:NextNumber(-20, 20)), o.rnd:NextNumber(0, 6.28), math.rad(74))
		or CFrame.new(0, 1.5 * s, 0)
	-- kasa
	p(m, cf, Vector3.new(3.2 * s, 1.4 * s, 2.2 * s), taban, DEMIR, Enum.Material.CorrodedMetal)
	p(m, cf, Vector3.new(3.0 * s, 0.9 * s, 2.0 * s), taban * CFrame.new(0, 0.5 * s, 0), Color3.fromRGB(48, 46, 46),
		Enum.Material.SmoothPlastic)
	-- kollar
	for _, sz in ipairs({ -1, 1 }) do
		p(m, cf, Vector3.new(4.4 * s, 0.24 * s, 0.24 * s),
			taban * CFrame.new(-1.8 * s, -0.4 * s, sz * 0.8 * s) * CFrame.Angles(0, 0, math.rad(-6)),
			AHSAP, Enum.Material.Wood)
	end
	-- tekerlek
	yuvarla(p(m, cf, Vector3.new(0.4 * s, 1.9 * s, 1.9 * s),
		taban * CFrame.new(1.6 * s, -0.9 * s, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)),
		Color3.fromRGB(38, 36, 36), Enum.Material.Rubber))
	-- yük
	if not devrik then
		for i = 1, o.rnd:NextInteger(3, 6) do
			local b = o.rnd:NextNumber(0.5, 0.9) * s
			p(m, cf, Vector3.new(b, b, b),
				taban * CFrame.new(o.rnd:NextNumber(-1.2, 1.2) * s, 0.9 * s, o.rnd:NextNumber(-0.7, 0.7) * s)
					* CFrame.Angles(o.rnd:NextNumber(0, 3), o.rnd:NextNumber(0, 3), 0),
				o.renkTas, Enum.Material.Slate)
		end
	end
	return bitir(m, o, "ElArabasi")
end

-- ==================================================================
-- 18. BAYRAK DİREĞİ — saha bayrağı
-- ==================================================================
local function bayrakDiregi(kok, cf, o)
	local s = o.olcek
	local m = yeniModel(kok, "BayrakDiregi", cf)
	p(m, cf, Vector3.new(2.2 * s, 0.6 * s, 2.2 * s), CFrame.new(0, 0.3 * s, 0), o.renkTas, Enum.Material.Slate)
	p(m, cf, Vector3.new(0.32 * s, 11 * s, 0.32 * s), CFrame.new(0, 5.8 * s, 0), DEMIR, Enum.Material.Metal)
	local renkler = {
		Color3.fromRGB(196, 62, 54), Color3.fromRGB(58, 122, 196),
		Color3.fromRGB(232, 176, 48), Color3.fromRGB(64, 168, 96),
	}
	local r = renkler[o.rnd:NextInteger(1, #renkler)]
	-- dalgalı bayrak: 4 hafif kaydırılmış plaka
	for i = 1, 4 do
		local t = (i - 1) / 3
		p(m, cf, Vector3.new(1.5 * s, 2.6 * s, 0.14 * s),
			CFrame.new((0.9 + i * 1.4) * s, 10.0 * s - t * 0.3 * s, math.sin(t * 3.2) * 0.45 * s)
				* CFrame.Angles(0, math.sin(t * 3.2) * 0.35, 0),
			r, Enum.Material.Fabric)
	end
	p(m, cf, Vector3.new(0.5 * s, 0.5 * s, 0.5 * s), CFrame.new(0, 11.4 * s, 0), Color3.fromRGB(232, 196, 62), Enum.Material.Metal)
	yosunLekesi(m, cf, o, Vector3.new(0, 0.6 * s, 0), Vector3.new(1.0 * s, 0.05, 1.0 * s), 3)
	return bitir(m, o, "BayrakDiregi")
end

M.YAPILAR = {
	{ ad = "susMesale", etiket = "Meşale", ikon = "🔥", kategori = "Süs", fn = mesale },
	{ ad = "susFener", etiket = "Fener Direği", ikon = "🏮", kategori = "Süs", fn = fenerDiregi },
	{ ad = "susSandik", etiket = "Sandık İstifi", ikon = "📦", kategori = "Süs", fn = sandik },
	{ ad = "susVaril", etiket = "Variller", ikon = "🛢", kategori = "Süs", fn = varil },
	{ ad = "susDestek", etiket = "Ahşap Destek", ikon = "🚧", kategori = "Süs", fn = ahsapDestek },
	{ ad = "susIskele", etiket = "İskele", ikon = "📶", kategori = "Süs", fn = iskele },
	{ ad = "susCevherYigin", etiket = "Cevher Yığını", ikon = "💎", kategori = "Süs", fn = cevherYigini },
	{ ad = "susMoloz", etiket = "Moloz Yığını", ikon = "⚒", kategori = "Süs", fn = molozYigini },
	{ ad = "susKampAtesi", etiket = "Kamp Ateşi", ikon = "🔥", kategori = "Süs", fn = kampAtesi },
	{ ad = "susAletStandi", etiket = "Alet Standı", ikon = "⛏", kategori = "Süs", fn = aletStandi },
	{ ad = "susTabela", etiket = "Tabela", ikon = "🚏", kategori = "Süs", fn = tabela },
	{ ad = "susCadir", etiket = "Çadır", ikon = "⛺", kategori = "Süs", fn = cadir },
	{ ad = "susCit", etiket = "Çit Hattı", ikon = "🚧", kategori = "Süs", fn = citHatti },
	{ ad = "susDinamit", etiket = "Dinamit Sandığı", ikon = "🧨", kategori = "Süs", fn = dinamitSandigi },
	{ ad = "susSuOlugu", etiket = "Su Oluğu", ikon = "💧", kategori = "Süs", fn = suOlugu },
	{ ad = "susOdun", etiket = "Odun Yığını", ikon = "🌲", kategori = "Süs", fn = odunYigini },
	{ ad = "susElArabasi", etiket = "El Arabası", ikon = "🛒", kategori = "Süs", fn = elArabasi },
	{ ad = "susBayrak", etiket = "Bayrak Direği", ikon = "🚩", kategori = "Süs", fn = bayrakDiregi },
}

return M
