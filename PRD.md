# 📄 Product Requirement Document (PRD) — Quizyu

> **Aplikasi Mobile Pembelajaran & Kuis Interaktif Berbasis Generative AI (Google Gemini)**

---

## 📌 1. Executive Summary & Visi Produk

**Quizyu** (Backend: *PrepMaster AI*) adalah aplikasi mobile *learning* pintar yang mentransformasi topik pembelajaran apa pun menjadi kuis pilihan ganda interaktif dan panduan belajar personalisasi secara *real-time*.

Dengan menggabungkan kecanggihan **Google Gemini Generative AI**, **Flutter**, dan **Express.js Backend**, Quizyu membantu siswa, mahasiswa, dan pemelajar mandiri untuk menguji pemahaman materi, mengidentifikasi kelemahan jawaban, serta mendapatkan analisis pembahasan secara otomatis.

---

## 👥 2. Target Pengguna (User Personas)

1. **Pelajar & Mahasiswa**: Membutuhkan latihan soal instan sebelum ujian pada mata pelajaran/kuliah tertentu.
2. **Developer & Professional**: Ingin menguji pemahaman teknologi baru (contoh: *Flutter, Node.js, SQL, Docker*).
3. **Pemelajar Mandiri (Self-Learner)**: Membutuhkan ringkasan materi dan kuis interaktif dari topik umum (sains, sejarah, bahasa).

---

## 🛠️ 3. Arsitektur Sistem & Tech Stack

```
┌─────────────────────────────────┐
│     Flutter Mobile App          │ (Frontend / UI / Riverpod / Dio)
└────────────────┬────────────────┘
                 │ HTTP (REST API / JSON)
                 ▼
┌─────────────────────────────────┐
│   Node.js Express Backend Proxy │ (Multi-Model Fallback / JSON Sanitizer)
└────────────────┬────────────────┘
                 │ Official Node SDK (@google/generative-ai)
                 ▼
┌─────────────────────────────────┐
│    Google Gemini AI API         │ (gemini-3.5-flash / gemini-2.0-flash-lite)
└─────────────────────────────────┘
```

| Komponen | Spesifikasi & Teknologi |
| :--- | :--- |
| **Frontend App** | **Flutter (Dart)** |
| **State Management** | **Flutter Riverpod** (`flutter_riverpod`) |
| **HTTP Network Client** | **Dio** (`dio`) dengan Interceptor & Custom Error Parser |
| **Markdown Renderer** | **Flutter Markdown** (`flutter_markdown`) |
| **Backend REST Proxy** | **Node.js** & **Express.js** (Listening on Port 3000) |
| **AI Integration** | **Google Generative AI SDK** (`@google/generative-ai`) |
| **CI/CD Pipeline** | **GitHub Actions** (`.github/workflows/ci.yml`) |

---

## 🎯 4. Spesifikasi Fitur Utama (Functional Requirements)

### 🔹 F-01: AI Quiz Generator & Natural Language Parser
- **Penginputan Topik**: Input teks bebas pada layar utama (contoh: *"Tata Surya"*, *"State Management Flutter"*).
- **Natural Language Regex Parser**: Otomatis mendeteksi jumlah soal langsung dari prompt pengguna (misal: *"buatkan 20 soal matematika dasar"* ➔ otomatis mengatur 20 soal).
- **Pengaturan Kuis**: Presets jumlah soal (5, 10, 20), slider kustom (3–30 soal), dan pilihan tingkat kesulitan (*Easy, Medium, Hard*).

### 🔹 F-02: Layar Loading Interaktif (Gorgeous Loading Screen)
- **Desain Visual**: Lingkaran *neon sweep gradient* berputar mengelilingi ikon Otak 🧠 (`Icons.psychology_rounded`).
- **Dynamic Cycling Messages**: Pesan status berganti secara otomatis sesuai konteks (Kuis AI vs Analisis Performa).
- **Tombol Batal**: Opsi *"Batal & Kembali ke Beranda"* muncul otomatis jika pemuatan memakan waktu lebih dari 60 detik.

### 🔹 F-03: Sesi Kuis Interaktif & Scoring
- **Pengalaman Menjawab**: Tampilan per soal dengan timer, opsi jawaban pilihan ganda, dan tombol *Hint Engine*.
- **Evaluasi Skor**: Hasil persentase akurasi, rincian jumlah jawaban Benar, Salah, dan Terlewatkan.

### 🔹 F-04: AI Performance Analysis & Study Guide
- **Analisis Kesalahan**: Backend mengirimkan daftar soal yang salah dijawab oleh pengguna ke AI.
- **Rekomendasi Belajar**: AI menyusun panduan materi pengulasan, konsep kunci, dan pembahasan rinci dalam format Markdown interaktif.

### 🔹 F-05: Penanganan Error & Jaringan Tangguh (Resilient Network Handling)
- **Multi-Model AI Fallback Loop**: Siklus otomatis mencoba model alternatif jika terjadi rate limit (`gemini-3.5-flash` ➔ `gemini-flash-latest` ➔ `gemini-2.0-flash-lite` ➔ `gemini-3.1-flash-lite`).
- **Pemisahan Error Cerdas**:
  - 🌐 **Offline / Server Down**: Tampilan Oranye dengan pesan jelas *"Tidak ada koneksi internet / Server backend Express belum berjalan"*.
  - ⏳ **Rate Limit 429**: Tampilan Ungu Electric dengan pesan *"Batas Kuota Gratis AI Gemini Terlampaui"*.
- **Robust JSON Extraction**: Backend mengekstrak JSON dari batas `{` pertama hingga `}` terakhir untuk menjamin 0% *parse crash*.

### 🔹 F-06: Model Switcher & Guardrails
- **Gemini Standard**: Aktif sebagai model default utama.
- **Gemini Pro**: Menampilkan notifikasi *Floating SnackBar* eksklusif: *"Fitur Gemini Pro belum tersedia saat ini"*.

---

## 🚀 5. Otomatisasi CI/CD (GitHub Actions)

Berkas konfigurasi **`.github/workflows/ci.yml`** menangani:
1. **`flutter-ci`**: `flutter analyze`, `flutter test`, dan `flutter build apk --debug`.
2. **`backend-ci`**: `npm install` dan sintaks check Node.js (`node -c index.js`).
3. **`backend-deploy`**: Mengirim sinyal *Webhook CD* ke Cloud Server (Render.com) otomatis setelah semua CI test lulus.

---

## 📁 6. Struktur Direktori Proyek

```
quizyu/
├── .github/workflows/
│   └── ci.yml                # Pipeline CI/CD GitHub Actions
├── backend/
│   ├── index.js              # Server Express Proxy & Handler Gemini API
│   ├── package.json          # Dependencies Node.js
│   └── .env                  # Environment Variables (GEMINI_API_KEY)
├── lib/
│   ├── main.dart             # Entry point aplikasi Flutter
│   ├── models/               # Data Models (Quiz, Question, Settings)
│   ├── providers/            # Riverpod Notifiers (Quiz, Study Guide, Settings)
│   ├── services/             # ApiService (Dio HTTP Client)
│   └── views/                # Screen UI (Home, Loading, Quiz, Result, StudyGuide)
├── test/
│   └── widget_test.dart      # Automated Flutter Widget Testing
├── PRD.md                    # Product Requirement Document
└── README.md                 # Dokumentasi Repositori GitHub
```

---

*Dokumen PRD ini disusun untuk proyek **Quizyu** (2026).*
