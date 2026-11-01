-- SWEAX TERRAIN — Arayuz: dock panel UI (sekmeli, kaydırmalı, İngilizce/Türkçe).
-- Kendi mini kiti: bölüm başlığı, kaydırıcı, onay kutusu, sayı kutusu, düğme, seçenek grubu.
-- Renkler Studio temasından okunur (açık/koyu) ve tema değişince yeniden boyanır; vurgu renkleri
-- arazinin kendisinden: çim yeşili (birincil), su mavisi (seçim/kaydırıcı), lav kırmızısı (silme).
-- Her denetim kendi "yenileyici"sini kaydeder: değerler koddan değişince (hazır dünya, dil, tema)
-- api.yenile() bütün paneli api.degerler ile yeniden eşitler.
local Dil = require(script.Parent:WaitForChild("Dil"))

local Arayuz = {}

local VURGU = Color3.fromRGB(84, 156, 82) -- çim
local VURGU2 = Color3.fromRGB(62, 130, 196) -- su
local TEHLIKE = Color3.fromRGB(204, 82, 60) -- lav
local UYARI = Color3.fromRGB(226, 160, 70)
local BEYAZ = Color3.new(1, 1, 1)

local FONT = Enum.Font.GothamMedium
local FONTB = Enum.Font.GothamBold

local function temaOku()
	local ok, tema = pcall(function()
		return settings().Studio.Theme
	end)
	local function c(rol, yedek)
		if ok and tema then
			local o, v = pcall(function()
				return tema:GetColor(rol)
			end)
			if o and v then return v end
		end
		return yedek
	end
	local S = Enum.StudioStyleGuideColor
	local zemin = c(S.MainBackground, Color3.fromRGB(46, 46, 46))
	local yazi = c(S.MainText, Color3.fromRGB(232, 232, 232))
	return {
		zemin = zemin,
		panel = zemin:Lerp(yazi, 0.045),
		panel2 = zemin:Lerp(yazi, 0.11),
		cizgi = c(S.Border, zemin:Lerp(yazi, 0.2)),
		yazi = yazi,
		soluk = c(S.SubText, zemin:Lerp(yazi, 0.6)),
		ray = c(S.InputFieldBackground, zemin:Lerp(Color3.new(0, 0, 0), 0.25)),
		vurgu = VURGU,
		vurgu2 = VURGU2,
		tehlike = TEHLIKE,
		uyari = UYARI,
		beyaz = BEYAZ,
	}
end

local function hex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- biyom ve hazır dünya şeritleri için arazi malzemesinin bu haritadaki rengi
local function malzemeRengi(mat)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if not terrain then return Color3.fromRGB(128, 128, 128) end
	if mat == Enum.Material.Water then return terrain.WaterColor end
	local ok, renk = pcall(function()
		return terrain:GetMaterialColor(mat)
	end)
	return ok and renk or Color3.fromRGB(128, 128, 128)
end

local E = Enum.Material

-- iç ad, Türkçe/İngilizce metin anahtarı, varsayılan açık mı, varsayılan ağırlık, yüzey malzemesi
local BIYOMLAR = {
	{ "ova", "b_ova", true, 0.8, E.Grass },
	{ "tepe", "b_tepe", true, 0.7, E.LeafyGrass },
	{ "dag", "b_dag", true, 0.9, E.Rock },
	{ "plato", "b_plato", false, 0.6, E.Ground },
	{ "kanyon", "b_kanyon", false, 0.8, E.Sandstone },
	{ "volkan", "b_volkan", false, 0.8, E.Basalt },
	{ "col", "b_col", false, 0.8, E.Sand },
	{ "arktik", "b_arktik", false, 0.8, E.Snow },
	{ "bataklik", "b_bataklik", false, 0.7, E.Mud },
}
Arayuz.BIYOMLAR = BIYOMLAR

local PRESETLER = {
	{ "alp", { E.Snow, E.Rock, E.Grass, E.Water } },
	{ "nehir", { E.Grass, E.LeafyGrass, E.Sand, E.Water } },
	{ "kanyon", { E.Sandstone, E.Sand, E.Rock, E.Ground } },
	{ "volkan", { E.Basalt, E.Rock, E.CrackedLava, E.Basalt } },
	{ "arktik", { E.Snow, E.Glacier, E.Ice, E.Rock } },
	{ "bataklik", { E.LeafyGrass, E.Mud, E.Ground, E.Water } },
	{ "sahil", { E.Grass, E.Sand, E.Water, E.Water } },
	{ "karisik", { E.Grass, E.Sandstone, E.Snow, E.Basalt } },
}
Arayuz.PRESETLER = PRESETLER

-- Yapı kütüphanesi kardeş "Yapilar" modülünden okunur. Bulunamazsa sekme boş kalır ama
-- panel yine açılır (Üret/Sil sekmeleri yapı modüllerine bağımlı değil).
local VARSAYILAN_KAT = { "Mimari", "Maden", "Alan" }
local function yapiListesiOku()
	local ms = script.Parent and script.Parent:FindFirstChild("Yapilar")
	if not ms then
		warn("[SweaxTerrain] Yapilar module missing from the package")
		return {}, VARSAYILAN_KAT
	end
	local ok, Y = pcall(require, ms)
	if not ok or type(Y) ~= "table" or type(Y.hepsi) ~= "function" then
		warn("[SweaxTerrain] Yapilar module failed to load: " .. tostring(Y))
		return {}, VARSAYILAN_KAT
	end
	local ok2, liste = pcall(Y.hepsi)
	if not ok2 or type(liste) ~= "table" then
		warn("[SweaxTerrain] structure list unavailable: " .. tostring(liste))
		return {}, VARSAYILAN_KAT
	end
	-- filtre düğmeleri yalnız DOLU kategoriler için çıksın
	local kat = VARSAYILAN_KAT
	if type(Y.kategoriler) == "function" then
		local ok3, k = pcall(Y.kategoriler)
		if ok3 and type(k) == "table" and #k > 0 then kat = k end
	end
	return liste, kat
end

-- ---------- kurucu ----------
-- Arayuz.kur(widget, {dil = "en"|"tr"}) → api { degerler, olay, getAyar, setDurum, setIlerleme, L, ... }
function Arayuz.kur(widget, secenek)
	secenek = secenek or {}
	local api = { degerler = {}, olay = {} }
	local dil = (secenek.dil == "tr") and "tr" or "en"
	local RENK = temaOku()

	local renkKayit = {} -- {nesne, özellik, rol}: tema değişince yeniden boyanır
	local metinKayit = {} -- {nesne, anahtar}: dil değişince yeniden yazılır
	local yenileyiciler = {} -- değer → görsel eşitleyiciler
	local dilYenileyiciler = {} -- dile bağlı özel metinler (yapı adları, kategoriler)

	local function L(anahtar, ...)
		return Dil.metin(dil, anahtar, ...)
	end
	api.L = L
	function api.dil()
		return dil
	end

	-- yeni(sinif, özellikler, ebeveyn): "@rol" renk değerleri temaya, "#anahtar" Text değerleri dile bağlanır
	local function yeni(sinif, oz, ebeveyn)
		local o = Instance.new(sinif)
		for k, v in pairs(oz) do
			if type(v) == "string" and k ~= "Text" and k ~= "Name" and v:sub(1, 1) == "@" then
				local rol = v:sub(2)
				table.insert(renkKayit, { o, k, rol })
				o[k] = RENK[rol]
			elseif k == "Text" and type(v) == "string" and v:sub(1, 1) == "#" then
				table.insert(metinKayit, { o, v:sub(2) })
				o.Text = L(v:sub(2))
			else
				o[k] = v
			end
		end
		o.Parent = ebeveyn
		return o
	end

	local function kose(o, r)
		yeni("UICorner", { CornerRadius = UDim.new(0, r or 4) }, o)
	end

	local function yenileyici(fn)
		table.insert(yenileyiciler, fn)
		fn()
	end

	local kok = yeni("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@zemin", BorderSizePixel = 0 }, widget)

	-- ---------- sekme çubuğu + dil düğmesi ----------
	local SEKME_Y = 36
	local DURUM_Y = 26
	local sekmeBar = yeni("Frame", { Size = UDim2.new(1, 0, 0, SEKME_Y), BackgroundColor3 = "@zemin", BorderSizePixel = 0 }, kok)
	yeni("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = "@cizgi",
		BorderSizePixel = 0 }, sekmeBar)
	local sekmeler = {}
	local SIRA = { "uret", "sil", "yapi" }
	local aktifSekme = "uret"
	local DIL_GEN = 54

	local function sekmeBoya()
		for ad, s in pairs(sekmeler) do
			local aktif = (ad == aktifSekme)
			s.buton.TextColor3 = aktif and RENK.yazi or RENK.soluk
			s.cizgi.Visible = aktif
			s.icerik.Visible = aktif
		end
	end
	local function sekmeSec(ad)
		aktifSekme = ad
		sekmeBoya()
	end
	api.sekmeSec = sekmeSec

	local function sekmeEkle(ad, anahtar, sira)
		local w = 1 / #SIRA
		local b = yeni("TextButton", { Size = UDim2.new(w, -DIL_GEN / #SIRA, 1, -1),
			Position = UDim2.new((sira - 1) * w, -(sira - 1) * DIL_GEN / #SIRA, 0, 0),
			BackgroundTransparency = 1, Text = "#" .. anahtar, Font = FONTB, TextSize = 13,
			TextColor3 = "@soluk", BorderSizePixel = 0, AutoButtonColor = false }, sekmeBar)
		local cizgi = yeni("Frame", { Size = UDim2.new(1, -20, 0, 2), Position = UDim2.new(0, 10, 1, -2),
			BackgroundColor3 = "@vurgu", BorderSizePixel = 0, Visible = false }, b)
		local icerik = yeni("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -(SEKME_Y + DURUM_Y)),
			Position = UDim2.new(0, 0, 0, SEKME_Y), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 5, ScrollBarImageColor3 = "@cizgi", CanvasSize = UDim2.new(), Visible = false,
			AutomaticCanvasSize = Enum.AutomaticSize.Y }, kok)
		yeni("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center }, icerik)
		yeni("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12) }, icerik)
		sekmeler[ad] = { buton = b, icerik = icerik, cizgi = cizgi }
		b.MouseButton1Click:Connect(function() sekmeSec(ad) end)
		return icerik
	end

	local uretS = sekmeEkle("uret", "tab_uret", 1)
	local silS = sekmeEkle("sil", "tab_sil", 2)
	local yapiS = sekmeEkle("yapi", "tab_yapi", 3)

	local dilB = yeni("TextButton", { Size = UDim2.new(0, DIL_GEN - 8, 0, 22), Position = UDim2.new(1, -DIL_GEN + 2, 0, 7),
		BackgroundColor3 = "@panel", Text = "", RichText = true, Font = FONTB, TextSize = 12,
		TextColor3 = "@yazi", BorderSizePixel = 0, AutoButtonColor = true }, sekmeBar)
	kose(dilB, 4)
	local function dilDugmesiYaz()
		local soluk = hex(RENK.soluk)
		if dil == "en" then
			dilB.Text = 'EN <font color="' .. soluk .. '">TR</font>'
		else
			dilB.Text = '<font color="' .. soluk .. '">EN</font> TR'
		end
	end

	-- ---------- durum çubuğu (her sekmede görünür) ----------
	local durumBar = yeni("Frame", { Size = UDim2.new(1, 0, 0, DURUM_Y), Position = UDim2.new(0, 0, 1, -DURUM_Y),
		BackgroundColor3 = "@panel", BorderSizePixel = 0 }, kok)
	yeni("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "@cizgi", BorderSizePixel = 0 }, durumBar)
	local durumYazi = yeni("TextLabel", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1, Text = "#d_hazir", Font = FONT, TextSize = 12, TextColor3 = "@soluk",
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, durumBar)

	-- ---------- kit ----------
	local sira = 0
	local function kart(ebeveyn, yuk)
		sira += 1
		local f = yeni("Frame", { Size = UDim2.new(1, -16, 0, yuk), BackgroundColor3 = "@panel",
			BorderSizePixel = 0, LayoutOrder = sira }, ebeveyn)
		kose(f, 4)
		return f
	end

	local function baslik(ebeveyn, anahtar)
		sira += 1
		local f = yeni("Frame", { Size = UDim2.new(1, -16, 0, 22), BackgroundTransparency = 1, LayoutOrder = sira }, ebeveyn)
		yeni("TextLabel", { Size = UDim2.new(1, -4, 1, 0), Position = UDim2.new(0, 2, 0, 2), BackgroundTransparency = 1,
			Text = "#" .. anahtar, Font = FONTB, TextSize = 13, TextColor3 = "@yazi",
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom }, f)
		return f
	end

	-- genis: etiket satırın sağındaki küçük denetime kadar uzanır (onay kutusu satırları)
	local function etiketli(f, y, anahtar, x, genis)
		if not anahtar or anahtar == "" then return end
		local boy = genis and UDim2.new(1, -44 - (x or 10), 0, 18) or UDim2.new(0.46, -8 - (x or 10) + 10, 0, 18)
		yeni("TextLabel", { Size = boy, Position = UDim2.new(0, x or 10, 0, y),
			BackgroundTransparency = 1, Text = "#" .. anahtar, Font = FONT, TextSize = 13, TextColor3 = "@yazi",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, f)
	end

	local UIS = game:GetService("UserInputService")
	local aktifSurukle = nil -- o an sürüklenen kaydırıcının uygula() fonksiyonu
	UIS.InputChanged:Connect(function(g)
		if aktifSurukle and g.UserInputType == Enum.UserInputType.MouseMovement then aktifSurukle(g.Position.X) end
	end)
	UIS.InputEnded:Connect(function(g)
		if g.UserInputType == Enum.UserInputType.MouseButton1 then aktifSurukle = nil end
	end)

	-- kaydırıcı: değeri api.degerler[anahtar] altında tutar
	local function slider(f, y, etiket, anahtar, minV, maxV, deger, adim, birim)
		etiketli(f, y, etiket)
		api.degerler[anahtar] = deger
		local ray = yeni("Frame", { Size = UDim2.new(0.54, -62, 0, 4), Position = UDim2.new(0.46, 4, 0, y + 8),
			BackgroundColor3 = "@ray", BorderSizePixel = 0 }, f)
		kose(ray, 2)
		local dolgu = yeni("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@vurgu2", BorderSizePixel = 0 }, ray)
		kose(dolgu, 2)
		local tutamac = yeni("Frame", { Size = UDim2.new(0, 6, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = "@yazi", BorderSizePixel = 0, ZIndex = 2 }, ray)
		kose(tutamac, 2)
		local kutu = yeni("TextLabel", { Size = UDim2.new(0, 52, 0, 18), Position = UDim2.new(1, -60, 0, y),
			BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = "@soluk",
			TextXAlignment = Enum.TextXAlignment.Right, Text = "" }, f)
		yenileyici(function()
			local v = tonumber(api.degerler[anahtar]) or deger
			local oran = math.clamp((v - minV) / (maxV - minV), 0, 1)
			dolgu.Size = UDim2.fromScale(oran, 1)
			tutamac.Position = UDim2.new(oran, 0, 0.5, 0)
			local m = (adim >= 1) and string.format("%d", v) or string.format("%.2f", v)
			kutu.Text = m .. (birim or "")
		end)
		local yenile = yenileyiciler[#yenileyiciler]
		local function uygula(px)
			local oran = math.clamp((px - ray.AbsolutePosition.X) / math.max(ray.AbsoluteSize.X, 1), 0, 1)
			local v = minV + oran * (maxV - minV)
			v = math.floor(v / adim + 0.5) * adim
			api.degerler[anahtar] = math.clamp(v, minV, maxV)
			yenile()
		end
		local function basla(g)
			if g.UserInputType == Enum.UserInputType.MouseButton1 then
				aktifSurukle = uygula
				uygula(g.Position.X)
			end
		end
		ray.InputBegan:Connect(basla)
		tutamac.InputBegan:Connect(basla)
	end

	-- kare onay kutusu (sağda)
	local function onayKutu(f, y, etiket, anahtar, deger)
		etiketli(f, y, etiket, nil, true)
		api.degerler[anahtar] = deger
		local b = yeni("TextButton", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -28, 0, y + 1),
			BackgroundColor3 = "@ray", Text = "", Font = FONTB, TextSize = 12, TextColor3 = "@beyaz",
			BorderSizePixel = 0, AutoButtonColor = false }, f)
		kose(b, 3)
		local cerceve = yeni("UIStroke", { Color = "@cizgi", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		yenileyici(function()
			local v = api.degerler[anahtar] == true
			b.BackgroundColor3 = v and RENK.vurgu or RENK.ray
			b.Text = v and "✓" or ""
			cerceve.Transparency = v and 1 or 0
		end)
		local yenile = yenileyiciler[#yenileyiciler]
		b.MouseButton1Click:Connect(function()
			api.degerler[anahtar] = not (api.degerler[anahtar] == true)
			yenile()
		end)
		return b
	end

	local function sayiKutu(f, y, etiket, anahtar, deger, gen)
		etiketli(f, y, etiket)
		api.degerler[anahtar] = deger
		gen = gen or 86
		local k = yeni("TextBox", { Size = UDim2.new(0, gen, 0, 20), Position = UDim2.new(1, -gen - 10, 0, y - 1),
			BackgroundColor3 = "@ray", Text = tostring(deger), Font = FONT, TextSize = 13,
			TextColor3 = "@yazi", BorderSizePixel = 0, ClearTextOnFocus = false }, f)
		kose(k, 3)
		yeni("UIStroke", { Color = "@cizgi", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, k)
		yenileyici(function()
			k.Text = tostring(api.degerler[anahtar])
		end)
		k.FocusLost:Connect(function()
			local v = tonumber(k.Text)
			if v then api.degerler[anahtar] = v else k.Text = tostring(api.degerler[anahtar]) end
		end)
		return k
	end

	-- düğme türleri: ana (çim), mavi (su), tehlike (lav), ikincil (panel)
	local TUR = {
		ana = { "@vurgu", "@beyaz" },
		mavi = { "@vurgu2", "@beyaz" },
		tehlike = { "@tehlike", "@beyaz" },
		ikincil = { "@panel2", "@yazi" },
	}
	local function buton(ebeveyn, anahtar, tur, yuk)
		sira += 1
		local t = TUR[tur or "ikincil"]
		local b = yeni("TextButton", { Size = UDim2.new(1, -16, 0, yuk or 32), BackgroundColor3 = t[1],
			Text = "#" .. anahtar, Font = FONTB, TextSize = 13, TextColor3 = t[2], BorderSizePixel = 0,
			LayoutOrder = sira, AutoButtonColor = true }, ebeveyn)
		kose(b, 4)
		return b
	end

	local function kucukButon(ebeveyn, metin, boyut, konum)
		local b = yeni("TextButton", { Size = boyut, Position = konum, BackgroundColor3 = "@panel2", Text = metin,
			Font = FONT, TextSize = 11, TextColor3 = "@yazi", BorderSizePixel = 0, AutoButtonColor = true }, ebeveyn)
		kose(b, 3)
		return b
	end

	-- ==================== ÜRET SEKMESİ ====================
	baslik(uretS, "h_hazir")
	local presetKart = kart(uretS, 106)
	for i, p in ipairs(PRESETLER) do
		local sx = ((i - 1) % 4) * 0.25
		local sy = math.floor((i - 1) / 4)
		local b = yeni("TextButton", { Size = UDim2.new(0.25, -6, 0, 44), Position = UDim2.new(sx, 4, 0, 6 + sy * 50),
			BackgroundColor3 = "@panel2", Text = "#p_" .. p[1], Font = FONT, TextSize = 11, TextColor3 = "@yazi",
			BorderSizePixel = 0, TextWrapped = true, AutoButtonColor = true, TextYAlignment = Enum.TextYAlignment.Center }, presetKart)
		kose(b, 3)
		yeni("UIPadding", { PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }, b)
		-- alt kenarda o dünyanın malzeme şeridi
		local serit = yeni("Frame", { Size = UDim2.new(1, 6, 0, 5), Position = UDim2.new(0, -3, 1, 1),
			BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
		for j, mat in ipairs(p[2]) do
			yeni("Frame", { Size = UDim2.new(1 / #p[2], 0, 1, 0), Position = UDim2.new((j - 1) / #p[2], 0, 0, 0),
				BackgroundColor3 = malzemeRengi(mat), BorderSizePixel = 0 }, serit)
		end
		b.MouseButton1Click:Connect(function()
			if api.olay.preset then api.olay.preset(p[1]) end
		end)
	end

	baslik(uretS, "h_bolge")
	local bolgeKart = kart(uretS, 126)
	slider(bolgeKart, 8, "s_genislik", "boyutX", 128, 2048, 512, 32, " st")
	slider(bolgeKart, 34, "s_derinlik", "boyutZ", 128, 2048, 512, 32, " st")
	local mx = sayiKutu(bolgeKart, 60, "s_merkez", "merkezX", 0, 58)
	mx.Position = UDim2.new(1, -192, 0, 59)
	local my = sayiKutu(bolgeKart, 60, nil, "merkezY", 40, 58)
	my.Position = UDim2.new(1, -130, 0, 59)
	local mz = sayiKutu(bolgeKart, 60, nil, "merkezZ", 0, 58)
	mz.Position = UDim2.new(1, -68, 0, 59)
	local kamB = yeni("TextButton", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 92),
		BackgroundColor3 = "@panel2", Text = "#b_kamera", Font = FONT, TextSize = 12,
		TextColor3 = "@yazi", BorderSizePixel = 0, AutoButtonColor = true }, bolgeKart)
	kose(kamB, 3)
	kamB.MouseButton1Click:Connect(function()
		if api.olay.kameraMerkez then api.olay.kameraMerkez() end
	end)

	baslik(uretS, "h_cekirdek")
	local cekKart = kart(uretS, 62)
	sayiKutu(cekKart, 8, "s_cekirdek", "cekirdek", 618033988, 110)
	local zarB = kucukButon(cekKart, "🎲", UDim2.new(0, 30, 0, 20), UDim2.new(1, -156, 0, 7))
	zarB.TextSize = 14
	zarB.MouseButton1Click:Connect(function()
		api.degerler.cekirdek = Random.new():NextInteger(1, 999999999)
		api.yenile()
	end)
	onayKutu(cekKart, 36, "c_otozar", "otoZar", true)

	baslik(uretS, "h_biyom")
	local biyomKart = kart(uretS, #BIYOMLAR * 26 + 10)
	for i, b in ipairs(BIYOMLAR) do
		local y = 6 + (i - 1) * 26
		local ornek = yeni("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 10, 0, y + 3),
			BackgroundColor3 = malzemeRengi(b[5]), BorderSizePixel = 0 }, biyomKart)
		kose(ornek, 2)
		yeni("UIStroke", { Color = "@cizgi", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ornek)
		etiketli(biyomKart, y, b[2], 30)
		onayKutu(biyomKart, y, nil, "b_" .. b[1], b[3])
		-- ağırlık kaydırıcısı (aynı satırda)
		local anahtar = "bw_" .. b[1]
		api.degerler[anahtar] = b[4]
		local rayW = yeni("Frame", { Size = UDim2.new(0, 84, 0, 4), Position = UDim2.new(1, -128, 0, y + 8),
			BackgroundColor3 = "@ray", BorderSizePixel = 0 }, biyomKart)
		kose(rayW, 2)
		local dolguW = yeni("Frame", { Size = UDim2.fromScale(b[4], 1), BackgroundColor3 = "@vurgu", BorderSizePixel = 0 }, rayW)
		kose(dolguW, 2)
		yenileyici(function()
			local acik = api.degerler["b_" .. b[1]] == true
			dolguW.Size = UDim2.fromScale(math.clamp(tonumber(api.degerler[anahtar]) or 0, 0, 1), 1)
			dolguW.BackgroundColor3 = acik and RENK.vurgu or RENK.cizgi
		end)
		local yenile = yenileyiciler[#yenileyiciler]
		local function uygulaW(px)
			local oran = math.clamp((px - rayW.AbsolutePosition.X) / math.max(rayW.AbsoluteSize.X, 1), 0.05, 1)
			api.degerler[anahtar] = oran
			yenile()
		end
		rayW.InputBegan:Connect(function(g)
			if g.UserInputType == Enum.UserInputType.MouseButton1 then
				aktifSurukle = uygulaW
				uygulaW(g.Position.X)
			end
		end)
	end

	baslik(uretS, "h_sekil")
	local sekilKart = kart(uretS, 138)
	slider(sekilKart, 8, "s_yuk", "yukOlcek", 0.3, 2.5, 1.0, 0.05)
	slider(sekilKart, 34, "s_puruz", "puruz", 0, 1, 0.5, 0.05)
	slider(sekilKart, 60, "s_warp", "warp", 0, 1, 0.5, 0.05)
	slider(sekilKart, 86, "s_teras", "teras", 0, 1, 0, 0.05)
	slider(sekilKart, 112, "s_biyomBoyut", "biyomBoyut", 120, 900, 320, 20, " st")

	baslik(uretS, "h_su")
	local suKart = kart(uretS, 312)
	slider(suKart, 8, "s_suSeviye", "suSeviye", -10, 20, 0, 1, " st")
	onayKutu(suKart, 36, "c_gol", "golEtkin", true)
	slider(suKart, 62, "s_golYog", "golYogunluk", 0, 1, 0.5, 0.05)
	slider(suKart, 88, "s_golDer", "golDerinlik", 3, 30, 10, 1, " st")
	slider(suKart, 114, "s_golKum", "golKum", 0, 16, 6, 1, " st")
	onayKutu(suKart, 144, "c_nehir", "nehirEtkin", false)
	slider(suKart, 170, "s_nehirAdet", "nehirAdet", 1, 5, 2, 1)
	slider(suKart, 196, "s_nehirGen", "nehirGen", 6, 40, 14, 1, " st")
	slider(suKart, 222, "s_nehirKivrim", "nehirKivrim", 0, 1, 0.6, 0.05)
	onayKutu(suKart, 252, "c_oky", "okyEtkin", false)
	api.degerler.okyYon = "bati"
	local yonler = { "bati", "dogu", "kuzey", "guney" }
	local yonB = {}
	for i, yv in ipairs(yonler) do
		local b = kucukButon(suKart, "#y_" .. yv, UDim2.new(0.25, -6, 0, 22), UDim2.new((i - 1) * 0.25, 5, 0, 280))
		yonB[yv] = b
		b.MouseButton1Click:Connect(function()
			api.degerler.okyYon = yv
			api.yenile()
		end)
	end
	yenileyici(function()
		for k, b in pairs(yonB) do
			local se = (k == api.degerler.okyYon)
			b.BackgroundColor3 = se and RENK.vurgu2 or RENK.panel2
			b.TextColor3 = se and RENK.beyaz or RENK.yazi
		end
	end)

	baslik(uretS, "h_magara")
	local magKart = kart(uretS, 164)
	onayKutu(magKart, 8, "c_magara", "magEtkin", false)
	slider(magKart, 34, "s_magYog", "magYogunluk", 0, 1, 0.5, 0.05)
	slider(magKart, 60, "s_magBoyut", "magBoyut", 0, 1, 0.5, 0.05)
	slider(magKart, 86, "s_cikinti", "cikinti", 0, 1, 0.35, 0.05)
	slider(magKart, 112, "s_benek", "benek", 0, 1, 0.6, 0.05)
	slider(magKart, 138, "s_kar", "karCizgisi", 0.1, 1, 0.72, 0.02)

	local uretB = buton(uretS, "b_uret", "ana", 40)
	uretB.TextSize = 14
	local ilerlemeKart = kart(uretS, 26)
	ilerlemeKart.BackgroundColor3 = RENK.ray
	table.insert(renkKayit, { ilerlemeKart, "BackgroundColor3", "ray" })
	local ilerlemeDolgu = yeni("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@vurgu", BorderSizePixel = 0 }, ilerlemeKart)
	kose(ilerlemeDolgu, 4)
	local ilerlemeYazi = yeni("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
		Font = FONT, TextSize = 12, TextColor3 = "@yazi", ZIndex = 2 }, ilerlemeKart)
	local iptalB = buton(uretS, "b_iptal", "tehlike", 26)
	iptalB.Visible = false
	api.uretButon, api.iptalButon = uretB, iptalB

	function api.setIlerleme(oran, metin)
		ilerlemeDolgu.Size = UDim2.fromScale(math.clamp(oran, 0, 1), 1)
		ilerlemeYazi.Text = metin or ""
	end

	uretB.MouseButton1Click:Connect(function()
		if api.olay.uret then api.olay.uret() end
	end)
	iptalB.MouseButton1Click:Connect(function()
		if api.olay.iptal then api.olay.iptal() end
	end)

	-- iki tıkla onaylanan tehlikeli düğme
	local function onayli(b, anahtar, eylem)
		local bekliyor = false
		b.MouseButton1Click:Connect(function()
			if not bekliyor then
				bekliyor = true
				b.Text = L("b_emin")
				task.delay(5, function()
					if bekliyor then
						bekliyor = false
						b.Text = L(anahtar)
					end
				end)
			else
				bekliyor = false
				b.Text = L(anahtar)
				eylem()
			end
		end)
	end

	-- ==================== SİL SEKMESİ ====================
	baslik(silS, "h_firca")
	local fircaKart = kart(silS, 62)
	slider(fircaKart, 8, "s_firca", "fircaYaricap", 4, 80, 16, 2, " st")
	yeni("TextLabel", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 34), BackgroundTransparency = 1,
		Text = "#n_firca", Font = FONT, TextSize = 11, TextColor3 = "@soluk", TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left }, fircaKart)
	local fircaB = buton(silS, "b_fircaAc", "mavi", 34)
	api.fircaButon = fircaB
	fircaB.MouseButton1Click:Connect(function()
		if api.olay.fircaDegistir then api.olay.fircaDegistir() end
	end)

	baslik(silS, "h_bolgeSil")
	local kutuKart = kart(silS, 60)
	slider(kutuKart, 8, "s_dikeyPay", "dikeyPay", 10, 200, 80, 5, " st")
	yeni("TextLabel", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 0, 34), BackgroundTransparency = 1,
		Text = "#n_bolge", Font = FONT, TextSize = 11, TextColor3 = "@soluk", TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left }, kutuKart)
	local secB = buton(silS, "b_secBasla", "mavi", 32)
	local secSilB = buton(silS, "b_secSil", "tehlike", 32)
	api.secButon = secB
	secB.MouseButton1Click:Connect(function()
		if api.olay.kutuSecim then api.olay.kutuSecim() end
	end)
	secSilB.MouseButton1Click:Connect(function()
		if api.olay.kutuSil then api.olay.kutuSil() end
	end)

	baslik(silS, "h_toptan")
	local sonSilB = buton(silS, "b_sonSil", "ikincil", 30)
	local hepsiB = buton(silS, "b_hepsiSil", "tehlike", 30)
	sonSilB.MouseButton1Click:Connect(function()
		if api.olay.sonSil then api.olay.sonSil() end
	end)
	onayli(hepsiB, "b_hepsiSil", function()
		if api.olay.hepsiniSil then api.olay.hepsiniSil() end
	end)

	-- ==================== YAPILAR SEKMESİ ====================
	api.yapiSecili = nil
	local yapiKartlar = {} -- ad → { buton, cerceve, kategori }

	baslik(yapiS, "h_kutuphane")

	local yapiListe, yapiKat = yapiListesiOku()
	local filtreler = { "Hepsi" }
	for _, k in ipairs(yapiKat) do table.insert(filtreler, k) end
	local filtreSatir = math.ceil(#filtreler / 3)
	local filtreKart = kart(yapiS, 8 + filtreSatir * 26)
	local filtreB = {}
	local aktifFiltre = "Hepsi"
	local function filtreUygula(kat)
		aktifFiltre = kat
		for k, b in pairs(filtreB) do
			local se = (k == kat)
			b.BackgroundColor3 = se and RENK.vurgu2 or RENK.panel2
			b.TextColor3 = se and RENK.beyaz or RENK.yazi
		end
		for _, t in pairs(yapiKartlar) do
			t.buton.Visible = (kat == "Hepsi") or (t.kategori == kat)
		end
	end
	for i, kat in ipairs(filtreler) do
		local sut = (i - 1) % 3
		local sat = math.floor((i - 1) / 3)
		local b = kucukButon(filtreKart, "", UDim2.new(1 / 3, -8, 0, 22), UDim2.new(sut / 3, 5, 0, 5 + sat * 26))
		b.TextTruncate = Enum.TextTruncate.AtEnd
		filtreB[kat] = b
		table.insert(dilYenileyiciler, function()
			b.Text = (kat == "Hepsi") and L("f_hepsi") or Dil.kategori(dil, kat)
		end)
		b.MouseButton1Click:Connect(function() filtreUygula(kat) end)
	end

	local izgaraKart = kart(yapiS, 300)
	local izgara = yeni("ScrollingFrame", { Size = UDim2.new(1, -12, 1, -12), Position = UDim2.new(0, 6, 0, 6),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
		ScrollBarImageColor3 = "@cizgi", CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y }, izgaraKart)
	yeni("UIGridLayout", { CellSize = UDim2.new(0, 92, 0, 58), CellPadding = UDim2.new(0, 6, 0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, izgara)

	local function yapiBoya()
		for a, t in pairs(yapiKartlar) do
			local se = (a == api.yapiSecili)
			t.cerceve.Color = se and RENK.vurgu or RENK.cizgi
			t.cerceve.Thickness = se and 2 or 1
			t.cerceve.Transparency = se and 0 or 0.4
			t.buton.BackgroundColor3 = se and RENK.panel2 or RENK.ray
		end
	end
	local function yapiSec(ad)
		api.yapiSecili = ad
		yapiBoya()
		if api.olay.yapiSec then api.olay.yapiSec(ad) end
	end
	api.yapiSec = yapiSec

	function api.yapiAdi(ad)
		for _, t in ipairs(yapiListe) do
			if t.ad == ad then return Dil.yapi(dil, t.ad, t.etiket) end
		end
		return tostring(ad)
	end

	for i, t in ipairs(yapiListe) do
		local b = yeni("TextButton", { Size = UDim2.new(0, 92, 0, 58), BackgroundColor3 = "@ray",
			Text = "", Font = FONT, TextSize = 11, TextColor3 = "@yazi", BorderSizePixel = 0,
			TextWrapped = true, LayoutOrder = i, AutoButtonColor = true }, izgara)
		kose(b, 3)
		yeni("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, b)
		local cerceve = yeni("UIStroke", { Color = RENK.cizgi, Thickness = 1, Transparency = 0.4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		yapiKartlar[t.ad] = { buton = b, cerceve = cerceve, kategori = t.kategori }
		table.insert(dilYenileyiciler, function()
			b.Text = (t.ikon or "🏛") .. "\n" .. Dil.yapi(dil, t.ad, t.etiket)
		end)
		b.MouseButton1Click:Connect(function() yapiSec(t.ad) end)
	end
	if #yapiListe == 0 then
		yeni("TextLabel", { Size = UDim2.new(1, -12, 0, 40), Position = UDim2.new(0, 6, 0, 6),
			BackgroundTransparency = 1, Text = "#n_yapiYok", Font = FONT, TextSize = 12,
			TextColor3 = "@soluk", TextWrapped = true }, izgaraKart)
	end
	yenileyici(function()
		yapiBoya()
		filtreUygula(aktifFiltre)
	end)

	baslik(yapiS, "h_ayarlar")
	local ayarKart = kart(yapiS, 262)
	slider(ayarKart, 8, "s_olcek", "yapiOlcek", 0.4, 3.0, 1.0, 0.05, "×")
	slider(ayarKart, 34, "s_yosun", "yapiYosun", 0, 1, 0.5, 0.05)
	slider(ayarKart, 60, "s_yikik", "yapiYikik", 0, 1, 0.35, 0.05)
	etiketli(ayarKart, 86, "s_donus")
	api.degerler.yapiDonus = 0
	local donusB = {}
	function api.yapiDonusAyarla(deg)
		deg = (math.floor((tonumber(deg) or 0) / 45 + 0.5) * 45) % 360
		api.degerler.yapiDonus = deg
		api.yenile()
		return deg
	end
	for i, deg in ipairs({ 0, 45, 90, 135, 180, 225, 270, 315 }) do
		local sut = (i - 1) % 4
		local sat = math.floor((i - 1) / 4)
		local b = kucukButon(ayarKart, deg .. "°", UDim2.new(0.25, -7, 0, 20), UDim2.new(sut * 0.25, 5, 0, 106 + sat * 24))
		donusB[deg] = b
		b.MouseButton1Click:Connect(function() api.yapiDonusAyarla(deg) end)
	end
	yenileyici(function()
		for d, b in pairs(donusB) do
			local se = (d == api.degerler.yapiDonus)
			b.BackgroundColor3 = se and RENK.vurgu2 or RENK.panel2
			b.TextColor3 = se and RENK.beyaz or RENK.yazi
		end
	end)
	onayKutu(ayarKart, 156, "c_isik", "yapiIsik", true)
	onayKutu(ayarKart, 182, "c_zemin", "yapiZemin", true)
	sayiKutu(ayarKart, 208, "s_tohum", "yapiTohum", Random.new():NextInteger(1, 999999999), 100)
	local yapiZarB = kucukButon(ayarKart, "🎲", UDim2.new(0, 30, 0, 20), UDim2.new(1, -146, 0, 207))
	yapiZarB.TextSize = 14
	function api.yapiTohumAyarla(v)
		v = math.floor(tonumber(v) or 1)
		api.degerler.yapiTohum = v
		api.yenile()
		return v
	end
	yapiZarB.MouseButton1Click:Connect(function()
		api.yapiTohumAyarla(Random.new():NextInteger(1, 999999999))
	end)
	onayKutu(ayarKart, 234, "c_otoTohum", "yapiOtoTohum", true)

	local yapiKamB = buton(yapiS, "b_kamKur", "ana", 36)
	local yapiTiklaB = buton(yapiS, "b_tikla", "mavi", 34)
	local yapiGeriB = buton(yapiS, "b_geriAl", "ikincil", 30)
	local yapiSilB = buton(yapiS, "b_yapiSil", "tehlike", 30)
	api.yapiButon = yapiTiklaB

	yapiKamB.MouseButton1Click:Connect(function()
		if api.olay.yapiKurKamera then api.olay.yapiKurKamera() end
	end)
	yapiTiklaB.MouseButton1Click:Connect(function()
		if api.olay.yapiTiklaModu then api.olay.yapiTiklaModu() end
	end)
	yapiGeriB.MouseButton1Click:Connect(function()
		if api.olay.yapiGeriAl then api.olay.yapiGeriAl() end
	end)
	onayli(yapiSilB, "b_yapiSil", function()
		if api.olay.yapiHepsiniSil then api.olay.yapiHepsiniSil() end
	end)

	-- ---------- durum ----------
	function api.setDurum(metin, uyari)
		durumYazi.Text = metin or ""
		durumYazi.TextColor3 = uyari and RENK.uyari or RENK.soluk
	end

	-- ---------- eşitleme / dil / tema ----------
	function api.yenile()
		for _, fn in ipairs(yenileyiciler) do fn() end
	end

	local function metinleriYaz()
		for _, k in ipairs(metinKayit) do
			k[1].Text = L(k[2])
		end
		for _, fn in ipairs(dilYenileyiciler) do fn() end
		dilDugmesiYaz()
	end

	function api.dilAyarla(d)
		dil = (d == "tr") and "tr" or "en"
		metinleriYaz()
		if api.olay.dilDegisti then api.olay.dilDegisti(dil) end
	end

	dilB.MouseButton1Click:Connect(function()
		api.dilAyarla(dil == "en" and "tr" or "en")
	end)

	local function temayiUygula()
		local yeniR = temaOku()
		for k, v in pairs(yeniR) do RENK[k] = v end
		for _, k in ipairs(renkKayit) do
			k[1][k[2]] = RENK[k[3]]
		end
		sekmeBoya()
		api.yenile()
		dilDugmesiYaz()
		durumYazi.TextColor3 = RENK.soluk
	end
	pcall(function()
		settings().Studio.ThemeChanged:Connect(temayiUygula)
	end)

	-- ---------- ayar toplama ----------
	function api.getAyar()
		local d = api.degerler
		local biyomlar = {}
		for _, b in ipairs(BIYOMLAR) do
			if d["b_" .. b[1]] then biyomlar[b[1]] = d["bw_" .. b[1]] end
		end
		return {
			cekirdek = math.floor(tonumber(d.cekirdek) or 42),
			merkez = Vector3.new(tonumber(d.merkezX) or 0, tonumber(d.merkezY) or 40, tonumber(d.merkezZ) or 0),
			boyutX = d.boyutX, boyutZ = d.boyutZ,
			yukOlcek = d.yukOlcek, puruz = d.puruz, warp = d.warp, teras = d.teras,
			biyomBoyut = d.biyomBoyut, biyomlar = biyomlar,
			su = {
				seviye = d.suSeviye,
				gol = { etkin = d.golEtkin, yogunluk = d.golYogunluk, derinlik = d.golDerinlik, kum = d.golKum },
				nehir = { etkin = d.nehirEtkin, adet = d.nehirAdet, genislik = d.nehirGen, kivrim = d.nehirKivrim, derinlik = 5 },
				okyanus = { etkin = d.okyEtkin, yon = d.okyYon, plaj = 40 },
			},
			magara = { etkin = d.magEtkin, yogunluk = d.magYogunluk, boyut = d.magBoyut },
			detay = { cikinti = d.cikinti, benek = d.benek, karCizgisi = d.karCizgisi },
		}
	end

	-- Hazır dünya: önce dünya ayarlarını varsayılana döndürür (bir öncekinin teras/kar ayarı
	-- sızmasın), sonra o dünyanın farklarını yazar ve paneli eşitler. Bölge, merkez, çekirdek,
	-- silgi ve yapı ayarları korunur.
	local VARS = table.clone(api.degerler)
	local KORU = { boyutX = true, boyutZ = true, merkezX = true, merkezY = true, merkezZ = true,
		cekirdek = true, otoZar = true, fircaYaricap = true, dikeyPay = true }
	function api.presetUygula(ad)
		local d = api.degerler
		for k, v in pairs(VARS) do
			if not KORU[k] and k:sub(1, 4) ~= "yapi" then d[k] = v end
		end
		for _, b in ipairs(BIYOMLAR) do d["b_" .. b[1]] = false end
		d.golEtkin, d.nehirEtkin, d.okyEtkin, d.magEtkin = false, false, false, false
		if ad == "alp" then
			d.b_dag, d.b_tepe, d.b_ova = true, true, true
			d.bw_dag, d.bw_tepe, d.bw_ova = 1, 0.6, 0.5
			d.golEtkin = true
			d.karCizgisi = 0.56
		elseif ad == "nehir" then
			d.b_ova, d.b_tepe = true, true
			d.bw_ova, d.bw_tepe = 1, 0.5
			d.golEtkin, d.nehirEtkin = true, true
			d.nehirAdet = 2
		elseif ad == "kanyon" then
			d.b_kanyon, d.b_col, d.b_plato = true, true, true
			d.bw_kanyon, d.bw_col, d.bw_plato = 1, 0.9, 0.6
			d.teras = 0.35
		elseif ad == "volkan" then
			d.b_volkan, d.b_dag = true, true
			d.bw_volkan, d.bw_dag = 1, 0.5
			d.magEtkin = true
		elseif ad == "arktik" then
			d.b_arktik, d.b_dag = true, true
			d.bw_arktik, d.bw_dag = 1, 0.5
			d.golEtkin = true
			d.karCizgisi = 0.3
		elseif ad == "bataklik" then
			d.b_bataklik, d.b_ova = true, true
			d.bw_bataklik, d.bw_ova = 1, 0.5
			d.golEtkin, d.nehirEtkin = true, true
		elseif ad == "sahil" then
			d.b_ova, d.b_tepe, d.b_col = true, true, true
			d.bw_ova, d.bw_tepe, d.bw_col = 1, 0.5, 0.4
			d.golEtkin, d.okyEtkin = true, true
		else -- karisik
			local r = Random.new()
			for _, b in ipairs(BIYOMLAR) do
				d["b_" .. b[1]] = r:NextNumber() > 0.45
				d["bw_" .. b[1]] = math.floor(r:NextNumber(0.4, 1) * 100 + 0.5) / 100
			end
			d.b_ova = true
			d.golEtkin = true
			d.nehirEtkin = r:NextNumber() > 0.5
			d.magEtkin = r:NextNumber() > 0.5
		end
		api.yenile()
		return ad
	end

	metinleriYaz()
	sekmeSec("uret")
	api.yenile()
	return api
end

return Arayuz
