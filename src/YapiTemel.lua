-- SWEAX TERRAIN — YapiTemel: architecture, ruins and nature structures (13).
-- Mimari/kalıntı TEMEL yapı kütüphanesi. Arazinin üstüne tek tıkla konan kaide, kemer,
-- sütun, kalıntı duvar, merdiven, dikili taş halkası, kule, köprü, su kanalı, kaya, avlu ve
-- meydan zemini. Palet üç renktir (TAS/KOYU/YOSUN); açık-koyu türevler bu üç renkten Lerp ile
-- üretilir ki renkTas değiştirildiğinde tüm yapı uyumlu kalsın. Yalnız Part kullanılır (MeshPart/Union YOK → asset
-- gerekmez), her şey Anchored+CanCollide (yalnız fener camı ve kanal suyu geçirgen).
-- Rastgelelik SADECE o.rnd üzerinden: aynı tohum → birebir aynı yapı.
-- Sözleşme: fn(kok, cf, o) -> Model ; cf = yapının TABAN MERKEZİ (y = zemin), -Z = ön.
local M = {}

-- ---------- kısa yollar ----------
local V3 = Vector3.new
local CF = CFrame.new
local ACI = CFrame.Angles
local RAD = math.rad

-- ---------- palet (ölçülen 3 renk + türevler) ----------
local BEYAZ = Color3.new(1, 1, 1)
local SIYAH = Color3.new(0, 0, 0)
local TAS = Color3.fromRGB(99, 95, 98) -- ana gövde
local KOYU = Color3.fromRGB(68, 68, 68) -- kenar/derz
local YOSUN = Color3.fromRGB(44, 101, 29) -- yosun aksanı
local AHSAP = Color3.fromRGB(104, 71, 42)
local AHSAP_KOYU = Color3.fromRGB(74, 50, 30)
local DEMIR = Color3.fromRGB(120, 124, 132)
local ALTIN = Color3.fromRGB(214, 170, 54)
local FENER = Color3.fromRGB(255, 206, 110)
local SU = Color3.fromRGB(60, 120, 190)
local CEVHER = {
	Color3.fromRGB(74, 214, 200),
	Color3.fromRGB(200, 60, 54),
	Color3.fromRGB(140, 90, 190),
}

-- ---------- malzemeler ----------
local M_TAS = Enum.Material.Slate -- taş gövde
local M_KOB = Enum.Material.Cobblestone -- kenar/derz/köşe blokları
local M_AHS = Enum.Material.WoodPlanks
local M_DEM = Enum.Material.Metal
local M_YOS = Enum.Material.Grass
local M_NEON = Enum.Material.Neon
local M_DUZ = Enum.Material.SmoothPlastic

M.PALET = {
	TAS = TAS, KOYU = KOYU, YOSUN = YOSUN, AHSAP = AHSAP, AHSAP_KOYU = AHSAP_KOYU,
	DEMIR = DEMIR, ALTIN = ALTIN, FENER = FENER, SU = SU, CEVHER = CEVHER,
}

-- ---------- ortak yardımcılar (bu dosya KENDİ İÇİNDE tanımlar — dış bağımlılık yok) ----------
-- Model → {cf, s, a} bağlamı: kutu() imzası (m, ad, boyut, yerelCF, renk, mat) olduğu için
-- taban CFrame ve ölçek modelin üstünden okunur. Zayıf anahtar: model silinince kayıt düşer.
local BAGLAM = setmetatable({}, { __mode = "k" })

local function say(v, d)
	return typeof(v) == "number" and v or d
end

local function ayarla(o)
	-- eksik alanları doldur; çağıranın tablosunu DEĞİŞTİRME (yerleştirici aynı tabloyu tekrar kullanabilir)
	o = o or {}
	local tohum = math.floor(say(o.tohum, 12345))
	local a = {
		olcek = math.max(0.05, say(o.olcek, 1)),
		tohum = tohum,
		rnd = o.rnd or Random.new(tohum),
		yosun = math.clamp(say(o.yosun, 0.5), 0, 1),
		yikik = math.clamp(say(o.yikik, 0.35), 0, 1),
		isik = o.isik ~= false,
		renkTas = o.renkTas or TAS,
		renkKoyu = o.renkKoyu or KOYU,
		renkYosun = o.renkYosun or YOSUN,
		uzunluk = o.uzunluk,
		sekil = o.sekil,
		en = o.en,
		boy = o.boy,
		adet = o.adet,
	}
	-- türevler renkTas'tan üretilir: ana taş değişirse açık/koyu tonlar uyumlu kalsın
	a.tasAcik = a.renkTas:Lerp(BEYAZ, 0.20) -- ~RGB(130,127,129)
	a.tasKoyu = a.renkTas:Lerp(SIYAH, 0.25) -- ~RGB(74,71,74)
	return a
end

local function yeni(ad, cf, a)
	local m = Instance.new("Model")
	m.Name = ad
	-- yosunButce: yapı başına yosun parçası tavanı (yosun=1'de parça sayısı 120'yi aşmasın)
	BAGLAM[m] = { cf = cf, s = a.olcek, a = a, yosunButce = 26 }
	return m
end

local function bitir(m, kok, ana, ad, a)
	m.PrimaryPart = ana
	m:SetAttribute("SweaxStructure", ad)
	m:SetAttribute("SweaxSeed", a.tohum)
	m.Parent = kok
	return m
end

-- kutu: yapının yerel koordinatında bir blok kur (cf * yerelCF ile dünyaya oturur)
local function kutu(m, ad, boyut, yerelCF, renk, mat)
	local b = BAGLAM[m]
	local s = b.s
	local yc = typeof(yerelCF) == "Vector3" and CF(yerelCF) or yerelCF
	local p = Instance.new("Part")
	p.Name = ad
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = true
	p.Size = V3(math.max(0.05, boyut.X * s), math.max(0.05, boyut.Y * s), math.max(0.05, boyut.Z * s))
	-- konum ölçeklenir, dönüş aynen korunur (aksi halde ölçekte yapı dağılır)
	p.CFrame = b.cf * (CF(yc.Position * s) * (yc - yc.Position))
	p.Color = renk or b.a.renkTas
	p.Material = mat or M_TAS
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

-- asin: parçayı "aşınabilir" işaretle (asindir yalnız işaretlileri bozar; taban/kolon bozulmasın)
local function asin(p)
	p:SetAttribute("SweaxWeathered", true)
	return p
end

-- yosunla: parçanın üstüne/yan yüzüne rastgele yosun yaması kondur
local function yosunla(m, p, o)
	local b = BAGLAM[m]
	local a = o or b.a
	if a.yosun <= 0.01 or not p or not p.Parent or b.yosunButce <= 0 then return end
	local rnd = a.rnd
	if rnd:NextNumber() > a.yosun then return end
	local adet = math.min(b.yosunButce, (rnd:NextNumber() < a.yosun * 0.55) and 2 or 1)
	b.yosunButce -= adet
	for _ = 1, adet do
		local ust = rnd:NextNumber() < 0.72
		local yp = Instance.new("Part")
		yp.Name = "Yosun"
		yp.Anchored = true
		yp.CanCollide = true
		yp.CastShadow = true
		-- v2: tek renk yerine hafif ton oynaması — düz yeşil "sticker" gibi durmasın
		yp.Color = a.renkYosun:Lerp(Color3.new(0, 0, 0), rnd:NextNumber(0, 0.30))
		yp.Material = M_YOS
		yp.TopSurface = Enum.SurfaceType.Smooth
		yp.BottomSurface = Enum.SurfaceType.Smooth
		local t = math.max(0.06, 0.2 * b.s)
		-- v2 TUZAK: boyut yalnız ORANLA hesaplanıyordu; 24×24 kademede %25-60 = 6-14 stud'luk
		-- dev yeşil plakalar çıkıyordu (heykel kaidesinde iki tanesi basamağı boydan boya kaplamıştı).
		-- Yosun bir LEKE'dir → mutlak tavan konur.
		local TAVAN = 2.4 * b.s
		if ust then
			local sx = math.min(TAVAN, math.max(0.1, p.Size.X * rnd:NextNumber(0.25, 0.6)))
			local sz = math.min(TAVAN, math.max(0.1, p.Size.Z * rnd:NextNumber(0.25, 0.6)))
			local dx = (p.Size.X - sx) * 0.5 * rnd:NextNumber(-1, 1)
			local dz = (p.Size.Z - sz) * 0.5 * rnd:NextNumber(-1, 1)
			yp.Size = V3(sx, t, sz)
			yp.CFrame = p.CFrame * CF(dx, p.Size.Y * 0.5 + t * 0.5, dz)
		else
			-- sarmaşık: -Z (ön) yüzüne yapışan ince şerit
			local sx = math.min(TAVAN, math.max(0.1, p.Size.X * rnd:NextNumber(0.18, 0.45)))
			local sy = math.min(TAVAN * 1.4, math.max(0.1, p.Size.Y * rnd:NextNumber(0.3, 0.8)))
			local dx = (p.Size.X - sx) * 0.5 * rnd:NextNumber(-1, 1)
			local dy = (p.Size.Y - sy) * 0.5 * rnd:NextNumber(-0.6, 1)
			yp.Size = V3(sx, sy, t)
			yp.CFrame = p.CFrame * CF(dx, dy, -(p.Size.Z * 0.5 + t * 0.5))
		end
		yp.Parent = m
	end
end

-- asindir: yıkık görünüm — işaretli parçaları kaydır/döndür/eksilt, bir kısmını düşür
local function asindir(m, o)
	local b = BAGLAM[m]
	local a = o or b.a
	if a.yikik <= 0.01 then return end
	local rnd, s = a.rnd, b.s
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p:GetAttribute("SweaxWeathered") then
			if rnd:NextNumber() < a.yikik * 0.16 then
				p:Destroy() -- düşmüş/kopmuş taş
			else
				local k = a.yikik * 0.6 * s
				p.CFrame = p.CFrame
					* CF(rnd:NextNumber(-k, k), rnd:NextNumber(-k * 0.5, k * 0.25), rnd:NextNumber(-k, k))
					* ACI(RAD(rnd:NextNumber(-7, 7) * a.yikik), RAD(rnd:NextNumber(-9, 9) * a.yikik), RAD(rnd:NextNumber(-7, 7) * a.yikik))
				if rnd:NextNumber() < a.yikik * 0.35 then
					local f = rnd:NextNumber(0.55, 0.92)
					p.Size = V3(math.max(0.05, p.Size.X * f), p.Size.Y, math.max(0.05, p.Size.Z * f))
				end
			end
		end
	end
end

-- fener: neon çekirdek + kafes + (isteğe bağlı) ışık; cam parçası geçirgen ve çarpışmasız
local function fenerKur(m, a, yerelCF, boy)
	boy = boy or 1
	kutu(m, "FenerDirek", V3(0.8 * boy, 2.4 * boy, 0.8 * boy), yerelCF * CF(0, -1.6 * boy, 0), DEMIR, M_DEM)
	local cekirdek = kutu(m, "FenerCekirdek", V3(1.4 * boy, 1.4 * boy, 1.4 * boy), yerelCF, FENER, M_NEON)
	for i = 1, 4 do
		local ax = (i == 1 or i == 4) and 1 or -1
		local az = (i <= 2) and 1 or -1
		kutu(m, "FenerKafes" .. i, V3(0.3 * boy, 2.2 * boy, 0.3 * boy),
			yerelCF * CF(ax * 0.95 * boy, 0, az * 0.95 * boy), DEMIR, M_DEM)
	end
	local cam = kutu(m, "FenerCam", V3(1.95 * boy, 1.95 * boy, 1.95 * boy), yerelCF, FENER, M_DUZ)
	cam.Transparency = 0.62
	cam.CanCollide = false -- tek istisna: cam (oyuncu fenere takılmasın)
	cam.CastShadow = false
	if a.isik then
		local l = Instance.new("PointLight")
		l.Color = FENER
		l.Brightness = 2.2
		l.Range = 24 * a.olcek
		l.Parent = cekirdek
	end
	return cekirdek
end

-- ==================================================================
-- 1) KADEMELİ KAİDE — referans görseldeki kademeli gri taş platform
-- ==================================================================
local function kademeliKaide(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Kademeli Kaide", cf, a)
	local kad = rnd:NextInteger(3, 4)
	local en0, yuk = 40, 2.4
	local taban

	for k = 1, kad do
		local en = en0 - (k - 1) * 8
		local y = (k - 1) * yuk
		local p = kutu(m, "Kademe" .. k, V3(en, yuk, en), CF(0, y + yuk * 0.5, 0), a.renkTas, M_TAS)
		if k == 1 then taban = p end
		-- pervaz: kademe sınırını belli eden koyu şerit (kademeler tek blok gibi görünmesin)
		kutu(m, "Pervaz" .. k, V3(en + 1.2, 0.5, en + 1.2), CF(0, y + yuk - 0.25, 0), a.renkKoyu, M_KOB)
		for i = 1, 4 do
			local ax = (i == 1 or i == 4) and 1 or -1
			local az = (i <= 2) and 1 or -1
			local c = kutu(m, "Kose" .. k .. "_" .. i, V3(3, yuk + 0.1, 3),
				CF(ax * (en * 0.5 - 1.5), y + yuk * 0.5, az * (en * 0.5 - 1.5)), a.renkKoyu, M_KOB)
			yosunla(m, c, a)
		end
		yosunla(m, p, a)
	end

	local ustY = kad * yuk
	local enUst = en0 - (kad - 1) * 8
	-- üst yüzey derzleri (3+3 ince çizgi): düz platform yerine döşenmiş taş hissi
	for i = 1, 3 do
		local d = (i - 2) * (enUst / 3)
		kutu(m, "DerzX" .. i, V3(enUst, 0.22, 0.5), CF(0, ustY + 0.11, d), a.tasKoyu, M_TAS)
		kutu(m, "DerzZ" .. i, V3(0.5, 0.22, enUst), CF(d, ustY + 0.11, 0), a.tasKoyu, M_TAS)
	end
	-- üst köşe süs blokları
	for i = 1, 4 do
		local ax = (i == 1 or i == 4) and 1 or -1
		local az = (i <= 2) and 1 or -1
		local c = kutu(m, "UstKose" .. i, V3(2.4, 1.4, 2.4),
			CF(ax * (enUst * 0.5 - 1.4), ustY + 0.7, az * (enUst * 0.5 - 1.4)), a.tasAcik, M_TAS)
		asin(c)
		yosunla(m, c, a)
	end
	-- ön yaklaşım basamakları (-Z ön; kaidenin DIŞINDA kalmalı, içine gömülmesin)
	for i = 1, 3 do
		local sy = i * (yuk * kad / 3)
		kutu(m, "Basamak" .. i, V3(14, sy, 2.2),
			CF(0, sy * 0.5, -(en0 * 0.5 + (4 - i) * 2.2 - 1.1)), a.renkTas, M_TAS)
	end

	asindir(m, a)
	return bitir(m, kok, taban, "kademeliKaide", a)
end

-- ==================================================================
-- 2) HEYKEL KAİDESİ — kademeli kaide + kazma tutan madenci heykeli
-- ==================================================================
local function heykelKaidesi(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Heykel Kaidesi", cf, a)
	local yuk, taban = 2.2, nil

	-- alt kademeler
	for k = 1, 3 do
		local en = 24 - (k - 1) * 5
		local y = (k - 1) * yuk
		local p = kutu(m, "Kademe" .. k, V3(en, yuk, en), CF(0, y + yuk * 0.5, 0), a.renkTas, M_TAS)
		if k == 1 then taban = p end
		kutu(m, "Pervaz" .. k, V3(en + 1, 0.45, en + 1), CF(0, y + yuk - 0.22, 0), a.renkKoyu, M_KOB)
		for i = 1, 4 do
			local ax = (i == 1 or i == 4) and 1 or -1
			local az = (i <= 2) and 1 or -1
			local c = kutu(m, "Kose" .. k .. "_" .. i, V3(2.6, yuk + 0.1, 2.6),
				CF(ax * (en * 0.5 - 1.3), y + yuk * 0.5, az * (en * 0.5 - 1.3)), a.renkKoyu, M_KOB)
			yosunla(m, c, a)
		end
		yosunla(m, p, a)
	end

	-- dikdörtgen kaide gövdesi
	local h0 = 3 * yuk
	kutu(m, "KaideAlt", V3(10.5, 1, 8.5), CF(0, h0 + 0.5, 0), a.renkKoyu, M_KOB)
	local govde = kutu(m, "KaideGovde", V3(9, 6, 7), CF(0, h0 + 4, 0), a.renkTas, M_TAS)
	kutu(m, "KaideUst", V3(10.5, 1, 8.5), CF(0, h0 + 7.5, 0), a.renkKoyu, M_KOB)
	yosunla(m, govde, a)
	-- ön yüzde kitabe + altın çerçeve
	kutu(m, "Kitabe", V3(5.4, 2.4, 0.4), CF(0, h0 + 4, -3.6), a.tasKoyu, M_TAS)
	kutu(m, "KitabeUst", V3(6, 0.35, 0.5), CF(0, h0 + 5.3, -3.65), ALTIN, M_DEM)
	kutu(m, "KitabeAlt", V3(6, 0.35, 0.5), CF(0, h0 + 2.7, -3.65), ALTIN, M_DEM)
	kutu(m, "KitabeSol", V3(0.35, 2.75, 0.5), CF(-2.85, h0 + 4, -3.65), ALTIN, M_DEM)
	kutu(m, "KitabeSag", V3(0.35, 2.75, 0.5), CF(2.85, h0 + 4, -3.65), ALTIN, M_DEM)

	-- ---- MADENCİ HEYKELİ (voksel) ----
	local hs = h0 + 8 -- heykel taban Y'si
	local ten = a.tasAcik -- heykel taş renginde
	kutu(m, "BotSol", V3(1.7, 0.9, 2.6), CF(-1.2, hs + 0.45, -0.2), ten, M_TAS)
	kutu(m, "BotSag", V3(1.7, 0.9, 2.6), CF(1.2, hs + 0.45, -0.2), ten, M_TAS)
	kutu(m, "BacakSol", V3(1.5, 3.5, 1.6), CF(-1.2, hs + 2.65, 0), ten, M_TAS)
	kutu(m, "BacakSag", V3(1.5, 3.5, 1.6), CF(1.2, hs + 2.65, 0), ten, M_TAS)
	kutu(m, "Kemer", V3(4.4, 1.2, 2.4), CF(0, hs + 5, 0), a.renkKoyu, M_KOB)
	kutu(m, "GovdeAlt", V3(4, 1.8, 2.2), CF(0, hs + 6.5, 0), ten, M_TAS)
	local gogus = kutu(m, "Gogus", V3(4.6, 2.2, 2.5), CF(0, hs + 8.5, 0), ten, M_TAS)
	kutu(m, "AskiSol", V3(0.5, 2.4, 0.4), CF(-1.1, hs + 8.4, -1.3), a.renkKoyu, M_KOB)
	kutu(m, "AskiSag", V3(0.5, 2.4, 0.4), CF(1.1, hs + 8.4, -1.3), a.renkKoyu, M_KOB)
	kutu(m, "OmuzSol", V3(1.4, 1.2, 2.4), CF(-2.7, hs + 9.1, 0), ten, M_TAS)
	kutu(m, "OmuzSag", V3(1.4, 1.2, 2.4), CF(2.7, hs + 9.1, 0), ten, M_TAS)
	kutu(m, "Boyun", V3(1.3, 0.8, 1.3), CF(0, hs + 9.95, 0), ten, M_TAS)
	kutu(m, "Kafa", V3(2.2, 2, 2.2), CF(0, hs + 11.3, 0), ten, M_TAS)
	kutu(m, "Kask", V3(2.7, 0.9, 2.7), CF(0, hs + 12.75, 0), ALTIN, M_DEM)
	kutu(m, "KaskTepe", V3(1.8, 0.7, 1.8), CF(0, hs + 13.5, 0), ALTIN, M_DEM)
	kutu(m, "KaskSiper", V3(2.7, 0.4, 0.9), CF(0, hs + 12.4, -1.6), ALTIN, M_DEM)
	local lamba = kutu(m, "KaskFeneri", V3(0.9, 0.8, 0.6), CF(0, hs + 12.7, -1.5), FENER, M_NEON)
	if a.isik then
		local l = Instance.new("PointLight")
		l.Color = FENER
		l.Brightness = 1.6
		l.Range = 16 * a.olcek
		l.Parent = lamba
	end
	-- sol kol aşağıda, sağ kol KAZMAYI HAVADA tutuyor (referans poz)
	kutu(m, "SolUstKol", V3(1.3, 3, 1.3), CF(-3, hs + 7.8, 0) * ACI(0, 0, RAD(7)), ten, M_TAS)
	kutu(m, "SolOnKol", V3(1.15, 2.6, 1.15), CF(-3.35, hs + 5.2, 0.5) * ACI(RAD(12), 0, 0), ten, M_TAS)
	kutu(m, "SolEl", V3(1.35, 1.1, 1.35), CF(-3.45, hs + 3.7, 0.8), ten, M_TAS)
	kutu(m, "SagUstKol", V3(1.3, 3, 1.3), CF(3.15, hs + 10, 0.3) * ACI(0, 0, RAD(-16)), ten, M_TAS)
	kutu(m, "SagOnKol", V3(1.15, 2.5, 1.15), CF(3.3, hs + 11.7, 0.6) * ACI(RAD(-12), 0, RAD(-8)), ten, M_TAS)
	local elCF = CF(3.15, hs + 12.7, 0.8)
	kutu(m, "SagEl", V3(1.35, 1.2, 1.35), elCF, ten, M_TAS)
	-- kazma: elden yukarı-geriye doğru savrulmuş
	local sapCF = elCF * ACI(RAD(32), 0, RAD(10)) * CF(0, 2.6, 0)
	kutu(m, "KazmaSapi", V3(0.7, 6.6, 0.7), sapCF, AHSAP, M_AHS)
	local basCF = sapCF * CF(0, 3, 0)
	kutu(m, "KazmaBasi", V3(0.95, 0.95, 5), basCF, DEMIR, M_DEM)
	kutu(m, "KazmaUc1", V3(0.85, 0.85, 1.9), basCF * CF(0, 0, 2.9) * ACI(RAD(-20), 0, 0), DEMIR, M_DEM)
	kutu(m, "KazmaUc2", V3(0.85, 0.85, 1.9), basCF * CF(0, 0, -2.9) * ACI(RAD(20), 0, 0), DEMIR, M_DEM)
	-- v2: heykelin GÖĞSÜNE yosun konmuyor artık — anıtın kendisi temiz kalmalı, yosun kaideye ait
	-- (madencinin göğsünde yeşil bir yama yamalık gibi duruyordu).

	asindir(m, a)
	return bitir(m, kok, taban, "heykelKaidesi", a)
end

-- ==================================================================
-- 3) TAŞ KEMER — iki ayak + kademeli kemer + kilit taşı
-- ==================================================================
local function taskemer(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Taş Kemer", cf, a)
	local acik, ayakEn, der = 16, 5, 6
	local ayakX = acik * 0.5 + ayakEn * 0.5
	local ayakY = 12
	local taban

	for s = -1, 1, 2 do
		local ad = (s < 0) and "Sol" or "Sag"
		local p = kutu(m, "Ayak" .. ad .. "Plaka", V3(ayakEn + 2, 1.2, der + 2), CF(s * ayakX, 0.6, 0), a.renkKoyu, M_KOB)
		if s < 0 then taban = p end
		for k = 1, 3 do
			local b = kutu(m, "Ayak" .. ad .. k, V3(ayakEn, 3.4, der),
				CF(s * ayakX, 1.2 + (k - 0.5) * 3.4, 0), a.renkTas, M_TAS)
			yosunla(m, b, a)
		end
		-- koyu kuşak bantları (yatay derz)
		kutu(m, "Bant" .. ad .. "1", V3(ayakEn + 0.5, 0.4, der + 0.5), CF(s * ayakX, 4.6, 0), a.renkKoyu, M_KOB)
		kutu(m, "Bant" .. ad .. "2", V3(ayakEn + 0.5, 0.4, der + 0.5), CF(s * ayakX, 8, 0), a.renkKoyu, M_KOB)
		kutu(m, "Baslik" .. ad, V3(ayakEn + 1.4, 1.4, der + 1.4), CF(s * ayakX, ayakY - 0.3, 0), a.tasAcik, M_TAS)
		kutu(m, "Payanda" .. ad, V3(2, 6, der - 1), CF(s * (ayakX + ayakEn * 0.5 + 0.9), 3.5, 0), a.renkTas, M_TAS)
	end

	-- kemer: yarım daire üzerinde 11 kama taşı (yerel Y ekseni yarıçap yönüne bakar)
	local R = acik * 0.5 + 2
	local n = 11
	for i = 1, n do
		local t = (i - 0.5) / n * math.pi
		local x = math.cos(t) * R
		local y = ayakY + math.sin(t) * R
		local k = kutu(m, "Kama" .. i, V3(3.4, 3.2, der),
			CF(x, y, 0) * ACI(0, 0, t - math.pi * 0.5), a.renkTas, M_TAS)
		asin(k)
		yosunla(m, k, a)
	end
	kutu(m, "KilitTasi", V3(4.2, 4.6, der + 0.8), CF(0, ayakY + R + 0.4, 0), a.tasAcik, M_TAS)
	kutu(m, "UstPervaz", V3(acik + ayakEn * 2 + 4, 1, der + 1.6), CF(0, ayakY + R + 3.2, 0), a.renkKoyu, M_KOB)
	kutu(m, "UstTac", V3(acik + ayakEn * 2, 0.9, der + 0.6), CF(0, ayakY + R + 4.1, 0), a.tasKoyu, M_TAS)
	-- zemin eşiği
	kutu(m, "EsikOn", V3(acik, 0.6, 2), CF(0, 0.3, -(der * 0.5 - 1)), a.renkKoyu, M_KOB)
	kutu(m, "EsikArka", V3(acik, 0.6, 2), CF(0, 0.3, der * 0.5 - 1), a.renkKoyu, M_KOB)

	asindir(m, a)
	return bitir(m, kok, taban, "taskemer", a)
end

-- ==================================================================
-- 4) SÜTUNLAR — farklı yükseklikte kırık sütunlar (bazıları devrik)
-- ==================================================================
local function sutunlar(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Sütunlar", cf, a)
	local adet = math.clamp(math.floor(say(a.adet, rnd:NextInteger(3, 6))), 3, 8)

	-- ortak zemin plakaları
	local taban = kutu(m, "ZeminPlaka1", V3(adet * 9 + 6, 0.8, 14), CF(0, 0.4, 0), a.renkTas, M_TAS)
	kutu(m, "ZeminPervaz", V3(adet * 9 + 8, 0.5, 16), CF(0, 0.2, 0), a.renkKoyu, M_KOB)
	for i = 1, 3 do
		kutu(m, "ZeminDerz" .. i, V3(adet * 9 + 6, 0.2, 0.5), CF(0, 0.85, (i - 2) * 4.5), a.tasKoyu, M_TAS)
	end
	kutu(m, "ZeminYama", V3(10, 0.3, 10), CF(rnd:NextNumber(-6, 6), 0.9, rnd:NextNumber(-3, 3)), a.tasAcik, M_TAS)

	for i = 1, adet do
		local x = (i - (adet + 1) * 0.5) * 9
		local devrik = rnd:NextNumber() < 0.32
		kutu(m, "Kaide" .. i, V3(5, 1, 5), CF(x, 1.3, 0), a.renkKoyu, M_KOB)
		if devrik then
			-- devrilmiş sütun: tamburlar yerde +Z yönüne dizili
			local kat = rnd:NextInteger(2, 4)
			for k = 1, kat do
				local d = kutu(m, "Devrik" .. i .. "_" .. k, V3(3.4, 3.6, 3.4),
					CF(x + rnd:NextNumber(-0.5, 0.5), 3.6, 3 + (k - 0.5) * 3.7)
						* ACI(RAD(90), RAD(rnd:NextNumber(-8, 8)), 0), a.renkTas, M_TAS)
				asin(d)
				yosunla(m, d, a)
			end
		else
			local kat = rnd:NextInteger(2, 4)
			for k = 1, kat do
				local d = kutu(m, "Tambur" .. i .. "_" .. k, V3(3.4, 3.6, 3.4),
					CF(x, 1.8 + (k - 0.5) * 3.6, 0) * ACI(0, RAD(rnd:NextNumber(-6, 6)), 0), a.renkTas, M_TAS)
				yosunla(m, d, a)
			end
			-- kırık üst: eğik ve daralmış son parça
			local ust = kutu(m, "Kirik" .. i, V3(3.2, rnd:NextNumber(0.8, 2.2), 3.2),
				CF(x, 1.8 + kat * 3.6 + 0.7, 0) * ACI(RAD(rnd:NextNumber(-9, 9)), 0, RAD(rnd:NextNumber(-9, 9))),
				a.tasAcik, M_TAS)
			asin(ust)
			yosunla(m, ust, a)
		end
	end

	-- moloz
	for i = 1, 8 do
		local r = kutu(m, "Moloz" .. i, V3(rnd:NextNumber(0.9, 2.4), rnd:NextNumber(0.7, 1.6), rnd:NextNumber(0.9, 2.4)),
			CF(rnd:NextNumber(-adet * 4.2, adet * 4.2), 1.2, rnd:NextNumber(-6, 6))
				* ACI(RAD(rnd:NextNumber(-15, 15)), RAD(rnd:NextNumber(0, 180)), RAD(rnd:NextNumber(-15, 15))),
			a.renkTas, M_KOB)
		yosunla(m, r, a)
	end

	asindir(m, a)
	return bitir(m, kok, taban, "sutunlar", a)
end

-- ==================================================================
-- 5) KALINTI DUVAR — düzensiz üstlü, delikli yıkık duvar + düşmüş bloklar
-- ==================================================================
local function kalintiDuvar(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Kalıntı Duvar", cf, a)
	local sut, satMax = 10, 6
	local bw, bh, bd = 3, 2, 2.4
	local uzun = sut * bw

	local taban = kutu(m, "Temel", V3(uzun + 2, 1, bd + 1.6), CF(0, 0.5, 0), a.renkKoyu, M_KOB)
	kutu(m, "TemelPervaz", V3(uzun + 3.2, 0.45, bd + 2.6), CF(0, 0.22, 0), a.tasKoyu, M_KOB)

	for i = 1, sut do
		local x = (i - (sut + 1) * 0.5) * bw
		local h = rnd:NextInteger(2, satMax) -- düzensiz üst kenar
		for j = 1, h do
			-- delikler: yükseldikçe artan boşluk olasılığı
			local bosluk = (j > 2) and (rnd:NextNumber() < 0.06 + a.yikik * 0.14) or false
			if not bosluk then
				local kaydir = (j % 2 == 0) and bw * 0.5 or 0 -- şaşırtmalı örgü
				local b = kutu(m, "Blok" .. i .. "_" .. j, V3(bw - 0.15, bh - 0.12, bd),
					CF(x + kaydir, 1 + (j - 0.5) * bh, 0), (j % 2 == 0) and a.renkTas or a.tasKoyu, M_TAS)
				if j >= h - 1 then asin(b) end
				yosunla(m, b, a)
			end
		end
	end

	-- düşmüş bloklar (duvarın önünde)
	for i = 1, 8 do
		local d = kutu(m, "Dusmus" .. i, V3(rnd:NextNumber(1.4, 3), rnd:NextNumber(1, 2), rnd:NextNumber(1.4, 2.6)),
			CF(rnd:NextNumber(-uzun * 0.5, uzun * 0.5), 1.5, -rnd:NextNumber(2.5, 8))
				* ACI(RAD(rnd:NextNumber(-20, 20)), RAD(rnd:NextNumber(0, 180)), RAD(rnd:NextNumber(-20, 20))),
			a.renkTas, M_KOB)
		yosunla(m, d, a)
	end

	asindir(m, a)
	return bitir(m, kok, taban, "kalintiDuvar", a)
end

-- ==================================================================
-- 6) MERDİVEN SETİ — geniş taş merdiven + rampalı yan duvarlar
-- ==================================================================
local function merdivenSeti(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Merdiven Seti", cf, a)
	local n, en, bh, bd = 10, 14, 1.2, 2.2
	local uz = n * bd

	local taban = kutu(m, "AltSahanlik", V3(en + 6, 0.8, 5), CF(0, 0.4, -(uz * 0.5 + 2.5)), a.renkKoyu, M_KOB)
	for i = 1, n do
		local z = -uz * 0.5 + (i - 0.5) * bd
		local h = i * bh
		local s = kutu(m, "Basamak" .. i, V3(en, h, bd), CF(0, h * 0.5, z), a.renkTas, M_TAS)
		kutu(m, "BasamakBurun" .. i, V3(en + 0.4, 0.25, 0.5), CF(0, h - 0.12, z - bd * 0.5 + 0.25), a.renkKoyu, M_KOB)
		yosunla(m, s, a)
	end
	kutu(m, "UstSahanlik", V3(en, n * bh, 5), CF(0, n * bh * 0.5, uz * 0.5 + 2.5), a.renkTas, M_TAS)

	-- yan duvarlar: basamakla birlikte yükselen kademeli rampa
	for sn = -1, 1, 2 do
		local ad = (sn < 0) and "Sol" or "Sag"
		for i = 1, n do
			local z = -uz * 0.5 + (i - 0.5) * bd
			local h = i * bh + 1.8
			local d = kutu(m, "Korkuluk" .. ad .. i, V3(2, h, bd), CF(sn * (en * 0.5 + 1), h * 0.5, z), a.renkTas, M_TAS)
			if i >= n - 2 then asin(d) end
			yosunla(m, d, a)
		end
		for i = 1, 3 do
			kutu(m, "Topuz" .. ad .. i, V3(2.6, 1.2, 2.6),
				CF(sn * (en * 0.5 + 1), (i * 3) * bh + 2.4, -uz * 0.5 + (i * 3 - 0.5) * bd), a.tasAcik, M_TAS)
		end
	end

	asindir(m, a)
	return bitir(m, kok, taban, "merdivenSeti", a)
end

-- ==================================================================
-- 7) DİKİLİ TAŞLAR — Stonehenge benzeri halka + lento taşları
-- ==================================================================
local function dikiliTaslar(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Dikili Taşlar", cf, a)
	local adet = math.clamp(math.floor(say(a.adet, rnd:NextInteger(5, 8))), 4, 10)
	local R = 13

	-- ortada düz zemin: dört çeyrek plaka (tek blok yerine döşeli dursun)
	local taban = kutu(m, "MeydanCerceve", V3(R * 1.5 + 1.6, 0.4, R * 1.5 + 1.6), CF(0, 0.2, 0), a.renkKoyu, M_KOB)
	local ce = R * 0.72
	for i = 1, 4 do
		local ax = (i == 1 or i == 4) and 1 or -1
		local az = (i <= 2) and 1 or -1
		kutu(m, "MeydanPlaka" .. i, V3(ce - 0.3, 0.7, ce - 0.3),
			CF(ax * ce * 0.5, 0.35, az * ce * 0.5), a.renkTas, M_TAS)
	end
	kutu(m, "OrtaTas", V3(4, 0.9, 4), CF(0, 0.85, 0), a.tasAcik, M_TAS)
	for i = 1, 3 do
		kutu(m, "MeydanDerz" .. i, V3(R * 1.5, 0.18, 0.45), CF(0, 0.72, (i - 2) * R * 0.42), a.tasKoyu, M_TAS)
	end

	local aci, boy = {}, {}
	for i = 1, adet do
		local t = (i - 1) / adet * math.pi * 2
		local h = rnd:NextNumber(8, 12)
		aci[i], boy[i] = t, h
		-- geniş yüz TEĞET dursun (halka duvarı hissi): Y dönüşü −t−π/2
		local p = kutu(m, "DikiliTas" .. i, V3(3.4, h, 2.2),
			CF(math.cos(t) * R, h * 0.5, math.sin(t) * R)
				* ACI(RAD(rnd:NextNumber(-4, 4)), -t - math.pi * 0.5, RAD(rnd:NextNumber(-4, 4))), a.renkTas, M_TAS)
		asin(p)
		yosunla(m, p, a)
	end
	-- lentolar: bir atlayarak komşu ikilileri bağla
	for i = 1, adet - 1, 2 do
		local t1, t2 = aci[i], aci[i + 1]
		local x1, z1 = math.cos(t1) * R, math.sin(t1) * R
		local x2, z2 = math.cos(t2) * R, math.sin(t2) * R
		local ox, oz = (x1 + x2) * 0.5, (z1 + z2) * 0.5
		local uz = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2) + 3
		local y = math.min(boy[i], boy[i + 1]) + 0.6
		local l = kutu(m, "Lento" .. i, V3(2.2, 1.4, uz),
			CF(ox, y, oz) * ACI(0, -math.atan2(z2 - z1, x2 - x1) + math.pi * 0.5, 0), a.tasAcik, M_TAS)
		asin(l)
		yosunla(m, l, a)
	end
	-- dip taşları ve dış işaret taşları
	for i = 1, 10 do
		local t = rnd:NextNumber(0, math.pi * 2)
		local r = R * rnd:NextNumber(0.75, 1.15)
		local s = kutu(m, "DipTas" .. i, V3(rnd:NextNumber(1.2, 2.6), rnd:NextNumber(0.8, 1.8), rnd:NextNumber(1.2, 2.6)),
			CF(math.cos(t) * r, 0.9, math.sin(t) * r) * ACI(0, RAD(rnd:NextNumber(0, 180)), 0), a.renkTas, M_KOB)
		yosunla(m, s, a)
	end
	for i = 1, 4 do
		local t = (i - 1) * math.pi * 0.5 + math.pi * 0.25
		local s = kutu(m, "IsaretTasi" .. i, V3(1.8, rnd:NextNumber(2.4, 4), 1.8),
			CF(math.cos(t) * R * 1.6, 1.6, math.sin(t) * R * 1.6) * ACI(0, -t - math.pi * 0.5, 0), a.tasKoyu, M_TAS)
		asin(s)
		yosunla(m, s, a)
	end

	asindir(m, a)
	return bitir(m, kok, taban, "dikiliTaslar", a)
end

-- ==================================================================
-- 8) GÖZETLEME KULESİ — 3 katlı kare kule, mazgallı üst, tepede fener
-- ==================================================================
local function gozetlemeKulesi(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Gözetleme Kulesi", cf, a)
	local en, katY, kat = 12, 8, 3
	local yari = en * 0.5

	local taban = kutu(m, "TabanPlaka", V3(en + 3, 1, en + 3), CF(0, 0.5, 0), a.renkTas, M_TAS)
	kutu(m, "TabanPervaz", V3(en + 4.4, 0.5, en + 4.4), CF(0, 0.25, 0), a.renkKoyu, M_KOB)

	-- köşe kolonları (kat kat: derz görünsün)
	for i = 1, 4 do
		local ax = (i == 1 or i == 4) and 1 or -1
		local az = (i <= 2) and 1 or -1
		for k = 1, kat do
			local c = kutu(m, "Kolon" .. i .. "_" .. k, V3(2.6, katY, 2.6),
				CF(ax * (yari - 0.6), 1 + (k - 0.5) * katY, az * (yari - 0.6)), a.tasKoyu, M_TAS)
			yosunla(m, c, a)
		end
	end

	-- duvar panelleri; 1. katın ön yüzünde KAPI boşluğu
	for k = 1, kat do
		local yb = 1 + (k - 1) * katY
		for yon = 1, 4 do
			local ad = ("Duvar%d_%d"):format(k, yon)
			local dcf
			if yon == 1 then dcf = CF(0, yb + katY * 0.5, -(yari - 0.6))
			elseif yon == 2 then dcf = CF(0, yb + katY * 0.5, yari - 0.6)
			elseif yon == 3 then dcf = CF(-(yari - 0.6), yb + katY * 0.5, 0) * ACI(0, RAD(90), 0)
			else dcf = CF(yari - 0.6, yb + katY * 0.5, 0) * ACI(0, RAD(90), 0) end
			if k == 1 and yon == 1 then
				-- kapı: iki yan pano + lento
				kutu(m, ad .. "_A", V3(3.2, katY, 1.2), dcf * CF(-3.2, 0, 0), a.renkTas, M_TAS)
				kutu(m, ad .. "_B", V3(3.2, katY, 1.2), dcf * CF(3.2, 0, 0), a.renkTas, M_TAS)
				kutu(m, ad .. "_Lento", V3(9.6, 1.6, 1.4), dcf * CF(0, katY * 0.5 - 0.8, 0), a.renkKoyu, M_KOB)
			else
				local p = kutu(m, ad, V3(9.6, katY, 1.2), dcf, a.renkTas, M_TAS)
				yosunla(m, p, a)
				if yon == 1 or yon == 3 then
					-- mazgal penceresi izlenimi (koyu niş)
					-- yalnız 1 ve 3: bu iki yüzde panelin yerel -Z'si DIŞARI bakar (2 ve 4'te içeri kalırdı)
					kutu(m, ad .. "_Nis", V3(1.4, 3, 0.5), dcf * CF(0, 1, -0.6), a.tasKoyu, M_TAS)
				end
			end
		end
		if k > 1 then
			kutu(m, "KatDoseme" .. k, V3(en - 1.4, 0.8, en - 1.4), CF(0, yb + 0.4, 0), a.renkKoyu, M_KOB)
		end
	end

	-- iç merdiven izlenimi (kapıdan görünen sarmal basamaklar)
	for i = 1, 8 do
		local t = RAD(i * 42)
		kutu(m, "IcBasamak" .. i, V3(4, 0.7, 2),
			CF(math.cos(t) * 3, 1.6 + i * 0.95, math.sin(t) * 3) * ACI(0, -t, 0), a.tasKoyu, M_TAS)
	end

	-- mazgallı üst
	local ustY = 1 + kat * katY
	kutu(m, "UstDoseme", V3(en + 2.4, 1, en + 2.4), CF(0, ustY + 0.5, 0), a.renkTas, M_TAS)
	kutu(m, "UstPervaz", V3(en + 3.6, 0.6, en + 3.6), CF(0, ustY + 0.2, 0), a.renkKoyu, M_KOB)
	for yon = 1, 4 do
		for i = 1, 3 do
			local d = (i - 2) * 4.2
			local mcf
			if yon == 1 then mcf = CF(d, ustY + 2.4, -(yari + 0.7))
			elseif yon == 2 then mcf = CF(d, ustY + 2.4, yari + 0.7)
			elseif yon == 3 then mcf = CF(-(yari + 0.7), ustY + 2.4, d)
			else mcf = CF(yari + 0.7, ustY + 2.4, d) end
			local mz = kutu(m, "Mazgal" .. yon .. "_" .. i, V3(2.6, 2.8, 2.6), mcf, a.tasAcik, M_TAS)
			asin(mz)
			yosunla(m, mz, a)
		end
	end
	fenerKur(m, a, CF(0, ustY + 4.6, 0), 1.2)

	asindir(m, a)
	return bitir(m, kok, taban, "gozetlemeKulesi", a)
end

-- ==================================================================
-- 9) TAŞ KÖPRÜ — kemerli köprü; o.uzunluk (varsayılan 40) ile uzar
-- ==================================================================
local function taskopru(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Taş Köprü", cf, a)
	local L = math.clamp(say(a.uzunluk, 40), 16, 90)
	local en = 10
	local R = math.clamp(L * 0.22, 5, 8.5) -- kemer yarıçapı
	local tabanY = 1.5
	local doseY = tabanY + R + 2.4 -- döşeme üst yüzeyi

	-- yakalar (kemerin dışında kalan dolu kısımlar)
	local yakaUz = math.max(3, L * 0.5 - R)
	local taban
	for s = -1, 1, 2 do
		local ad = (s < 0) and "On" or "Arka"
		local p = kutu(m, "Yaka" .. ad, V3(en + 2, doseY - 1.2, yakaUz),
			CF(0, (doseY - 1.2) * 0.5, s * (L * 0.5 - yakaUz * 0.5)), a.renkTas, M_TAS)
		if s < 0 then taban = p end
		kutu(m, "YakaPervaz" .. ad, V3(en + 3.4, 1, yakaUz + 1.2),
			CF(0, doseY - 1.7, s * (L * 0.5 - yakaUz * 0.5)), a.renkKoyu, M_KOB)
		yosunla(m, p, a)
	end

	-- kemer kama taşları (YZ düzleminde yarım daire)
	-- yerel Y yarıçap yönüne baksın: (0,1,0) → (0, sin t, cos t) için X ekseninde (π/2 − t) dönüş
	for i = 1, 11 do
		local t = (i - 0.5) / 11 * math.pi
		local z = math.cos(t) * R
		local y = tabanY + math.sin(t) * R
		local k = kutu(m, "Kama" .. i, V3(en + 1, 3.2, 3.4),
			CF(0, y, z) * ACI(math.pi * 0.5 - t, 0, 0), a.tasKoyu, M_TAS)
		asin(k)
	end
	-- kemer ile döşeme arası dolgu
	for i = 1, 6 do
		local z = (i - 3.5) * (R * 0.5)
		kutu(m, "Dolgu" .. i, V3(en, 2.6, R * 0.5), CF(0, doseY - 2.6, z), a.renkTas, M_TAS)
	end

	-- döşeme
	local par = math.clamp(math.floor(L / 5), 4, 18)
	for i = 1, par do
		local z = -L * 0.5 + (i - 0.5) * (L / par)
		local d = kutu(m, "Doseme" .. i, V3(en, 1.2, L / par - 0.25), CF(0, doseY - 0.6, z), a.renkTas, M_TAS)
		yosunla(m, d, a)
	end
	for s = -1, 1, 2 do
		kutu(m, "Bordur" .. (s < 0 and "Sol" or "Sag"), V3(1, 1.4, L), CF(s * (en * 0.5 - 0.5), doseY - 0.5, 0), a.renkKoyu, M_KOB)
	end

	-- korkuluklar
	local direk = math.clamp(math.floor(L / 8), 4, 8)
	for s = -1, 1, 2 do
		local ad = (s < 0) and "Sol" or "Sag"
		for i = 1, direk do
			local z = -L * 0.5 + (i - 0.5) * (L / direk)
			local dk = kutu(m, "Direk" .. ad .. i, V3(1.6, 3.2, 1.6), CF(s * (en * 0.5 - 0.6), doseY + 1.6, z), a.tasAcik, M_TAS)
			asin(dk)
			yosunla(m, dk, a)
			if i < direk then
				kutu(m, "Tirabzan" .. ad .. i, V3(1.1, 1, L / direk), CF(s * (en * 0.5 - 0.6), doseY + 2.6, z + (L / direk) * 0.5), a.renkTas, M_TAS)
			end
		end
	end

	asindir(m, a)
	return bitir(m, kok, taban, "taskopru", a)
end

-- ==================================================================
-- 10) SU KANALI — taş oluk + geçirgen su; o.uzunluk (varsayılan 30)
-- ==================================================================
local function suKanali(kok, cf, o)
	local a = ayarla(o)
	local m = yeni("Su Kanalı", cf, a)
	-- alt sınır 16: daha kısa kanal 25 parçanın altına düşerdi; üst sınır 12 dilim (parça tavanı)
	local L = math.clamp(say(a.uzunluk, 30), 16, 80)
	local n = math.clamp(math.floor(L / 4), 4, 12)
	local dz = L / n
	local taban

	for i = 1, n do
		local z = -L * 0.5 + (i - 0.5) * dz
		local p = kutu(m, "Taban" .. i, V3(7.2, 1.2, dz - 0.15), CF(0, 0.6, z), a.renkTas, M_TAS)
		if i == 1 then taban = p end
		for s = -1, 1, 2 do
			local ad = (s < 0) and "Sol" or "Sag"
			local d = kutu(m, "Duvar" .. ad .. i, V3(1.6, 3, dz - 0.15), CF(s * 2.8, 2.5, z), a.renkTas, M_TAS)
			kutu(m, "Pervaz" .. ad .. i, V3(2.6, 0.6, dz - 0.15), CF(s * 2.9, 4.3, z), a.renkKoyu, M_KOB)
			if i % 2 == 1 then
				-- payanda: kanalı taşıyan dış destek (uzun düz duvar sıkıcı duruyor)
				kutu(m, "Payanda" .. ad .. i, V3(1.4, 2.2, 1.6), CF(s * 4.2, 1.1, z), a.tasKoyu, M_KOB)
			end
			yosunla(m, d, a)
		end
	end
	-- ağız taşları (iki uç): alçak eşik — kanalı tıkamasın, su içeride kalsın
	for s = -1, 1, 2 do
		kutu(m, "Agiz" .. (s < 0 and "On" or "Arka"), V3(8.4, 1.8, 1.6), CF(0, 0.9, s * (L * 0.5 + 0.8)), a.tasKoyu, M_TAS)
	end

	-- SU: Material Water yerine geçirgen SmoothPlastic (haritadaki terrain suyuyla çakışmasın)
	local su = math.clamp(math.floor(n / 2), 2, 5)
	for i = 1, su do
		local sz = L / su
		local p = kutu(m, "Su" .. i, V3(4, 1.8, sz - 0.1), CF(0, 2.1, -L * 0.5 + (i - 0.5) * sz), SU, M_DUZ)
		p.Transparency = 0.35
		p.CanCollide = false -- suya girilebilsin (katı su plakası oyunu bozar)
		p.CastShadow = false
	end

	asindir(m, a)
	return bitir(m, kok, taban, "suKanali", a)
end

-- ==================================================================
-- 11) KAYA OLUŞUMU — araziye karışan doğal kaya kümesi
-- ==================================================================
local function kayaOlusum(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Kaya Oluşumu", cf, a)
	local buyuk = math.clamp(math.floor(say(a.adet, rnd:NextInteger(8, 11))), 7, 14)

	-- zemine gömülü taban yamaları (kaya araziden çıkıyormuş gibi dursun)
	local taban = kutu(m, "TabanYama1", V3(16, 1, 14), CF(0, 0.3, 0), a.tasKoyu, M_KOB)
	kutu(m, "TabanYama2", V3(11, 0.8, 17), CF(rnd:NextNumber(-3, 3), 0.25, rnd:NextNumber(-3, 3)), a.renkTas, M_KOB)
	kutu(m, "TabanYama3", V3(8, 0.7, 8), CF(rnd:NextNumber(-5, 5), 0.35, rnd:NextNumber(-5, 5)), a.tasAcik, M_KOB)
	kutu(m, "TabanYama4", V3(6, 0.6, 12), CF(rnd:NextNumber(-6, 6), 0.3, rnd:NextNumber(-4, 4)), a.renkTas, M_KOB)

	for i = 1, buyuk do
		local bx = rnd:NextNumber(3, 6.5)
		local by = rnd:NextNumber(3, 8)
		local bz = rnd:NextNumber(3, 6.5)
		local r = rnd:NextNumber(0, 6)
		local t = rnd:NextNumber(0, math.pi * 2)
		local k = kutu(m, "Kaya" .. i, V3(bx, by, bz),
			CF(math.cos(t) * r, by * 0.35, math.sin(t) * r) -- kısmen gömülü
				* ACI(RAD(rnd:NextNumber(-16, 16)), RAD(rnd:NextNumber(0, 180)), RAD(rnd:NextNumber(-16, 16))),
			rnd:NextNumber() < 0.3 and a.tasKoyu or a.renkTas, M_TAS)
		yosunla(m, k, a)
	end
	for i = 1, rnd:NextInteger(11, 15) do
		local t = rnd:NextNumber(0, math.pi * 2)
		local r = rnd:NextNumber(4, 11)
		local s = kutu(m, "Cakil" .. i, V3(rnd:NextNumber(0.8, 2.2), rnd:NextNumber(0.6, 1.6), rnd:NextNumber(0.8, 2.2)),
			CF(math.cos(t) * r, 0.7, math.sin(t) * r) * ACI(RAD(rnd:NextNumber(-25, 25)), RAD(rnd:NextNumber(0, 180)), 0),
			a.tasAcik, M_KOB)
		yosunla(m, s, a)
	end
	-- cevher damarları (madenci teması: kayada parlayan çizgiler)
	for i = 1, 4 do
		local t = rnd:NextNumber(0, math.pi * 2)
		local d = kutu(m, "CevherDamari" .. i, V3(rnd:NextNumber(1, 2.2), 0.5, rnd:NextNumber(1.4, 3)),
			CF(math.cos(t) * rnd:NextNumber(1, 5), rnd:NextNumber(2, 5), math.sin(t) * rnd:NextNumber(1, 5))
				* ACI(RAD(rnd:NextNumber(-30, 30)), RAD(rnd:NextNumber(0, 180)), RAD(rnd:NextNumber(-30, 30))),
			CEVHER[rnd:NextInteger(1, #CEVHER)], M_DUZ)
		d.Reflectance = 0.15
	end

	return bitir(m, kok, taban, "kayaOlusum", a)
end

-- ==================================================================
-- 12) AVLU DUVARI — L ya da U şeklinde duvar, kapı boşluğu, mazgallı üst
-- ==================================================================
local function avluDuvari(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Avlu Duvarı", cf, a)
	local sekil = (a.sekil == "L" or a.sekil == "U") and a.sekil or (rnd:NextNumber() < 0.5 and "L" or "U")
	local uzun, blokEn, satir = 26, 4.2, 2
	local adetB = math.floor(uzun / blokEn)
	local yariU = uzun * 0.5
	local taban

	-- tek duvar kolunu kuran iç yardımcı (yerel çerçeve verilir; kapi=true ise ortası boş)
	local function duvarKur(ad, yerel, kapi)
		local temel = kutu(m, "Temel" .. ad, V3(uzun + 2, 1, 4), yerel * CF(0, 0.5, 0), a.renkKoyu, M_KOB)
		if not taban then taban = temel end
		for i = 1, adetB do
			local x = (i - (adetB + 1) * 0.5) * blokEn
			local ortada = kapi and (i == math.ceil(adetB / 2) or i == math.ceil(adetB / 2) + 1)
			for j = 1, satir do
				if not ortada then -- kapı boşluğu: bu iki sütunda gövde bloğu yok
					local b = kutu(m, ("Blok%s_%d_%d"):format(ad, i, j), V3(blokEn - 0.2, 3, 2.6),
						yerel * CF(x, 1 + (j - 0.5) * 3, 0), (j % 2 == 0) and a.renkTas or a.tasKoyu, M_TAS)
					yosunla(m, b, a)
				end
			end
			if i % 2 == 1 then
				local mz = kutu(m, ("Mazgal%s_%d"):format(ad, i), V3(blokEn - 0.6, 2, 2.6),
					yerel * CF(x, 8, 0), a.tasAcik, M_TAS)
				asin(mz)
				yosunla(m, mz, a)
			end
		end
		if kapi then
			-- kapı boşluğu: iki sövede + lento
			local kx = (math.ceil(adetB / 2) - (adetB + 1) * 0.5) * blokEn + blokEn * 0.5
			kutu(m, "Sove" .. ad .. "1", V3(1.2, 7, 3.2), yerel * CF(kx - blokEn - 0.6, 4.5, 0), a.tasAcik, M_TAS)
			kutu(m, "Sove" .. ad .. "2", V3(1.2, 7, 3.2), yerel * CF(kx + blokEn + 0.6, 4.5, 0), a.tasAcik, M_TAS)
			kutu(m, "KapiLento" .. ad, V3(blokEn * 2 + 3.6, 1.6, 3.2), yerel * CF(kx, 7.8, 0), a.renkKoyu, M_KOB)
		end
	end

	duvarKur("Arka", CF(0, 0, yariU), true) -- arka duvar: kapı burada
	duvarKur("Sol", CF(-yariU, 0, 0) * ACI(0, RAD(90), 0), false)
	if sekil == "U" then
		duvarKur("Sag", CF(yariU, 0, 0) * ACI(0, RAD(90), 0), false)
	end

	-- köşe kuleleri (duvarların birleştiği yerler)
	local koseler = { CF(-yariU, 0, yariU) }
	if sekil == "U" then table.insert(koseler, CF(yariU, 0, yariU)) end
	for i, kc in ipairs(koseler) do
		kutu(m, "KuleTaban" .. i, V3(6, 1, 6), kc * CF(0, 0.5, 0), a.renkKoyu, M_KOB)
		local g = kutu(m, "KuleGovde" .. i, V3(5, 10, 5), kc * CF(0, 5.5, 0), a.renkTas, M_TAS)
		kutu(m, "KuleTac" .. i, V3(6.4, 1.2, 6.4), kc * CF(0, 11, 0), a.tasAcik, M_TAS)
		yosunla(m, g, a)
	end

	asindir(m, a)
	return bitir(m, kok, taban, "avluDuvari", a)
end

-- ==================================================================
-- 13) MEYDAN ZEMİNİ — döşeli plakalar + koyu derz + kırık/yosunlu plakalar
-- ==================================================================
local function meydanZemini(kok, cf, o)
	local a = ayarla(o)
	local rnd = a.rnd
	local m = yeni("Meydan Zemini", cf, a)
	-- 4..7 aralığı: 4×4 tam 25 parça (alt sınır), 7×7 kırık plakalar + yosunla 120'nin altında kalır
	local en = math.clamp(math.floor(say(a.en, 6)), 4, 7)
	local boy = math.clamp(math.floor(say(a.boy, 6)), 4, 7)
	local p0, bosluk = 6, 0.5 -- plaka adımı ve derz payı
	local W, D = en * p0, boy * p0

	-- alttaki koyu tabla derz görevi görür: her plaka arasına ayrı çubuk koymaya gerek kalmaz
	local taban = kutu(m, "DerzTablasi", V3(W + 2, 0.7, D + 2), CF(0, 0.35, 0), a.renkKoyu, M_KOB)

	for i = 1, en do
		for j = 1, boy do
			local x = (i - (en + 1) * 0.5) * p0
			local z = (j - (boy + 1) * 0.5) * p0
			local kirik = rnd:NextNumber() < a.yikik * 0.25
			if kirik then
				-- kırık plaka: 3 parçaya ayrılmış, hafif kaymış
				for k = 1, 3 do
					local f = kutu(m, ("Kirik%d_%d_%d"):format(i, j, k),
						V3((p0 - bosluk) / 3 - 0.2, 0.9, p0 - bosluk - rnd:NextNumber(0, 1)),
						CF(x + (k - 2) * (p0 - bosluk) / 3, 1.05, z + rnd:NextNumber(-0.3, 0.3))
							* ACI(0, RAD(rnd:NextNumber(-6, 6)), 0), a.tasKoyu, M_TAS)
					yosunla(m, f, a)
				end
			else
				local pl = kutu(m, ("Plaka%d_%d"):format(i, j), V3(p0 - bosluk, 1, p0 - bosluk),
					CF(x, 1.05, z), (i + j) % 2 == 0 and a.renkTas or a.tasAcik, M_TAS)
				yosunla(m, pl, a)
			end
		end
	end

	-- bordür ve köşe taşları
	for s = -1, 1, 2 do
		kutu(m, "BordurX" .. (s < 0 and "1" or "2"), V3(W + 3, 1.4, 1.4), CF(0, 0.9, s * (D * 0.5 + 0.8)), a.tasKoyu, M_KOB)
		kutu(m, "BordurZ" .. (s < 0 and "1" or "2"), V3(1.4, 1.4, D + 3), CF(s * (W * 0.5 + 0.8), 0.9, 0), a.tasKoyu, M_KOB)
	end
	for i = 1, 4 do
		local ax = (i == 1 or i == 4) and 1 or -1
		local az = (i <= 2) and 1 or -1
		local c = kutu(m, "KoseTasi" .. i, V3(2.4, 2, 2.4),
			CF(ax * (W * 0.5 + 0.8), 1.2, az * (D * 0.5 + 0.8)), a.renkKoyu, M_KOB)
		yosunla(m, c, a)
	end

	return bitir(m, kok, taban, "meydanZemini", a)
end

-- ---------- kayıt defteri (arayüz bu listeden buton üretir) ----------
M.YAPILAR = {
	{ ad = "kademeliKaide", etiket = "Kademeli Kaide", ikon = "🏛", kategori = "Mimari", fn = kademeliKaide },
	{ ad = "heykelKaidesi", etiket = "Madenci Heykeli", ikon = "⛏", kategori = "Mimari", fn = heykelKaidesi },
	{ ad = "taskemer", etiket = "Taş Kemer", ikon = "🚪", kategori = "Mimari", fn = taskemer },
	{ ad = "sutunlar", etiket = "Kırık Sütunlar", ikon = "🏺", kategori = "Kalıntı", fn = sutunlar },
	{ ad = "kalintiDuvar", etiket = "Kalıntı Duvar", ikon = "🧱", kategori = "Kalıntı", fn = kalintiDuvar },
	{ ad = "merdivenSeti", etiket = "Taş Merdiven", ikon = "📶", kategori = "Mimari", fn = merdivenSeti },
	{ ad = "dikiliTaslar", etiket = "Dikili Taşlar", ikon = "🗿", kategori = "Kalıntı", fn = dikiliTaslar },
	{ ad = "gozetlemeKulesi", etiket = "Gözetleme Kulesi", ikon = "🗼", kategori = "Mimari", fn = gozetlemeKulesi },
	{ ad = "taskopru", etiket = "Taş Köprü", ikon = "🌉", kategori = "Mimari", fn = taskopru },
	{ ad = "suKanali", etiket = "Su Kanalı", ikon = "💧", kategori = "Su", fn = suKanali },
	{ ad = "kayaOlusum", etiket = "Kaya Oluşumu", ikon = "⛰", kategori = "Doğa", fn = kayaOlusum },
	{ ad = "avluDuvari", etiket = "Avlu Duvarı", ikon = "🏰", kategori = "Mimari", fn = avluDuvari },
	{ ad = "meydanZemini", etiket = "Meydan Zemini", ikon = "⬛", kategori = "Zemin", fn = meydanZemini },
}

return M
