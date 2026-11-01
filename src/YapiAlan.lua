-- SWEAX TERRAIN — YapiAlan: landforms (10) that carve or raise terrain where you click.
-- ARAZİ ALANLARI (terrain şekillendirme hazırları)
-- MİMARİ ÖZET
--  • Yapı kütüphanesinin (YapiTemel/YapiMaden = PART yapıları) terrain karşılığı: tek tıkla çukur, plato,
--    sırt, mağara ağzı, kanyon, gölet açar; sahneyi kurmadan önce zemin bunlarla hazırlanır.
--  • SÖZLEŞME yapı fonksiyonlarıyla AYNI kalıp: fn(kok, cf, o) -> Model|nil, ama bunlar Instance değil
--    TERRAIN yazar; geri dönen Model yalnız "işaretçi"dir (SweaxLandform niteliği + bbox) — silinince terrain KALIR
--    (terrain geri alma: Ctrl+Z ya da ÜRET sekmesindeki temizleme).
--  • Her alan ChangeHistory ile geri alınabilir; mevcut araziyi SİLMEZ, üstüne işler.
--  • Malzeme paleti taş yapılarla ortak: taş gövde + koyu derz + yosun yeşili yüzey.
--  • Tüm boyutlar o.olcek ile ölçeklenir; rastgelelik yalnız o.rnd üzerinden (aynı tohum → aynı sonuç).
local Terrain = workspace.Terrain
local M = {}

local COZ = 4 -- voksel çözünürlüğü

-- ---------- yardımcılar ----------
local function say(v, varsayilan)
	v = tonumber(v)
	return (v and v == v) and v or varsayilan
end

-- Kutu doldur/oy: cf yerel, boyut dünya; mat nil ise Air (oyma)
local function kutu(cf, boyut, mat)
	local ok = pcall(function()
		Terrain:FillBlock(cf, boyut, mat or Enum.Material.Air)
	end)
	return ok
end

local function kure(merkez, r, mat)
	pcall(function() Terrain:FillBall(merkez, math.max(r, COZ), mat or Enum.Material.Air) end)
end

local function silindir(cf, yukseklik, r, mat)
	pcall(function() Terrain:FillCylinder(cf, math.max(yukseklik, COZ), math.max(r, COZ), mat or Enum.Material.Air) end)
end

-- İşaretçi model: alanın nerede açıldığını gösterir (görünmez kutu + nitelik)
local function isaretci(kok, ad, cf, boyut, bilgi)
	local m = Instance.new("Model")
	m.Name = ad
	local p = Instance.new("Part")
	p.Name = "Alan"
	p.Size = boyut
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = m
	m.PrimaryPart = p
	m:SetAttribute("SweaxLandform", ad)
	if bilgi then m:SetAttribute("Bilgi", bilgi) end
	m.Parent = kok
	return m
end

local function malzeme(o, varsayilan)
	local m = o and o.malzeme
	if typeof(m) == "EnumItem" then return m end
	if type(m) == "string" and Enum.Material[m] then return Enum.Material[m] end
	return varsayilan
end

-- ==================================================================
-- 1. TAŞ OCAĞI ÇUKURU — kademeli (teraslı) açık maden çukuru
-- ==================================================================
local function tasOcagi(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local kademe = math.clamp(math.floor(say(o.kademe, 4)), 2, 7)
	local ustR = say(o.yaricap, 60) * s
	local derinlik = say(o.derinlik, 9) * s -- kademe başına
	local daralma = 0.74 -- her kademede yarıçap oranı
	local r = ustR
	local y = cf.Y
	for k = 1, kademe do
		-- teras: silindir oyma; kenarları rastgele bozarak doğallık
		silindir(CFrame.new(cf.X, y - derinlik / 2, cf.Z) * CFrame.Angles(0, 0, math.rad(90)), derinlik + COZ, r, nil)
		if rnd then
			for _ = 1, 3 do
				local a = rnd:NextNumber(0, math.pi * 2)
				local d = r * rnd:NextNumber(0.75, 1.02)
				kure(Vector3.new(cf.X + math.cos(a) * d, y - derinlik * 0.5, cf.Z + math.sin(a) * d),
					r * rnd:NextNumber(0.10, 0.20), nil)
			end
		end
		y -= derinlik
		r *= daralma
	end
	-- taban: küçük düz alan + moloz dokusu (taş)
	silindir(CFrame.new(cf.X, y - COZ, cf.Z) * CFrame.Angles(0, 0, math.rad(90)), COZ * 2, r, malzeme(o, Enum.Material.Rock))
	return isaretci(kok, "Alan_TasOcagi", CFrame.new(cf.X, cf.Y - (kademe * derinlik) / 2, cf.Z),
		Vector3.new(ustR * 2, kademe * derinlik, ustR * 2), ("%d kademe · %d stud derin"):format(kademe, math.floor(kademe * derinlik)))
end

-- ==================================================================
-- 2. MADEN PLATOSU — düz, yükseltilmiş çalışma alanı (üs kurmak için)
-- ==================================================================
local function plato(kok, cf, o)
	local s = say(o.olcek, 1)
	local en = say(o.en, 120) * s
	local boy = say(o.boy, 120) * s
	local yuk = say(o.yukseklik, 14) * s
	local mat = malzeme(o, Enum.Material.Rock)
	-- gövde
	kutu(CFrame.new(cf.X, cf.Y + yuk / 2 - 2, cf.Z), Vector3.new(en, yuk + 4, boy), mat)
	-- üst yüzey kaplaması (çim/kum/taş — o.yuzey)
	local yuzey = o.yuzey
	if typeof(yuzey) == "EnumItem" then
		kutu(CFrame.new(cf.X, cf.Y + yuk - 1, cf.Z), Vector3.new(en, 3, boy), yuzey)
	end
	-- kenar yumuşatma: köşelere küre
	if o.rnd then
		for _ = 1, 8 do
			local a = o.rnd:NextNumber(0, math.pi * 2)
			kure(Vector3.new(cf.X + math.cos(a) * en * 0.5, cf.Y + yuk * o.rnd:NextNumber(0.2, 0.9), cf.Z + math.sin(a) * boy * 0.5),
				o.rnd:NextNumber(6, 14) * s, mat)
		end
	end
	return isaretci(kok, "Alan_Plato", CFrame.new(cf.X, cf.Y + yuk / 2, cf.Z), Vector3.new(en, yuk, boy),
		("%d×%d · %d yüksek"):format(math.floor(en), math.floor(boy), math.floor(yuk)))
end

-- ==================================================================
-- 3. KAYA SIRTI — arkaya duvar/sırt (madenin arkasına dağ hissi)
-- ==================================================================
local function kayaSirti(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local uzunluk = say(o.uzunluk, 140) * s
	local yuk = say(o.yukseklik, 40) * s
	local kalinlik = say(o.kalinlik, 26) * s
	local mat = malzeme(o, Enum.Material.Rock)
	local adim = math.max(COZ * 3, uzunluk / 12)
	local n = math.floor(uzunluk / adim)
	for i = 0, n do
		local t = i / math.max(n, 1)
		local yerel = (t - 0.5) * uzunluk
		local h = yuk * (0.55 + 0.45 * math.sin(t * math.pi)) -- ortası yüksek sırt
		if rnd then h *= rnd:NextNumber(0.82, 1.18) end
		local nokta = cf * CFrame.new(yerel, 0, 0)
		kutu(CFrame.new(nokta.X, cf.Y + h / 2 - 4, nokta.Z),
			Vector3.new(adim * 1.6, h + 8, kalinlik * (rnd and rnd:NextNumber(0.8, 1.2) or 1)), mat)
		if rnd and rnd:NextNumber() < 0.5 then
			kure(Vector3.new(nokta.X, cf.Y + h * rnd:NextNumber(0.4, 1.0), nokta.Z + rnd:NextNumber(-1, 1) * kalinlik * 0.4),
				rnd:NextNumber(5, 12) * s, mat)
		end
	end
	return isaretci(kok, "Alan_KayaSirti", CFrame.new(cf.X, cf.Y + yuk / 2, cf.Z),
		Vector3.new(uzunluk, yuk, kalinlik * 1.4), ("%d uzun · %d yüksek"):format(math.floor(uzunluk), math.floor(yuk)))
end

-- ==================================================================
-- 4. MAĞARA AĞZI — tepe + içine oyulmuş tünel (girişe yapı konur)
-- ==================================================================
local function magaraAgzi(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local tepeR = say(o.yaricap, 46) * s
	local tepeY = say(o.yukseklik, 34) * s
	local agizR = say(o.agiz, 9) * s
	local derinlik = say(o.derinlik, 60) * s
	local mat = malzeme(o, Enum.Material.Rock)
	-- tepe kütlesi (birkaç küreyle organik)
	kure(Vector3.new(cf.X, cf.Y + tepeY * 0.35, cf.Z), tepeR, mat)
	if rnd then
		for _ = 1, 5 do
			local a = rnd:NextNumber(0, math.pi * 2)
			kure(Vector3.new(cf.X + math.cos(a) * tepeR * 0.5, cf.Y + rnd:NextNumber(0.1, 0.6) * tepeY,
				cf.Z + math.sin(a) * tepeR * 0.5), tepeR * rnd:NextNumber(0.45, 0.72), mat)
		end
	end
	-- tünel: -Z yönünde oy (yapı sözleşmesi: -Z ön)
	local yon = cf.LookVector
	local adim = agizR * 0.8
	local n = math.floor(derinlik / adim)
	for i = 0, n do
		local p = Vector3.new(cf.X, cf.Y + agizR * 0.75, cf.Z) + yon * (i * adim)
		local r = agizR * (1 - 0.25 * (i / math.max(n, 1)))
		kure(p, r, nil)
	end
	-- ağzın önünü düzle (yapı oturtmak için)
	kutu(CFrame.new(cf.X, cf.Y - 2, cf.Z) + yon * (-agizR * 1.6), Vector3.new(agizR * 4, 6, agizR * 3), mat)
	return isaretci(kok, "Alan_MagaraAgzi", CFrame.new(cf.X, cf.Y + tepeY / 2, cf.Z),
		Vector3.new(tepeR * 2, tepeY, tepeR * 2 + derinlik), ("ağız %d · derinlik %d"):format(math.floor(agizR * 2), math.floor(derinlik)))
end

-- ==================================================================
-- 5. KANYON YARIĞI — dar, derin yarık (köprü kurmak için)
-- ==================================================================
local function kanyon(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local uzunluk = say(o.uzunluk, 160) * s
	local genislik = say(o.genislik, 22) * s
	local derinlik = say(o.derinlik, 40) * s
	local adim = math.max(COZ * 2, uzunluk / 16)
	local n = math.floor(uzunluk / adim)
	for i = 0, n do
		local t = i / math.max(n, 1)
		local kayma = (rnd and rnd:NextNumber(-1, 1) or 0) * genislik * 0.35 -- menderes
		local g = genislik * (0.8 + 0.4 * math.sin(t * math.pi * 2))
		local nokta = cf * CFrame.new((t - 0.5) * uzunluk, 0, kayma)
		kutu(CFrame.new(nokta.X, cf.Y - derinlik / 2 + 2, nokta.Z), Vector3.new(adim * 1.6, derinlik + 8, g), nil)
	end
	return isaretci(kok, "Alan_Kanyon", CFrame.new(cf.X, cf.Y - derinlik / 2, cf.Z),
		Vector3.new(uzunluk, derinlik, genislik * 2), ("%d uzun · %d derin"):format(math.floor(uzunluk), math.floor(derinlik)))
end

-- ==================================================================
-- 6. GÖLET ÇUKURU — su dolu havuz (kenarında kum)
-- ==================================================================
local function golet(kok, cf, o)
	local s = say(o.olcek, 1)
	local r = say(o.yaricap, 40) * s
	local derinlik = say(o.derinlik, 12) * s
	-- çanak
	kure(Vector3.new(cf.X, cf.Y - derinlik * 0.35, cf.Z), r, nil)
	silindir(CFrame.new(cf.X, cf.Y - derinlik / 2, cf.Z) * CFrame.Angles(0, 0, math.rad(90)), derinlik, r * 0.92, nil)
	-- su (üst yarısı)
	silindir(CFrame.new(cf.X, cf.Y - derinlik * 0.45, cf.Z) * CFrame.Angles(0, 0, math.rad(90)),
		derinlik * 0.9, r * 0.88, Enum.Material.Water)
	-- kıyı kumu
	if o.kum ~= false then
		silindir(CFrame.new(cf.X, cf.Y - 1, cf.Z) * CFrame.Angles(0, 0, math.rad(90)), 4, r * 1.12, Enum.Material.Sand)
		silindir(CFrame.new(cf.X, cf.Y - 1, cf.Z) * CFrame.Angles(0, 0, math.rad(90)), 5, r * 0.9, nil)
		silindir(CFrame.new(cf.X, cf.Y - derinlik * 0.45, cf.Z) * CFrame.Angles(0, 0, math.rad(90)),
			derinlik * 0.9, r * 0.88, Enum.Material.Water)
	end
	return isaretci(kok, "Alan_Golet", CFrame.new(cf.X, cf.Y - derinlik / 2, cf.Z),
		Vector3.new(r * 2.2, derinlik, r * 2.2), ("yarıçap %d · derinlik %d"):format(math.floor(r), math.floor(derinlik)))
end

-- ==================================================================
-- 7. CEVHER YATAĞI — terrain içinde renkli malzeme damarı
-- ==================================================================
local function cevherYatagi(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local r = say(o.yaricap, 26) * s
	local mat = malzeme(o, Enum.Material.CrackedLava)
	-- ana kütle taş, içinde damar
	kure(Vector3.new(cf.X, cf.Y + r * 0.4, cf.Z), r, Enum.Material.Rock)
	local n = math.floor(say(o.damar, 6))
	for i = 1, n do
		local a = rnd and rnd:NextNumber(0, math.pi * 2) or (i / n) * math.pi * 2
		local d = r * (rnd and rnd:NextNumber(0.2, 0.7) or 0.5)
		kure(Vector3.new(cf.X + math.cos(a) * d, cf.Y + r * (rnd and rnd:NextNumber(0.2, 0.7) or 0.45), cf.Z + math.sin(a) * d),
			r * (rnd and rnd:NextNumber(0.14, 0.26) or 0.2), mat)
	end
	return isaretci(kok, "Alan_CevherYatagi", CFrame.new(cf.X, cf.Y + r * 0.4, cf.Z),
		Vector3.new(r * 2, r * 2, r * 2), ("%d damar"):format(n))
end

-- ==================================================================
-- 8. DÜZLE — alanı tam düz yap (üs/yapı kurmadan önce)
-- ==================================================================
local function duzle(kok, cf, o)
	local s = say(o.olcek, 1)
	local en = say(o.en, 100) * s
	local boy = say(o.boy, 100) * s
	local mat = malzeme(o, Enum.Material.Rock)
	-- üstünü sil, altını doldur
	kutu(CFrame.new(cf.X, cf.Y + 60, cf.Z), Vector3.new(en, 120, boy), nil)
	kutu(CFrame.new(cf.X, cf.Y - 20, cf.Z), Vector3.new(en, 40, boy), mat)
	return isaretci(kok, "Alan_Duzle", CFrame.new(cf.X, cf.Y, cf.Z), Vector3.new(en, 8, boy),
		("%d×%d düzlendi"):format(math.floor(en), math.floor(boy)))
end

-- ==================================================================
-- 9. TEMİZLE — alandaki terrain'i tamamen sil
-- ==================================================================
local function temizle(kok, cf, o)
	local s = say(o.olcek, 1)
	local en = say(o.en, 100) * s
	local boy = say(o.boy, 100) * s
	local yuk = say(o.yukseklik, 120) * s
	kutu(CFrame.new(cf.X, cf.Y + yuk / 2 - 20, cf.Z), Vector3.new(en, yuk, boy), nil)
	return isaretci(kok, "Alan_Temizle", CFrame.new(cf.X, cf.Y, cf.Z), Vector3.new(en, 8, boy),
		("%d×%d temizlendi"):format(math.floor(en), math.floor(boy)))
end

-- ==================================================================
-- 10. TEPE — yumuşak tepecik (arka plan doldurmak için)
-- ==================================================================
local function tepe(kok, cf, o)
	local s = say(o.olcek, 1)
	local rnd = o.rnd
	local r = say(o.yaricap, 44) * s
	local yuk = say(o.yukseklik, 28) * s
	local mat = malzeme(o, Enum.Material.Ground)
	local katman = 5
	for i = 1, katman do
		local t = (i - 1) / katman
		kure(Vector3.new(cf.X + (rnd and rnd:NextNumber(-1, 1) * r * 0.12 or 0),
			cf.Y + yuk * t, cf.Z + (rnd and rnd:NextNumber(-1, 1) * r * 0.12 or 0)),
			r * (1 - t * 0.62), mat)
	end
	if o.yuzey ~= false then
		kure(Vector3.new(cf.X, cf.Y + yuk * 0.82, cf.Z), r * 0.42, Enum.Material.Grass)
	end
	return isaretci(kok, "Alan_Tepe", CFrame.new(cf.X, cf.Y + yuk / 2, cf.Z),
		Vector3.new(r * 2, yuk, r * 2), ("yarıçap %d · %d yüksek"):format(math.floor(r), math.floor(yuk)))
end

M.YAPILAR = {
	{ ad = "alanDuzle", etiket = "Düzle", ikon = "▬", kategori = "Alan", fn = duzle },
	{ ad = "alanTemizle", etiket = "Temizle", ikon = "🧽", kategori = "Alan", fn = temizle },
	{ ad = "alanPlato", etiket = "Maden Platosu", ikon = "⬛", kategori = "Alan", fn = plato },
	{ ad = "alanTasOcagi", etiket = "Taş Ocağı Çukuru", ikon = "🕳", kategori = "Alan", fn = tasOcagi },
	{ ad = "alanKanyon", etiket = "Kanyon Yarığı", ikon = "🏜", kategori = "Alan", fn = kanyon },
	{ ad = "alanMagaraAgzi", etiket = "Mağara Ağzı", ikon = "🚪", kategori = "Alan", fn = magaraAgzi },
	{ ad = "alanKayaSirti", etiket = "Kaya Sırtı", ikon = "⛰", kategori = "Alan", fn = kayaSirti },
	{ ad = "alanTepe", etiket = "Tepe", ikon = "🌄", kategori = "Alan", fn = tepe },
	{ ad = "alanGolet", etiket = "Gölet", ikon = "💧", kategori = "Alan", fn = golet },
	{ ad = "alanCevherYatagi", etiket = "Cevher Yatağı", ikon = "💎", kategori = "Alan", fn = cevherYatagi },
}

return M
