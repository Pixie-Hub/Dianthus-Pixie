# Dianthus Pixie

## Game Design Document

A 2D Survival Crafting Action Game

> Engine: Godot   |   Style: 2D Pixel Art (Aseprite)   |   Version 1.1
> 

---

# **1. Pitch**

Dianthus Alchemist adalah game 2D survival crafting action di mana pemain berperan sebagai seorang alkemis tanaman yang bertugas menjaga kebun Dianthus, sebuah tanaman misterius yang menarik makhluk kegelapan setiap malam. Pemain akan menjelajah lingkungan untuk mengumpulkan sumber daya, melakukan eksperimen tanaman untuk menciptakan senjata dan kemampuan baru, serta bertahan dari serangan musuh di malam hari melalui sistem pertarungan real-time yang dikombinasikan dengan mekanik pertahanan kebun.

# **2. High Concept**

Dianthus Alchemist merupakan game survival crafting berbasis day-night cycle yang berfokus pada eksplorasi, eksperimen tanaman, dan pertahanan strategis. Pemain berperan sebagai alkemis yang memanfaatkan tanaman, khususnya Dianthus, sebagai sumber kekuatan utama dalam bertahan hidup.

Permainan terbagi menjadi dua fase waktu:

- Pagi - Sore — eksplorasi, pengumpulan resource, crafting, dan cross-breeding tanaman
- Malam — pertahanan kebun dari gelombang musuh (FSM-based AI)

# **3. Main Story**

Dianthus adalah tanaman langka yang memiliki energi kehidupan tinggi dan kemampuan untuk berinteraksi dengan lingkungan sekitarnya. Namun, energi tersebut juga menarik makhluk dari dunia kegelapan yang berusaha menghancurkannya.

Pemain berperan sebagai seorang alkemis yang menemukan kebun Dianthus dan memutuskan untuk merawat serta melindunginya. Seiring berjalannya waktu, pemain menemukan bahwa dengan menggabungkan Dianthus dengan tanaman lain, mereka dapat menciptakan senjata dan kemampuan baru. Konflik utama permainan terletak pada upaya pemain untuk bertahan hidup dan mengungkap potensi sebenarnya dari Dianthus, sambil menghadapi ancaman yang semakin besar setiap malam.

# **4. Game Loop**

1. Pemain menjelajah area pada siang hari untuk mengumpulkan resource dan tanaman baru
2. Pemain kembali ke kebun untuk melakukan crafting dan eksperimen tanaman
3. Pemain menyiapkan strategi pertahanan sebelum malam tiba
4. Musuh menyerang dalam bentuk gelombang pada malam hari
5. Pemain bisa bertarung secara langsung sambil mempertahankan kebun
6. Setelah malam selesai, pemain memperoleh reward berupa resource
7. Tingkat kesulitan meningkat seiring bertambahnya hari
8. Masuk ke hari selanjutnya — loop kembali ke tahap eksplorasi

# **5. Defeat & Win Conditions**

## **5.1 Defeat Conditions**

Permainan berakhir (Game Over) dalam kondisi berikut:

- **Dianthus Core Health mencapai 0 — game over langsung, tanpa grace period. Layar akhir menampilkan hari yang dicapai dan pilihan untuk restart atau kembali ke menu.**
    - Tidak ada last-stand mechanic — hilangnya Dianthus Core bersifat permanen per sesi.
    - Pemain disarankan memprioritaskan perlindungan Dianthus di atas keselamatan karakter sendiri.
- **Gagal menyelesaikan Critical Story Quest — beberapa quest cerita bersifat wajib dan memiliki batas waktu tertentu. Kegagalannya memicu ending alternatif, bukan game over langsung.**

### **Death Mechanic (Player Character)**

Kematian karakter pemain TIDAK langsung mengakhiri permainan:

- Pemain respawn setelah 5 detik di dekat Dianthus Core
- Saat respawn, pemain kehilangan 25% energi yang tersimpan
- Item yang diequip tetap tersimpan — resource tidak hilang
- Jika pemain mati 3+ kali dalam satu malam tanpa mengalahkan musuh, Dianthus Core akan menerima bonus damage sebesar 10% dari total serangan malam itu

## **5.2 Win Conditions**

Permainan memiliki tiga jalur penyelesaian:

| **Ending** | **Kondisi** | **Deskripsi** |
| --- | --- | --- |
| True Ending | Unlock potensi penuh Dianthus (Hari 30+) | Pemain mengungkap rahasia Dianthus, mengalahkan The Devourer, dan membebaskan kebun dari kegelapan |
| Survival Ending | Bertahan hingga Hari 20 tanpa mengungkap Dianthus | Pemain bertahan tetapi kebun tetap terancam — cerita terbuka |
| Discovery Ending | Menyelesaikan semua Discovery Quest | Pemain memahami seluruh sistem tanaman — Dianthus berkembang menjadi makhluk hidup |

### **Endless / Post-Game Mode**

Setelah menyelesaikan True Ending, mode Endless terbuka. Tidak ada target hari, kesulitan terus meningkat secara eksponensial, dan pemain bisa bersaing via leaderboard lokal berdasarkan hari yang dicapai.

# **6. Resource System**

## **6.1 Resource Types**

| **Nama** | **Sumber** | **Rarity** | **Digunakan untuk** |
| --- | --- | --- | --- |
| Petal Shard | Forage / drop tanaman biasa | Common | Crafting senjata dasar, cross-breeding |
| Verdant Sap | Pohon, semak — diekstrak manual | Common | Upgrade senjata, crafting traps |
| Moonspore | Muncul malam hari di area tertentu | Uncommon | Crafting skill aktif, breeding khusus |
| Shadow Resin | Drop dari musuh elite | Uncommon | Crafting pertahanan, upgrade Dianthus |
| Aether Bloom | Reward quest, chest tersembunyi | Rare | Resep langka, upgrade Dianthus Core |
| Dianthus Pollen | Khusus dari Dianthus Core (diambil 1x/hari) | Rare | Semua resep Dianthus hybrid |

## **6.2 Inventory**

- Pemain memiliki 30 slot inventory (tidak berbasis berat)
- Resource tidak expire atau membusuk
- Stack maksimal per slot: 99 unit untuk Common, 20 unit untuk Uncommon, 5 unit untuk Rare
- Slot inventory bisa ditambah hingga 60 slot melalui upgrade Garden Storage

## **6.3 Economy & Scarcity**

- Resource tidak bisa diperdagangkan antar pemain (single player)
- Pada kematian, resource tidak hilang — hanya energi yang berkurang
- Scarcity meningkat secara gradual: Common tetap mudah ditemukan, Uncommon dan Rare semakin langka setiap 5 hari
- Reward malam memberikan 3-5 Common resource dan 1 Uncommon setiap wave yang berhasil dipertahankan

# **7. Plant & Crafting System**

## **7.1 Plant Catalogue (Initial)**

| **Nama Tanaman** | **Role** | **Efek Dasar** | **Unlock** |
| --- | --- | --- | --- |
| Dianthus | Hybrid (Core) | Sumber energi utama, memancarkan aura pertahanan | Tersedia dari awal |
| Bougainvillea | Offensive | Duri yang melukai musuh dalam radius (5 DMG/tick, 24px) | Tersedia dari awal |
| Rafflesia | Defensive | Miasma busuk yang memperlambat musuh dalam radius (0.6×, 40px) | Hari 2, forage |
| Melati | Support | Meregenerasi energi pemain secara pasif saat di dekatnya (+3/sec, 32px) | Hari 3, quest |
| Wijaya Kusuma | Offensive | Menyerang otomatis musuh di malam hari dengan proyektil petal (8 DMG, 48px) | Hari 4, breeding |
| Beringin | Defensive | Menumbuhkan tembok akar hidup sementara di jalur musuh (Wall HP: 60, 20s) | Hari 5, craft |
| Kecombrang | Support | Boost attack speed pemain +20% selama 15s saat diaktifkan (28px) | Hari 7, rare forage |
| Kunyit | Hybrid | Memperkuat senjata melee (+3 DMG, penetrasi armor) dalam radius (24px) | Discovery Quest |

## **7.2 Cross-Breeding Rules**

Sistem cross-breeding bersifat semi-deterministik:

- Kombinasi spesifik SELALU menghasilkan tanaman yang sama (deterministik)
- Kualitas hasil (biasa / superior / masterwork) ditentukan oleh performa minigame saat eksperimen
- Kombinasi yang belum diketahui pemain menghasilkan hasil acak — bisa berhasil atau gagal

### **Failure States**

- Kegagalan ringan: menghasilkan Wilted Plant (tanaman lemah, efek 50%)
- Kegagalan berat: resource terbuang, tidak ada hasil — dipicu saat minigame skor < 30%
- Total kombinasi yang direncanakan: 24 kombinasi unik

### **Contoh Kombinasi**

| **Plant A** | **Plant B** | **Hasil** |
| --- | --- | --- |
| Bougainvillea | Kecombrang | Bunga Api (duri + api AoE, 7 DMG/tick + 3 burn DMG) |
| Rafflesia | Wijaya Kusuma | Bunga Bayang (slow + night auto-attack area, 4 DMG, 0.7× slow) |
| Melati | Dianthus Pollen | Melati Emas (regenerasi HP +2/sec + energi +4/sec) |
| Kunyit | Shadow Resin | Baja Kuning (armor buff +30% + counter-attack 25% reflect) |

## **7.3 Crafting Recipes**

| **Senjata** | **Material** | **Crafting Time** | **Upgrade Path** |
| --- | --- | --- | --- |
| Thorn Sword | 3x Petal Shard + 2x Bougainvillea extract | Instan | Thorn Sword > Blazeblade (+ Kecombrang) |
| Spore Bomb | 2x Moonspore + 1x Rafflesia | Instan | Spore Bomb > Void Grenade (+ Shadow Resin) |
| Vine Whip | 4x Verdant Sap + 1x Bougainvillea | Instan | Vine Whip > Crystal Lash (+ Kunyit) |
| Petal Shield | 5x Petal Shard + 2x Beringin root | Instan | Petal Shield > Iron Bloom Shield (+ Shadow Resin) |

## **7.4 Plant Placement (Defense Phase)**

- Sistem penempatan berbasis grid (16x16 px per tile)
- Pemain menempatkan tanaman selama Preparation Phase, bukan saat malam berjalan
- Tanaman bisa dihancurkan musuh — dapat ditanam ulang di siang berikutnya
- Maksimal 8 tanaman aktif di kebun secara bersamaan
- Tiap jenis tanaman memiliki radius efek visualisasi saat placement mode

# **8. Enemy Roster & Difficulty Scaling**

## **8.1 Enemy Archetypes**

| **Nama** | **HP** | **Kecepatan** | **Damage** | **FSM Quirk** | **Kelemahan** | **Muncul Hari** |
| --- | --- | --- | --- | --- | --- | --- |
| Shadowling | 40 | Sedang | 8/hit | Standard FSM | Melati, Kecombrang | Hari 1 |
| Voidrunner | 25 | Sangat Cepat | 5/hit | Skip Scouting — langsung Rush | Slow trap, Rafflesia | Hari 2 |
| Stonehusk | 120 | Lambat | 20/hit | Tidak retreat — terus Siege sampai mati | Vine Whip, Crystal Lash | Hari 4 |
| Phantom Weaver | 60 | Cepat | 12/hit | Teleport saat HP < 30%, re-Scout ulang | Wijaya Kusuma, cahaya area | Hari 6 |
| Swarm Larva | 15 per unit | Cepat | 3/hit | Bergerak 5-10 unit sekaligus | AoE weapon (Spore Bomb / Rafflesia) | Hari 8 |
| The Devourer | 1200 (Boss) | Lambat-Sedang | 50/hit | Boss unik — 3 fase, memanggil minion | Dianthus Pollen weapon | Final Night |

## **8.2 Difficulty Scaling**

- Hari 1-5 (Early): HP musuh +5% per hari, spawn count +1 per wave
- Hari 6-14 (Mid): HP +8% per hari, spawn +2, kecepatan spawn +10%, enemy baru muncul
- Hari 15-29 (Late): HP +12% per hari, multi-wave per malam, campuran enemy types
- Hari 30+ (Endless): Scaling eksponensial — x1.5 HP dan damage tiap 5 hari

### **Spike Nights (Boss Waves)**

- Setiap malam ke-7: wave khusus 'Surge Night' — jumlah musuh 3x normal, semua enemy satu tier lebih kuat
- Malam ke-21: Mini-boss Voidlord muncul sebagai pendahulu The Devourer
- Malam Final (tergantarkan oleh story quest): The Devourer — boss bermekanik 3 fase

# **9. Player Stats & Progression**

## **9.1 Base Stats**

| **Stat** | **Nilai Awal** | **Cara Upgrade** |
| --- | --- | --- |
| Max HP | 100 | Tiap survive 5 malam (+10 HP), quest tertentu |
| Movement Speed | 5 tiles/sec | Kecombrang brew, upgrade Garden |
| Attack Speed | 1.0x (base) | Kecombrang activation (+20%), Blazeblade (+15%) |
| Energy Capacity | 100 | Tiap 3 Melati ditemukan (+10 Energy Max) |
| Respawn Invincibility | 3 detik | Tidak bisa diupgrade |

## **9.2 Loadout**

- Pemain bisa equip 2 senjata aktif secara bersamaan (hotbar slot 1 & 2)
- Satu slot skill aktif (tanaman yang diaktifkan dengan energi)
- Loadout hanya bisa diganti di Preparation Phase (sore hari) atau di Garden Base
- Saat malam berlangsung, loadout dikunci — tidak bisa swap senjata

## **9.3 Upgrade Path**

Tidak ada skill tree. Progression bersifat item-driven:

- Senjata diupgrade melalui crafting dengan material tambahan
- Stat HP dan Energy naik melalui milestone hari dan quest reward
- Garden bisa diperluas dengan membangun struktur (Storage, Breeding Bench, Watchtower)

# **10. World & Map Design**

## **10.1 Map Structure**

| **Zone** | **Biome** | **Resource Unik** | **Unlock** |
| --- | --- | --- | --- |
| Meadow Edge | Padang rumput — zona awal | Petal Shard, Bougainvillea, Verdant Sap | Tersedia dari awal |
| Dusk Forest | Hutan gelap — cahaya redup | Moonspore, Wijaya Kusuma, Rafflesia | Hari 3 |
| Ruins of Veld | Reruntuhan kota kuno | Shadow Resin, Kunyit | Hari 7, quest |
| Obsidian Bog | Rawa hitam — terrain sulit | Aether Bloom, Void materials | Hari 14 |
| Core Sanctum | Area sakral Dianthus | Dianthus Pollen (unlimited) | Final quest |

## **10.2 The Garden (Home Base)**

- Ukuran awal: 12x10 tile grid
- Dianthus Core diposisikan di pusat kebun — dikelilingi oleh 4 designated plant slots
- Pemain bisa membangun struktur di pinggir garden: Storage (+inventory slot), Breeding Bench (unlock resep baru), Watchtower (visualisasi spawn direction)
- Garden bisa diperluas hingga 20x16 tile dengan material Verdant Sap dan Stone

## **10.3 Enemy Spawn Points**

- 4 fixed entry points: Utara, Selatan, Timur, Barat garden
- Setiap malam, 1-3 entry point aktif secara acak
- Pemain bisa membangun barrier (Mosswarden Wall) di entry point — memperlambat musuh masuk
- Pada Surge Night, semua 4 entry point aktif serentak

# **11. UI / HUD & Save System**

## **11.1 HUD Elements**

- Player HP Bar — pojok kiri atas, bar merah
- Dianthus Core HP Bar — tengah atas, bar hijau bercahaya, lebih besar dari player HP
- Energy Meter — di bawah player HP, bar biru/teal
- Time-of-Day Indicator — ikon matahari/bulan bergerak di sudut kanan atas; saat 75% ke arah malam, bar berubah merah sebagai peringatan
- Hotbar Senjata — pojok kanan bawah, 2 slot senjata + 1 slot skill aktif
- Mini-map — pojok kiri bawah, menampilkan posisi pemain, batas kebun, dan arah enemy spawn (hanya saat malam)
- Wave Counter — saat malam: "Wave X / Y" ditampilkan di atas minimap

## **11.2 Menus & Screens**

- Crafting Menu — diakses dari Breeding Bench di Garden
- Inventory — tombol I atau via Garden area; grid 30-slot
- Quest Log — tombol Q; menampilkan active quests dan progress
- Plant Codex — dibuka melalui Quest; menampilkan semua tanaman yang sudah ditemukan beserta kombinasi yang sudah dicoba
- Pause Menu — akses ke Settings, Save/Load, dan Main Menu

## **11.3 Save System**

- Auto-save terjadi setiap setelah malam berhasil dipertahankan (transisi ke siang)
- Manual save tersedia kapan saja selama Exploration/Preparation Phase
- Satu save slot per permainan (tidak ada multiple save); pemain bisa mulai New Game+ setelah ending
- Tidak ada permadeath mode (sesuai target audience remaja 13-19 tahun)

## **11.4 Accessibility**

- 3 level kesulitan: Normal (default), Easy (musuh -20% stats), Hard (musuh +30% stats)
- Colorblind mode: ikon tambahan pada bar HP/Energy (simbol tidak hanya warna)
- Tutorial interaktif di 3 hari pertama — bisa dinonaktifkan
- Kecepatan teks dialog bisa diatur (dikelola melalui Dialogic text-speed setting)

# **12. Audio & Visual Direction**

## **12.1 Visual Style**

- Resolusi tile: 16x16 px per tile; karakter 16x24 px
- Palette daytime: hangat, vibrant — kuning, hijau cerah, biru langit
- Palette nighttime: desaturated, dingin — ungu gelap, abu-abu biru, aksen merah bahaya
- Dianthus Core: glowing pink-white aura yang berfluktuasi sesuai HP — makin redup saat HP rendah
- UI Style: traditional overlay (bukan diegetic); frame HUD bergaya panel kayu alami

## **12.2 Animation Priorities**

1. Player — attack, roll/dodge, respawn
2. Dianthus Core — idle glow, damage state, destruction
3. Enemy — walk, attack, death, retreat
4. Plant — bloom (placement), active effect, wither (kerusakan)
5. Senjata — swing VFX, impact particles
6. UI — HP bar shake saat damage, energy fill animation

## **12.3 Audio Direction**

### **Music**

- Exploration Phase: musik akustik ringan, instrumen petik, tempo santai
- Preparation Phase: underscore tegang ringan, mendekati nada malam
- Night / Defense Phase: musik perkusi intens berbasis synth gelap + layer melodik tanaman
- Dynamic layer: jika >50% musuh masih hidup, layer intensitas tinggi ditambahkan secara otomatis

### **Key SFX**

- Crafting success: chime kristal lembut
- Plant activation: efek organik (suara tanaman tumbuh, burst daun)
- Enemy hit: impact berdaging + efek thorn/spore sesuai senjata
- Dianthus Core damage: reverb deep boom + crack kayu
- Surge Night warning: suara angin berubah ke nada minor sebagai ambient cue

# **13. Health & Energy System**

## **13.1 Player Health**

- Representasi kondisi fisik pemain — bar merah di HUD
- Berkurang saat terkena serangan musuh
- Jika habis: respawn setelah 5 detik di dekat Dianthus Core (lihat Death Mechanic bagian 5.1)

## **13.2 Dianthus Core Health**

- Representasi kondisi kebun utama — bar hijau bercahaya di HUD
- Jika habis: GAME OVER — tidak ada grace period
- Bisa diregenerasi: 5 HP/menit saat siang hari; item Aether Bloom memulihkan 30 HP

## **13.3 Energy System**

Energi digunakan untuk mengaktifkan kemampuan tanaman dan skill karakter.

### **Sumber Energi**

- Menyerang musuh: +3 energi per hit
- Mengalahkan musuh: +10 energi
- Berada di dekat Dianthus Core: +2 energi/detik (pasif)

### **Penggunaan Energi**

- Skill aktif tanaman: 20-50 energi tergantung tanaman
- Skill karakter khusus: 30 energi per aktivasi

# **14. Combat**

Sistem combat bersifat real-time action. Pemain dapat menggunakan senjata berbasis tanaman, menghindari serangan musuh, dan mengaktifkan skill berbasis energi.

| **Senjata** | **Tipe** | **Keterangan** |
| --- | --- | --- |
| Thorn Sword | Melee | Serangan jarak dekat, swing arc 90 derajat |
| Spore Bomb | Ranged / AoE | Lempar bom area, delay 1 detik, slow + damage |
| Vine Whip | Melee Mid-range | Jangkauan 2.5 tile, bisa pull enemy |
| Petal Shield | Defensive | Block damage 80%, counter-attack jika timing tepat |

# **15. Enemy Behavior (FSM)**

Musuh menggunakan sistem Finite State Machine (FSM) dengan state berikut:

- Idle / Patrol — menunggu di spawn point, bergerak acak kecil
- Scouting — mendeteksi kebun dari jarak jauh, bergerak mendekat secara hati-hati
- Siege — mengepung kebun dan mencari rute masuk
- Attack — menyerang Dianthus Core atau pemain
- Retreat — mundur jika HP < 20% atau jika jumlah rekan di area < 2

Setiap enemy type memiliki quirk FSM yang membedakan behavior-nya (lihat tabel Enemy Archetypes di bagian 8).

# **16. Quest System**

Dialog NPC dan cutscene story diimplementasikan menggunakan **Dialogic** (addon Godot) — timeline `.dtl`, resource karakter `.dch`, dan branching berbasis variabel. Story Quest menggunakan Dialogic timeline untuk percakapan penting.

| **Jenis Quest** | **Contoh Objective** | **Reward** |
| --- | --- | --- |
| Daily Quest | Kumpulkan 10 Petal Shard; Kalahkan 5 Shadowling | Resource Common/Uncommon |
| Progress Quest | Bertahan hingga Hari 10; Buka semua zone sebelum Hari 15 | Aether Bloom, upgrade unlock |
| Discovery Quest | Temukan Nightbloom melalui breeding; Coba 5 kombinasi baru | Codex entry, resep baru |
| Story Quest | Selidiki Ruins of Veld; Hadapi Voidlord | Cerita lanjut, area baru terbuka |

# **17. Minigames**

Beberapa aktivitas dikemas dalam minigame untuk menambah keterlibatan pemain:

- Plant Experimentation — pemain mencocokkan kombinasi energi (ritme sederhana / puzzle singkat); skor menentukan kualitas hasil breeding (Biasa / Superior / Masterwork)
- Crafting Assembly — drag-and-drop komponen dalam urutan yang tepat; bonus damage +10% jika sempurna
- Harvest Event — QTE singkat saat mengambil resource langka; gagal = yield berkurang 50%

# **18. Technical & Tools**

| **Engine** | Godot 4.x |
| --- | --- |
| **Art Tools** | Aseprite (pixel art, animasi) |
| **Visual Style** | 2D Pixel Art — 16x16 tile, 16x24 character |
| **Audio** | Godot AudioStreamPlayer + dynamic layer system |
| **AI** | Finite State Machine (FSM) — implemented via Godot StateMachine node |
| **Dialog** | Dialogic (Godot addon) — timeline-based dialog, character portraits, branching |

# **19. Game References**

| **Game** | **Relevansi** |
| --- | --- |
| Plant Tycoon | Sistem breeding dan kombinasi tanaman |
| Drakantos | Sistem gameplay survival action |
| Plants vs Zombies | Jenis skill dan efek untuk tiap tanaman |
| Stardew Valley | Sistem farming dan daily cycle |
| Don't Starve Together | Tone survival dan resource management |
| Moonlighter | Loop siang-malam dan crafting economy |

# 20. Genres

Survival, Crafting, Action, Adventure, Fantasy

# 21. Competition Mode

Single player

# 22. Target Audience

Remaja 13-19 tahun — menyukai light survival, crafting, dan exploration