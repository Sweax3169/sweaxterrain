-- SWEAX TERRAIN 1.0.0 — terrain generator, eraser and structure library for Roblox Studio.
-- Arazi üretici, silgi ve hazır yapı kütüphanesi (Studio eklentisi). Sweax Studios, MIT lisansı.
-- Roblox'un Arazi Düzenleyicisi'nden farkı: ağırlıklı biyom karışımı, ayrıntılı göl/nehir/okyanus/
-- mağara denetimleri, hazır dünyalar, tohumlu çeşitlilik, silgi fırçası + bölge silme, tek tıkla
-- yapı yerleştirme (canlı önizlemeli). Her üretim/silme/yerleştirme Ctrl+Z ile geri alınır.
if not plugin then return end

local SURUM = "1.0.0"

local ChangeHistory = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Uretici = require(script:WaitForChild("Uretici"))
local Arayuz = require(script:WaitForChild("Arayuz"))
local Dil = require(script:WaitForChild("Dil"))

-- Yapı kütüphanesi olmadan da eklenti çalışsın (Üret/Sil sekmeleri ona bağlı değil)
local Yapilar = nil
do
	local ms = script:FindFirstChild("Yapilar")
	if ms then
		local ok, sonuc = pcall(require, ms)
		if ok then Yapilar = sonuc else warn("[SweaxTerrain] Yapilar failed to load:", sonuc) end
	end
end

local AYAR_DIL = "SweaxTerrain_dil"
local dil = plugin:GetSetting(AYAR_DIL)
if dil ~= "en" and dil ~= "tr" then dil = Dil.varsayilan() end

local toolbar = plugin:CreateToolbar("Sweax Terrain")
local anaButon = toolbar:CreateButton("SweaxTerrain", Dil.metin(dil, "ipucu"), "rbxassetid://4458901886", "Sweax Terrain")
anaButon.ClickableWhenViewportHidden = true

local widget = plugin:CreateDockWidgetPluginGui("SweaxTerrainPanel", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, false, false, 360, 700, 330, 460))
widget.Title = "Sweax Terrain " .. SURUM
widget.Name = "SweaxTerrain"

local api = Arayuz.kur(widget, { dil = dil })
local L = api.L
local terrain = workspace.Terrain

anaButon.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	anaButon:SetActive(widget.Enabled)
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	anaButon:SetActive(widget.Enabled)
end)

-- ==================== ÜRETİM ====================
local uretiliyor = false
local iptalKutu = { iptal = false }
local sonBolge = nil -- {merkez, boyutX, boyutZ} son üretim (geri silme için)

api.olay.uret = function()
	if uretiliyor then return end
	local d = api.degerler
	if d.otoZar then
		d.cekirdek = Random.new():NextInteger(1, 999999999)
		api.yenile()
	end
	local ayar = api.getAyar()
	if next(ayar.biyomlar) == nil then
		api.setDurum(L("st_biyomSec"), true)
		return
	end
	uretiliyor = true
	iptalKutu.iptal = false
	api.uretButon.Text = L("b_uretiliyor")
	api.iptalButon.Visible = true
	task.spawn(function()
		local ok, sonuc = pcall(function()
			return Uretici.uret(terrain, ayar, function(oran, asama)
				api.setIlerleme(oran, math.floor(oran * 100) .. "%  " .. L("i_" .. tostring(asama)))
			end, iptalKutu)
		end)
		uretiliyor = false
		api.uretButon.Text = L("b_uret")
		api.iptalButon.Visible = false
		if ok and sonuc ~= false then
			sonBolge = { merkez = ayar.merkez, boyutX = ayar.boyutX, boyutZ = ayar.boyutZ }
			api.setIlerleme(1, "")
			api.setDurum(L("st_uretildi"))
			ChangeHistory:SetWaypoint("SweaxTerrain generate")
		elseif ok then
			api.setIlerleme(0, "")
			api.setDurum(L("st_iptal"))
		else
			api.setIlerleme(0, "")
			api.setDurum(L("st_hata", tostring(sonuc):sub(1, 80)), true)
			warn("[SweaxTerrain] generate failed:", sonuc)
		end
	end)
end

api.olay.iptal = function()
	iptalKutu.iptal = true
end

api.olay.preset = function(ad)
	api.presetUygula(ad)
	api.setDurum(L("st_preset", L("p_" .. ad)))
end

api.olay.kameraMerkez = function()
	local kam = workspace.CurrentCamera
	if not kam then return end
	local ileri = kam.CFrame.Position + kam.CFrame.LookVector * (api.degerler.boyutX / 2 + 80)
	api.degerler.merkezX = math.floor(ileri.X)
	api.degerler.merkezY = math.floor(math.max(ileri.Y - 60, -200))
	api.degerler.merkezZ = math.floor(ileri.Z)
	api.yenile()
	api.setDurum(L("st_kamera"))
end

api.olay.sonSil = function()
	if not sonBolge then
		api.setDurum(L("st_sonYok"))
		return
	end
	local b = sonBolge
	terrain:FillRegion(Region3.new(
		Vector3.new(b.merkez.X - b.boyutX / 2, b.merkez.Y - 120, b.merkez.Z - b.boyutZ / 2),
		Vector3.new(b.merkez.X + b.boyutX / 2, b.merkez.Y + 320, b.merkez.Z + b.boyutZ / 2)
	):ExpandToGrid(4), 4, Enum.Material.Air)
	ChangeHistory:SetWaypoint("SweaxTerrain erase last area")
	api.setDurum(L("st_sonSilindi"))
end

api.olay.hepsiniSil = function()
	terrain:Clear()
	ChangeHistory:SetWaypoint("SweaxTerrain erase all terrain")
	api.setDurum(L("st_hepsiSilindi"))
end

-- ==================== SİLGİ FIRÇASI + KÖŞE SEÇİMİ ====================
local mod = nil -- nil | "firca" | "secim" | "yapi"
local fare = plugin:GetMouse()
local onizleme = nil -- fırça küresi
local basili = false
local kose1, kose2 = nil, nil
local secimKutusu = nil
local adimSayac = 0
local yapiOnizTemizle -- aşağıda tanımlanır; modKapat ondan önce gelir

local function onizlemeTemizle()
	if onizleme then onizleme:Destroy() onizleme = nil end
end

local function secimTemizle()
	if secimKutusu then secimKutusu:Destroy() secimKutusu = nil end
	kose1, kose2 = nil, nil
end

-- mod düğmelerinin metni o anki moda ve dile göre
local function dugmeleriYaz()
	api.fircaButon.Text = L(mod == "firca" and "b_fircaKapat" or "b_fircaAc")
	api.secButon.Text = L(mod == "secim" and "b_secIptal" or "b_secBasla")
	api.yapiButon.Text = L(mod == "yapi" and "b_tiklaKapat" or "b_tikla")
	api.uretButon.Text = L(uretiliyor and "b_uretiliyor" or "b_uret")
end

api.olay.dilDegisti = function(yeniDil)
	dil = yeniDil
	plugin:SetSetting(AYAR_DIL, yeniDil)
	dugmeleriYaz()
	api.setDurum(L("d_hazir"))
end

local function modKapat()
	mod = nil
	basili = false
	onizlemeTemizle()
	if yapiOnizTemizle then yapiOnizTemizle() end
	plugin:Activate(false)
	dugmeleriYaz()
end

api.olay.fircaDegistir = function()
	if mod == "firca" then
		modKapat()
		api.setDurum(L("st_fircaKapandi"))
		return
	end
	secimTemizle()
	if yapiOnizTemizle then yapiOnizTemizle() end
	mod = "firca"
	plugin:Activate(true)
	dugmeleriYaz()
	api.setDurum(L("st_fircaAcik"))
	onizlemeTemizle()
	onizleme = Instance.new("Part")
	onizleme.Shape = Enum.PartType.Ball
	onizleme.Anchored = true
	onizleme.CanCollide = false
	onizleme.CanQuery = false
	onizleme.CanTouch = false
	onizleme.Material = Enum.Material.ForceField
	onizleme.Color = Color3.fromRGB(235, 90, 80)
	onizleme.Transparency = 0.35
	onizleme.Name = "SweaxTerrain_Brush"
	onizleme.Archivable = false
	onizleme.Parent = workspace
	fare.TargetFilter = onizleme
end

api.olay.kutuSecim = function()
	if mod == "secim" then
		modKapat()
		secimTemizle()
		api.setDurum(L("st_secimIptal"))
		return
	end
	onizlemeTemizle()
	secimTemizle()
	if yapiOnizTemizle then yapiOnizTemizle() end
	mod = "secim"
	plugin:Activate(true)
	dugmeleriYaz()
	api.setDurum(L("st_kose1"))
end

api.olay.kutuSil = function()
	if not (kose1 and kose2) then
		api.setDurum(L("st_onceKose"), true)
		return
	end
	local pay = api.degerler.dikeyPay or 80
	local mn = Vector3.new(math.min(kose1.X, kose2.X), math.min(kose1.Y, kose2.Y) - pay, math.min(kose1.Z, kose2.Z))
	local mx = Vector3.new(math.max(kose1.X, kose2.X), math.max(kose1.Y, kose2.Y) + pay, math.max(kose1.Z, kose2.Z))
	terrain:FillRegion(Region3.new(mn, mx):ExpandToGrid(4), 4, Enum.Material.Air)
	ChangeHistory:SetWaypoint("SweaxTerrain erase region")
	api.setDurum(L("st_secimSilindi", math.floor(mx.X - mn.X), math.floor(mx.Z - mn.Z)))
	secimTemizle()
	modKapat()
end

-- ==================== YAPI YERLEŞTİRME ====================
-- Önizleme ayrı bir klasörde (Archivable=false → kaydedilmez), yarı saydam ve tıklanamaz.
-- Yeniden KURULUM yalnız ayar/seçim değişince olur; fare gezerken sadece PivotTo ile taşınır.
local yapiKlasor = nil
local yapiOniz = nil
local yapiBagil = CFrame.new() -- kurulum cf'si ile modelin pivotu arasındaki sabit fark
local yapiImzaSon = ""
local yapiKonumSon = nil

local function yapiSecenek()
	local d = api.degerler
	local t = math.floor(tonumber(d.yapiTohum) or 1)
	return {
		olcek = tonumber(d.yapiOlcek) or 1,
		tohum = t,
		rnd = Random.new(t), -- aynı tohum → aynı yapı
		yosun = tonumber(d.yapiYosun) or 0.5,
		yikik = tonumber(d.yapiYikik) or 0.35,
		isik = d.yapiIsik ~= false,
	}
end

local function yapiCF(pos)
	return CFrame.new(pos) * CFrame.Angles(0, math.rad(tonumber(api.degerler.yapiDonus) or 0), 0)
end

local function yapiImza()
	local d = api.degerler
	return table.concat({ tostring(api.yapiSecili), tostring(d.yapiOlcek), tostring(d.yapiTohum),
		tostring(d.yapiYosun), tostring(d.yapiYikik), tostring(d.yapiIsik), tostring(d.yapiDonus) }, "|")
end

-- "Zemine otur" açıksa fare hangi yüzeye değerse değsin yapı gerçek zemine iner
local function yapiZeminliPos(pos)
	if api.degerler.yapiZemin and Yapilar then
		local y = Yapilar.zeminHiza(pos.X, pos.Z, yapiKlasor)
		if y then return Vector3.new(pos.X, y, pos.Z) end
	end
	return pos
end

local function yapiOnizKlasor()
	if yapiKlasor and yapiKlasor.Parent then return yapiKlasor end
	local eski = workspace:FindFirstChild("SweaxOnizleme")
	if eski then eski:Destroy() end
	yapiKlasor = Instance.new("Folder")
	yapiKlasor.Name = "SweaxOnizleme"
	yapiKlasor.Archivable = false
	yapiKlasor.Parent = workspace
	return yapiKlasor
end

function yapiOnizTemizle()
	if yapiOniz then yapiOniz:Destroy() end
	yapiOniz = nil
	if yapiKlasor then yapiKlasor:Destroy() end
	yapiKlasor = nil
	yapiImzaSon = ""
	yapiKonumSon = nil
	if fare.TargetFilter and fare.TargetFilter.Name == "SweaxOnizleme" then
		fare.TargetFilter = nil
	end
end

local function yapiOnizKur(pos)
	if not (Yapilar and api.yapiSecili) then return end
	if Yapilar.terrainMi(api.yapiSecili) then return end
	local kls = yapiOnizKlasor()
	if yapiOniz then yapiOniz:Destroy() yapiOniz = nil end
	local cf = yapiCF(pos)
	local model = Yapilar.olustur(api.yapiSecili, cf, yapiSecenek(), kls)
	if not model then return end
	model.Archivable = false
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			d.Transparency = math.max(d.Transparency, 0.55)
		elseif d:IsA("Light") then
			d.Enabled = false -- önizleme sahnenin ışığını bozmasın
		end
	end
	yapiOniz = model
	yapiBagil = cf:Inverse() * model:GetPivot()
	yapiKonumSon = pos
	fare.TargetFilter = kls -- fare kendi önizlememize takılmasın
end

local function yapiKur(pos, kameraOnu)
	if not Yapilar then
		api.setDurum(L("st_yapiModulYok"), true)
		return
	end
	if not api.yapiSecili then
		api.setDurum(L("st_onceYapi"), true)
		return
	end
	local ad = api.yapiAdi(api.yapiSecili)
	local model = Yapilar.yerlestir(api.yapiSecili, yapiCF(yapiZeminliPos(pos)), yapiSecenek())
	if not model then
		api.setDurum(L("st_yapiKurulamadi", ad), true)
		return
	end
	model.Name = ad -- Explorer'da panelin dilinde görünsün (iç ad SweaxStructure niteliğinde)
	-- arka arkaya konan yapılar birbirinin kopyası olmasın
	if api.degerler.yapiOtoTohum ~= false then
		api.yapiTohumAyarla(Random.new():NextInteger(1, 999999999))
	end
	api.setDurum(L(kameraOnu and "st_kurulduKamera" or "st_kuruldu", ad))
end

api.olay.yapiSec = function(ad)
	if Yapilar and Yapilar.terrainMi(ad) then
		api.setDurum(L("st_seciliAlan", api.yapiAdi(ad)))
	else
		api.setDurum(L("st_seciliYapi", api.yapiAdi(ad)))
	end
end

api.olay.yapiKurKamera = function()
	local kam = workspace.CurrentCamera
	if not kam then return end
	local hedef = kam.CFrame.Position + kam.CFrame.LookVector * 30
	local y = Yapilar and Yapilar.zeminHiza(hedef.X, hedef.Z, yapiKlasor)
	yapiKur(Vector3.new(hedef.X, y or hedef.Y, hedef.Z), true)
end

api.olay.yapiTiklaModu = function()
	if mod == "yapi" then
		modKapat()
		api.setDurum(L("st_yerlestirmeKapandi"))
		return
	end
	if not Yapilar then
		api.setDurum(L("st_yapiModulYok"), true)
		return
	end
	if not api.yapiSecili then
		api.setDurum(L("st_onceYapi"), true)
		return
	end
	onizlemeTemizle()
	secimTemizle()
	yapiOnizTemizle()
	mod = "yapi"
	plugin:Activate(true)
	dugmeleriYaz()
	api.setDurum(L("st_tiklaKur"))
end

api.olay.yapiGeriAl = function()
	if not Yapilar then return end
	local ad = Yapilar.sonuncuyuSil()
	if ad then
		api.setDurum(L("st_geriAlindi", api.yapiAdi(ad)))
	else
		api.setDurum(L("st_geriYok"))
	end
end

api.olay.yapiHepsiniSil = function()
	if not Yapilar then return end
	local sayi = Yapilar.hepsiniSil()
	api.setDurum(L("st_yapiSilindi", sayi))
end

local function fircaVur(pos)
	terrain:FillBall(pos, api.degerler.fircaYaricap or 16, Enum.Material.Air)
end

fare.Button1Down:Connect(function()
	if mod == "firca" then
		basili = true
		if fare.Hit then fircaVur(fare.Hit.Position) end
	elseif mod == "yapi" then
		local hit = fare.Hit
		if not hit then return end
		-- Shift basılıyken tıklamak dönüşü 45° ilerletir (mod açık kalır)
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
			api.yapiDonusAyarla(((tonumber(api.degerler.yapiDonus) or 0) + 45) % 360)
		end
		yapiKur(hit.Position, false)
	elseif mod == "secim" then
		local p = fare.Hit and fare.Hit.Position
		if not p then return end
		if not kose1 then
			kose1 = p
			api.setDurum(L("st_kose2"))
		else
			kose2 = p
			-- önizleme kutusu
			if secimKutusu then secimKutusu:Destroy() end
			local pay = api.degerler.dikeyPay or 80
			local mn = Vector3.new(math.min(kose1.X, kose2.X), math.min(kose1.Y, kose2.Y) - pay, math.min(kose1.Z, kose2.Z))
			local mx = Vector3.new(math.max(kose1.X, kose2.X), math.max(kose1.Y, kose2.Y) + pay, math.max(kose1.Z, kose2.Z))
			secimKutusu = Instance.new("Part")
			secimKutusu.Anchored = true
			secimKutusu.CanCollide = false
			secimKutusu.CanQuery = false
			secimKutusu.CanTouch = false
			secimKutusu.Transparency = 0.75
			secimKutusu.Color = Color3.fromRGB(235, 90, 80)
			secimKutusu.Material = Enum.Material.Neon
			secimKutusu.Size = mx - mn
			secimKutusu.CFrame = CFrame.new((mn + mx) / 2)
			secimKutusu.Archivable = false
			secimKutusu.Name = "SweaxTerrain_Selection"
			secimKutusu.Parent = workspace
			api.setDurum(L("st_secimHazir"))
		end
	end
end)

fare.Button1Up:Connect(function()
	basili = false
	if mod == "firca" then
		ChangeHistory:SetWaypoint("SweaxTerrain brush erase")
	end
end)

RunService.Heartbeat:Connect(function()
	if mod == "yapi" then
		if not (Yapilar and api.yapiSecili) then return end
		-- arazi alanları terrain yazar: önizleme kurmak gerçek araziyi oyardı → önizleme yok
		if Yapilar.terrainMi(api.yapiSecili) then
			if yapiOniz then yapiOnizTemizle() end
			return
		end
		local hit = fare.Hit
		if not hit then return end
		local pos = yapiZeminliPos(hit.Position)
		local imza = yapiImza()
		if imza ~= yapiImzaSon or not (yapiOniz and yapiOniz.Parent) then
			yapiImzaSon = imza
			yapiOnizKur(pos) -- ayar/seçim değişti → yeniden kur (pahalı ama seyrek)
		elseif not yapiKonumSon or (pos - yapiKonumSon).Magnitude > 2 then
			yapiKonumSon = pos -- 2 stud eşiği: her karede taşımayalım
			yapiOniz:PivotTo(yapiCF(pos) * yapiBagil)
		end
		return
	end
	if mod ~= "firca" or not onizleme then return end
	local hit = fare.Hit
	if hit then
		local r = api.degerler.fircaYaricap or 16
		onizleme.Size = Vector3.new(r * 2, r * 2, r * 2)
		onizleme.Position = hit.Position
		adimSayac += 1
		if basili and adimSayac % 3 == 0 then
			fircaVur(hit.Position)
		end
	end
end)

plugin.Deactivation:Connect(function()
	if mod then
		mod = nil
		basili = false
		onizlemeTemizle()
		secimTemizle()
		yapiOnizTemizle()
		dugmeleriYaz()
	end
end)

plugin.Unloading:Connect(function()
	onizlemeTemizle()
	secimTemizle()
	yapiOnizTemizle()
	local artik = workspace:FindFirstChild("SweaxOnizleme")
	if artik then artik:Destroy() end
end)

dugmeleriYaz()
api.setDurum(L("d_hazir"))
