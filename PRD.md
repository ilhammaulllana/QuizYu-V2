# Product Requirements Document — Quizyu

**Versi dokumen:** 2.0    
**Status produk:** MVP fungsional / prototipe yang dapat dijalankan  
**Sumber:** pemeriksaan kode aplikasi Flutter, backend Express, konfigurasi proyek, dan dokumentasi repositori.

> Dokumen ini menggambarkan produk sebagaimana tercermin di repositori saat ini. Bagian berlabel **Usulan** adalah arah pengembangan, bukan fitur yang sudah tersedia. Informasi operasional yang tidak tersimpan di repositori—seperti status layanan produksi, kuota AI, dan metrik pengguna—belum dapat diverifikasi.

## 1. Ringkasan produk

Quizyu adalah aplikasi belajar mandiri yang mengubah topik teks menjadi kuis pilihan ganda. Pengguna menjawab pertanyaan, melihat ringkasan hasil, lalu dapat meminta panduan belajar berbasis jawaban yang salah. Aplikasi dibuat dengan Flutter dan Riverpod; layanan backend Express menghubungkan aplikasi ke Google Gemini dan menyediakan generator fallback.

Nilai utama Quizyu adalah memperpendek jarak antara “ingin belajar suatu topik” dan “mulai berlatih serta memahami kesalahan”. Produk saat ini berfokus pada satu sesi kuis; akun, penyimpanan riwayat jangka panjang, dan fitur sosial tidak tercermin dalam implementasi.

## 2. Masalah dan tujuan

### Masalah pengguna

- Menyiapkan latihan soal untuk suatu topik membutuhkan waktu dan sumber yang tersebar.
- Pengguna perlu mengetahui bagian mana yang belum dipahami setelah latihan.
- Materi koreksi yang tersedia sering tidak menyesuaikan jawaban salah pengguna.

### Tujuan produk

1. Memungkinkan pengguna memulai latihan hanya dengan memasukkan topik.
2. Memberi kontrol sederhana atas jumlah soal dan tingkat kesulitan.
3. Menampilkan progres sesi dan hasil yang mudah dipahami.
4. Mengubah jawaban yang salah menjadi bahan ulasan yang relevan.
5. Menyediakan respons yang layak ketika layanan AI atau jaringan tidak tersedia.

### Bukan tujuan versi saat ini

- Menjadi Learning Management System untuk kelas atau institusi.
- Mengelola akun, sinkronisasi lintas perangkat, atau perpustakaan riwayat belajar.
- Menjamin bahwa seluruh soal generatif setara dengan soal ujian resmi atau tervalidasi ahli.
- Menyediakan duel, leaderboard, konten buatan komunitas, atau pembayaran.

## 3. Pengguna sasaran

### Persona utama: pelajar dan mahasiswa

Mencari latihan cepat untuk mengulang materi sekolah, kuliah, atau persiapan ujian.

### Persona pendukung: pemelajar mandiri

Ingin menguji pemahaman awal atas topik baru tanpa membuat soal sendiri.

### Persona pendukung: profesional dan praktisi

Ingin berlatih konsep bidang kerja atau teknologi tertentu secara mandiri.

## 4. Platform dan arsitektur saat ini

- **Klien:** Flutter/Dart; target proyek mencakup Android, iOS, web, dan Windows melalui konfigurasi Flutter yang tersedia.
- **State aplikasi:** Riverpod (`flutter_riverpod`).
- **Komunikasi HTTP:** Dio.
- **Tampilan panduan:** Markdown melalui `flutter_markdown`.
- **Backend:** Node.js dan Express, dengan endpoint untuk membuat kuis dan panduan belajar.
- **AI:** integrasi `@google/generative-ai`; nama model dipilih di backend dan perlu diverifikasi terhadap ketersediaan API saat deployment.
- **URL backend klien:** `https://quiz-yu-v2-cki8.vercel.app` ditetapkan di `lib/services/api_service.dart`.
- **Fallback klien:** jika panggilan backend gagal, aplikasi mencoba generator lokal di `lib/services/mock_data.dart`.
- **Fallback backend:** backend menyediakan bank soal topik tertentu dan template generik, serta fallback panduan belajar.

Model AI tertentu, status deployment URL, pipeline CI/CD, dan konfigurasi kunci API tidak dianggap sebagai jaminan produk dalam PRD ini karena tidak dapat dipastikan dari seluruh kondisi deployment hanya melalui kode repositori.

## 5. Alur pengguna utama

1. Pengguna membuka beranda dan memasukkan topik belajar.
2. Pengguna dapat membuka pengaturan untuk memilih cakupan latihan, jumlah soal, dan tingkat kesulitan.
3. Aplikasi mendeteksi jumlah soal yang ditulis di prompt bila nilainya berada pada rentang 1–30; jika tidak, nilai pengaturan digunakan.
4. Aplikasi menampilkan layar pemuatan, lalu meminta soal ke backend. Bila permintaan gagal, klien mencoba data fallback lokal.
5. Pengguna menjawab atau melewati pertanyaan dan dapat membuka petunjuk yang tersedia.
6. Setelah sesi selesai, aplikasi menampilkan akurasi, jumlah benar, salah, dan dilewati.
7. Pengguna dapat membuat panduan analisis berdasarkan soal yang salah atau meminta kuis tambahan/fokus perbaikan.
8. Pengguna dapat kembali ke beranda untuk memulai sesi baru.

## 6. Persyaratan fungsional

### F-01 — Pembuatan kuis

- Pengguna dapat memasukkan topik dengan teks bebas.
- Topik kosong harus ditolak dengan umpan balik yang jelas.
- Pengaturan jumlah menyediakan preset 5, 10, dan 20 soal serta rentang kustom 3–30.
- Pengaturan kesulitan menyediakan Mudah, Sedang, dan Sulit.
- Jumlah eksplisit di prompt dapat dikenali dan dipakai jika 1–30.
- Aplikasi menerima pertanyaan, pilihan jawaban, indeks jawaban benar, petunjuk, dan penjelasan dalam bentuk terstruktur.
- Backend mengembalikan status validasi topik dan pesan bila topik tidak dapat diproses.
- Kebutuhan kualitas: jumlah soal, bentuk opsi, dan indeks jawaban benar harus divalidasi sebelum sesi ditampilkan. Validasi menyeluruh ini merupakan kebutuhan kualitas; implementasi saat ini belum membuktikan seluruh pemeriksaan tersebut.

### F-02 — Pemuatan dan pembatalan

- Saat kuis dibuat, tampilkan layar pemuatan dengan pesan status bergilir.
- Tawarkan pembatalan setelah pemuatan berjalan 60 detik.
- Pemuatan harus berakhir pada sesi kuis atau pesan kegagalan yang dapat dimengerti.
- Catatan kondisi saat ini: layar menyediakan opsi batal setelah 60 detik, tetapi dukungan pembatalan permintaan jaringan/backend perlu diverifikasi.

### F-03 — Pengerjaan kuis

- Tampilkan satu pertanyaan pada satu waktu dengan indikator posisi/progres.
- Pengguna dapat memilih jawaban, berpindah ke pertanyaan berikut/sebelumnya, dan melewati pertanyaan.
- Petunjuk soal dapat dibuka saat sesi berlangsung.
- Tidak ada timer pengerjaan kuis yang terkonfirmasi dalam alur kode yang ditinjau; timer bukan persyaratan versi saat ini.
- Jawaban yang dipilih dicatat untuk perhitungan hasil sesi.

### F-04 — Hasil sesi

- Setelah pertanyaan terakhir, tampilkan akurasi dan jumlah benar dari total.
- Tampilkan jumlah benar, salah, dan dilewati.
- Sediakan tindakan untuk membuka analisis/panduan belajar, membuat latihan tambahan, dan kembali ke beranda.
- Akurasi menggunakan jumlah benar dibagi total soal, termasuk soal yang dilewati.

### F-05 — Panduan belajar

- Kirim topik dan soal yang salah atau terlewat ke endpoint panduan belajar.
- Tampilkan hasil sebagai Markdown.
- Bila tidak ada jawaban salah/terlewat, tampilkan pesan apresiasi dan arahan untuk melanjutkan latihan.
- Bila AI tidak tersedia, backend atau klien dapat menyajikan panduan fallback.

### F-06 — Pengaturan fokus latihan

- Pengaturan menampilkan cakupan “Semua topik” dan “Peluang perbaikan”.
- Fokus perbaikan mencoba memasukkan ulang soal sebelumnya yang salah dan melengkapinya dengan soal baru sampai jumlah yang diminta.
- Bila tidak ada kesalahan sebelumnya, alur kembali ke pembuatan kuis biasa.
- Kualitas pemetaan soal baru ke kelemahan konsep belum dapat dijamin oleh implementasi saat ini.

### F-07 — Kegagalan dan fallback

- Kegagalan jaringan/backend harus menghasilkan umpan balik yang dapat dipahami.
- Backend mendukung fallback kuis dan panduan ketika kredensial AI tidak tersedia atau model gagal.
- Klien mencoba generator lokal bila permintaan API gagal.
- Hasil fallback dapat berbeda cakupan dan kualitasnya dari hasil AI; produk perlu memberi penanda yang jelas agar pengguna tidak mengira semua konten dihasilkan AI.
- Rangkaian model fallback dan pemisahan error kuota perlu dipelihara berdasarkan dukungan aktual Google AI API, bukan diasumsikan tetap.

### F-08 — Pilihan model

- State pengaturan mengenal nilai Standard dan Pro.
- Ketersediaan “Pro” belum terbukti sebagai mode model aktif; jangan mengiklankannya sebagai kapabilitas sebelum perilaku dan aksesnya tervalidasi.

## 7. Persyaratan nonfungsional

- **Kegunaan:** alur utama dapat digunakan tanpa membuat akun dan label tindakan menggunakan Bahasa Indonesia.
- **Responsif:** antarmuka menyesuaikan ukuran layar ponsel, tablet, dan desktop.
- **Keandalan:** kesalahan API, respons tak valid, topik tidak layak, dan timeout tidak boleh membuat aplikasi berhenti tanpa penjelasan.
- **Kinerja:** layar pemuatan memberi umpan balik segera; target waktu respons kuis perlu ditetapkan setelah pengukuran produksi.
- **Privasi:** kirim hanya topik dan data soal/jawaban yang diperlukan untuk membuat sesi atau panduan. Kebijakan retensi provider AI dan kebijakan privasi produk perlu ditetapkan sebelum rilis publik.
- **Keamanan:** kunci Gemini hanya berada di server; endpoint publik perlu pembatasan penyalahgunaan, validasi input, dan batas payload sebelum skala produksi.
- **Aksesibilitas:** kontrol utama memiliki label semantik, fokus keyboard (web/desktop), dan kontras yang memadai; audit aksesibilitas belum tercatat dalam repositori.

## 8. Batasan dan risiko yang diketahui

- Sesi dan pengaturan berada dalam state aplikasi; penyimpanan persisten/akun tidak terlihat pada implementasi saat ini.
- Generator fallback mencakup bank/template soal, sehingga relevansi dan kedalaman konten dapat tidak merata untuk topik bebas.
- Konten AI dapat mengandung kekeliruan. Pengguna perlu dapat memahami bahwa soal dan ulasan adalah materi bantu, bukan sumber otoritatif.
- Endpoint produksi dikonfigurasi langsung pada klien; status aktif dan pemantauan operasionalnya perlu dipastikan oleh pemilik deployment.
- Backend menerima input pengguna dan mengirim sebagian data sesi ke AI; batas ukuran, rate limiting, dan proteksi penyalahgunaan harus dipastikan sebelum penggunaan luas.
- Dokumentasi lama tidak sepenuhnya cocok dengan implementasi—termasuk klaim timer, pemisahan error kuota yang spesifik, model tertentu, serta CI/CD. Dokumen ini tidak menganggap klaim tersebut aktif tanpa bukti implementasi.

## 9. Kriteria penerimaan MVP

1. Pengguna dapat menghasilkan sesi kuis dari topik yang tidak kosong.
2. Pengaturan jumlah (preset/kustom) dan tingkat kesulitan diteruskan ke proses pembuatan kuis.
3. Pengguna dapat menjawab, melewati, dan menyelesaikan semua pertanyaan.
4. Hasil menampilkan hitungan yang konsisten dengan jawaban sesi.
5. Panduan belajar dapat dibuka dari hasil dan memakai data soal yang belum dikuasai.
6. Kegagalan layanan tidak menutup aplikasi secara tak tertangani dan mencoba fallback sesuai alur yang tersedia.
7. Pengguna dapat kembali ke beranda dan memulai sesi baru.

## 10. Metrik keberhasilan yang disarankan

Belum ada analitik penggunaan yang ditemukan di repositori. Jika analitik ditambahkan dengan persetujuan privasi yang sesuai, pantau:

- tingkat keberhasilan pembuatan kuis;
- median waktu dari submit topik ke pertanyaan pertama;
- tingkat penyelesaian sesi;
- proporsi sesi yang membuka panduan belajar;
- tingkat kegagalan API dan frekuensi fallback;
- rating kegunaan konten soal/panduan dari pengguna.

Tetapkan baseline dan target angka setelah ada instrumentasi dan data nyata; jangan menganggap angka target sebagai fakta sebelum divalidasi.

## 11. Prioritas pengembangan berikutnya

### P0 — Kualitas dan keandalan inti

- Validasi respons soal secara ketat (jumlah, struktur opsi, indeks jawaban, duplikasi, dan teks kosong).
- Tandai dengan jelas apakah hasil berasal dari AI atau generator fallback.
- Tinjau konsistensi akurasi, hitungan jawaban terlewat, serta penentuan daftar soal untuk panduan.
- Pastikan timeout, pembatalan, dan pesan kegagalan berperilaku sesuai di web dan perangkat.
- Tetapkan batas input, payload, serta perlindungan dasar endpoint.

### P1 — Pembelajaran berkelanjutan

- Simpan riwayat sesi lokal agar pengguna dapat meninjau hasil sebelumnya.
- Tambahkan ulasan per soal yang menampilkan jawaban pengguna, jawaban benar, dan penjelasan.
- Uji apakah mode fokus perbaikan benar-benar mengulang konsep yang salah, bukan hanya menambahkan soal generik.

### P2 — Pengembangan produk

- Pertimbangkan akun dan sinkronisasi hanya jika kebutuhan lintas perangkat tervalidasi.
- Tambahkan pelaporan soal yang keliru dan mekanisme umpan balik konten.
- Jelajahi pengingat belajar atau rencana latihan setelah kebutuhan pengguna diukur.

## 12. Referensi implementasi

- Aplikasi dan state: `lib/views/`, `lib/providers/`, `lib/models/`.
- Komunikasi API: `lib/services/api_service.dart`.
- Fallback lokal: `lib/services/mock_data.dart`.
- Endpoint dan fallback backend: `backend/index.js`, `backend/api/index.js`.
- Konfigurasi klien/dependensi: `pubspec.yaml`, `backend/package.json`.

---

Dokumen ini adalah baseline produk yang dapat ditinjau bersama kode saat ini. Perbarui tanggal dan status setiap kali ruang lingkup atau perilaku produk berubah secara material.
