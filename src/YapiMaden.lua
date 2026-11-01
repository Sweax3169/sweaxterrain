-- SWEAX TERRAIN — YapiMaden: mining and industry structures (13).
-- Maden/endüstri hazır yapı kütüphanesi: arazinin üstüne "maden sahası" hissini kuran
-- tek-tık yapılar: tünel ağzı, koridor, vinç, ray, vagon, damar, kuyu, kamp,
-- depo, konveyör, fırın, cevher yığını, asansör kulesi.
-- Sözleşme: fn(kok, cf, o) -> Model. cf = TABAN MERKEZİ (y = zemin), yapı +Y'ye yükselir,
-- -Z "ön" kabul edilir. Tüm parçalar Anchored + CanCollide (yalnız fener/vitrin camı hariç),
-- yalnız Part kullanılır (MeshPart/Union YOK — hiçbir asset gerekmez).
-- Rastgelelik SADECE o.rnd üstünden: aynı tohum → birebir aynı yapı.
-- Ölçek: kutu() her boyutu ve her yerel konumu o.olcek ile çarpar (dönme korunur).
-- Bağımlılık YOK: yardımcılar (kutu/yosunla/asindir) bu dosyanın içinde tanımlıdır.
local M = {}

local E = Enum.Material
local PT = Enum.PartType

-- ---------- palet (taş yapılarla ortak üç iskelet renk + maden renkleri) ----------
local TAS = Color3.fromRGB(99, 95, 98)
local KOYU = Color3.fromRGB(68, 68, 68)
local YOSUN = Color3.fromRGB(44, 101, 29)
local TAS_ACIK = Color3.fromRGB(128, 124, 126)
local TAS_KOYU = Color3.fromRGB(74, 71, 74)
local AHSAP = Color3.fromRGB(104, 71, 42)
local AHSAP_KOYU = Color3.fromRGB(74, 50, 30)
local DEMIR = Color3.fromRGB(120, 124, 132)
local ALTIN = Color3.fromRGB(214, 170, 54)
local FENER = Color3.fromRGB(255, 206, 110)
local SU = Color3.fromRGB(60, 120, 190)
local CEV_CYAN = Color3.fromRGB(74, 214, 200)
local CEV_KIZIL = Color3.fromRGB(200, 60, 54)
local CEV_MOR = Color3.fromRGB(140, 90, 190)
local KARANLIK = Color3.fromRGB(6, 6, 8)
local ATES = Color3.fromRGB(255, 138, 40)
local KOMUR = Color3.fromRGB(32, 32, 34)
local BEZ = Color3.fromRGB(168, 152, 116)

-- ---------- ortak yardımcılar ----------
-- Model → { cf = taban CFrame, s = ölçek }. Zayıf anahtar: model silinince kayıt da düşer.
local TABAN = setmetatable({}, { __mode = "k" })

local function hazirla(o)
	-- eksik alanları doldur; çağıran yarım tablo verse de yapı bozulmasın
	o = o or {}
	local t = o.tohum or 12345
	return {
		olcek = o.olcek or 1,
		tohum = t,
		rnd = o.rnd or Random.new(t),
		yosun = o.yosun == nil and 0.5 or o.yosun,
		yikik = o.yikik == nil and 0.35 or o.yikik,
		isik = o.isik ~= false,
		renkTas = o.renkTas or TAS,
		renkKoyu = o.renkKoyu or KOYU,
		renkYosun = o.renkYosun or YOSUN,
		uzunluk = o.uzunluk,
		kavis = o.kavis,
		egim = o.egim,
		cevherRenk = o.cevherRenk,
	}
end

local function yeniModel(ad, cf, o)
	local m = Instance.new("Model")
	m.Name = ad
	m:SetAttribute("SweaxStructure", ad)
	m:SetAttribute("SweaxSeed", o.tohum)
	TABAN[m] = { cf = cf, s = o.olcek }
	return m
end

local function kutu(m, ad, boyut, yerelCF, renk, mat)
	-- yerelCF yapı tabanına GÖRE; konum ölçeklenir, dönme aynen taşınır
	local t = TABAN[m]
	local s = t.s
	local p = Instance.new("Part")
	p.Name = ad
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = true
	p.Material = mat or E.Slate
	p.Color = renk or TAS
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(
		math.max(0.05, boyut.X * s),
		math.max(0.05, boyut.Y * s),
		math.max(0.05, boyut.Z * s)
	)
	local konum = yerelCF.Position * s
	p.CFrame = t.cf * (CFrame.new(konum.X, konum.Y, konum.Z) * yerelCF.Rotation)
	p.Parent = m
	return p
end

local function sabit(p)
	-- aşındırma bu parçaya dokunmasın (taşıyıcı iskelet, neon, karanlık dolgu)
	p:SetAttribute("SweaxFixed", true)
	return p
end

local function silindir(m, ad, boyut, yerelCF, renk, mat)
	local p = kutu(m, ad, boyut, yerelCF, renk, mat)
	p.Shape = PT.Cylinder -- eksen X'tir: Size.X = kalınlık, Y/Z = çap
	return p
end

local function kure(m, ad, cap, yerelCF, renk, mat)
	local p = kutu(m, ad, Vector3.new(cap, cap, cap), yerelCF, renk, mat)
	p.Shape = PT.Ball
	return p
end

local function eksenKutu(m, ad, kalinlik, a, b, renk, mat)
	-- iki YEREL nokta arasına kiriş. Açıyı elle atan2 ile kurmak yanlış eğim veriyordu
	-- (vinç ayakları 38° yatıyordu, konveyör çaprazları savruluyordu — ekran görüntüsüyle ölçüldü).
	local yon = b - a
	local uz = yon.Magnitude
	if uz < 0.05 then return nil end
	-- dikey kirişte lookAt'in varsayılan yukarısı yönle paralel kalır → NaN; ekseni değiştir
	local ust = (math.abs(yon.Unit.Y) > 0.999) and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	local orta = (a + b) * 0.5
	return kutu(m, ad, Vector3.new(kalinlik, uz, kalinlik),
		CFrame.lookAt(orta, b, ust) * CFrame.Angles(math.pi * 0.5, 0, 0), renk, mat)
end

local function sap(o, k)
	-- simetrik sapma [-k, k] (yalnız o.rnd)
	return (o.rnd:NextNumber() - 0.5) * 2 * k
end

local function isikKoy(p, renk, menzil, parlak)
	local l = Instance.new("PointLight")
	l.Color = renk
	l.Range = menzil
	l.Brightness = parlak or 1.4
	l.Shadows = false
	l.Parent = p
end

local function yosunla(m, p, o)
	-- taş yüzeylere rastgele yosun yamaları; parça p'ye GÖRE konumlanır (dünya uzayında)
	local yg = o.yosun or 0
	if yg <= 0.02 then return end
	local r = o.rnd
	if r:NextNumber() > yg then return end
	local sz = p.Size
	local adet = (r:NextNumber() < yg * 0.6) and 2 or 1
	for _ = 1, adet do
		local yuz = r:NextInteger(1, 3)
		local kal = 0.12 * (TABAN[m] and TABAN[m].s or 1)
		local b, ofs
		-- yamalar KÜÇÜK tutulur: yüzün yarısını kaplayınca yosun değil, yeşil çıkartma gibi
		-- duruyordu (ilk ekran görüntüsü). Kenara doğru kaydırılır ki köşeden sarkmış görünsün.
		if yuz == 1 then -- üst yüz
			b = Vector3.new(sz.X * r:NextNumber(0.18, 0.44), kal, sz.Z * r:NextNumber(0.18, 0.44))
			ofs = CFrame.new((r:NextNumber() - 0.5) * sz.X * 0.5, sz.Y * 0.5 + kal * 0.5, (r:NextNumber() - 0.5) * sz.Z * 0.5)
		elseif yuz == 2 then -- ön/arka yüz
			local yon = (r:NextNumber() < 0.5) and 1 or -1
			b = Vector3.new(sz.X * r:NextNumber(0.16, 0.42), sz.Y * r:NextNumber(0.14, 0.34), kal)
			ofs = CFrame.new((r:NextNumber() - 0.5) * sz.X * 0.5, (r:NextNumber() - 0.5) * sz.Y * 0.45, yon * (sz.Z * 0.5 + kal * 0.5))
		else -- yan yüz
			local yon = (r:NextNumber() < 0.5) and 1 or -1
			b = Vector3.new(kal, sz.Y * r:NextNumber(0.14, 0.34), sz.Z * r:NextNumber(0.16, 0.42))
			ofs = CFrame.new(yon * (sz.X * 0.5 + kal * 0.5), (r:NextNumber() - 0.5) * sz.Y * 0.45, (r:NextNumber() - 0.5) * sz.Z * 0.5)
		end
		local y = Instance.new("Part")
		y.Name = "Yosun"
		y.Anchored = true
		y.CanCollide = true
		y.CastShadow = true
		y.Material = E.Grass
		y.Color = o.renkYosun
		y.Size = Vector3.new(math.max(0.05, b.X), math.max(0.05, b.Y), math.max(0.05, b.Z))
		y.TopSurface = Enum.SurfaceType.Smooth
		y.BottomSurface = Enum.SurfaceType.Smooth
		y.CFrame = p.CFrame * ofs
		y.Parent = m
	end
end

local function asindir(m, o)
	-- yıkık his: kenar parçalarını kaydır/döndür, azını komple eksilt (iskelet dokunulmaz)
	local yk = o.yikik or 0
	if yk <= 0.02 then return end
	local r = o.rnd
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p ~= m.PrimaryPart and p:GetAttribute("SweaxFixed") ~= true then
			local z = r:NextNumber()
			if z < yk * 0.10 then
				p:Destroy()
			elseif z < yk * 0.55 then
				local k = yk * (TABAN[m] and TABAN[m].s or 1)
				p.CFrame = p.CFrame
					* CFrame.new(sap(o, k * 0.5), sap(o, k * 0.3), sap(o, k * 0.5))
					* CFrame.Angles(sap(o, k * 0.16), sap(o, k * 0.22), sap(o, k * 0.16))
			end
		end
	end
end

local function bitir(m, kok, ana, o)
	m.PrimaryPart = ana
	asindir(m, o)
	m.Parent = kok or workspace
	return m
end

local function fenerKoy(m, yerelCF, o, renk)
	-- kol + kafes + neon cam; cam CanCollide=false (oyuncu takılmasın)
	renk = renk or FENER
	sabit(kutu(m, "FenerKol", Vector3.new(0.3, 0.3, 1.8), yerelCF * CFrame.new(0, 1.0, -0.85), DEMIR, E.Metal))
	sabit(kutu(m, "FenerKafes", Vector3.new(1.0, 1.35, 1.0), yerelCF * CFrame.new(0, 0.35, -1.55), o.renkKoyu, E.Metal))
	local cam = kutu(m, "FenerCam", Vector3.new(0.68, 0.9, 0.68), yerelCF * CFrame.new(0, 0.35, -1.55), renk, E.Neon)
	cam.CanCollide = false
	sabit(cam)
	if o.isik then isikKoy(cam, renk, 26, 1.6) end
	return cam
end

local function cevherRengi(o, i)
	-- Her YAPI tek cevher türünde olsun: 4 rengi sırayla dağıtmak konfeti gibi duruyordu
	-- (vagon/yığın ekran görüntüsü). Tür yapı başına bir kez tohumla seçilir, ~5'te 1 altın aksan.
	if o.cevherRenk then return o.cevherRenk end
	if not o.anaCevher then
		local liste = { CEV_CYAN, CEV_KIZIL, ALTIN, CEV_MOR }
		o.anaCevher = liste[o.rnd:NextInteger(1, 4)]
	end
	if i and i % 5 == 0 and o.anaCevher ~= ALTIN then return ALTIN end
	return o.anaCevher
end

local function molozSac(m, o, adet, yaricap, taban)
	-- yapının eteğine kırık taş serpiştirir (oturmuş görünsün)
	for i = 1, adet do
		local a = o.rnd:NextNumber() * math.pi * 2
		local d = yaricap * (0.55 + o.rnd:NextNumber() * 0.45)
		local b = 0.7 + o.rnd:NextNumber() * 1.5
		local p = kutu(m, "Moloz", Vector3.new(b, b * 0.6, b * 0.85),
			CFrame.new(math.cos(a) * d, (taban or 0) + b * 0.3, math.sin(a) * d)
				* CFrame.Angles(sap(o, 0.4), o.rnd:NextNumber() * 3.14, sap(o, 0.4)),
			(i % 3 == 0) and TAS_ACIK or o.renkTas, E.Slate)
		if i % 4 == 0 then yosunla(m, p, o) end
	end
end

local function rayParcasi(m, ad, yerelCF, uz, o)
	-- iki paralel ray + altına travers: tünel/hat/asansör hepsinde aynı reçete
	sabit(kutu(m, ad .. "SolRay", Vector3.new(0.3, 0.35, uz), yerelCF * CFrame.new(-1.35, 0.42, 0), DEMIR, E.Metal))
	sabit(kutu(m, ad .. "SagRay", Vector3.new(0.3, 0.35, uz), yerelCF * CFrame.new(1.35, 0.42, 0), DEMIR, E.Metal))
end

-- =====================================================================
-- 1) MADEN GİRİŞİ — kaya yüzüne oyulmuş tünel ağzı (~55 parça)
-- =====================================================================
local function madenGirisi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("madenGirisi", cf, o)
	local ana = sabit(kutu(m, "Taban", Vector3.new(27, 1, 11), CFrame.new(0, 0.5, 1.5), TAS_KOYU, E.Cobblestone))

	-- kaya yüzü: 6 sütun × 5 kat; ortadaki 2×3 hücre tünel ağzı için boş bırakılır
	local gw, gh = 4.3, 3.4
	for sx = 1, 6 do
		for sy = 1, 5 do
			if not ((sx == 3 or sx == 4) and sy <= 3) then
				local d = 5.5 + o.rnd:NextNumber() * 2.5
				local p = kutu(m, "Kaya", Vector3.new(gw + 0.4, gh + 0.35, d),
					CFrame.new((sx - 3.5) * gw + sap(o, 0.3), (sy - 0.5) * gh + 1, 1.5 + sap(o, 0.5))
						* CFrame.Angles(sap(o, 0.04), sap(o, 0.06), sap(o, 0.035)),
					(o.rnd:NextNumber() < 0.3) and TAS_ACIK or o.renkTas, E.Slate)
				sabit(p)
				yosunla(m, p, o)
			end
		end
	end

	-- içerideki karanlık: tünelin dibi görünmesin
	sabit(kutu(m, "Karanlik", Vector3.new(8.8, 10.6, 1), CFrame.new(0, 6.2, 3.2), KARANLIK, E.SmoothPlastic))

	-- ahşap destek çerçevesi (dış + iç)
	for _, s in ipairs({ -1, 1 }) do
		sabit(kutu(m, "Dikme", Vector3.new(1.15, 10.8, 1.15), CFrame.new(s * 4.9, 5.4, -1.4), AHSAP, E.Wood))
		kutu(m, "Payanda", Vector3.new(0.65, 3.4, 0.65),
			CFrame.new(s * 3.7, 9.6, -1.4) * CFrame.Angles(0, 0, s * 0.78), AHSAP_KOYU, E.Wood)
		sabit(kutu(m, "IcDikme", Vector3.new(0.9, 10.2, 0.9), CFrame.new(s * 4.6, 5.1, 2.6), AHSAP_KOYU, E.Wood))
	end
	sabit(kutu(m, "Kiris", Vector3.new(11.8, 1.25, 1.5), CFrame.new(0, 11.3, -1.4), AHSAP, E.Wood))
	kutu(m, "UstKiris", Vector3.new(12.8, 0.8, 1.1), CFrame.new(0, 12.3, -1.1), AHSAP_KOYU, E.Wood)
	sabit(kutu(m, "IcKiris", Vector3.new(10.6, 1.0, 1.2), CFrame.new(0, 10.8, 2.6), AHSAP, E.Wood))

	-- tabela
	kutu(m, "Tabela", Vector3.new(6.4, 1.9, 0.35), CFrame.new(0, 13.6, -1.7) * CFrame.Angles(-0.12, 0, 0), AHSAP, E.WoodPlanks)
	kutu(m, "TabelaCerceve", Vector3.new(6.9, 0.3, 0.45), CFrame.new(0, 12.6, -1.75), AHSAP_KOYU, E.Wood)
	kutu(m, "TabelaYazi", Vector3.new(4.6, 0.45, 0.12), CFrame.new(0, 13.6, -1.95) * CFrame.Angles(-0.12, 0, 0), ALTIN, E.Metal)

	-- fenerler
	fenerKoy(m, CFrame.new(-5.6, 8.6, -1.6), o)
	fenerKoy(m, CFrame.new(5.6, 8.6, -1.6), o)

	-- ağızdan çıkan ray güdüğü
	for i = 1, 3 do
		kutu(m, "Travers", Vector3.new(4.4, 0.4, 0.9), CFrame.new(0, 0.9, -1 - (i - 1) * 3.2), AHSAP_KOYU, E.Wood)
	end
	rayParcasi(m, "Giris", CFrame.new(0, 1.0, -4.4), 11, o)

	molozSac(m, o, 6, 9, 1)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 2) MADEN TÜNELİ — açık koridor: destek çerçeveleri + taş duvar + ray (~74 parça)
-- =====================================================================
local function madenTuneli(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("madenTuneli", cf, o)
	local uz = math.clamp(o.uzunluk or 64, 16, 160)
	local ana = sabit(kutu(m, "Taban", Vector3.new(11, 0.8, uz), CFrame.new(0, 0.4, -uz * 0.5), TAS_KOYU, E.Cobblestone))

	-- bütçe: 8 aralık üstü + tam yosun (her duvar 2 yama) 120 parçayı aşıyordu — ölçüldü
	local adet = math.clamp(math.floor(uz / 8), 3, 8)
	local adim = uz / adet
	for i = 0, adet do
		local z = -i * adim
		-- destek çerçevesi: 2 dikme + kiriş + 2 payanda
		for _, s in ipairs({ -1, 1 }) do
			sabit(kutu(m, "Dikme", Vector3.new(1.0, 8.2, 1.0), CFrame.new(s * 4.1, 4.1, z), AHSAP, E.Wood))
			if i % 2 == 0 then
				kutu(m, "Payanda", Vector3.new(0.6, 2.6, 0.6),
					CFrame.new(s * 3.2, 7.4, z) * CFrame.Angles(0, 0, s * 0.78), AHSAP_KOYU, E.Wood)
			end
		end
		sabit(kutu(m, "Kiris", Vector3.new(10, 1.1, 1.2), CFrame.new(0, 8.75, z), AHSAP, E.Wood))
		-- iki çerçeve arasına tavan tahtası + yan taş duvar
		if i < adet then
			local zo = z - adim * 0.5
			kutu(m, "TavanTahta", Vector3.new(9.4, 0.45, adim * 0.85), CFrame.new(0, 9.35, zo), AHSAP_KOYU, E.WoodPlanks)
			for _, s in ipairs({ -1, 1 }) do
				local p = kutu(m, "Duvar", Vector3.new(2.6, 7.4 + sap(o, 0.6), adim * 0.94),
					CFrame.new(s * 6.0, 3.7, zo) * CFrame.Angles(0, sap(o, 0.03), 0),
					(o.rnd:NextNumber() < 0.32) and TAS_ACIK or o.renkTas, E.Slate)
				yosunla(m, p, o)
			end
			if i % 3 == 0 then
				kutu(m, "Travers", Vector3.new(4.4, 0.4, 0.9), CFrame.new(0, 1.0, zo), AHSAP_KOYU, E.Wood)
			end
		end
	end

	-- ray: 20 stud'luk dilimler (tek uzun parça yerine — yıkıklık dilimde daha doğal)
	local dilim = math.clamp(math.floor(uz / 20), 1, 4)
	local du = uz / dilim
	for i = 1, dilim do
		rayParcasi(m, "Hat" .. i, CFrame.new(0, 0.8, -(i - 0.5) * du), du - 0.4, o)
	end

	if o.isik then
		for i = 1, math.min(3, adet) do
			fenerKoy(m, CFrame.new(-3.5, 6.4, -(i - 0.5) * (uz / math.min(3, adet))) * CFrame.Angles(0, math.pi * 0.5, 0), o)
		end
	end
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 3) VİNÇ KULESİ — ahşap+demir kule, makara, kova, halat (~77 parça)
-- =====================================================================
local function vincKulesi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("vincKulesi", cf, o)
	local ana = sabit(kutu(m, "Taban", Vector3.new(14, 1.2, 14), CFrame.new(0, 0.6, 0), TAS_KOYU, E.Cobblestone))

	local yuk, kat = 26, 3
	local altG, ustG = 5.2, 2.9 -- ayaklar yukarı doğru daralır (klasik vinç silueti)
	local function ayakNokta(sx, sz, t)
		local g = altG + (ustG - altG) * t
		return Vector3.new(sx * g, 1.2 + yuk * t, sz * g)
	end

	local KOSE = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } -- saat yönünde 4 köşe

	-- ayaklar: gerçek uç noktalar arasına kiriş (elle açı = yamuk kule)
	for _, k4 in ipairs(KOSE) do
		for k = 0, kat - 1 do
			sabit(eksenKutu(m, "Ayak", 1.0,
				ayakNokta(k4[1], k4[2], k / kat), ayakNokta(k4[1], k4[2], (k + 1) / kat), AHSAP, E.Wood))
		end
	end

	-- her katta 4 yüz: üst kuşak + köşeden köşeye tek çapraz
	for k = 1, kat do
		local yAlt, yUst = 1.2 + yuk * (k - 1) / kat, 1.2 + yuk * k / kat
		local gAlt = altG + (ustG - altG) * (k - 1) / kat
		local gUst = altG + (ustG - altG) * k / kat
		for i = 1, 4 do
			local a1, a2 = KOSE[i], KOSE[i % 4 + 1]
			local ust1 = Vector3.new(a1[1] * gUst, yUst, a1[2] * gUst)
			local ust2 = Vector3.new(a2[1] * gUst, yUst, a2[2] * gUst)
			sabit(eksenKutu(m, "Kusak", 0.62, ust1, ust2, AHSAP_KOYU, E.Wood))
			eksenKutu(m, "Capraz", 0.45, Vector3.new(a1[1] * gAlt, yAlt, a1[2] * gAlt), ust2, DEMIR, E.Metal)
		end
	end

	-- tepe platformu + makara + halat + kova
	local ty = 1.2 + yuk
	for i = -1, 2 do
		sabit(kutu(m, "Doseme", Vector3.new(7.2, 0.4, 1.6), CFrame.new(0, ty + 0.2, i * 1.7), AHSAP, E.WoodPlanks))
	end
	sabit(kutu(m, "MakaraKiris", Vector3.new(1.0, 1.0, 9), CFrame.new(0, ty + 2.6, -1.5), AHSAP, E.Wood))
	sabit(kutu(m, "MakaraAsk", Vector3.new(0.6, 2.2, 0.6), CFrame.new(0, ty + 1.5, -5.2), DEMIR, E.Metal))
	sabit(silindir(m, "Makara", Vector3.new(0.9, 2.6, 2.6), CFrame.new(0, ty + 0.5, -5.2), DEMIR, E.Metal))
	sabit(silindir(m, "MakaraYanak", Vector3.new(0.25, 3.2, 3.2), CFrame.new(-0.6, ty + 0.5, -5.2), o.renkKoyu, E.Metal))
	sabit(silindir(m, "MakaraYanak", Vector3.new(0.25, 3.2, 3.2), CFrame.new(0.6, ty + 0.5, -5.2), o.renkKoyu, E.Metal))
	sabit(silindir(m, "Tambur", Vector3.new(2.6, 2.2, 2.2), CFrame.new(0, ty + 1.0, 2.2), AHSAP_KOYU, E.Wood))
	sabit(kutu(m, "Kol", Vector3.new(0.4, 0.4, 2.6), CFrame.new(1.6, ty + 1.0, 3.2) * CFrame.Angles(0.7, 0, 0), DEMIR, E.Metal))

	local kovaY = 8.5
	sabit(kutu(m, "Halat", Vector3.new(0.22, ty - 1.6 - kovaY, 0.22), CFrame.new(0, (ty + kovaY) * 0.5, -5.2), AHSAP_KOYU, E.Fabric))
	sabit(kutu(m, "HalatEgim", Vector3.new(0.22, 3.2, 0.22), CFrame.new(0, ty + 1.9, -1.5) * CFrame.Angles(0, 0, 0), AHSAP_KOYU, E.Fabric))
	for _, s in ipairs({ -1, 1 }) do
		kutu(m, "KovaKulp", Vector3.new(0.2, 1.6, 0.2), CFrame.new(s * 1.5, kovaY + 0.4, -5.2), DEMIR, E.Metal)
		kutu(m, "KovaYan", Vector3.new(0.3, 2.6, 3.2), CFrame.new(s * 1.5, kovaY - 1.1, -5.2), DEMIR, E.Metal)
		kutu(m, "KovaOn", Vector3.new(3.2, 2.6, 0.3), CFrame.new(0, kovaY - 1.1, -5.2 + s * 1.5), DEMIR, E.Metal)
	end
	kutu(m, "KovaTaban", Vector3.new(3.2, 0.3, 3.2), CFrame.new(0, kovaY - 2.4, -5.2), o.renkKoyu, E.Metal)
	kutu(m, "KovaCevher", Vector3.new(2.4, 0.9, 2.4), CFrame.new(0, kovaY - 1.4, -5.2), cevherRengi(o, 1), E.Neon).CanCollide = false

	-- merdiven + taban taşları
	for i = 1, 6 do
		kutu(m, "Basamak", Vector3.new(3.2, 0.35, 0.8), CFrame.new(0, 2.4 + (i - 1) * 3.6, 6.4 - i * 0.25), AHSAP, E.Wood)
	end
	molozSac(m, o, 5, 9, 1.2)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 4) RAY HATTI — travers + ray + ballast; o.kavis ile hafif yay (~56 parça)
-- =====================================================================
local function rayHatti(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("rayHatti", cf, o)
	local uz = math.clamp(o.uzunluk or 80, 16, 200)
	local kavis = o.kavis or 0
	-- alt sınır 7: kısa hat (uz=16) 19 parçaya düşüyordu, bütçe tabanı 25 (ölçüldü)
	local adet = math.clamp(math.floor(uz / 4.5), 7, 22)
	local adim = uz / adet
	local ana = sabit(kutu(m, "Ballast", Vector3.new(8, 0.5, adim + 0.6), CFrame.new(0, 0.25, -adim * 0.5), TAS_KOYU, E.Cobblestone))

	-- yolu adım adım kur: her adımda kavisin bir dilimi kadar dön (yay böyle çıkar)
	local yerel = CFrame.new(0, 0, 0)
	for i = 1, adet do
		local orta = yerel * CFrame.new(0, 0, -adim * 0.5)
		if i > 1 then
			kutu(m, "Ballast", Vector3.new(8, 0.5 + sap(o, 0.08), adim + 0.6), orta * CFrame.new(0, 0.25, 0), TAS_KOYU, E.Cobblestone)
		end
		kutu(m, "Travers", Vector3.new(4.6, 0.45, 1.0), orta * CFrame.new(0, 0.72, 0) * CFrame.Angles(0, sap(o, 0.02), 0),
			AHSAP_KOYU, E.Wood)
		rayParcasi(m, "Hat" .. i, orta * CFrame.new(0, 0.6, 0), adim + 0.25, o)
		if i % 5 == 0 then
			kutu(m, "Cakil", Vector3.new(1.2, 0.5, 1.2), orta * CFrame.new(sap(o, 3.5), 0.5, sap(o, 1)), o.renkTas, E.Slate)
		end
		yerel = yerel * CFrame.new(0, 0, -adim) * CFrame.Angles(0, kavis / adet, 0)
	end

	-- hat sonu tamponu
	sabit(kutu(m, "Tampon", Vector3.new(4.6, 1.6, 0.8), yerel * CFrame.new(0, 1.4, 0.3), AHSAP, E.Wood))
	sabit(kutu(m, "TamponDikme", Vector3.new(0.7, 2.2, 0.7), yerel * CFrame.new(-1.4, 1.1, 0.6), AHSAP_KOYU, E.Wood))
	sabit(kutu(m, "TamponDikme", Vector3.new(0.7, 2.2, 0.7), yerel * CFrame.new(1.4, 1.1, 0.6), AHSAP_KOYU, E.Wood))
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 5) CEVHER VAGONU — gövde, 4 tekerlek, içinde renkli cevher küpleri (~36 parça)
-- =====================================================================
local function cevherVagonu(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("cevherVagonu", cf, o)
	local ana = sabit(kutu(m, "Sasi", Vector3.new(4.6, 0.5, 6.4), CFrame.new(0, 1.55, 0), o.renkKoyu, E.Metal))

	-- gövde: taban + 4 duvar + köşe dikmeleri + üst kuşak
	sabit(kutu(m, "Zemin", Vector3.new(4.4, 0.4, 6.0), CFrame.new(0, 1.95, 0), AHSAP_KOYU, E.WoodPlanks))
	for _, s in ipairs({ -1, 1 }) do
		sabit(kutu(m, "Yan", Vector3.new(0.4, 2.6, 6.0), CFrame.new(s * 2.2, 3.25, 0), AHSAP, E.WoodPlanks))
		sabit(kutu(m, "UcDuvar", Vector3.new(4.4, 2.6, 0.4), CFrame.new(0, 3.25, s * 3.0), AHSAP, E.WoodPlanks))
		kutu(m, "UstKusak", Vector3.new(0.5, 0.35, 6.2), CFrame.new(s * 2.2, 4.6, 0), DEMIR, E.Metal)
		kutu(m, "UcKusak", Vector3.new(4.5, 0.35, 0.5), CFrame.new(0, 4.6, s * 3.0), DEMIR, E.Metal)
		for _, s2 in ipairs({ -1, 1 }) do
			kutu(m, "KoseDikme", Vector3.new(0.55, 3.0, 0.55), CFrame.new(s * 2.2, 3.4, s2 * 2.9), DEMIR, E.Metal)
		end
	end
	kutu(m, "AltKusak", Vector3.new(4.7, 0.35, 0.5), CFrame.new(0, 2.3, 0), DEMIR, E.Metal)

	-- tekerlek + aks
	for _, sz in ipairs({ -1, 1 }) do
		sabit(silindir(m, "Aks", Vector3.new(5.4, 0.4, 0.4), CFrame.new(0, 1.1, sz * 2.1) * CFrame.Angles(0, 0, 0), DEMIR, E.Metal))
		for _, sx in ipairs({ -1, 1 }) do
			sabit(silindir(m, "Tekerlek", Vector3.new(0.5, 2.2, 2.2), CFrame.new(sx * 2.6, 1.1, sz * 2.1), o.renkKoyu, E.Metal))
			sabit(silindir(m, "Gobek", Vector3.new(0.7, 0.8, 0.8), CFrame.new(sx * 2.75, 1.1, sz * 2.1), DEMIR, E.Metal))
		end
	end

	-- yük: cevher küpleri (neon, tepesi taşmış)
	for i = 1, 9 do
		local b = 0.9 + o.rnd:NextNumber() * 0.7
		local c = kutu(m, "Cevher", Vector3.new(b, b, b),
			CFrame.new(sap(o, 1.4), 4.4 + o.rnd:NextNumber() * 0.9, sap(o, 2.2))
				* CFrame.Angles(sap(o, 0.6), sap(o, 0.9), sap(o, 0.6)),
			cevherRengi(o, i), E.Neon)
		sabit(c)
		if o.isik and i == 1 then isikKoy(c, c.Color, 14, 1.1) end
	end
	for i = 1, 3 do
		kutu(m, "Kaya", Vector3.new(1.3, 1.1, 1.3), CFrame.new(sap(o, 1.5), 4.2, sap(o, 2.2)), o.renkTas, E.Slate)
	end
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 6) CEVHER DAMARI — kaya kütlesi içinde parlayan damar (~40 parça)
-- =====================================================================
local function cevherDamari(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("cevherDamari", cf, o)
	local ana = sabit(kutu(m, "Kaide", Vector3.new(12, 2, 10), CFrame.new(0, 1, 0), TAS_KOYU, E.Slate))
	local renk = o.cevherRenk or cevherRengi(o, 1)

	-- kütle: merkeze yaklaştıkça YÜKSELEN bloklar. (Önce tek büyük slab + üstüne kristal
	-- konuyordu; ekran görüntüsünde gri kutu gibi duruyordu, damar okunmuyordu.)
	for i = 1, 15 do
		local a = o.rnd:NextNumber() * math.pi * 2
		local d = 1.0 + o.rnd:NextNumber() * 4.6
		local h = math.max(1.8, 8.6 - d * 1.15 + sap(o, 0.8))
		local b = 2.7 - d * 0.16 + sap(o, 0.35)
		local p = kutu(m, "Kaya", Vector3.new(b, h, b * 0.95),
			CFrame.new(math.cos(a) * d, 1.9 + h * 0.5, math.sin(a) * d * 0.8 + 0.6)
				* CFrame.Angles(sap(o, 0.1), o.rnd:NextNumber() * 3.14, sap(o, 0.1)),
			(i % 3 == 0) and TAS_ACIK or ((i % 5 == 0) and TAS_KOYU or o.renkTas), E.Slate)
		yosunla(m, p, o)
	end

	-- ÖN YÜZ: damarın üstüne oturacağı düz kaya duvarı (yoksa kristaller havada kalıyor)
	local yuzZ = -3.1
	sabit(kutu(m, "Yuz", Vector3.new(9.5, 7.6, 2.2), CFrame.new(0, 4.0, yuzZ) * CFrame.Angles(0.13, 0, 0), o.renkTas, E.Slate))
	sabit(kutu(m, "YuzEtek", Vector3.new(10.5, 2.4, 2.8), CFrame.new(0, 1.5, yuzZ - 0.4), TAS_KOYU, E.Slate))

	-- damar: yüzeyde çaprazlama tırmanan, kayaya YARI GÖMÜLÜ neon dizi
	local x, yy = -3.2, 2.2
	for i = 1, 11 do
		local b = 1.35 - i * 0.045 + sap(o, 0.16)
		local c = kutu(m, "Cevher", Vector3.new(b, b, b * 0.9),
			CFrame.new(x, yy, yuzZ - 1.0 + sap(o, 0.25)) * CFrame.Angles(sap(o, 0.45), sap(o, 0.6), sap(o, 0.45)),
			renk, E.Neon)
		sabit(c)
		if o.isik and (i == 3 or i == 9) then isikKoy(c, renk, 18, 1.5) end
		x = x + 0.58 + o.rnd:NextNumber() * 0.22
		yy = yy + 0.42 + o.rnd:NextNumber() * 0.34
	end

	-- yüzün dibine dökülmüş kırıntılar (damarın altına toplanır, sağa sola saçılmaz)
	for i = 1, 7 do
		local b = 0.4 + o.rnd:NextNumber() * 0.45
		sabit(kutu(m, "Kirinti", Vector3.new(b, b, b),
			CFrame.new(sap(o, 3.6), 0.5 + o.rnd:NextNumber() * 0.5, yuzZ - 1.9 - o.rnd:NextNumber() * 1.4)
				* CFrame.Angles(sap(o, 1), sap(o, 1), sap(o, 1)), renk, E.Neon))
	end
	molozSac(m, o, 6, 7.5, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 7) KUYU AĞZI — dairesel taş halka, ahşap çatı, makara + kova (~45 parça)
-- =====================================================================
local function kuyuAgzi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("kuyuAgzi", cf, o)
	local ana = sabit(silindir(m, "Kaide", Vector3.new(0.8, 12, 12), CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.pi * 0.5), TAS_KOYU, E.Cobblestone))

	-- halka: 10 blok × 2 kat (blok yüzü merkeze dönük)
	local n, R = 10, 4.4
	for kat = 1, 2 do
		for i = 1, n do
			local a = (i / n) * math.pi * 2 + (kat - 1) * (math.pi / n)
			local p = kutu(m, "Halka", Vector3.new(3.0, 1.5, 1.5),
				CFrame.new(math.cos(a) * R, 0.8 + kat * 1.45, math.sin(a) * R)
					* CFrame.Angles(0, -a + math.pi * 0.5, sap(o, 0.05)),
				(i % 3 == 0) and TAS_ACIK or o.renkTas, E.Cobblestone)
			yosunla(m, p, o)
		end
	end
	-- içi karanlık: dipsiz görünsün
	sabit(silindir(m, "Karanlik", Vector3.new(0.5, 7.2, 7.2), CFrame.new(0, 3.0, 0) * CFrame.Angles(0, 0, math.pi * 0.5), KARANLIK, E.SmoothPlastic))

	-- çatı iskeleti
	for _, s in ipairs({ -1, 1 }) do
		sabit(kutu(m, "CatiDireK", Vector3.new(0.85, 7.5, 0.85), CFrame.new(s * 4.2, 7.5, 0), AHSAP, E.Wood))
		kutu(m, "Payanda", Vector3.new(0.5, 2.4, 0.5), CFrame.new(s * 3.4, 10.4, 0) * CFrame.Angles(0, 0, s * 0.8), AHSAP_KOYU, E.Wood)
		for i = 1, 2 do
			kutu(m, "CatiTahta", Vector3.new(5.0, 0.35, 3.0),
				CFrame.new(s * 2.4, 12.4 - i * 0.5, (i - 1.5) * 3.0) * CFrame.Angles(0, 0, -s * 0.5), AHSAP_KOYU, E.WoodPlanks)
		end
	end
	sabit(kutu(m, "Mahya", Vector3.new(1.0, 0.9, 7.0), CFrame.new(0, 12.6, 0), AHSAP, E.Wood))

	-- makara + kol + kova
	sabit(silindir(m, "Tambur", Vector3.new(6.4, 1.5, 1.5), CFrame.new(0, 9.6, 0), AHSAP_KOYU, E.Wood))
	sabit(kutu(m, "Kol", Vector3.new(0.4, 0.4, 2.2), CFrame.new(3.6, 9.6, 1.0) * CFrame.Angles(0.9, 0, 0), DEMIR, E.Metal))
	sabit(kutu(m, "Halat", Vector3.new(0.2, 4.4, 0.2), CFrame.new(0, 7.2, 0), AHSAP_KOYU, E.Fabric))
	for _, s in ipairs({ -1, 1 }) do
		kutu(m, "KovaYan", Vector3.new(0.3, 1.8, 2.2), CFrame.new(s * 1.05, 4.2, 0), DEMIR, E.Metal)
		kutu(m, "KovaUc", Vector3.new(2.2, 1.8, 0.3), CFrame.new(0, 4.2, s * 1.05), DEMIR, E.Metal)
	end
	kutu(m, "KovaTaban", Vector3.new(2.2, 0.3, 2.2), CFrame.new(0, 3.35, 0), o.renkKoyu, E.Metal)
	kutu(m, "KovaSu", Vector3.new(1.8, 0.5, 1.8), CFrame.new(0, 4.6, 0), SU, E.Glass).CanCollide = false

	molozSac(m, o, 6, 8, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 8) MADENCİ KAMPI — çadır, kamp ateşi, variller, sandık, kütükler (~62 parça)
-- =====================================================================
local function madenciKampi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("madenciKampi", cf, o)
	local ana = sabit(kutu(m, "Zemin", Vector3.new(24, 0.5, 22), CFrame.new(0, 0.25, 0), TAS_KOYU, E.Ground))

	-- büyük çadır (ahşap iskelet + bez örtü)
	local function cadir(x, z, olc, dondur)
		local t = CFrame.new(x, 0, z) * CFrame.Angles(0, dondur, 0)
		sabit(kutu(m, "CadirMahya", Vector3.new(0.6 * olc, 0.6 * olc, 10 * olc), t * CFrame.new(0, 5.2 * olc, 0), AHSAP, E.Wood))
		for _, s in ipairs({ -1, 1 }) do
			sabit(kutu(m, "CadirDirek", Vector3.new(0.6 * olc, 5.4 * olc, 0.6 * olc), t * CFrame.new(0, 2.7 * olc, s * 4.8 * olc), AHSAP, E.Wood))
			for i = 1, 2 do
				kutu(m, "CadirBez", Vector3.new(0.28 * olc, 7.0 * olc, 5.2 * olc),
					t * CFrame.new(s * 2.4 * olc, 2.7 * olc, (i - 1.5) * 5.2 * olc) * CFrame.Angles(0, 0, s * 0.42),
					BEZ, E.Fabric)
			end
			kutu(m, "CadirKazik", Vector3.new(0.3 * olc, 1.2 * olc, 0.3 * olc), t * CFrame.new(s * 5.2 * olc, 0.6 * olc, 3.4 * olc), AHSAP_KOYU, E.Wood)
			kutu(m, "CadirIp", Vector3.new(0.16 * olc, 0.16 * olc, 3.4 * olc),
				t * CFrame.new(s * 4.0 * olc, 2.8 * olc, 4.0 * olc) * CFrame.Angles(-0.7, s * 0.5, 0), AHSAP_KOYU, E.Fabric)
		end
	end
	cadir(-6.5, -3, 1.0, 0.18)
	cadir(7.5, 4.5, 0.62, -0.5)

	-- kamp ateşi: taş halka + odun + neon alev
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local p = kutu(m, "AtesTasi", Vector3.new(1.2, 0.9, 1.2),
			CFrame.new(math.cos(a) * 2.2, 0.7, math.sin(a) * 2.2) * CFrame.Angles(sap(o, 0.2), a, sap(o, 0.2)),
			o.renkTas, E.Slate)
		yosunla(m, p, o)
	end
	for i = 1, 5 do
		kutu(m, "Odun", Vector3.new(0.5, 0.5, 2.8),
			CFrame.new(sap(o, 0.5), 0.9 + i * 0.18, sap(o, 0.5)) * CFrame.Angles(0.35, (i / 5) * math.pi, 0), AHSAP_KOYU, E.Wood)
	end
	local alev = kutu(m, "Alev", Vector3.new(1.6, 2.2, 1.6), CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0.5, 0), ATES, E.Neon)
	alev.CanCollide = false
	sabit(alev)
	if o.isik then isikKoy(alev, ATES, 34, 2.2) end

	-- variller, sandık, kütükler
	for i = 1, 2 do
		local vx, vz = -1 + i * 5.4, -8.5
		sabit(silindir(m, "Varil", Vector3.new(3.4, 2.4, 2.4), CFrame.new(vx, 1.7, vz) * CFrame.Angles(0, 0, math.pi * 0.5), DEMIR, E.Metal))
		kutu(m, "VarilKusak", Vector3.new(2.6, 0.3, 2.6), CFrame.new(vx, 2.4, vz), o.renkKoyu, E.Metal)
		kutu(m, "VarilKusak", Vector3.new(2.6, 0.3, 2.6), CFrame.new(vx, 1.0, vz), o.renkKoyu, E.Metal)
	end
	sabit(kutu(m, "Sandik", Vector3.new(3.4, 2.0, 2.4), CFrame.new(-9.5, 1.0, 6.5) * CFrame.Angles(0, 0.4, 0), AHSAP, E.WoodPlanks))
	kutu(m, "SandikKapak", Vector3.new(3.5, 0.5, 2.5), CFrame.new(-9.5, 2.2, 6.5) * CFrame.Angles(0, 0.4, 0), AHSAP_KOYU, E.Wood)
	kutu(m, "SandikKilit", Vector3.new(0.6, 0.7, 0.35), CFrame.new(-9.5, 1.7, 5.3) * CFrame.Angles(0, 0.4, 0), ALTIN, E.Metal)
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2 + 0.6
		sabit(silindir(m, "Kutuk", Vector3.new(1.6, 1.8, 1.8),
			CFrame.new(math.cos(a) * 5.4, 0.9, math.sin(a) * 5.4) * CFrame.Angles(0, 0, math.pi * 0.5), AHSAP, E.Wood))
	end

	-- dayalı aletler + fener direği
	sabit(kutu(m, "Direk", Vector3.new(0.5, 7.0, 0.5), CFrame.new(10.5, 3.5, -6.0), AHSAP, E.Wood))
	fenerKoy(m, CFrame.new(10.5, 5.6, -6.4), o)
	kutu(m, "KazmaSap", Vector3.new(0.3, 4.2, 0.3), CFrame.new(-11.5, 2.1, -1.0) * CFrame.Angles(0.28, 0, 0.2), AHSAP, E.Wood)
	kutu(m, "KazmaUc", Vector3.new(2.6, 0.4, 0.4), CFrame.new(-11.0, 4.1, -1.6) * CFrame.Angles(0, 0, 0.2), DEMIR, E.Metal)
	molozSac(m, o, 6, 11, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 9) CEVHER DEPOSU — açık ahşap depo: platform, direkler, çatı, yük (~70 parça)
-- =====================================================================
local function cevherDeposu(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("cevherDeposu", cf, o)
	local ana = sabit(kutu(m, "Kaide", Vector3.new(20, 1.0, 16), CFrame.new(0, 0.5, 0), TAS_KOYU, E.Cobblestone))

	-- zemin: kirişler + tahta döşeme
	for i = 1, 3 do
		sabit(kutu(m, "Kiris", Vector3.new(19, 0.7, 0.8), CFrame.new(0, 1.35, (i - 2) * 6.4), AHSAP_KOYU, E.Wood))
	end
	for i = 1, 8 do
		kutu(m, "Doseme", Vector3.new(19, 0.4, 1.9), CFrame.new(0, 1.9, (i - 4.5) * 2.0), AHSAP, E.WoodPlanks)
	end

	-- 4 direk + çapraz payandalar
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			sabit(kutu(m, "Direk", Vector3.new(1.1, 9.0, 1.1), CFrame.new(sx * 8.6, 6.4, sz * 6.8), AHSAP, E.Wood))
			kutu(m, "Payanda", Vector3.new(0.55, 2.8, 0.55),
				CFrame.new(sx * 7.7, 10.0, sz * 6.8) * CFrame.Angles(0, 0, sx * 0.78), AHSAP_KOYU, E.Wood)
		end
		sabit(kutu(m, "Asik", Vector3.new(1.0, 0.9, 15.0), CFrame.new(sx * 8.6, 11.2, 0), AHSAP, E.Wood))
	end
	sabit(kutu(m, "Mahya", Vector3.new(0.9, 0.9, 15.4), CFrame.new(0, 14.0, 0), AHSAP, E.Wood))

	-- beşik çatı
	for _, sx in ipairs({ -1, 1 }) do
		for i = 1, 5 do
			kutu(m, "CatiTahta", Vector3.new(10.4, 0.4, 3.0),
				CFrame.new(sx * 4.6, 12.5, (i - 3) * 3.1) * CFrame.Angles(0, 0, -sx * 0.52), AHSAP_KOYU, E.WoodPlanks)
		end
	end

	-- yük: sandıklar, variller, cevher yığını
	for i = 1, 5 do
		local x = -6.5 + (i - 1) * 3.1
		local kat = (i % 2 == 0) and 2 or 1
		for k = 1, kat do
			sabit(kutu(m, "Sandik", Vector3.new(2.6, 2.0, 2.4), CFrame.new(x, 3.1 + (k - 1) * 2.1, -4.6 + sap(o, 0.4))
				* CFrame.Angles(0, sap(o, 0.25), 0), AHSAP, E.WoodPlanks))
			kutu(m, "SandikKusak", Vector3.new(2.7, 0.3, 2.5), CFrame.new(x, 3.9 + (k - 1) * 2.1, -4.6), AHSAP_KOYU, E.Wood)
		end
	end
	for i = 1, 3 do
		local x = 3.0 + (i - 1) * 2.9
		sabit(silindir(m, "Varil", Vector3.new(3.2, 2.3, 2.3), CFrame.new(x, 3.7, 4.4) * CFrame.Angles(0, 0, math.pi * 0.5), DEMIR, E.Metal))
		kutu(m, "VarilKusak", Vector3.new(2.5, 0.3, 2.5), CFrame.new(x, 4.3, 4.4), o.renkKoyu, E.Metal)
	end
	for i = 1, 8 do
		local b = 1.1 + o.rnd:NextNumber() * 0.7
		local c = kutu(m, "Cevher", Vector3.new(b, b, b),
			CFrame.new(-5.0 + sap(o, 2.4), 2.8 + o.rnd:NextNumber() * 1.6, 4.4 + sap(o, 1.8))
				* CFrame.Angles(sap(o, 0.7), sap(o, 0.9), sap(o, 0.7)),
			cevherRengi(o, i), E.Neon)
		sabit(c)
		if o.isik and i == 2 then isikKoy(c, c.Color, 16, 1.2) end
	end

	-- rampa + korkuluk
	sabit(kutu(m, "Rampa", Vector3.new(5.0, 0.5, 5.6), CFrame.new(0, 1.4, -9.0) * CFrame.Angles(0.34, 0, 0), AHSAP, E.WoodPlanks))
	for _, sx in ipairs({ -1, 1 }) do
		kutu(m, "Korkuluk", Vector3.new(0.4, 0.4, 14.0), CFrame.new(sx * 8.4, 4.4, 0), AHSAP_KOYU, E.Wood)
		kutu(m, "KorkulukDikme", Vector3.new(0.4, 2.4, 0.4), CFrame.new(sx * 8.4, 3.3, 0), AHSAP_KOYU, E.Wood)
	end
	if o.isik then fenerKoy(m, CFrame.new(0, 10.4, -6.6), o) end
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 10) KONVEYÖR İSKELESİ — eğimli bant yatağı + ayaklar + makaralar (~54 parça)
-- =====================================================================
local function konveyorIskele(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("konveyorIskele", cf, o)
	local uz = math.clamp(o.uzunluk or 42, 14, 110)
	local egim = math.clamp(o.egim or 0.42, 0.05, 0.9) -- radyan
	local ana = sabit(kutu(m, "Kaide", Vector3.new(9, 1.0, 8), CFrame.new(0, 0.5, 1.5), TAS_KOYU, E.Cobblestone))

	local ayakAdet = math.clamp(math.floor(uz / 9), 2, 6)
	local adim = uz / ayakAdet
	local function yolCF(t)
		-- bant ekseni: -Z boyunca ilerlerken +Y'ye tırmanır
		local z = -t * uz
		local y = 2.0 + math.tan(egim) * (t * uz)
		return CFrame.new(0, y, z) * CFrame.Angles(egim, 0, 0)
	end

	-- ayaklar (DİK) + iki ayak arasına gerçek uçlardan çapraz
	for i = 0, ayakAdet do
		local y = yolCF(i / ayakAdet).Position.Y
		local z = -i * adim
		for _, sx in ipairs({ -1, 1 }) do
			sabit(kutu(m, "Ayak", Vector3.new(0.9, y, 0.9), CFrame.new(sx * 2.6, y * 0.5, z), DEMIR, E.Metal))
		end
		sabit(kutu(m, "AyakBag", Vector3.new(6.0, 0.5, 0.5), CFrame.new(0, y * 0.55, z), o.renkKoyu, E.Metal))
		if i > 0 then
			local oy = yolCF((i - 1) / ayakAdet).Position.Y
			for _, sx in ipairs({ -1, 1 }) do
				eksenKutu(m, "Capraz", 0.42, Vector3.new(sx * 2.6, 0.8, z + adim), Vector3.new(sx * 2.6, y - 0.9, z), DEMIR, E.Metal)
			end
			sabit(kutu(m, "AltBag", Vector3.new(5.6, 0.4, 0.4), CFrame.new(0, math.min(oy, y) * 0.22 + 0.8, z + adim * 0.5), o.renkKoyu, E.Metal))
		end
	end

	-- bant yatağı: dilimli (koyu bant + sarı kenar) + makaralar
	local dilim = math.clamp(math.floor(uz / 6), 3, 9)
	for i = 1, dilim do
		local c = yolCF((i - 0.5) / dilim)
		local du = (uz / dilim) / math.cos(egim) + 0.3
		-- yatak kalınlaştırıldı: 0.35 kalınlıkta bant uzaktan ince sarı tahta gibi duruyordu
		sabit(kutu(m, "BantYatak", Vector3.new(4.8, 0.8, du), c * CFrame.new(0, -0.1, 0), o.renkKoyu, E.Metal))
		sabit(kutu(m, "Bant", Vector3.new(4.2, 0.4, du), c * CFrame.new(0, 0.45, 0), KOMUR, E.SmoothPlastic))
		for _, sx in ipairs({ -1, 1 }) do
			sabit(kutu(m, "Kenar", Vector3.new(0.5, 1.1, du), c * CFrame.new(sx * 2.6, 0.55, 0), ALTIN, E.Metal))
		end
		if i % 2 == 0 then
			sabit(silindir(m, "Makara", Vector3.new(5.6, 1.4, 1.4), c * CFrame.new(0, -0.75, 0) * CFrame.Angles(0, 0, math.pi * 0.5), DEMIR, E.Metal))
		end
		-- banttaki cevher: hareket hissi
		if i % 3 == 1 then
			local b = 0.8 + o.rnd:NextNumber() * 0.5
			sabit(kutu(m, "Cevher", Vector3.new(b, b, b), c * CFrame.new(sap(o, 1.2), 0.9, sap(o, 1.5))
				* CFrame.Angles(sap(o, 0.8), sap(o, 0.8), sap(o, 0.8)), cevherRengi(o, i), E.Neon))
		end
	end

	-- alt besleme hunisi + üst boşaltma ağzı
	sabit(kutu(m, "HuniOn", Vector3.new(4.6, 2.6, 0.35), CFrame.new(0, 2.4, 3.0) * CFrame.Angles(-0.42, 0, 0), DEMIR, E.Metal))
	sabit(kutu(m, "HuniArka", Vector3.new(4.6, 2.6, 0.35), CFrame.new(0, 2.4, 0.6) * CFrame.Angles(0.42, 0, 0), DEMIR, E.Metal))
	for _, sx in ipairs({ -1, 1 }) do
		sabit(kutu(m, "HuniYan", Vector3.new(0.35, 2.6, 3.2), CFrame.new(sx * 2.2, 2.4, 1.8) * CFrame.Angles(0, 0, sx * 0.42), o.renkKoyu, E.Metal))
	end
	local ucCF = yolCF(1)
	sabit(kutu(m, "BosaltmaAgzi", Vector3.new(5.0, 2.4, 2.4), ucCF * CFrame.new(0, -0.9, -1.6), o.renkKoyu, E.Metal))
	sabit(kutu(m, "AgizOluk", Vector3.new(4.2, 0.35, 3.0), ucCF * CFrame.new(0, -2.0, -2.6) * CFrame.Angles(-0.5, 0, 0), DEMIR, E.Metal))
	if o.isik then fenerKoy(m, ucCF * CFrame.new(2.9, 1.4, 0), o) end
	molozSac(m, o, 5, 6, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 11) ERİTME OCAĞI — taş fırın, neon ateş ağzı, baca, kömür, örs (~58 parça)
-- =====================================================================
local function eritmeOcagi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("eritmeOcagi", cf, o)
	local ana = sabit(kutu(m, "Kaide", Vector3.new(16, 1.0, 14), CFrame.new(0, 0.5, 0), TAS_KOYU, E.Cobblestone))

	-- DOLU gövde + üstüne örgü taşları. (Önce sadece 3 halka vardı: dağınık taş yığını
	-- gibi duruyordu, fırın okunmuyordu — ekran görüntüsü.)
	sabit(kutu(m, "Govde", Vector3.new(9.4, 8.6, 8.4), CFrame.new(0, 5.3, 0.6), o.renkTas, E.Cobblestone))
	for kat = 1, 3 do
		local yk = 2.4 + (kat - 1) * 3.1
		for i = 1, 6 do
			local a = (i / 6) * math.pi * 2 + kat * 0.4
			local onYuz = math.sin(a) < -0.55 -- -Z = ön yüz, ateş ağzına yer aç
			if not (kat == 1 and onYuz) then
				local p = kutu(m, "Kaplama", Vector3.new(2.5, 2.7 + sap(o, 0.2), 2.5),
					CFrame.new(math.cos(a) * 4.4, yk, math.sin(a) * 4.0 + 0.6) * CFrame.Angles(0, -a, sap(o, 0.05)),
					(i % 3 == 0) and TAS_ACIK or ((i % 4 == 0) and TAS_KOYU or o.renkTas), E.Cobblestone)
				if kat >= 2 then yosunla(m, p, o) end
			end
		end
	end
	sabit(kutu(m, "Korniş", Vector3.new(10.6, 0.8, 9.6), CFrame.new(0, 9.9, 0.6), TAS_KOYU, E.Slate))

	-- ateş ağzı: karanlık niş + neon alev + demir kemer
	sabit(kutu(m, "AgizNis", Vector3.new(3.4, 3.2, 1.6), CFrame.new(0, 2.5, -3.6), KARANLIK, E.SmoothPlastic))
	local ates = kutu(m, "Ates", Vector3.new(2.4, 1.7, 0.7), CFrame.new(0, 2.0, -4.0), ATES, E.Neon)
	ates.CanCollide = false
	sabit(ates)
	if o.isik then isikKoy(ates, ATES, 40, 3.0) end
	sabit(kutu(m, "AgizKemer", Vector3.new(4.6, 0.8, 1.2), CFrame.new(0, 4.3, -4.0), DEMIR, E.Metal))
	sabit(kutu(m, "AgizEsik", Vector3.new(4.6, 0.7, 1.8), CFrame.new(0, 1.05, -4.3), o.renkKoyu, E.Metal))

	-- baca: yukarı daralan bloklar
	-- baca KALIN ve KISA: 16 stud'luk base üstünde 21 stud'luk ince çubuk direk gibi duruyordu
	for i = 1, 5 do
		local b = 3.9 - i * 0.2
		local p = kutu(m, "Baca", Vector3.new(b, 2.1, b), CFrame.new(sap(o, 0.1), 11.3 + (i - 1) * 2.1, 0.8 + sap(o, 0.1)),
			(i % 2 == 0) and TAS_KOYU or o.renkTas, E.Cobblestone)
		if i <= 2 then yosunla(m, p, o) end
	end
	sabit(kutu(m, "BacaAgzi", Vector3.new(4.0, 0.9, 4.0), CFrame.new(0, 20.5, 0.8), o.renkKoyu, E.Slate))
	sabit(kutu(m, "BacaIci", Vector3.new(2.2, 0.7, 2.2), CFrame.new(0, 21.1, 0.8), KARANLIK, E.SmoothPlastic))

	-- kömür yığını
	for i = 1, 8 do
		local b = 0.9 + o.rnd:NextNumber() * 0.9
		kutu(m, "Komur", Vector3.new(b, b * 0.8, b),
			CFrame.new(-6.2 + sap(o, 1.6), 1.0 + o.rnd:NextNumber() * 1.4, 3.4 + sap(o, 1.6))
				* CFrame.Angles(sap(o, 0.8), sap(o, 0.9), sap(o, 0.8)), KOMUR, E.Slate)
	end
	-- örs + kütük + çekiç
	sabit(silindir(m, "OrsKutugu", Vector3.new(2.4, 2.6, 2.6), CFrame.new(6.0, 1.3, -2.4) * CFrame.Angles(0, 0, math.pi * 0.5), AHSAP, E.Wood))
	sabit(kutu(m, "OrsGovde", Vector3.new(1.5, 1.2, 3.2), CFrame.new(6.0, 3.2, -2.4), DEMIR, E.Metal))
	sabit(kutu(m, "OrsUst", Vector3.new(1.9, 0.6, 4.0), CFrame.new(6.0, 4.0, -2.4), o.renkKoyu, E.Metal))
	kutu(m, "CekicSap", Vector3.new(0.3, 0.3, 2.2), CFrame.new(6.6, 4.4, -1.2) * CFrame.Angles(0, 0.4, 0), AHSAP, E.Wood)
	kutu(m, "CekicUc", Vector3.new(0.8, 0.8, 1.2), CFrame.new(6.6, 4.5, -2.2), DEMIR, E.Metal)
	-- eriyik potası
	sabit(kutu(m, "Pota", Vector3.new(2.0, 1.4, 2.0), CFrame.new(-5.4, 1.7, -3.4), DEMIR, E.Metal))
	sabit(kutu(m, "PotaEriyik", Vector3.new(1.5, 0.4, 1.5), CFrame.new(-5.4, 2.5, -3.4), ALTIN, E.Neon))
	molozSac(m, o, 5, 8, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 12) CEVHER YIĞINI — moloz piramidi + parlayan parçalar (~34 parça)
-- =====================================================================
local function cevherYigini(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("cevherYigini", cf, o)
	local ana = sabit(kutu(m, "TozTaban", Vector3.new(15, 0.4, 15), CFrame.new(0, 0.2, 0), TAS_KOYU, E.Ground))

	-- piramit: yükseldikçe yarıçap ve blok küçülür
	local katlar = { { n = 8, R = 4.6, b = 2.6, y = 1.3 }, { n = 6, R = 3.2, b = 2.2, y = 3.2 }, { n = 4, R = 1.9, b = 1.9, y = 4.9 } }
	for ki, k in ipairs(katlar) do
		for i = 1, k.n do
			local a = (i / k.n) * math.pi * 2 + ki * 0.4
			local p = kutu(m, "Kaya", Vector3.new(k.b + sap(o, 0.3), k.b * 0.85, k.b + sap(o, 0.3)),
				CFrame.new(math.cos(a) * k.R, k.y, math.sin(a) * k.R)
					* CFrame.Angles(sap(o, 0.22), a + sap(o, 0.3), sap(o, 0.22)),
				(i % 3 == 0) and TAS_ACIK or ((i % 4 == 0) and TAS_KOYU or o.renkTas), E.Slate)
			yosunla(m, p, o)
		end
	end
	sabit(kutu(m, "Tepe", Vector3.new(2.2, 1.8, 2.2), CFrame.new(sap(o, 0.3), 6.2, sap(o, 0.3)) * CFrame.Angles(sap(o, 0.2), 0.5, sap(o, 0.2)), o.renkTas, E.Slate))

	-- parlayan cevher parçaları
	for i = 1, 8 do
		local b = 0.7 + o.rnd:NextNumber() * 0.8
		local a = o.rnd:NextNumber() * math.pi * 2
		local d = o.rnd:NextNumber() * 4.2
		local c = kutu(m, "Cevher", Vector3.new(b, b, b),
			CFrame.new(math.cos(a) * d, 1.2 + o.rnd:NextNumber() * 5.4, math.sin(a) * d)
				* CFrame.Angles(sap(o, 1), sap(o, 1), sap(o, 1)), cevherRengi(o, i), E.Neon)
		sabit(c)
		if o.isik and i == 1 then isikKoy(c, c.Color, 20, 1.6) end
	end
	molozSac(m, o, 8, 7, 0)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
-- 13) ASANSÖR KULESİ — taş taban + demir kafes + kabin + karşı ağırlık (~82 parça)
-- =====================================================================
local function asansorKulesi(kok, cf, o)
	o = hazirla(o)
	local m = yeniModel("asansorKulesi", cf, o)
	local ana = sabit(kutu(m, "Kaide", Vector3.new(16, 1.4, 16), CFrame.new(0, 0.7, 0), TAS_KOYU, E.Cobblestone))

	-- taş taban halkası (kuyu ağzını çevreler)
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local p = kutu(m, "TabanTasi", Vector3.new(3.0, 1.8, 1.8),
			CFrame.new(math.cos(a) * 5.2, 2.2, math.sin(a) * 5.2) * CFrame.Angles(0, -a + math.pi * 0.5, sap(o, 0.04)),
			(i % 3 == 0) and TAS_ACIK or o.renkTas, E.Cobblestone)
		yosunla(m, p, o)
	end
	sabit(kutu(m, "KuyuKaranligi", Vector3.new(6.4, 0.6, 6.4), CFrame.new(0, 1.5, 0), KARANLIK, E.SmoothPlastic))

	-- demir kafes kule: 4 ayak × 4 dilim + kuşak + çapraz
	local yuk, kat = 32, 4
	local g = 4.2
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			for k = 1, kat do
				sabit(kutu(m, "Ayak", Vector3.new(0.9, yuk / kat + 0.2, 0.9),
					CFrame.new(sx * g, 1.4 + (k - 0.5) * (yuk / kat), sz * g), DEMIR, E.Metal))
			end
		end
	end
	-- kuşak + çapraz: köşe noktalarından kurulur (elle açı hesabı kafesi savuruyordu)
	local KOSE = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
	for k = 1, kat do
		local yAlt, yUst = 1.4 + (k - 1) * (yuk / kat), 1.4 + k * (yuk / kat)
		for i = 1, 4 do
			local a1, a2 = KOSE[i], KOSE[i % 4 + 1]
			local ust1 = Vector3.new(a1[1] * g, yUst, a1[2] * g)
			local ust2 = Vector3.new(a2[1] * g, yUst, a2[2] * g)
			sabit(eksenKutu(m, "Kusak", 0.55, ust1, ust2, o.renkKoyu, E.Metal))
			-- kabin ÖN yüzden (i==1, -Z) inip çıkar: o yüzü çaprazla kapatma
			if i ~= 1 then
				eksenKutu(m, "Capraz", 0.4, Vector3.new(a1[1] * g, yAlt, a1[2] * g), ust2, DEMIR, E.Metal)
			end
		end
	end

	-- tepe: çark + motor kutusu + kirişler
	local ty = 1.4 + yuk
	sabit(kutu(m, "TepeKiris", Vector3.new(0.9, 0.9, 10.0), CFrame.new(-2.0, ty + 1.4, 0), DEMIR, E.Metal))
	sabit(kutu(m, "TepeKiris", Vector3.new(0.9, 0.9, 10.0), CFrame.new(2.0, ty + 1.4, 0), DEMIR, E.Metal))
	sabit(silindir(m, "Cark", Vector3.new(0.9, 6.4, 6.4), CFrame.new(0, ty + 2.6, 0), o.renkKoyu, E.Metal))
	sabit(silindir(m, "CarkGobek", Vector3.new(1.6, 1.8, 1.8), CFrame.new(0, ty + 2.6, 0), DEMIR, E.Metal))
	for i = 1, 4 do
		local a = (i / 4) * math.pi
		sabit(kutu(m, "CarkKol", Vector3.new(0.45, 6.0, 0.7), CFrame.new(0, ty + 2.6, 0) * CFrame.Angles(a, 0, 0), DEMIR, E.Metal))
	end
	sabit(kutu(m, "MotorKutu", Vector3.new(3.4, 2.6, 4.0), CFrame.new(-5.4, ty - 0.4, 0), o.renkKoyu, E.Metal))
	sabit(kutu(m, "MotorBoru", Vector3.new(0.6, 0.6, 4.6), CFrame.new(-3.4, ty + 0.4, 0) * CFrame.Angles(0, 0, 0), DEMIR, E.Metal))

	-- halatlar + kabin + karşı ağırlık
	local kabinY = 9.0
	sabit(kutu(m, "Halat", Vector3.new(0.22, ty + 2.6 - kabinY - 2.2, 0.22), CFrame.new(-1.2, (ty + kabinY) * 0.5, 0), AHSAP_KOYU, E.Fabric))
	sabit(kutu(m, "Halat", Vector3.new(0.22, ty + 2.6 - 16, 0.22), CFrame.new(1.2, (ty + 18) * 0.5, 0), AHSAP_KOYU, E.Fabric))
	sabit(kutu(m, "KabinTaban", Vector3.new(5.2, 0.4, 5.2), CFrame.new(-1.2, kabinY - 2.4, 0), DEMIR, E.Metal))
	sabit(kutu(m, "KabinTavan", Vector3.new(5.4, 0.4, 5.4), CFrame.new(-1.2, kabinY + 2.2, 0), o.renkKoyu, E.Metal))
	for _, s in ipairs({ -1, 1 }) do
		sabit(kutu(m, "KabinYan", Vector3.new(0.35, 4.6, 5.2), CFrame.new(-1.2 + s * 2.5, kabinY - 0.1, 0), DEMIR, E.Metal))
		sabit(kutu(m, "KabinArka", Vector3.new(5.2, 4.6, 0.35), CFrame.new(-1.2, kabinY - 0.1, s * 2.5), o.renkKoyu, E.Metal))
		kutu(m, "KabinKorkuluk", Vector3.new(5.4, 0.3, 0.3), CFrame.new(-1.2, kabinY + 0.8, s * 2.6), ALTIN, E.Metal)
	end
	if o.isik then
		local lamba = kutu(m, "KabinLamba", Vector3.new(1.2, 0.5, 1.2), CFrame.new(-1.2, kabinY + 1.8, 0), FENER, E.Neon)
		lamba.CanCollide = false
		sabit(lamba)
		isikKoy(lamba, FENER, 22, 1.5)
	end
	sabit(kutu(m, "KarsiAgirlik", Vector3.new(1.8, 4.0, 2.6), CFrame.new(1.2, 18.0, 0), o.renkKoyu, E.Metal))
	sabit(kutu(m, "AgirlikKusak", Vector3.new(2.0, 0.4, 2.8), CFrame.new(1.2, 19.6, 0), DEMIR, E.Metal))

	-- merdiven + çıkış platformu
	for i = 1, 6 do
		kutu(m, "Basamak", Vector3.new(2.6, 0.3, 0.7), CFrame.new(6.4, 3.0 + (i - 1) * 4.6, 0), DEMIR, E.Metal)
	end
	for i = 1, 3 do
		sabit(kutu(m, "Platform", Vector3.new(5.0, 0.4, 1.9), CFrame.new(-7.4, 8.0, (i - 2) * 2.0), DEMIR, E.Metal))
	end
	sabit(kutu(m, "PlatformDikme", Vector3.new(0.6, 8.0, 0.6), CFrame.new(-9.4, 4.0, 0), DEMIR, E.Metal))
	molozSac(m, o, 6, 10, 1.4)
	return bitir(m, kok, ana, o)
end

-- =====================================================================
M.YAPILAR = {
	{ ad = "madenGirisi", etiket = "Maden Girişi", ikon = "⛏", kategori = "Maden", fn = madenGirisi },
	{ ad = "madenTuneli", etiket = "Maden Tüneli", ikon = "🕳", kategori = "Maden", fn = madenTuneli },
	{ ad = "vincKulesi", etiket = "Vinç Kulesi", ikon = "🏗", kategori = "Maden", fn = vincKulesi },
	{ ad = "rayHatti", etiket = "Ray Hattı", ikon = "🛤", kategori = "Maden", fn = rayHatti },
	{ ad = "cevherVagonu", etiket = "Cevher Vagonu", ikon = "🛒", kategori = "Maden", fn = cevherVagonu },
	{ ad = "cevherDamari", etiket = "Cevher Damarı", ikon = "💎", kategori = "Maden", fn = cevherDamari },
	{ ad = "kuyuAgzi", etiket = "Kuyu Ağzı", ikon = "⏬", kategori = "Maden", fn = kuyuAgzi },
	{ ad = "madenciKampi", etiket = "Madenci Kampı", ikon = "🏕", kategori = "Maden", fn = madenciKampi },
	{ ad = "cevherDeposu", etiket = "Cevher Deposu", ikon = "🏚", kategori = "Maden", fn = cevherDeposu },
	{ ad = "konveyorIskele", etiket = "Konveyör İskelesi", ikon = "📐", kategori = "Maden", fn = konveyorIskele },
	{ ad = "eritmeOcagi", etiket = "Eritme Ocağı", ikon = "🔥", kategori = "Maden", fn = eritmeOcagi },
	{ ad = "cevherYigini", etiket = "Cevher Yığını", ikon = "🔶", kategori = "Maden", fn = cevherYigini },
	{ ad = "asansorKulesi", etiket = "Asansör Kulesi", ikon = "⏫", kategori = "Maden", fn = asansorKulesi },
}

return M
