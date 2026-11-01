-- SWEAX TERRAIN — Yapilar: index of the structure library and the code that places structures.
-- Hazır yapı kütüphanesinin İNDEKSİ + sahneye YERLEŞTİRİCİSİ.
-- Kütüphane kardeş modüllerde yaşar: YapiTemel (Mimari/Kalıntı...), YapiMaden (Maden) ve
-- YapiSus (Süs) ve YapiAlan (Alan = terrain şekillendirme); her biri M.YAPILAR = { {ad, etiket, ikon, kategori, fn}, ... }
-- döndürür ve fn(kok, cf, o) -> Model imzasına uyar.
-- Bu dosya onları birleştirir (modül yoksa uyarı basıp o kategoriyi atlar — eklenti yine açılır),
-- seçenek varsayılanlarını doldurur (olcek/tohum/rnd/yosun/yikik/isik/renkler), yapıyı
-- workspace.SweaxYapilar klasörüne kurar, SweaxStructure/SweaxSeed niteliklerini garantiler,
-- ChangeHistory işareti koyar (Ctrl+Z) ve yerleştirme yığınını tutar (sonuncuyu geri al).
-- Zemin raycast'i kendi yapılarımızı hariç tutar ki üst üste yığılma olmasın.
-- Bağımlılık yok: Arayuz ve Ana.server bu modülü require eder, bu modül onları etmez.
local M = {}

local ChangeHistory = game:GetService("ChangeHistoryService")

-- taş yapıların ortak paleti: taş gövde, koyu derz, yosun
M.PALET = {
	tas = Color3.fromRGB(99, 95, 98),
	koyu = Color3.fromRGB(68, 68, 68),
	yosun = Color3.fromRGB(44, 101, 29),
}

M.KOK_AD = "SweaxYapilar"
M.ONIZLEME_AD = "SweaxOnizleme"

-- kategori sırası UI'daki filtre sırasıdır
M.KATEGORILER = { "Mimari", "Maden", "Süs", "Alan" }
-- terrain = true olan modüller PART değil TERRAIN yazar → canlı önizleme yapılmaz
-- (önizleme kurmak gerçek araziyi oyardı) ve Model yerine "işaretçi" dönebilirler.
local MODULLER = {
	{ dosya = "YapiTemel", kategori = "Mimari" },
	{ dosya = "YapiMaden", kategori = "Maden" },
	{ dosya = "YapiSus", kategori = "Süs" },
	{ dosya = "YapiAlan", kategori = "Alan", terrain = true },
}

local yigin = {} -- yerleştirme geçmişi (son eleman = en son kurulan)
local onbellek = nil
local uyarildi = {} -- aynı modül için tekrar tekrar warn basmayalım

-- ---------- kütüphane toplama ----------

-- Modüller Ana.server (Script) altında kardeş ModuleScript'lerdir.
local function kardes(ad)
	local p = script.Parent
	return p and p:FindFirstChild(ad) or nil
end

-- hem dizi biçimini {ad, etiket, ikon, kategori, fn} hem de adlandırılmış alanları kabul et
local function normalle(t, m)
	if type(t) ~= "table" then return nil end
	local fn = t.fn or t[5]
	local ad = t.ad or t[1]
	if type(fn) ~= "function" or type(ad) ~= "string" then return nil end
	return {
		ad = ad,
		etiket = t.etiket or t[2] or ad,
		ikon = t.ikon or t[3] or "🏛",
		kategori = t.kategori or t[4] or m.kategori,
		fn = fn,
		terrain = (t.terrain == true) or (m.terrain == true),
	}
end

-- M.hepsi() → birleşik tanım listesi (modül sırasıyla)
function M.hepsi()
	if onbellek then return onbellek end
	local liste = {}
	for _, m in ipairs(MODULLER) do
		local ms = kardes(m.dosya)
		if not ms then
			if not uyarildi[m.dosya] then
				uyarildi[m.dosya] = true
				warn("[SweaxTerrain] structure module missing, category skipped: " .. m.dosya .. " (" .. m.kategori .. ")")
			end
		else
			local ok, mod = pcall(require, ms)
			if not ok or type(mod) ~= "table" or type(mod.YAPILAR) ~= "table" then
				if not uyarildi[m.dosya] then
					uyarildi[m.dosya] = true
					warn("[SweaxTerrain] structure module failed to load: " .. m.dosya .. " → " .. tostring(ok and "no M.YAPILAR" or mod))
				end
			else
				for _, ham in ipairs(mod.YAPILAR) do
					local t = normalle(ham, m)
					if t then table.insert(liste, t) end
				end
			end
		end
	end
	onbellek = liste
	return liste
end

-- modüller yeniden yüklendiğinde (paket güncellemesi) listeyi tazele
function M.yenile()
	onbellek = nil
	uyarildi = {}
	return M.hepsi()
end

function M.bul(ad)
	for _, t in ipairs(M.hepsi()) do
		if t.ad == ad then return t end
	end
	return nil
end

-- M.kategoriler() → listede GERÇEKTEN bulunan kategoriler. Önce M.KATEGORILER sırası,
-- sonra modüllerin kendi ek kategorileri (Kalıntı, Su, Doğa, Zemin...) görülme sırasıyla.
-- Arayüzdeki filtre butonları buradan üretilir; boş kategori butonu çıkmaz.
function M.kategoriler()
	local liste = M.hepsi()
	local sirali, gorulen = {}, {}
	local function ekle(k)
		if type(k) == "string" and k ~= "" and not gorulen[k] then
			gorulen[k] = true
			table.insert(sirali, k)
		end
	end
	for _, k in ipairs(M.KATEGORILER) do
		for _, t in ipairs(liste) do
			if t.kategori == k then
				ekle(k)
				break
			end
		end
	end
	for _, t in ipairs(liste) do ekle(t.kategori) end
	return sirali
end

-- terrain yazan girdiler için önizleme YAPILMAZ (arayüz/araç buna bakar)
function M.terrainMi(ad)
	local t = M.bul(ad)
	return (t ~= nil) and (t.terrain == true)
end

-- ---------- seçenekler ----------

-- Sözleşme: fn(kok, cf, o) — o burada tam doldurulur ki yapı dosyaları kontrol yapmasın.
function M.secenek(opt)
	opt = opt or {}
	local tohum = math.floor(tonumber(opt.tohum) or Random.new():NextInteger(1, 999999999))
	return {
		olcek = math.clamp(tonumber(opt.olcek) or 1, 0.2, 6),
		tohum = tohum,
		rnd = opt.rnd or Random.new(tohum), -- aynı tohum → aynı yapı
		yosun = math.clamp(tonumber(opt.yosun) or 0.5, 0, 1),
		yikik = math.clamp(tonumber(opt.yikik) or 0.35, 0, 1),
		isik = (opt.isik ~= false),
		renkTas = opt.renkTas or M.PALET.tas,
		renkKoyu = opt.renkKoyu or M.PALET.koyu,
		renkYosun = opt.renkYosun or M.PALET.yosun,
	}
end

-- ---------- kök klasör ----------

function M.kok()
	local k = workspace:FindFirstChild(M.KOK_AD)
	if not (k and k:IsA("Folder")) then
		k = Instance.new("Folder")
		k.Name = M.KOK_AD
		k.Parent = workspace
	end
	if k:GetAttribute("SweaxRoot") ~= true then
		k:SetAttribute("SweaxRoot", true)
	end
	return k
end

-- ---------- kurma ----------

-- M.olustur: yığına yazmadan/işaret koymadan yapıyı kurar (önizleme de bunu kullanır)
-- → Model, o   |   nil, hataMetni
function M.olustur(ad, cf, opt, ebeveyn)
	local tanim = M.bul(ad)
	if not tanim then return nil, "yapı bulunamadı: " .. tostring(ad) end
	local o = M.secenek(opt)
	local hedef = ebeveyn or M.kok()
	local ok, model = pcall(tanim.fn, hedef, cf or CFrame.new(), o)
	if not ok then
		warn("[SweaxTerrain] could not build " .. tanim.ad .. ": " .. tostring(model))
		return nil, tostring(model)
	end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		-- terrain girdileri işi voksellere yazar; Model dönmezse boş bir işaretçi yeterli
		if tanim.terrain then
			local isaret = Instance.new("Model")
			isaret.Name = tanim.ad
			model = isaret
		else
			warn("[SweaxTerrain] " .. tanim.ad .. " did not return a Model")
			return nil, "Model döndürmedi"
		end
	end
	if model.Parent == nil then model.Parent = hedef end
	if model.Name == "" or model.Name == "Model" then model.Name = tanim.ad end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	-- sözleşme garantisi: yapı dosyası unutsa bile attr'lar dursun
	model:SetAttribute("SweaxStructure", tanim.ad)
	model:SetAttribute("SweaxSeed", o.tohum)
	return model, o
end

-- M.yerlestir: kalıcı kurulum (kök klasör + geri alma işareti + yığın)
function M.yerlestir(ad, cf, opt)
	local model, o = M.olustur(ad, cf, opt, M.kok())
	if not model then return nil, o end
	table.insert(yigin, model)
	pcall(function()
		ChangeHistory:SetWaypoint("SweaxTerrain yapı: " .. model.Name)
	end)
	return model, o
end

-- ---------- zemin ----------

-- M.zeminHiza(x, z, disla) → zemin Y'si ya da nil. Kendi yapılarımız + önizleme hariç tutulur
-- (yoksa yeni yapı bir öncekinin çatısına oturur).
function M.zeminHiza(x, z, disla)
	local liste = {}
	local k = workspace:FindFirstChild(M.KOK_AD)
	if k then table.insert(liste, k) end
	local o = workspace:FindFirstChild(M.ONIZLEME_AD)
	if o then table.insert(liste, o) end
	if typeof(disla) == "Instance" then
		table.insert(liste, disla)
	elseif type(disla) == "table" then
		for _, d in ipairs(disla) do
			if typeof(d) == "Instance" then table.insert(liste, d) end
		end
	end
	local par = RaycastParams.new()
	par.FilterType = Enum.RaycastFilterType.Exclude
	par.FilterDescendantsInstances = liste
	par.IgnoreWater = false
	local sonuc = workspace:Raycast(Vector3.new(x, 4096, z), Vector3.new(0, -12000, 0), par)
	if sonuc then return sonuc.Position.Y end
	return nil
end

-- ---------- geri alma / temizlik ----------

-- M.sonuncuyuSil() → silinen yapının adı ya da nil (yığında elle silinmiş kayıtlar atlanır)
function M.sonuncuyuSil()
	while #yigin > 0 do
		local m = table.remove(yigin)
		if m and m.Parent then
			local ad = m.Name
			m:Destroy()
			pcall(function()
				ChangeHistory:SetWaypoint("SweaxTerrain yapı geri alındı")
			end)
			return ad
		end
	end
	return nil
end

-- M.hepsiniSil() → silinen yapı sayısı
function M.hepsiniSil()
	local k = workspace:FindFirstChild(M.KOK_AD)
	local sayi = 0
	if k then
		for _, c in ipairs(k:GetChildren()) do
			sayi += 1
			c:Destroy()
		end
	end
	table.clear(yigin)
	if sayi > 0 then
		pcall(function()
			ChangeHistory:SetWaypoint("SweaxTerrain tüm yapılar silindi")
		end)
	end
	return sayi
end

function M.sayi()
	return #yigin
end

return M
