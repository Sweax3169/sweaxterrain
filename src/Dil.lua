-- SWEAX TERRAIN — Dil: interface text in English and Turkish.
-- Arayüz metinleri (İngilizce / Türkçe). Anahtar → metin; %s/%d yer tutucuları string.format ile dolar.
-- Yapı adlarının Türkçesi yapı modüllerindeki "etiket" alanındadır; İngilizcesi burada (YAPI).
local Dil = {}

Dil.DILLER = { "en", "tr" }

local T = {}

T.en = {
	baslik = "Sweax Terrain",
	ipucu = "Terrain generator, eraser and structure library",

	tab_uret = "Generate",
	tab_sil = "Erase",
	tab_yapi = "Structures",

	h_hazir = "Ready-made worlds",
	p_alp = "Alpine",
	p_nehir = "River plains",
	p_kanyon = "Desert canyon",
	p_volkan = "Volcanic",
	p_arktik = "Arctic",
	p_bataklik = "Swamp",
	p_sahil = "Coast",
	p_karisik = "Random mix",

	h_bolge = "Area",
	s_genislik = "Width (X)",
	s_derinlik = "Depth (Z)",
	s_merkez = "Centre X · Y · Z",
	b_kamera = "Centre in front of the camera",

	h_cekirdek = "Seed",
	s_cekirdek = "Seed",
	c_otozar = "New seed on every run",

	h_biyom = "Biomes, blended by weight",
	b_ova = "Plains",
	b_tepe = "Hills",
	b_dag = "Mountains",
	b_plato = "Plateaus",
	b_kanyon = "Canyons",
	b_volkan = "Volcanic",
	b_col = "Desert dunes",
	b_arktik = "Arctic",
	b_bataklik = "Swamp",

	h_sekil = "Shape",
	s_yuk = "Height scale",
	s_puruz = "Roughness",
	s_warp = "Flow (domain warp)",
	s_teras = "Terracing",
	s_biyomBoyut = "Biome region size",

	h_su = "Water",
	s_suSeviye = "Water level above base",
	c_gol = "Lakes",
	s_golYog = "Lake density",
	s_golDer = "Lake depth",
	s_golKum = "Beach width",
	c_nehir = "Rivers",
	s_nehirAdet = "River count",
	s_nehirGen = "River width",
	s_nehirKivrim = "Meander",
	c_oky = "Ocean edge",
	y_bati = "West",
	y_dogu = "East",
	y_kuzey = "North",
	y_guney = "South",

	h_magara = "Caves and detail",
	c_magara = "Caves",
	s_magYog = "Cave density",
	s_magBoyut = "Cave size",
	s_cikinti = "Rock outcrops",
	s_benek = "Surface patches",
	s_kar = "Snow line (low = snowier)",

	b_uret = "Generate world",
	b_uretiliyor = "Generating…",
	b_iptal = "Cancel",
	d_hazir = "Ready",
	i_yukseklik = "height map",
	i_voksel = "writing voxels",
	i_bitti = "done",

	h_firca = "Eraser brush",
	s_firca = "Brush radius",
	n_firca = "With the brush on, click or drag in the scene.",
	b_fircaAc = "Turn brush on",
	b_fircaKapat = "Turn brush off",
	h_bolgeSil = "Erase a region",
	s_dikeyPay = "Vertical margin (±)",
	n_bolge = "Click two corners, then Erase selection.",
	b_secBasla = "Pick two corners",
	b_secIptal = "Cancel selection",
	b_secSil = "Erase selection",
	h_toptan = "Everything at once",
	b_sonSil = "Erase the last generated area",
	b_hepsiSil = "Erase all terrain in this place",
	b_emin = "Sure? Click again within 5 s",

	h_kutuphane = "Structure library",
	f_hepsi = "All",
	n_yapiYok = "The structure modules did not load. Reinstall the plugin.",
	h_ayarlar = "Settings",
	s_olcek = "Scale",
	s_yosun = "Moss",
	s_yikik = "Ruin",
	s_donus = "Rotation",
	c_isik = "Lights (torches, lamps)",
	c_zemin = "Snap to ground",
	s_tohum = "Seed",
	c_otoTohum = "New seed on every placement",
	b_kamKur = "Place in front of the camera",
	b_tikla = "Click to place",
	b_tiklaKapat = "Stop placing",
	b_geriAl = "Undo last structure",
	b_yapiSil = "Remove all structures",
	d_yapiSec = "Pick a structure, then place it.",

	st_biyomSec = "Pick at least one biome.",
	st_uretildi = "Done. Not happy? Press Ctrl+Z.",
	st_iptal = "Cancelled.",
	st_hata = "Error: %s",
	st_preset = "%s loaded. Press Generate world.",
	st_kamera = "Centre moved in front of the camera.",
	st_sonYok = "Nothing has been generated yet.",
	st_sonSilindi = "Last generated area erased.",
	st_hepsiSilindi = "All terrain erased. Ctrl+Z brings it back.",
	st_fircaKapandi = "Brush off.",
	st_fircaAcik = "Brush on: click or drag in the scene.",
	st_secimIptal = "Selection cancelled.",
	st_kose1 = "Click the first corner.",
	st_kose2 = "Click the second corner.",
	st_secimHazir = "Selection ready. Press Erase selection.",
	st_onceKose = "Pick two corners first.",
	st_secimSilindi = "Erased a %d × %d stud region.",
	st_yapiModulYok = "The structure modules are not loaded.",
	st_onceYapi = "Pick a structure from the grid first.",
	st_yapiKurulamadi = "Could not place %s.",
	st_kuruldu = "Placed %s. Ctrl+Z undoes it.",
	st_kurulduKamera = "Placed %s in front of the camera. Ctrl+Z undoes it.",
	st_seciliAlan = "%s is a landform: no preview, it is carved where you click.",
	st_seciliYapi = "Selected: %s",
	st_yerlestirmeKapandi = "Placing off.",
	st_tiklaKur = "Click in the scene to place. Shift+click turns it 45°.",
	st_geriAlindi = "Undone: %s",
	st_geriYok = "No structure to undo.",
	st_yapiSilindi = "Removed %d structures. Ctrl+Z undoes it.",
}

T.tr = {
	baslik = "Sweax Terrain",
	ipucu = "Arazi üretici, silgi ve yapı kütüphanesi",

	tab_uret = "Üret",
	tab_sil = "Sil",
	tab_yapi = "Yapılar",

	h_hazir = "Hazır dünyalar",
	p_alp = "Alp",
	p_nehir = "Nehirli ova",
	p_kanyon = "Çöl kanyonu",
	p_volkan = "Volkanik",
	p_arktik = "Arktik",
	p_bataklik = "Bataklık",
	p_sahil = "Sahil",
	p_karisik = "Karışık",

	h_bolge = "Bölge",
	s_genislik = "Genişlik (X)",
	s_derinlik = "Derinlik (Z)",
	s_merkez = "Merkez X · Y · Z",
	b_kamera = "Merkezi kameranın önüne al",

	h_cekirdek = "Çekirdek",
	s_cekirdek = "Çekirdek",
	c_otozar = "Her üretimde yeni çekirdek",

	h_biyom = "Biyomlar, ağırlıkla karışır",
	b_ova = "Ovalar",
	b_tepe = "Tepeler",
	b_dag = "Dağlar",
	b_plato = "Platolar",
	b_kanyon = "Kanyonlar",
	b_volkan = "Volkanik",
	b_col = "Çöl kumulları",
	b_arktik = "Arktik",
	b_bataklik = "Bataklık",

	h_sekil = "Şekil",
	s_yuk = "Yükseklik ölçeği",
	s_puruz = "Pürüz",
	s_warp = "Akışkanlık (warp)",
	s_teras = "Teraslama",
	s_biyomBoyut = "Biyom bölge boyutu",

	h_su = "Su",
	s_suSeviye = "Su seviyesi (tabandan)",
	c_gol = "Göller",
	s_golYog = "Göl yoğunluğu",
	s_golDer = "Göl derinliği",
	s_golKum = "Kumsal genişliği",
	c_nehir = "Nehirler",
	s_nehirAdet = "Nehir sayısı",
	s_nehirGen = "Nehir genişliği",
	s_nehirKivrim = "Kıvrım",
	c_oky = "Okyanus kenarı",
	y_bati = "Batı",
	y_dogu = "Doğu",
	y_kuzey = "Kuzey",
	y_guney = "Güney",

	h_magara = "Mağara ve detay",
	c_magara = "Mağaralar",
	s_magYog = "Mağara yoğunluğu",
	s_magBoyut = "Mağara boyutu",
	s_cikinti = "Kaya çıkıntıları",
	s_benek = "Yüzey benekleri",
	s_kar = "Kar çizgisi (alçak = karlı)",

	b_uret = "Dünyayı üret",
	b_uretiliyor = "Üretiliyor…",
	b_iptal = "İptal",
	d_hazir = "Hazır",
	i_yukseklik = "yükseklik haritası",
	i_voksel = "voksel yazımı",
	i_bitti = "bitti",

	h_firca = "Silgi fırçası",
	s_firca = "Fırça yarıçapı",
	n_firca = "Fırça açıkken sahnede tıkla ya da sürükle.",
	b_fircaAc = "Fırçayı aç",
	b_fircaKapat = "Fırçayı kapat",
	h_bolgeSil = "Bölge silme",
	s_dikeyPay = "Dikey pay (±)",
	n_bolge = "İki köşeye tıkla, sonra Seçimi sil.",
	b_secBasla = "İki köşe seç",
	b_secIptal = "Seçimi iptal et",
	b_secSil = "Seçimi sil",
	h_toptan = "Toptan",
	b_sonSil = "Son üretilen bölgeyi sil",
	b_hepsiSil = "Bu haritadaki tüm araziyi sil",
	b_emin = "Emin misin? 5 sn içinde tekrar tıkla",

	h_kutuphane = "Yapı kütüphanesi",
	f_hepsi = "Hepsi",
	n_yapiYok = "Yapı modülleri yüklenemedi. Eklentiyi yeniden kur.",
	h_ayarlar = "Ayarlar",
	s_olcek = "Ölçek",
	s_yosun = "Yosun",
	s_yikik = "Yıkıklık",
	s_donus = "Dönüş",
	c_isik = "Işıklar (meşale, fener)",
	c_zemin = "Zemine otur",
	s_tohum = "Tohum",
	c_otoTohum = "Her kurulumda yeni tohum",
	b_kamKur = "Kameranın önüne kur",
	b_tikla = "Tıklayarak kur",
	b_tiklaKapat = "Yerleştirmeyi kapat",
	b_geriAl = "Sonuncuyu geri al",
	b_yapiSil = "Tüm yapıları sil",
	d_yapiSec = "Bir yapı seç, sonra kur.",

	st_biyomSec = "En az bir biyom seç.",
	st_uretildi = "Üretildi. Beğenmediysen Ctrl+Z.",
	st_iptal = "İptal edildi.",
	st_hata = "Hata: %s",
	st_preset = "%s seçildi. Dünyayı üret'e bas.",
	st_kamera = "Merkez kameranın önüne alındı.",
	st_sonYok = "Henüz bir şey üretilmedi.",
	st_sonSilindi = "Son üretilen bölge silindi.",
	st_hepsiSilindi = "Tüm arazi silindi. Ctrl+Z geri getirir.",
	st_fircaKapandi = "Fırça kapandı.",
	st_fircaAcik = "Fırça açık: sahnede tıkla ya da sürükle.",
	st_secimIptal = "Seçim iptal edildi.",
	st_kose1 = "Birinci köşeye tıkla.",
	st_kose2 = "İkinci köşeye tıkla.",
	st_secimHazir = "Seçim hazır. Seçimi sil'e bas.",
	st_onceKose = "Önce iki köşe seç.",
	st_secimSilindi = "%d × %d stud bölge silindi.",
	st_yapiModulYok = "Yapı modülleri yüklenmedi.",
	st_onceYapi = "Önce ızgaradan bir yapı seç.",
	st_yapiKurulamadi = "%s kurulamadı.",
	st_kuruldu = "%s kuruldu. Ctrl+Z geri alır.",
	st_kurulduKamera = "%s kameranın önüne kuruldu. Ctrl+Z geri alır.",
	st_seciliAlan = "%s bir arazi alanı: önizleme yok, tıkladığın yere işlenir.",
	st_seciliYapi = "Seçili: %s",
	st_yerlestirmeKapandi = "Yerleştirme kapandı.",
	st_tiklaKur = "Sahnede tıkla, kurulsun. Shift+tık 45° çevirir.",
	st_geriAlindi = "Geri alındı: %s",
	st_geriYok = "Geri alınacak yapı yok.",
	st_yapiSilindi = "%d yapı silindi. Ctrl+Z geri alır.",
}

-- yapı kategorileri: modüllerdeki Türkçe kategori adı → İngilizce
Dil.KATEGORI = {
	["Mimari"] = "Architecture",
	["Kalıntı"] = "Ruins",
	["Su"] = "Water",
	["Doğa"] = "Nature",
	["Zemin"] = "Ground",
	["Maden"] = "Mining",
	["Süs"] = "Props",
	["Alan"] = "Landforms",
}

-- yapı adları (iç ad → İngilizce); Türkçesi modüldeki etiket
Dil.YAPI = {
	kademeliKaide = "Stepped Plinth",
	heykelKaidesi = "Miner Statue",
	taskemer = "Stone Arch",
	sutunlar = "Broken Columns",
	kalintiDuvar = "Ruined Wall",
	merdivenSeti = "Stone Stairs",
	dikiliTaslar = "Standing Stones",
	gozetlemeKulesi = "Watchtower",
	taskopru = "Stone Bridge",
	suKanali = "Water Channel",
	kayaOlusum = "Rock Formation",
	avluDuvari = "Courtyard Wall",
	meydanZemini = "Plaza Floor",

	madenGirisi = "Mine Entrance",
	madenTuneli = "Mine Tunnel",
	vincKulesi = "Crane Tower",
	rayHatti = "Rail Line",
	cevherVagonu = "Ore Cart",
	cevherDamari = "Ore Vein",
	kuyuAgzi = "Shaft Head",
	madenciKampi = "Miners' Camp",
	cevherDeposu = "Ore Depot",
	konveyorIskele = "Conveyor Gantry",
	eritmeOcagi = "Smelting Furnace",
	cevherYigini = "Ore Pile",
	asansorKulesi = "Lift Tower",

	susMesale = "Torch",
	susFener = "Lamp Post",
	susSandik = "Crate Stack",
	susVaril = "Barrels",
	susDestek = "Timber Prop",
	susIskele = "Scaffold",
	susCevherYigin = "Ore Heap",
	susMoloz = "Rubble Pile",
	susKampAtesi = "Campfire",
	susAletStandi = "Tool Rack",
	susTabela = "Signpost",
	susCadir = "Tent",
	susCit = "Fence Line",
	susDinamit = "Dynamite Crate",
	susSuOlugu = "Water Trough",
	susOdun = "Woodpile",
	susElArabasi = "Wheelbarrow",
	susBayrak = "Flagpole",

	alanDuzle = "Flatten",
	alanTemizle = "Clear",
	alanPlato = "Mining Plateau",
	alanTasOcagi = "Quarry Pit",
	alanKanyon = "Canyon Rift",
	alanMagaraAgzi = "Cave Mouth",
	alanKayaSirti = "Rock Ridge",
	alanTepe = "Hill",
	alanGolet = "Pond",
	alanCevherYatagi = "Ore Bed",
}

-- Dil.metin(dil, anahtar, ...) → çevrilmiş metin (eksikse İngilizce, o da yoksa anahtarın kendisi)
function Dil.metin(dil, anahtar, ...)
	local s = (T[dil] and T[dil][anahtar]) or T.en[anahtar] or anahtar
	if select("#", ...) > 0 then
		local ok, sonuc = pcall(string.format, s, ...)
		if ok then return sonuc end
	end
	return s
end

function Dil.kategori(dil, kat)
	if dil == "tr" then return kat end
	return Dil.KATEGORI[kat] or kat
end

function Dil.yapi(dil, ad, etiket)
	if dil == "tr" then return etiket or ad end
	return Dil.YAPI[ad] or etiket or ad
end

-- Studio arayüz dili Türkçeyse Türkçe, değilse İngilizce başla
function Dil.varsayilan()
	local ok, yerel = pcall(function()
		return game:GetService("StudioService").StudioLocaleId
	end)
	if ok and type(yerel) == "string" and yerel:lower():sub(1, 2) == "tr" then
		return "tr"
	end
	return "en"
end

-- testler için: iki dilde de aynı anahtarlar var mı
function Dil.eksikler()
	local eksik = {}
	for k in pairs(T.en) do
		if T.tr[k] == nil then table.insert(eksik, "tr:" .. k) end
	end
	for k in pairs(T.tr) do
		if T.en[k] == nil then table.insert(eksik, "en:" .. k) end
	end
	return eksik
end

return Dil
