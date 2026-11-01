-- SWEAX TERRAIN — Uretici: the procedural terrain core (independent of the plugin UI, testable).
-- Prosedürel arazi çekirdeği (eklenti arayüzünden bağımsız, test edilebilir).
-- Roblox'un kendi editöründen farkları: ağırlıklı biyom karışımı + domain warp + ridged dağlar,
-- ayrı GÖL/NEHİR/OKYANUS denetimleri (derinlik, kıyı kumu, kıvrım...), teraslama, kaya çıkıntısı
-- (3B yoğunluk), mağara solucanları, eğim/yükseklik/benek bazlı malzeme katmanları, buz kapaklı
-- arktik göller, volkan kraterleri. Her şey tohumlu (çekirdek) — aynı tohum aynı dünya.
local Uretici = {}

local E = Enum.Material
local COZ = 4 -- voksel çözünürlüğü (Roblox sabiti)

-- ---------- gürültü ----------
local function fbm(x, z, ok, f, kaz)
	-- ok oktav, f taban frekans, kaz kazanç; çıktı ~[-1,1]
	local top, gen, tf, nrm = 0, 1, f, 0
	for _ = 1, ok do
		top += math.noise(x * tf, kaz * 7.31, z * tf) * gen
		nrm += gen
		gen *= 0.5
		tf *= 2.03
	end
	return top / nrm
end

local function ridged(x, z, ok, f, kaz)
	-- sırtlı gürültü (dağ zirveleri): 1-|n| keskinleştirilir
	local top, gen, tf, nrm = 0, 1, f, 0
	for _ = 1, ok do
		local n = 1 - math.abs(math.noise(x * tf, kaz * 3.77, z * tf))
		top += n * n * gen
		nrm += gen
		gen *= 0.52
		tf *= 2.11
	end
	return top / nrm -- ~[0,1]
end

-- tohumdan tekrar üretilebilir 0..1 sayı. Random.new yerine bunu kullanıyoruz ki web sitesindeki
-- JavaScript kopyası (docs/js/generator.js) aynı tohumla aynı dünyayı birebir üretebilsin.
local function tohumSayi(K, i, kanal)
	local n = math.noise(i * 0.7317 + 0.1234, kanal * 1.618 + 0.377, K * 0.913 + 0.5)
	return (n * 43758.5453) % 1
end

-- ---------- ayar varsayılanları ----------
local VARSAYILAN = {
	cekirdek = 618033988,
	merkez = Vector3.new(0, 40, 0), -- Y = taban (su seviyesi referansı)
	boyutX = 512,
	boyutZ = 512,
	yukOlcek = 1.0, -- genel yükseklik çarpanı
	puruz = 0.5, -- 0..1 ek yüzey detayı
	warp = 0.5, -- 0..1 domain warp (akışkan, organik şekiller)
	teras = 0, -- 0..1 teraslama şiddeti
	biyomBoyut = 320, -- biyom bölgelerinin ölçeği (stud)
	biyomlar = { ova = 1, tepe = 0.7, dag = 0.6 }, -- ad → ağırlık 0..1
	su = {
		seviye = 0, -- taban Y'ye göre ofset
		gol = { etkin = true, yogunluk = 0.5, derinlik = 10, kum = 6 },
		nehir = { etkin = false, adet = 1, genislik = 10, kivrim = 0.5, derinlik = 5 },
		okyanus = { etkin = false, yon = "bati", plaj = 40 },
	},
	magara = { etkin = false, yogunluk = 0.5, boyut = 0.5 },
	detay = { cikinti = 0.35, benek = 0.6, karCizgisi = 0.72 },
}

local function derinKopya(t)
	local y = {}
	for k, v in pairs(t) do
		y[k] = typeof(v) == "table" and derinKopya(v) or v
	end
	return y
end

local function birlestir(taban, ust)
	local y = derinKopya(taban)
	for k, v in pairs(ust or {}) do
		-- biyomlar REPLACE edilir (merge, seçilmeyen varsayılan biyomları sızdırıyordu:
		-- arktik+volkan istenirken ova/tepe/dağ da karışmıştı — harita dökümüyle ölçüldü)
		if k == "biyomlar" then
			y[k] = derinKopya(v)
		elseif typeof(v) == "table" and typeof(y[k]) == "table" then
			y[k] = birlestir(y[k], v)
		else
			y[k] = v
		end
	end
	return y
end

-- ---------- biyom yükseklik fonksiyonları ----------
-- her biri (u, v, K) → taban üstü yükseklik (stud); u,v warp'lı koordinat, K kanal ofseti
local BIYOM = {}

function BIYOM.ova(u, v, K)
	return 4 + fbm(u, v, 3, 1 / 90, K + 1) * 5
end

function BIYOM.tepe(u, v, K)
	local n = fbm(u, v, 4, 1 / 150, K + 2)
	return 12 + n * 16 + math.abs(fbm(u, v, 3, 1 / 55, K + 2.5)) * 6
end

function BIYOM.dag(u, v, K)
	local sirt = ridged(u, v, 4, 1 / 260, K + 3)
	local govde = sirt * sirt * 130
	return 14 + govde + fbm(u, v, 3, 1 / 60, K + 3.5) * 10
end

function BIYOM.plato(u, v, K)
	local n = (fbm(u, v, 3, 1 / 200, K + 4) + 1) / 2
	local kat = math.floor(n * 4.6)
	local kesir = n * 4.6 - kat
	local kenar = math.clamp((kesir - 0.82) / 0.18, 0, 1) -- katlar arası kısa rampa
	return 6 + (kat + kenar) * 14
end

function BIYOM.kanyon(u, v, K)
	local taban = 30 + fbm(u, v, 3, 1 / 160, K + 5) * 8
	local m = math.abs(fbm(u, v, 2, 1 / 240, K + 5.5)) -- menderes şeridi
	if m < 0.24 then
		local d = 1 - m / 0.24 -- 0..1 şerit merkezine yaklaşım
		local derin = math.min(d * 1.6, 1)
		-- teraslı yamaç
		derin = math.floor(derin * 4) / 4 + (derin * 4 % 1) * 0.12
		taban -= derin * 42
	end
	return math.max(taban, 1.5) -- KURU taban: su seviyesi altına inmesin (çöl kanyonu göle dönüyordu)
end

-- volkan: hücre başına en fazla bir koni (Worley tarzı en yakın nokta). Eski bölge maskesi
-- (fbm > eşik) koniyi nadiren kratere kadar yükseltiyordu; harita dökümünde krater çıkmadı, lav
-- yalnız rastgele benekti. Şimdi her koni tepesinde düz tabanlı bir krater ve lav gölü var.
-- İkinci dönüş değeri: o noktanın krater tabanı (lav) payı 0..1.
local VOLKAN_HUCRE = 230
function BIYOM.volkan(u, v, K)
	local hx0, hz0 = math.floor(u / VOLKAN_HUCRE), math.floor(v / VOLKAN_HUCRE)
	local koni = 0
	for dx = -1, 1 do
		for dz = -1, 1 do
			local hx, hz = hx0 + dx, hz0 + dz
			-- hücrenin tohumlu rastgele değerleri (math.noise tam sayıda 0 verir → kesirli kaydır)
			local var = math.noise(hx * 0.71 + 0.13, hz * 0.59 + 0.41, K + 6.1)
			if var > -0.2 then
				local px = (hx + 0.5 + math.clamp(math.noise(hx * 0.37 + 0.29, hz * 0.83 + 0.17, K + 6.2), -0.5, 0.5) * 0.6) * VOLKAN_HUCRE
				local pz = (hz + 0.5 + math.clamp(math.noise(hx * 0.91 + 0.53, hz * 0.27 + 0.61, K + 6.3), -0.5, 0.5) * 0.6) * VOLKAN_HUCRE
				local yaricap = 92 + (var + 0.2) * 40
				local d = math.sqrt((u - px) ^ 2 + (v - pz) ^ 2)
				koni = math.max(koni, 1 - d / yaricap)
			end
		end
	end
	koni = math.clamp(koni, 0, 1)
	local h = 8 + (koni ^ 1.7) * 120
	local lav = 0
	if koni > 0.72 then -- krater: kenardan içeri inen, tabanı düz çanak
		local kr = (koni - 0.72) / 0.28
		h = 8 + (0.72 ^ 1.7) * 120 - math.min(kr * 2.4, 1) * 24
		lav = math.clamp((kr - 0.3) / 0.15, 0, 1)
	end
	return h + ridged(u, v, 3, 1 / 70, K + 6.5) * 9 * (1 - lav), lav
end

function BIYOM.col(u, v, K)
	local yon = fbm(u, v, 2, 1 / 500, K + 7) * 0.7
	local dalga = math.sin(u * 0.045 + yon * 8 + fbm(u, v, 2, 1 / 120, K + 7.3) * 3)
	return 7 + (dalga * 0.5 + 0.5) * 12 + fbm(u, v, 3, 1 / 200, K + 7.6) * 4
end

function BIYOM.arktik(u, v, K)
	local n = fbm(u, v, 4, 1 / 190, K + 8)
	local vadi = math.abs(fbm(u, v, 2, 1 / 300, K + 8.4))
	return 10 + n * 14 + vadi * vadi * 42 -- U vadili buzul tepeleri
end

function BIYOM.bataklik(u, v, K)
	-- taban su seviyesinin hafif ALTINDA gezinir → doğal su birikintileri
	return -0.5 + fbm(u, v, 4, 1 / 70, K + 9) * 2.6
end

-- biyom başına ana malzeme takımı: {yuzey, yamac, alt, benek}
local TAKIM = {
	ova = { E.Grass, E.Ground, E.Ground, E.LeafyGrass },
	tepe = { E.Grass, E.Rock, E.Ground, E.LeafyGrass },
	dag = { E.Rock, E.Slate, E.Rock, E.Ground },
	plato = { E.Ground, E.Sandstone, E.Sandstone, E.Grass },
	kanyon = { E.Sandstone, E.Sandstone, E.Rock, E.Ground },
	volkan = { E.Basalt, E.Basalt, E.Rock, E.Rock }, -- lav yalnız krater tabanında (rastgele benek değil)
	col = { E.Sand, E.Sandstone, E.Sandstone, E.Sand },
	arktik = { E.Snow, E.Glacier, E.Rock, E.Snow }, -- buz yalnız donmuş göl kapağında
	bataklik = { E.LeafyGrass, E.Mud, E.Ground, E.Mud },
}

-- ---------- üretim ----------
-- ilerleme: fonksiyon(0..1, aşama) — aşama "yukseklik" | "voksel" | "bitti"; iptal: tablo {iptal=false}
function Uretici.uret(terrain, ayarUst, ilerleme, iptalKutu)
	local A = birlestir(VARSAYILAN, ayarUst)
	ilerleme = ilerleme or function() end
	iptalKutu = iptalKutu or {}
	-- gürültü kanal ofseti. Tohum 7919 ile karıştırılır: yalnız (tohum % 100000) / 977 iken komşu
	-- tohumlar (571, 572, 573...) neredeyse aynı dünyayı veriyordu — JS kopyasıyla taranarak bulundu.
	local K = ((A.cekirdek % 100000) * 7919 % 100000) / 977.0

	-- etkin biyomlar
	local adlar, agirliklar = {}, {}
	for ad, w in pairs(A.biyomlar) do
		if BIYOM[ad] and w > 0.02 then
			adlar[#adlar + 1] = ad
			agirliklar[ad] = w
		end
	end
	table.sort(adlar)
	if #adlar == 0 then
		adlar = { "ova" }
		agirliklar.ova = 1
	end

	local tabanY = A.merkez.Y
	local suSeviye = tabanY + A.su.seviye
	local Nx = math.max(8, math.floor(A.boyutX / COZ + 0.5))
	local Nz = math.max(8, math.floor(A.boyutZ / COZ + 0.5))
	-- TUZAK (bildirilen hata: "Bad argument materials[1][1] to 'WriteVoxels' (25-element array
	-- expected)"): terrain voksel ızgarası dünyada 4'ün katlarına oturur. x0/z0 4'ün katı değilse
	-- Region3:ExpandToGrid bölgeyi BİR HÜCRE BÜYÜTÜR, ama mat/occ dizileri sx×Ny×sz kalır →
	-- boyutlar tutmaz ve üretim hata verir. "Merkezi kameranın önüne al" merkezi rastgele bir
	-- tam sayı yaptığı için bu neredeyse her seferinde tetikleniyordu. Köşeyi ızgaraya OTURT.
	local x0 = math.floor((A.merkez.X - Nx * COZ / 2) / COZ) * COZ
	local z0 = math.floor((A.merkez.Z - Nz * COZ / 2) / COZ) * COZ

	-- ------ 1. geçiş: yükseklik + biyom + su alanları ------
	local H = table.create(Nx + 2) -- yükseklik haritası (kenar payıyla; eğim için)
	local ANA = table.create(Nx + 2) -- baskın biyom adı
	local SUALT = table.create(Nx + 2) -- su kazısı yapılan sütun (göl/nehir/okyanus) → kum kıyı
	local LAV = table.create(Nx + 2) -- volkan krater tabanı payı (lav gölü)
	local OKY = table.create(Nx + 2) -- okyanus kıyı bandındaki sütun
	local warpS = A.warp * 60

	local golA = A.su.gol
	local nehirA = A.su.nehir
	local okyA = A.su.okyanus
	-- nehir yolları (X boyunca akar; z konumu kıvrımla oynar)
	local nehirler = {}
	if nehirA.etkin then
		for i = 1, math.max(1, math.floor(nehirA.adet)) do
			nehirler[i] = { zTaban = 0.15 + 0.7 * tohumSayi(K, i, 1), faz = 1000 * tohumSayi(K, i, 2) }
		end
	end

	for ix = 0, Nx + 1 do
		local kolH, kolAna, kolSu = table.create(Nz + 2), table.create(Nz + 2), table.create(Nz + 2)
		local kolLav, kolOky = table.create(Nz + 2), table.create(Nz + 2)
		H[ix], ANA[ix], SUALT[ix], LAV[ix], OKY[ix] = kolH, kolAna, kolSu, kolLav, kolOky
		local x = x0 + ix * COZ
		for iz = 0, Nz + 1 do
			local z = z0 + iz * COZ
			-- domain warp: koordinatı gürültüyle bük (organik kıyılar/sırtlar)
			local u = x + fbm(x, z, 2, 1 / 180, K + 11) * warpS
			local v = z + fbm(x, z, 2, 1 / 180, K + 12) * warpS

			-- biyom ağırlıkları (bölgesel maskeler) — ^3 keskinleştirme: bölgeler ayrışır,
			-- kenarlarda yumuşak geçiş kalır (ilk kalibrasyonda karışım dağları eziyordu:
			-- zirveler kar çizgisine ulaşamıyordu — harita dökümüyle ölçüldü)
			local topW, enAd, enW = 0, adlar[1], -1
			local hTop, lavTop = 0, 0
			local bf = 1 / math.max(60, A.biyomBoyut)
			for i, ad in ipairs(adlar) do
				local m = (fbm(u, v, 2, bf, K + 20 + i * 4) + 1) / 2
				m = (m * m * m) * agirliklar[ad]
				if #adlar == 1 then m = 1 end
				if m > 0.001 then
					local hb, ek = BIYOM[ad](u, v, K)
					hTop += hb * m
					lavTop += (ek or 0) * m
					topW += m
					if m > enW then
						enW = m
						enAd = ad
					end
				end
			end
			local h = (topW > 0.001) and (hTop / topW) or 4
			h *= A.yukOlcek
			-- pürüz: ince detay
			h += fbm(u, v, 3, 1 / 26, K + 13) * (A.puruz * 4.5)
			-- teraslama
			if A.teras > 0.03 then
				local basamak = 10
				local q = math.floor(h / basamak) * basamak
				h = h + (q - h) * math.min(A.teras, 1) * 0.85
			end

			local suKazisi = false
			-- GÖL: alçaltıcı çukur maskesi (yalnız ova/tepe/bataklık/arktik tarzı alanlarda doğal durur)
			if golA.etkin then
				local g = (fbm(u, v, 2, 1 / 150, K + 14) + 1) / 2
				-- kalibrasyon: 2 oktav fbm std ~0.25 → eşik 0.66-yoğunluk*0.14 ≈ %8-22 alan
				local esik = 0.66 - golA.yogunluk * 0.14
				if g > esik then
					-- yalnız ALÇAK arazide açılır (ilk kalibrasyonda dağ ortasına krater açıyordu)
					local alcak = math.clamp(1 - (h - 14) / 26, 0, 1)
					local d = math.min((g - esik) / (1 - esik) * 1.5, 1) * alcak
					local hedef = (suSeviye - tabanY) - golA.derinlik * d
					local yeni = math.min(h, 3 + hedef) -- yumuşak: en fazla çukur hedefine
					h = h + (yeni - h) * math.min(d * 1.8, 1)
					if h + tabanY < suSeviye + 0.5 then suKazisi = true end
				end
			end
			-- NEHİR
			if nehirA.etkin then
				for _, n in ipairs(nehirler) do
					local yolZ = z0 + n.zTaban * Nz * COZ
						+ fbm(x, n.faz, 2, 1 / 150, K + 15) * (nehirA.kivrim * 140)
					local dz = math.abs(z - yolZ)
					local yariGen = nehirA.genislik / 2
					if dz < yariGen + 10 then
						local d = math.clamp(1 - (dz - yariGen) / 10, 0, 1) -- kıyı geçişi
						if dz < yariGen then d = 1 end
						local hedef = (suSeviye - tabanY) - nehirA.derinlik
						local yeni = math.min(h, hedef + (1 - d) * 6)
						h = h + (yeni - h) * d
						if dz < yariGen + 4 then suKazisi = true end
					end
				end
			end
			-- OKYANUS: seçilen kenardan derinleşen deniz + plaj. Bant genişliği haritanın o yöndeki
			-- boyunun %38'i (sabit 64 stud iken 512'lik haritada ince bir şerit kalıyordu — ölçüldü)
			local okyanusta = false
			if okyA.etkin then
				local dKenar, boy
				if okyA.yon == "bati" then dKenar, boy = x - x0, Nx * COZ
				elseif okyA.yon == "dogu" then dKenar, boy = (x0 + Nx * COZ) - x, Nx * COZ
				elseif okyA.yon == "kuzey" then dKenar, boy = z - z0, Nz * COZ
				else dKenar, boy = (z0 + Nz * COZ) - z, Nz * COZ end
				local plaj = math.max(okyA.plaj, 8)
				local deniz = math.max(plaj * 1.6, boy * 0.38)
				if dKenar < deniz then
					okyanusta = true
					local t = math.clamp(dKenar / deniz, 0, 1)
					local kiyiN = fbm(0, (okyA.yon == "kuzey" or okyA.yon == "guney") and x or z, 2, 1 / 150, K + 16) * 0.25
					t = math.clamp(t + kiyiN, 0, 1)
					local hedef = (suSeviye - tabanY) - 18 * (1 - t)
					h = math.min(h, hedef + t * t * (h - hedef))
					if h + tabanY < suSeviye + 0.5 then suKazisi = true end
				end
			end

			kolH[iz] = tabanY + h
			kolAna[iz] = enAd
			kolSu[iz] = suKazisi
			kolLav[iz] = (topW > 0.001) and (lavTop / topW) or 0
			kolOky[iz] = okyanusta
		end
		if ix % 24 == 0 then
			ilerleme(0.05 + 0.30 * ix / (Nx + 1), "yukseklik")
			task.wait()
			if iptalKutu.iptal then return false, "iptal" end
		end
	end

	-- ------ kıyı: suya YATAYDA yakın ve su seviyesinin az üstündeki kara sütunları ------
	-- Eski kural göl maskesinin her yerine kum koyuyordu; su açılmamış çukurlarda bile kumsal
	-- lekeleri kalıyordu (harita dökümünde nehirli ovada görüldü). Şimdi kumsal yalnız gerçek
	-- suyun (göl, nehir, okyanus) çevresinde, kumsal genişliği kadar.
	local KIYI = table.create(Nx + 2)
	do
		local kum = golA.kum or 0
		local adim = math.clamp(math.ceil(kum / COZ), 0, 4)
		local islak = table.create(Nx + 2)
		for ix = 0, Nx + 1 do
			local k = table.create(Nz + 2, false)
			for iz = 0, Nz + 1 do
				k[iz] = H[ix][iz] < suSeviye - 0.3 and ANA[ix][iz] ~= "volkan"
			end
			islak[ix] = k
		end
		local yayil = islak
		for _ = 1, adim do
			local yeni = table.create(Nx + 2)
			for ix = 0, Nx + 1 do
				local k = table.create(Nz + 2, false)
				local onceki, sonraki, bu = yayil[ix - 1], yayil[ix + 1], yayil[ix]
				for iz = 0, Nz + 1 do
					k[iz] = bu[iz] or bu[iz - 1] == true or bu[iz + 1] == true
						or (onceki ~= nil and onceki[iz]) or (sonraki ~= nil and sonraki[iz])
				end
				yeni[ix] = k
			end
			yayil = yeni
		end
		for ix = 0, Nx + 1 do
			local k = table.create(Nz + 2, false)
			for iz = 0, Nz + 1 do
				local h = H[ix][iz]
				local plajBoy = OKY[ix][iz] and math.max(kum, 5) or kum
				k[iz] = (not islak[ix][iz]) and h >= suSeviye - 0.5 and h < suSeviye + plajBoy
					and (yayil[ix][iz] or (OKY[ix][iz] and h < suSeviye + 3))
			end
			KIYI[ix] = k
		end
	end

	-- ------ 2. geçiş: voksel yazımı (parça parça) ------
	-- dikey aralık
	local minH, maxH = math.huge, -math.huge
	for ix = 0, Nx + 1 do
		for iz = 0, Nz + 1 do
			local h = H[ix][iz]
			if h < minH then minH = h end
			if h > maxH then maxH = h end
		end
	end
	minH = math.min(minH, suSeviye) - 14 -- taban dolgu payı (mağara bandı)
	maxH = math.max(maxH, suSeviye) + 6
	local y0 = math.floor(minH / COZ) * COZ
	local Ny = math.ceil((maxH - y0) / COZ) + 1

	-- üretim öncesi bölge temizliği: üst üste üretimde ESKİ arazinin yüksek kalıntıları
	-- kalmasın (yeni Y bandı eskiden darsa tepeler sahnede asılı kalıyordu — ölçüldü)
	pcall(function()
		terrain:FillRegion(Region3.new(
			Vector3.new(x0, y0 - 60, z0),
			Vector3.new(x0 + Nx * COZ, y0 + Ny * COZ + 220, z0 + Nz * COZ)
		):ExpandToGrid(COZ), COZ, E.Air)
	end)

	local PARCA = 24 -- sütun/parça kenarı
	local toplamParca = math.ceil(Nx / PARCA) * math.ceil(Nz / PARCA)
	local parcaNo = 0
	local magA = A.magara
	local cik = A.detay.cikinti
	local karC = A.detay.karCizgisi
	local benekS = A.detay.benek

	for px = 0, Nx - 1, PARCA do
		local sx = math.min(PARCA, Nx - px)
		for pz = 0, Nz - 1, PARCA do
			local sz = math.min(PARCA, Nz - pz)
			parcaNo += 1
			local mat = table.create(sx)
			local occ = table.create(sx)
			for i = 1, sx do
				local mx = table.create(Ny)
				local ox = table.create(Ny)
				mat[i] = mx
				occ[i] = ox
				local ix = px + i - 1
				local x = x0 + (ix + 0.5) * COZ
				for j = 1, Ny do
					mx[j] = table.create(sz, E.Air)
					ox[j] = table.create(sz, 0)
				end
				local kolH = H[ix]
				local kolH1 = H[ix + 1]
				for kz = 1, sz do
					local iz = pz + kz - 1
					local z = z0 + (iz + 0.5) * COZ
					local h = kolH[iz]
					-- eğim (komşu farkları)
					local egim = math.max(
						math.abs(kolH1[iz] - h),
						math.abs(kolH[iz + 1] - h)
					) / COZ
					local ana = ANA[ix][iz]
					local takim = TAKIM[ana] or TAKIM.ova
					local suKazisi = SUALT[ix][iz]
					local kiyi = KIYI[ix][iz]
					local lav = LAV[ix][iz]
					local benek = benekS > 0.05 and (fbm(x, z, 2, 1 / 34, K + 17) > (0.62 - benekS * 0.3)) or false

					for j = 1, Ny do
						local yAlt = y0 + (j - 1) * COZ
						local yUst = yAlt + COZ
						local doluluk = math.clamp((h - yAlt) / COZ, 0, 1)

						-- kaya çıkıntısı: dağ/kanyon yamaçlarında yüzey bandını 3B gürültüyle oy/şişir
						if cik > 0.03 and doluluk > 0 and doluluk < 1 or (cik > 0.03 and math.abs(yAlt - h) < 10) then
							if (ana == "dag" or ana == "kanyon" or ana == "volkan") and egim > 0.55 then
								local n3 = math.noise(x / 23, yAlt / 23, z / 23)
								doluluk = math.clamp(doluluk + n3 * cik * 1.3, 0, 1)
							end
						end
						-- mağara solucanları (yüzeyin ≥6 stud altı)
						if magA.etkin and doluluk > 0 and (h - yUst) > 6 and yAlt > y0 + 4 then
							local f = 1 / (30 + magA.boyut * 40)
							local c1 = math.noise(x * f, yAlt * f * 1.6, z * f)
							local c2 = math.noise(x * f + 91.7, yAlt * f * 1.6 + 12.9, z * f + 47.3)
							local esik = 0.055 + magA.yogunluk * 0.075
							if math.abs(c1) < esik and math.abs(c2) < esik then
								doluluk = 0
							end
						end

						if doluluk > 0.01 then
							-- malzeme katmanı
							local derinlik = h - yUst
							local m
							if derinlik > 7 then
								m = takim[3]
							elseif egim > 1.1 then
								m = takim[2]
							else
								m = benek and takim[4] or takim[1]
							end
							-- yükseklik kuralları
							if (ana == "dag" or ana == "tepe" or ana == "arktik")
								and h > tabanY + (30 + karC * 35) * A.yukOlcek and derinlik < 6 then
								m = (ana == "arktik") and E.Glacier or E.Snow
							end
							-- dağ etekleri: leke kenarında çim-toprak bandı (doğal geçiş)
							if ana == "dag" and derinlik < 4 and h < tabanY + 26 and egim < 0.9 then
								m = benek and E.Grass or E.Ground
							end
							if ana == "volkan" and lav > 0.5 and derinlik < 6 then
								m = E.CrackedLava -- krater tabanındaki lav gölü
							end
							-- kumsal: yalnız gerçek suyun çevresinde (KIYI); volkanda asla
							if kiyi and ana ~= "volkan" and derinlik < 4 then
								m = (ana == "arktik") and E.Snow or (ana == "bataklik" and E.Mud or E.Sand)
							end
							if suKazisi and derinlik < 5 then
								m = (ana == "bataklik") and E.Mud or E.Sand -- su tabanı
							end
							mx[j][kz] = m
							ox[j][kz] = doluluk
						end
						-- SU: yüzeyin üstü, su seviyesinin altı
						if yAlt >= h - COZ and yUst <= suSeviye + COZ then
							local suDoluluk = math.clamp((suSeviye - yAlt) / COZ, 0, 1)
							if suDoluluk > 0.05 and doluluk < 0.5 then
								if ana == "volkan" then
									mx[j][kz] = E.CrackedLava -- volkanda su yerine LAV gölü/krateri
									ox[j][kz] = 1
								elseif ana == "arktik" and suDoluluk < 1 then
									mx[j][kz] = E.Ice -- donmuş göl kapağı
									ox[j][kz] = 1
								else
									mx[j][kz] = E.Water
									ox[j][kz] = suDoluluk
								end
							end
						end
					end
				end
			end
			local bolge = Region3.new(
				Vector3.new(x0 + px * COZ, y0, z0 + pz * COZ),
				Vector3.new(x0 + (px + sx) * COZ, y0 + Ny * COZ, z0 + (pz + sz) * COZ)
			):ExpandToGrid(COZ)
			terrain:WriteVoxels(bolge, COZ, mat, occ)
			if parcaNo % 3 == 0 then
				ilerleme(0.35 + 0.65 * parcaNo / toplamParca, "voksel")
				task.wait()
				if iptalKutu.iptal then return false, "iptal" end
			end
		end
	end
	ilerleme(1, "bitti")
	return true, string.format("%d×%d stud · %d sütun", Nx * COZ, Nz * COZ, Nx * Nz)
end

Uretici.VARSAYILAN = VARSAYILAN
return Uretici
