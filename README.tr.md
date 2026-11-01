<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/art/banner-dark-tr.svg">
  <img src="docs/art/banner-light-tr.svg" width="100%" alt="Sweax Terrain: Roblox Studio'da dünya üret, sil, üstüne kur">
</picture>

[![İndir](https://img.shields.io/github/v/release/Sweax3169/sweaxterrain?label=indir&color=4C7D29&style=for-the-badge)](https://github.com/Sweax3169/sweaxterrain/releases/latest)
[![Roblox Studio eklentisi](https://img.shields.io/badge/Roblox%20Studio-eklenti-2A679A?style=for-the-badge)](#kurulum)
[![Luau](https://img.shields.io/badge/Luau-8%20mod%C3%BCl-6B7075?style=for-the-badge)](#proje-yap%C4%B1s%C4%B1)
[![Lisans](https://img.shields.io/badge/lisans-MIT-C9501F?style=for-the-badge)](LICENSE)

[Site ve canlı deneme](https://sweax3169.github.io/sweaxterrain/) · [English](README.md) · [İndir](https://github.com/Sweax3169/sweaxterrain/releases/latest)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/generate-dark.gif">
  <img src="docs/media/gif/generate-light.gif" width="760" alt="Bir Alp dünyası, eklentinin Roblox arazisine yazdığı sırayla 24'e 24 sütunluk parçalar halinde beliriyor">
</picture>

</div>

Sweax Terrain, Roblox Studio'da arazi kurmak için bir eklenti. Birbirine karışan dokuz biyomdan
göllü, nehirli, okyanus kenarlı ve mağaralı koca dünyalar üretir; araziyi fırçayla ya da iki köşe
seçerek siler; 44 hazır yapıyı ve 10 arazi alanını zemine oturan yarı saydam bir önizlemeyle tek
tıkla yerleştirir. Her adım <kbd>Ctrl</kbd> + <kbd>Z</kbd> ile geri alınır.

Panel İngilizce ve Türkçe konuşur, Studio'nun açık ya da koyu temasını izler. Hiçbir web isteği
yapmaz ve asset istemez: yapılar düz parçalardan kurulur.

## Tarayıcıda dene

[Sitede](https://sweax3169.github.io/sweaxterrain/) eklenti panelinin bir kopyası, eklentinin
Luau'dan JavaScript'e satır satır taşınmış kendi üreticisini çalıştırıyor. Roblox'un `math.noise`
fonksiyonu bit bit aynı yeniden yazıldı, yani bir tohum tarayıcıda da Studio'daki dünyanın aynısını
üretir. Orada üretebilir, fırçayı kullanabilir, bölge silebilir ve yapı kurabilirsin.

Bu kopya doğrudan Studio'yla karşılaştırılıyor: [`tools/check_generator.mjs`](tools/check_generator.mjs)
eklentinin kullandığı ayarlarla bir dünya üretip her sütunu Studio'nun yazdığı voksellerle
kıyaslar. Bu sayfa için yapılan 22 dünyada (238.848 sütun) her yüzey yüksekliği, yüzey malzemesi
ve su seviyesi aynı çıktı; en büyük yükseklik farkı 0,016 stud, yani 8 bitlik doluluk değerinin
yuvarlaması.

## Bir bakışta

<table>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-biomes-dark-tr.svg"><img src="docs/art/card-biomes-light-tr.svg" width="100%" alt="Dokuz biyom: her biri kendi yükseklik fonksiyonu, ağırlıkla karışırlar"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-worlds-dark-tr.svg"><img src="docs/art/card-worlds-light-tr.svg" width="100%" alt="Sekiz hazır dünya ve her üretimde yeni tohum"></picture></td>
</tr>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-caves-dark-tr.svg"><img src="docs/art/card-caves-light-tr.svg" width="100%" alt="Üretilmiş tepelerden mağara tünellerini gösteren gerçek bir kesit"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-erase-dark-tr.svg"><img src="docs/art/card-erase-light-tr.svg" width="100%" alt="Gerçek arazide fırça silgisi ve bölge silgisi"></picture></td>
</tr>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-structures-dark-tr.svg"><img src="docs/art/card-structures-light-tr.svg" width="100%" alt="Bir gözetleme kulesi yarı saydam iner ve katılaşır"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-undo-dark-tr.svg"><img src="docs/art/card-undo-light-tr.svg" width="100%" alt="Ctrl+Z silinen araziyi geri getirir"></picture></td>
</tr>
</table>

Bu sayfadaki her görsel eklentinin gerçek çıktısı. Arazi ve yapılar Roblox Studio'da üretildi,
voksel voksel ve parça parça geri okundu ve Blender ile çizildi; panel görüntüleri Studio'nun kendi
ekran yakalaması. Bunu yapan betikler [`tools/`](tools) klasöründe.

## Başlamak için sekiz dünya

Hazır dünya bir dizi biyomu açar, suyu ve detayı senin yerine ayarlar. Paneldeki geri kalan her şey
senin elinde ve **Dünyayı üret**'e her basış yeni bir tohum getirir.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/worlds-dark.gif">
    <img src="docs/media/gif/worlds-light.gif" width="680" alt="Sekiz hazır dünya art arda">
  </picture>
</p>

<table>
<tr>
<td align="center" width="25%"><img src="docs/media/world-alp.webp" alt="Alp"><br><b>Alp</b><br><sub>dağ, tepe, ova, göl · kar çizgisi 0,56 · tohum 8927</sub></td>
<td align="center" width="25%"><img src="docs/media/world-nehir.webp" alt="Nehirli ova"><br><b>Nehirli ova</b><br><sub>ova, tepe, göl, iki nehir · tohum 314159</sub></td>
<td align="center" width="25%"><img src="docs/media/world-kanyon.webp" alt="Çöl kanyonu"><br><b>Çöl kanyonu</b><br><sub>kanyon, kumul, plato · teraslama 0,35 · tohum 77001</sub></td>
<td align="center" width="25%"><img src="docs/media/world-volkan.webp" alt="Volkanik"><br><b>Volkanik</b><br><sub>volkan, dağ, mağara · tohum 40404</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/world-arktik.webp" alt="Arktik"><br><b>Arktik</b><br><sub>arktik, dağ, donmuş göl · kar çizgisi 0,30 · tohum 23571</sub></td>
<td align="center"><img src="docs/media/world-bataklik.webp" alt="Bataklık"><br><b>Bataklık</b><br><sub>bataklık, ova, göl, nehir · tohum 662607</sub></td>
<td align="center"><img src="docs/media/world-sahil.webp" alt="Sahil"><br><b>Sahil</b><br><sub>ova, tepe, kumul, göl, okyanus kenarı · tohum 141421</sub></td>
<td align="center"><img src="docs/media/world-karisik.webp" alt="Karışık"><br><b>Karışık</b><br><sub>rastgele biyomlar ve ağırlıklar · tohum 299792</sub></td>
</tr>
</table>

Bu tablodaki tohumu panele yaz, ayarlara dokunma: aynı dünya gelir.

## Dokuz biyom

Her biyom ayrı bir yükseklik fonksiyonu. Birkaçı açıkken her biyomun düşük frekanslı bir maskesi
nerede hüküm süreceğine karar verir; maskelerin küpü alınır, böylece bölgeler net ayrışır ama
kenarlarda birbirine akar. Biyomun ağırlığı maskesini ölçekler: ağırlık arttıkça daha çok yer kaplar.

<table>
<tr>
<td align="center" width="33%"><img src="docs/media/biome-ova.webp" alt="Ovalar"><br><b>Ovalar</b><br><sub>Alçak, yumuşak zemin. Yaprak lekeli çim.</sub></td>
<td align="center" width="33%"><img src="docs/media/biome-tepe.webp" alt="Tepeler"><br><b>Tepeler</b><br><sub>Dalgalı tepeler; yamaç dikleşince kaya görünür.</sub></td>
<td align="center" width="33%"><img src="docs/media/biome-dag.webp" alt="Dağlar"><br><b>Dağlar</b><br><sub>Sırtlı gürültünün karesi. Kar çizgisinin üstü kar.</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/biome-plato.webp" alt="Platolar"><br><b>Platolar</b><br><sub>Aralarında kısa rampalar olan düz basamaklar.</sub></td>
<td align="center"><img src="docs/media/biome-kanyon.webp" alt="Kanyonlar"><br><b>Kanyonlar</b><br><sub>Teraslı, kıvrılan yarıklarla kesilmiş kuru plato.</sub></td>
<td align="center"><img src="docs/media/biome-volkan.webp" alt="Volkanik"><br><b>Volkanik</b><br><sub>Ayrı ayrı koniler; her birinin tepesinde krater ve lav gölü.</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/biome-col.webp" alt="Çöl kumulları"><br><b>Çöl kumulları</b><br><sub>Kum ve kumtaşında uzun kumul dalgaları.</sub></td>
<td align="center"><img src="docs/media/biome-arktik.webp" alt="Arktik"><br><b>Arktik</b><br><sub>U biçimli buzul vadileri. Göller donar.</sub></td>
<td align="center"><img src="docs/media/biome-bataklik.webp" alt="Bataklık"><br><b>Bataklık</b><br><sub>Su seviyesinin hemen altında gezinen zemin: çamur ve gölcükler.</sub></td>
</tr>
</table>

## Su ve mağaralar

<table>
<tr>
<td width="33%"><img src="docs/media/world-nehir.webp" alt="Nehirler"><br><b>Göller ve nehirler</b><br><sub>Göller yalnız alçak zemine kazılır. Beşe kadar nehir, her birinin kendi genişliği ve kıvrımıyla. Kumlu kıyılar yalnız gerçek su olan yerde, ayarladığın kumsal genişliği kadar oluşur.</sub></td>
<td width="33%"><img src="docs/media/world-sahil.webp" alt="Okyanus kenarı"><br><b>Okyanus kenarı</b><br><sub>Batı, doğu, kuzey ya da güney. Kara o yönde alanın %38'i boyunca denize iner, kıyı boyunca kumsal oluşur.</sub></td>
<td width="33%"><img src="docs/media/caves.webp" alt="Mağaralar"><br><b>Mağaralar</b><br><sub>İki 3B gürültü alanının ikisinin de sıfırdan geçtiği yerde, yüzeyin en az 6 stud altında solucan tüneller. Görünsünler diye burada kesilerek açıldı.</sub></td>
</tr>
</table>

Volkanik biyomda su lava döner, arktik göllerin üstü buzla kapanır.

## Silme

Silgi haritadaki her araziyi siler, yalnız Sweax Terrain'in yaptığını değil.

<table>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/erase-dark.gif"><img src="docs/media/gif/erase-light.gif" width="100%" alt="Kırmızı fırça küresi nehirli ovada bir yol oyuyor"></picture><br><b>Fırça.</b> Fırçayı aç, sahnede tıkla ya da sürükle. Kırmızı küre boyutunu gösterir (yarıçap 4 ile 80 stud); bir sürükleme tek bir geri alma adımıdır.</td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/region-dark.gif"><img src="docs/media/gif/region-light.gif" width="100%" alt="İki köşe seçiliyor, aralarında kırmızı bir kutu büyüyor ve içindeki arazi gidiyor"></picture><br><b>Bölge.</b> İki köşeye tıkla, sonra <b>Seçimi sil</b>. Kutu köşelerin üstüne ve altına dikey pay kadar uzanır (10 ile 200 stud).</td>
</tr>
</table>

**Son üretilen bölgeyi sil** son üretimin yaptığını temizler. **Bu haritadaki tüm araziyi sil** beş
saniye içinde ikinci bir tıklama ister. Hepsi <kbd>Ctrl</kbd> + <kbd>Z</kbd> ile geri gelir.

## Yapılar ve arazi alanları

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/structures-dark.gif">
    <img src="docs/media/gif/structures-light.gif" width="760" alt="Üretilmiş tepelere on yapı tek tek kuruluyor, her biri önce yarı saydam önizleme olarak">
  </picture>
</p>

Bir yapı seç, sonra **Tıklayarak kur**: yarı saydam bir önizleme fareyi izler ve **Zemine otur**
açıkken altındaki araziye oturur. Kurmak için tıkla; <kbd>Shift</kbd> + tık önce 45° çevirir.
**Kameranın önüne kur** baktığın yere bir tane bırakır.

Her kurulum kendi tohumunu alır, iki gözetleme kulesi hiçbir zaman tıpatıp aynı olmaz; birini geri
almak için tohumunu yaz. **Yosun** taşa yamalar ekler, **Yıkıklık** gevşek blokları kaydırır,
eğer ve düşürür, **Ölçek** 0,4× ile 3× arası, **Işıklar** meşale ve fenerleri açar ya da kapatır.
Yapılar Workspace'te `SweaxYapilar` klasörüne gider; her biri `SweaxStructure` ve `SweaxSeed`
nitelikli bir modeldir. **Sonuncuyu geri al** ve **Tüm yapıları sil** ızgaranın altında.

Arazi alanları farklı: tıkladığın yerde araziyi oyar ya da yükseltir (taş ocağı çukuru, plato,
mağara ağzı, gölet...), bu yüzden önizlemeleri yoktur.

<details>
<summary><b>54'ünün hepsi</b></summary>
<br>

<table>
<tr><td align="center" width="16%"><img src="docs/media/structures/kademeliKaide.webp" width="110" alt="Kademeli Kaide"><br><sub><b>Kademeli Kaide</b><br>Mimari</sub></td><td align="center" width="16%"><img src="docs/media/structures/heykelKaidesi.webp" width="110" alt="Madenci Heykeli"><br><sub><b>Madenci Heykeli</b><br>Mimari</sub></td><td align="center" width="16%"><img src="docs/media/structures/taskemer.webp" width="110" alt="Taş Kemer"><br><sub><b>Taş Kemer</b><br>Mimari</sub></td><td align="center" width="16%"><img src="docs/media/structures/sutunlar.webp" width="110" alt="Kırık Sütunlar"><br><sub><b>Kırık Sütunlar</b><br>Kalıntı</sub></td><td align="center" width="16%"><img src="docs/media/structures/kalintiDuvar.webp" width="110" alt="Kalıntı Duvar"><br><sub><b>Kalıntı Duvar</b><br>Kalıntı</sub></td><td align="center" width="16%"><img src="docs/media/structures/merdivenSeti.webp" width="110" alt="Taş Merdiven"><br><sub><b>Taş Merdiven</b><br>Mimari</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/dikiliTaslar.webp" width="110" alt="Dikili Taşlar"><br><sub><b>Dikili Taşlar</b><br>Kalıntı</sub></td><td align="center" width="16%"><img src="docs/media/structures/gozetlemeKulesi.webp" width="110" alt="Gözetleme Kulesi"><br><sub><b>Gözetleme Kulesi</b><br>Mimari</sub></td><td align="center" width="16%"><img src="docs/media/structures/taskopru.webp" width="110" alt="Taş Köprü"><br><sub><b>Taş Köprü</b><br>Mimari</sub></td><td align="center" width="16%"><img src="docs/media/structures/suKanali.webp" width="110" alt="Su Kanalı"><br><sub><b>Su Kanalı</b><br>Su</sub></td><td align="center" width="16%"><img src="docs/media/structures/kayaOlusum.webp" width="110" alt="Kaya Oluşumu"><br><sub><b>Kaya Oluşumu</b><br>Doğa</sub></td><td align="center" width="16%"><img src="docs/media/structures/avluDuvari.webp" width="110" alt="Avlu Duvarı"><br><sub><b>Avlu Duvarı</b><br>Mimari</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/meydanZemini.webp" width="110" alt="Meydan Zemini"><br><sub><b>Meydan Zemini</b><br>Zemin</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenGirisi.webp" width="110" alt="Maden Girişi"><br><sub><b>Maden Girişi</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenTuneli.webp" width="110" alt="Maden Tüneli"><br><sub><b>Maden Tüneli</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/vincKulesi.webp" width="110" alt="Vinç Kulesi"><br><sub><b>Vinç Kulesi</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/rayHatti.webp" width="110" alt="Ray Hattı"><br><sub><b>Ray Hattı</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/cevherVagonu.webp" width="110" alt="Cevher Vagonu"><br><sub><b>Cevher Vagonu</b><br>Maden</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/cevherDamari.webp" width="110" alt="Cevher Damarı"><br><sub><b>Cevher Damarı</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/kuyuAgzi.webp" width="110" alt="Kuyu Ağzı"><br><sub><b>Kuyu Ağzı</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenciKampi.webp" width="110" alt="Madenci Kampı"><br><sub><b>Madenci Kampı</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/cevherDeposu.webp" width="110" alt="Cevher Deposu"><br><sub><b>Cevher Deposu</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/konveyorIskele.webp" width="110" alt="Konveyör İskelesi"><br><sub><b>Konveyör İskelesi</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/eritmeOcagi.webp" width="110" alt="Eritme Ocağı"><br><sub><b>Eritme Ocağı</b><br>Maden</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/cevherYigini.webp" width="110" alt="Cevher Yığını"><br><sub><b>Cevher Yığını</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/asansorKulesi.webp" width="110" alt="Asansör Kulesi"><br><sub><b>Asansör Kulesi</b><br>Maden</sub></td><td align="center" width="16%"><img src="docs/media/structures/susMesale.webp" width="110" alt="Meşale"><br><sub><b>Meşale</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susFener.webp" width="110" alt="Fener Direği"><br><sub><b>Fener Direği</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susSandik.webp" width="110" alt="Sandık İstifi"><br><sub><b>Sandık İstifi</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susVaril.webp" width="110" alt="Variller"><br><sub><b>Variller</b><br>Süs</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susDestek.webp" width="110" alt="Ahşap Destek"><br><sub><b>Ahşap Destek</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susIskele.webp" width="110" alt="İskele"><br><sub><b>İskele</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCevherYigin.webp" width="110" alt="Cevher Yığını"><br><sub><b>Cevher Yığını</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susMoloz.webp" width="110" alt="Moloz Yığını"><br><sub><b>Moloz Yığını</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susKampAtesi.webp" width="110" alt="Kamp Ateşi"><br><sub><b>Kamp Ateşi</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susAletStandi.webp" width="110" alt="Alet Standı"><br><sub><b>Alet Standı</b><br>Süs</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susTabela.webp" width="110" alt="Tabela"><br><sub><b>Tabela</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCadir.webp" width="110" alt="Çadır"><br><sub><b>Çadır</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCit.webp" width="110" alt="Çit Hattı"><br><sub><b>Çit Hattı</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susDinamit.webp" width="110" alt="Dinamit Sandığı"><br><sub><b>Dinamit Sandığı</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susSuOlugu.webp" width="110" alt="Su Oluğu"><br><sub><b>Su Oluğu</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susOdun.webp" width="110" alt="Odun Yığını"><br><sub><b>Odun Yığını</b><br>Süs</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susElArabasi.webp" width="110" alt="El Arabası"><br><sub><b>El Arabası</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/susBayrak.webp" width="110" alt="Bayrak Direği"><br><sub><b>Bayrak Direği</b><br>Süs</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanDuzle.webp" width="110" alt="Düzle"><br><sub><b>Düzle</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTemizle.webp" width="110" alt="Temizle"><br><sub><b>Temizle</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanPlato.webp" width="110" alt="Maden Platosu"><br><sub><b>Maden Platosu</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTasOcagi.webp" width="110" alt="Taş Ocağı Çukuru"><br><sub><b>Taş Ocağı Çukuru</b><br>Alan</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/alanKanyon.webp" width="110" alt="Kanyon Yarığı"><br><sub><b>Kanyon Yarığı</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanMagaraAgzi.webp" width="110" alt="Mağara Ağzı"><br><sub><b>Mağara Ağzı</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanKayaSirti.webp" width="110" alt="Kaya Sırtı"><br><sub><b>Kaya Sırtı</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTepe.webp" width="110" alt="Tepe"><br><sub><b>Tepe</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanGolet.webp" width="110" alt="Gölet"><br><sub><b>Gölet</b><br>Alan</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanCevherYatagi.webp" width="110" alt="Cevher Yatağı"><br><sub><b>Cevher Yatağı</b><br>Alan</sub></td></tr>
</table>

</details>

## Panel

Panelin gerçek Studio yakalamaları: Üret (sekmenin üstü ve üretim sırasında altı), Sil ve Yapılar.

<table>
<tr>
<td width="25%"><img src="docs/media/panel-generate-tr.png" alt="Üret sekmesi: hazır dünyalar, bölge, çekirdek ve biyomlar"></td>
<td width="25%"><img src="docs/media/panel-generate-bottom-tr.png" alt="Üretim sırasında Üret sekmesi: şekil, su, mağaralar ve ilerleme çubuğu"></td>
<td width="25%"><img src="docs/media/panel-erase-tr.png" alt="Sil sekmesi: fırça, bölge ve toptan silme düğmeleri"></td>
<td width="25%"><img src="docs/media/panel-structures-tr.png" alt="Yapılar sekmesi: kategori süzgeçleri, yapı ızgarası ve kurulum ayarları"></td>
</tr>
</table>

Araç çubuğu düğmesi her yere yerleştirebileceğin yüzen bir panel açar. Üstteki **EN · TR** dili
değiştirir; ilk açılışta Studio'nun kendi dilini izler. Alttaki durum satırı her sekmede sıradaki
adımı söyler.

## Kurulum

1. Son sürümden [`SweaxTerrain.rbxmx`](https://github.com/Sweax3169/sweaxterrain/releases/latest/download/SweaxTerrain.rbxmx) dosyasını indir.
2. Studio eklenti klasörüne koy. Studio'da: **Plugins** sekmesi → **Plugins Folder**.
   - Windows: `%LOCALAPPDATA%\Roblox\Plugins`
   - macOS: `~/Documents/Roblox/Plugins`
3. Roblox Studio'yu kapatıp aç.
4. **Plugins** sekmesinde **Sweax Terrain**'e tıkla.

Güncellemek için dosyayı değiştirip Studio'yu yeniden aç. Kaldırmak için dosyayı sil.

Her sürüm dosyanın SHA-256 değerini `SHA256SUMS.txt` içinde verir. Windows'ta:

```powershell
Get-FileHash SweaxTerrain.rbxmx -Algorithm SHA256
```

### Kaynaktan derleme

Eklenti [`src/`](src) içinde düz Luau. Python 3 onu tek bir `.rbxmx` dosyasına paketler:

```bash
python tools/build.py
```

```bash
python tools/build.py --install
```

Birincisi `dist/SweaxTerrain.rbxmx` yazar; ikincisi onu eklenti klasörüne de kopyalar.

## Kullanım

**Üret.** Hazır bir dünya seç ya da biyomları kendin işaretle, dünya baktığın yere gelsin diye
**Merkezi kameranın önüne al**'a bas, sonra **Dünyayı üret**. Vokseller yazılırken ilerleme çubuğu
akar, **İptal** durdurur. Beğenmedin mi? <kbd>Ctrl</kbd> + <kbd>Z</kbd>, ya da yeni bir tohum için
**Dünyayı üret**'e yine bas.

<details>
<summary><b>Bütün ayarlar</b></summary>
<br>

| Grup | Ayar | Aralık | Varsayılan |
| --- | --- | --- | --- |
| Bölge | Genişlik (X), Derinlik (Z) | 128 – 2048 stud, 32'lik adım | 512 |
| | Merkez X · Y · Z | herhangi; Y taban yüksekliği | 0 · 40 · 0 |
| Çekirdek | Çekirdek | herhangi bir tam sayı; 🎲 rastgele atar | 618033988 |
| | Her üretimde yeni çekirdek | açık / kapalı | açık |
| Biyomlar | Ovalar · Tepeler · Dağlar | açık / kapalı, ağırlık 0,05 – 1 | açık · 0,8 · 0,7 · 0,9 |
| | Platolar · Kanyonlar · Volkanik · Çöl kumulları · Arktik · Bataklık | açık / kapalı, ağırlık 0,05 – 1 | kapalı |
| Şekil | Yükseklik ölçeği | 0,3 – 2,5 | 1,0 |
| | Pürüz | 0 – 1 | 0,5 |
| | Akışkanlık (warp) | 0 – 1 | 0,5 |
| | Teraslama | 0 – 1 | 0 |
| | Biyom bölge boyutu | 120 – 900 stud | 320 |
| Su | Su seviyesi (tabandan) | −10 – 20 stud | 0 |
| | Göller · yoğunluk · derinlik · kumsal genişliği | açık / kapalı · 0 – 1 · 3 – 30 · 0 – 16 stud | açık · 0,5 · 10 · 6 |
| | Nehirler · sayı · genişlik · kıvrım | açık / kapalı · 1 – 5 · 6 – 40 stud · 0 – 1 | kapalı · 2 · 14 · 0,6 |
| | Okyanus kenarı · yön | açık / kapalı · batı, doğu, kuzey, güney | kapalı · batı |
| Mağara ve detay | Mağaralar · yoğunluk · boyut | açık / kapalı · 0 – 1 · 0 – 1 | kapalı · 0,5 · 0,5 |
| | Kaya çıkıntıları | 0 – 1 | 0,35 |
| | Yüzey benekleri | 0 – 1 | 0,6 |
| | Kar çizgisi (alçak = karlı) | 0,1 – 1 | 0,72 |
| Sil | Fırça yarıçapı | 4 – 80 stud | 16 |
| | Dikey pay (±) | 10 – 200 stud | 80 |
| Yapılar | Ölçek · Yosun · Yıkıklık | 0,4 – 3 · 0 – 1 · 0 – 1 | 1 · 0,5 · 0,35 |
| | Dönüş | 0° – 315°, 45°'lik adım | 0° |
| | Işıklar · Zemine otur · Her kurulumda yeni tohum | açık / kapalı | açık · açık · açık |

Hazır dünya önce dünya ayarlarını (biyom, şekil, su, mağara, detay) varsayılana döndürür, sonra
kendi değerlerini yazar; bölge, merkez, çekirdek, silgi ve yapı ayarlarına dokunmaz.

</details>

**Hız.** Studio'da Ryzen 5 7600 üzerinde 512 × 512'lik dünya 0,30 sn, 1024 × 1024 0,95 sn,
2048 × 2048 3,6 sn sürüyor (Alp, `os.clock` ile ölçüldü).

## Nasıl çalışır

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/art/architecture-dark-tr.svg">
  <img src="docs/art/architecture-light-tr.svg" width="100%" alt="Mimari: panel, iki geçişli üretici, araçlar ve yapı kütüphanesi; workspace.Terrain ve workspace.SweaxYapilar'a yazarlar">
</picture>

1. Alan, Roblox arazi vokseli boyunda 4 studluk sütunlara bölünür. Köşe voksel ızgarasına
   oturtulur; böylece `WriteVoxels` her zaman tam beklediği boyutta diziler alır.
2. **Birinci geçiş, yükseklik haritası.** Her sütunun koordinatı domain warp ile (iki fBm alanı)
   bükülür, açık her biyom bir yükseklik verir ve küpü alınmış biyom maskeleri bunları karıştırır.
   Yükseklik ölçeği, pürüz ve teraslama uygulanır, sonra göller (yalnız alçak zeminde), nehirler ve
   okyanus kenarı oyar.
3. **Kumsallar.** Su seviyesinin altındaki sütunlar kumsal genişliği kadar genişletilir, böylece kum
   yalnız karanın gerçek suyla buluştuğu yere gelir.
4. **İkinci geçiş, vokseller.** Her vokselin malzemesi biyomun takımından (yüzey, yamaç, derin,
   benek), kar çizgisinden, kumsallardan ve volkanın lav göllerinden gelir; kaya çıkıntıları ve
   mağaralar doluluğu 3B gürültüyle büker. Dünya 24 × 24 sütunluk parçalar halinde yazılır; aralarda
   ilerleme çubuğu ilerler ve **İptal** denetlenir.
5. **Geri alma.** Üretim, her fırça darbesi, bölge silme ve yerleştirme bir `ChangeHistoryService`
   noktasıyla biter; <kbd>Ctrl</kbd> + <kbd>Z</kbd> Studio'daki her şeyde olduğu gibi çalışır.

Tohumlar gürültüyü kaydırmadan önce karıştırılır (`tohum × 7919 mod 100000`), böylece 571 ve 572
gibi komşu tohumlar birbirine hiç benzemeyen dünyalar verir. Üreticideki her rastgelelik `Random`'dan
değil `math.noise`'dan gelir; site bir dünyayı bu sayede birebir yeniden üretebiliyor.

## Proje yapısı

```
src/
  Ana.server.lua     araç çubuğu düğmesi, panel penceresi, fırça / bölge / kurulum araçları, geri alma noktaları
  Arayuz.lua         panel: sekmeler, kaydırıcılar, hazır dünyalar, tema renkleri, EN · TR
  Dil.lua            bütün İngilizce ve Türkçe metinler, yapı ve kategori adları
  Uretici.lua        üretici: biyomlar, su, kumsallar, malzemeler, mağaralar, WriteVoxels
  Yapilar.lua        yapı kütüphanesi dizini, yerleştirme, zemine oturtma, geri alma yığını
  YapiTemel.lua      13 mimari, kalıntı, su, doğa ve zemin parçası
  YapiMaden.lua      13 maden yapısı
  YapiSus.lua        18 süs ve eşya
  YapiAlan.lua       araziyi oyan ya da yükselten 10 arazi alanı
tools/
  build.py           src/'yi dist/SweaxTerrain.rbxmx'e paketler (--install Studio'ya kopyalar)
  bridge.py          Studio ile bu klasör arasında yerel HTTP köprüsü (yalnız 127.0.0.1)
  studio_dump.lua    köprü üzerinden Studio'dan arazi voksellerini ve parça modellerini okur
  check_generator.mjs, check_noise.mjs   JavaScript kopyasını Studio dökümleriyle karşılaştırır
  render_blender.py  dökümleri Blender ile çizer (voksel doluluğu üstünde surface nets)
  art_jobs.py, art.py, svgart.py, render_map.py, site_data.py, voxels.py   README ve site görselleri
docs/                site (GitHub Pages): js/noise.js, js/generator.js, js/view.js, js/panel.js
```

## Sorular

**Var olan arazime dokunur mu?** Üretim yalnız belirlediğin alanı, yeni arazinin 60 stud altından
220 stud üstüne kadar bir bantta temizleyip yeniden yazar. Silgi yalnız gösterdiğin yeri siler.
İkisini de <kbd>Ctrl</kbd> + <kbd>Z</kbd> geri alır.

**HTTP ya da asset gerekiyor mu?** Hayır. Hiçbir web isteği yapmaz ve yapılar düz parçalardan oluşur.

**Paylaşabilir miyim?** Evet, `.rbxmx` dosyasını ya da bu sayfanın bağlantısını gönder. MIT lisanslı.

**Kurulan yapıların Explorer'daki adı ne?** Panelin dilindeki adı (Türkçede Gözetleme Kulesi,
İngilizcede Watchtower). İç ad `SweaxStructure` niteliğinde durur.

## Lisans

[MIT](LICENSE) © 2026 Sweax Studios
