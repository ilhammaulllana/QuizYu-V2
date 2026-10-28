const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

const app = express();
app.use(cors());
app.use(express.json());

// Catch malformed JSON request bodies gracefully
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('⚠️ [PrepMaster API] Malformed JSON in request body:', err.message);
    return res.status(400).json({
      is_valid: false,
      error_message: "[SYSTEM_ERROR] Request payload contains invalid JSON."
    });
  }
  next(err);
});

// Prevent server process crashes from unhandled promise rejections or uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('⚠️ [PrepMaster API] Uncaught Exception:', err);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('⚠️ [PrepMaster API] Unhandled Rejection:', reason);
});

const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = (process.env.GEMINI_API_KEY || "").trim();

// Periksa apakah GEMINI_API_KEY memiliki format valid dari Google AI Studio (biasanya diawali AIzaSy...)
function isValidGeminiApiKey(key) {
  if (!key) return false;
  const trimmed = key.trim();
  if (
    trimmed === '' ||
    trimmed === 'YOUR_GEMINI_API_KEY_HERE' ||
    trimmed.length < 20
  ) {
    return false;
  }
  return true;
}

if (!isValidGeminiApiKey(GEMINI_API_KEY)) {
  console.warn("⚠️ PERINGATAN: GEMINI_API_KEY di backend/.env belum valid atau berupa token OAuth.");
  console.warn("💡 TIPS: Dapatkan API Key Gemini gratis dari Google AI Studio: https://aistudio.google.com/app/apikey (diawali AIzaSy...)");
  console.warn("🚀 Smart Fallback Engine AKTIF: Aplikasi akan tetap berfungsi penuh dengan generator kuis cerdas lokal.\n");
}

// Inisialisasi Google Generative AI jika key valid
const genAI = isValidGeminiApiKey(GEMINI_API_KEY) ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;

// Helper untuk mengecek apakah kesalahan disebabkan oleh masalah koneksi internet/jaringan secara fisik
function isNetworkError(err) {
  if (!err) return false;
  const msg = (err.message || err.toString() || '').toLowerCase();
  const code = (err.code || '').toLowerCase();

  // Exclude SDK/API validation or key errors
  if (msg.includes('api key') || msg.includes('bad request') || msg.includes('invalid') || msg.includes('400') || msg.includes('403')) {
    return false;
  }

  return (
    code === 'enotfound' ||
    code === 'enetunreach' ||
    code === 'econnrefused' ||
    code === 'etimedout' ||
    msg.includes('getaddrinfo enotfound') ||
    msg.includes('connect enetunreach') ||
    msg.includes('connect econnrefused')
  );
}

// System Prompt untuk Pembuatan Kuis
const systemPromptQuiz = `
Anda adalah PrepMaster AI, sebuah AI pembuat kuis pintar.
Tugas Anda adalah memproses topik belajar yang diberikan pengguna dan menghasilkan kuis pilihan ganda yang terstruktur.

Langkah-langkah pemrosesan:
1. Validasi Input:
   Periksa apakah topik belajar yang dimasukkan pengguna valid dan masuk akal untuk dipelajari.
   Jika topiknya kosong, terlalu pendek (kurang dari 3 karakter), berupa ketukan acak keyboard/gibberish (misalnya "asdfgh", "qwertyuiop", "xxxxx"), atau tidak memiliki arti edukatif yang jelas, Anda harus menganggap input ini TIDAK VALID.
   Jika tidak valid, kembalikan JSON dengan format:
   {
     "is_valid": false,
     "error_message": "Topik tidak jelas atau terlalu acak. Silakan masukkan topik belajar yang valid (contoh: \\"Flutter\\", \\"Sains\\", \\"Tata Surya\\", \\"Sejarah\\")."
   }

2. Pembuatan Pertanyaan (jika topik VALID):
   Buatlah tepat N pertanyaan pilihan ganda mengenai topik tersebut dengan tingkat kesulitan D (Mudah, Sedang, atau Sulit).
   Ketentuan pertanyaan:
   - Harus dalam Bahasa Indonesia yang baik dan benar.
   - Setiap pertanyaan harus memiliki tepat 4 opsi pilihan ganda.
   - Tentukan indeks jawaban benar (correct_answer_index) dari 0 sampai 3 (0=opsi A, 1=opsi B, 2=opsi C, 3=opsi D).
   - SANGAT PENTING: Distribusikan posisi jawaban benar secara ACAK dan SEIMBANG di antara 0, 1, 2, dan 3 (A, B, C, dan D). JANGAN selalu menaruh jawaban benar di opsi B (indeks 1)! Pastikan semua opsi (A, B, C, D) memiliki peluang yang seimbang sebagai jawaban benar.
   - Tulis petunjuk singkat (hint) yang membantu pengguna memikirkan jawaban tanpa membocorkannya langsung.
   - Tulis penjelasan (explanation) detail yang menjelaskan mengapa jawaban tersebut benar dan konsep di baliknya.
   Kembalikan JSON dengan format:
   {
     "is_valid": true,
     "topic": "Nama topik yang dirapikan (kapitalisasi yang benar)",
     "questions": [
       {
         "question": "Teks pertanyaan",
         "options": ["Opsi A", "Opsi B", "Opsi C", "Opsi D"],
         "correct_answer_index": 0,
         "hint": "Petunjuk singkat",
         "explanation": "Penjelasan detail"
       }
     ]
   }

Kembalikan HANYA data JSON di atas tanpa markdown wrapper, tanpa tag \`\`\`json, dan tanpa teks tambahan lainnya.
`;

// System Prompt untuk Panduan Belajar (Study Guide)
const systemPromptStudyGuide = `
Anda adalah PrepMaster AI, sebuah asisten belajar personal berbasis AI.
Tugas Anda adalah meracik Panduan Belajar personalisasi (Study Guide) berformat Markdown dalam Bahasa Indonesia yang berfokus pada perbaikan pemahaman konsep dari pertanyaan-pertanyaan kuis yang salah dijawab oleh pengguna.

Format keluaran harus menggunakan Markdown yang bersih dan indah.
Struktur Markdown yang wajib diikuti:

# 📚 Panduan Belajar AI Personalisasi: [Nama Topik]
Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.

## 💡 Ulasan Konsep yang Meleset
Ulaslah setiap pertanyaan yang salah dijawab oleh pengguna secara terperinci. Jelaskan konsep teoritis di balik pertanyaan tersebut dengan bahasa yang mudah dipahami, ramah, dan mendidik.
Untuk setiap pertanyaan:
### [Nomor]. [Teks Pertanyaan]
* **Jawaban Benar yang Seharusnya:** [Teks opsi jawaban yang benar]
* **Penjelasan Detail:**
  [Penjelasan detail, mendalam, dan terstruktur tentang mengapa jawaban tersebut benar dan apa konsep utamanya.]

## 📖 Kamus Istilah Pintar (Glossary)
Berikan daftar istilah/kosakata kunci yang relevan dengan topik ini (minimal 3-5 istilah) berserta definisinya agar pemahaman pengguna lebih matang. Gunakan format list bullet:
* **[Istilah]**: [Definisi istilah]

Berikan teks keluaran langsung dalam format Markdown. Jangan bungkus dengan tag \`\`\`markdown atau teks pembuka/penutup lainnya.
`;

// ==================== SMART FALLBACK GENERATOR ====================

function isGibberish(input) {
  const cleaned = input.toLowerCase().replace(/\s+/g, '');
  if (!cleaned || cleaned.length < 3) return true;

  // 1. Tidak ada huruf
  if (!/[a-z]/.test(cleaned)) return true;

  // 2. Karakter berulang beruntun (misal: "aaaa", "zzzzz")
  if (/(.)\1{3,}/.test(cleaned)) return true;

  // 3. Pola repetisi pendek (misal: "asdasd", "abcabc")
  if (cleaned.length >= 6) {
    const half = Math.floor(cleaned.length / 2);
    if (cleaned.substring(0, half) === cleaned.substring(half)) return true;
  }

  // 4. Perbandingan vokal
  const vowels = cleaned.match(/[aeiouy]/g) || [];
  const letters = cleaned.match(/[a-z]/g) || [];
  if (letters.length >= 4 && vowels.length === 0) return true;
  if (letters.length >= 6 && (vowels.length / letters.length) < 0.15) return true;

  // 5. Konsonan beruntun 5+
  if (/[bcdfghjklmnpqrstvwxz]{5,}/.test(cleaned)) return true;

  // 6. Keyboard sliding patterns
  const patterns = ['asdf', 'sdfg', 'dfgh', 'ghjk', 'hjkl', 'qwer', 'wert', 'erty', 'uiop', 'zxcv', 'xcvb', 'cvbn'];
  for (const p of patterns) {
    if (cleaned.includes(p)) return true;
  }

  return false;
}

const mockBankFlutter = [
  {
    question: 'Apa peran utama dari Widget dalam framework Flutter?',
    options: [
      'Mengatur database lokal aplikasi',
      'Mendefinisikan elemen antarmuka pengguna (UI) secara deklaratif',
      'Mengompilasi kode Dart menjadi kode mesin',
      'Mengelola request HTTP secara asynchronous'
    ],
    correct_answer_index: 1,
    hint: 'Semua hal di Flutter adalah...',
    explanation: 'Dalam Flutter, hampir semua hal adalah Widget. Widget mendefinisikan tampilan dan struktur UI secara deklaratif.'
  },
  {
    question: 'Mengapa Riverpod dianggap lebih aman dibandingkan Provider tradisional?',
    options: [
      'Riverpod tidak membutuhkan context untuk membaca state, sehingga menghindari error runtime saat UI dibangun',
      'Riverpod secara otomatis melakukan enkripsi pada penyimpanan data lokal',
      'Riverpod ditulis menggunakan bahasa C++ sehingga lebih cepat',
      'Riverpod hanya bekerja di platform iOS untuk keamanan ekstra'
    ],
    correct_answer_index: 0,
    hint: 'Pikirkan tentang ketergantungan pada BuildContext.',
    explanation: 'Riverpod tidak bergantung pada Flutter Widget Tree (BuildContext) untuk membaca provider, sehingga meminimalkan error runtime dan aman saat kompilasi.'
  },
  {
    question: 'Bagaimanakah Hot Reload berbeda dari Hot Restart di Flutter?',
    options: [
      'Hot Reload merestart seluruh aplikasi dari awal, sedangkan Hot Restart hanya memperbarui logika',
      'Hot Reload menyuntikkan perubahan kode ke dalam VM Dart dan mempertahankan state, sementara Hot Restart membangun ulang aplikasi dan menyetel ulang state',
      'Hot Reload memerlukan instalasi ulang SDK Flutter',
      'Hot Reload hanya bekerja pada emulator Android'
    ],
    correct_answer_index: 1,
    hint: 'Mana yang mempertahankan data/variabel yang sedang aktif di layar?',
    explanation: 'Hot Reload menyuntikkan kode baru ke VM Dart tanpa merestart aplikasi sehingga state layar saat itu tetap terjaga.'
  },
  {
    question: 'Package manakah yang paling sering digunakan untuk melakukan request HTTP secara handal dengan fitur Interceptors di Flutter?',
    options: ['http', 'dio', 'shared_preferences', 'path_provider'],
    correct_answer_index: 1,
    hint: 'Disebutkan dalam PRD untuk networking.',
    explanation: 'Dio adalah library HTTP client yang powerful untuk Dart/Flutter yang mendukung Interceptors, Global Configuration, FormData, dan Request Cancellation.'
  },
  {
    question: 'Manakah dari berikut ini yang merupakan deskripsi tepat dari StatelessWidget?',
    options: [
      'Widget yang tampilannya tidak dapat berubah sepanjang siklus hidupnya setelah dibangun',
      'Widget yang memiliki animasi dinamis secara otomatis',
      'Widget yang terhubung langsung ke database cloud',
      'Widget yang menyimpan state internal yang dapat diubah menggunakan setState'
    ],
    correct_answer_index: 0,
    hint: 'Kata kuncinya adalah "Stateless" (tanpa keadaan/state dinamis).',
    explanation: 'StatelessWidget adalah kelas widget immutable yang konfigurasinya tidak berubah sepanjang siklus hidupnya setelah dirender di layar.'
  },
  {
    question: 'Fungsi utama dari file pubspec.yaml adalah untuk...',
    options: [
      'Menulis kode logika backend Node.js',
      'Mengonfigurasi package dependencies, asset gambar, custom font, dan metadata aplikasi',
      'Mendefinisikan skema database SQLite',
      'Mengompilasi file Dart menjadi file APK'
    ],
    correct_answer_index: 1,
    hint: 'Tempat kita menambahkan library eksternal.',
    explanation: 'File pubspec.yaml adalah file konfigurasi utama proyek Flutter di mana dependensi, aset, font, versi proyek, dan pengaturan SDK dideklarasikan.'
  },
  {
    question: 'Apa kegunaan dari kata kunci "async" dan "await" pada Dart?',
    options: [
      'Membuat eksekusi kode menjadi sinkron dan memblokir thread UI',
      'Menangani operasi asynchronous secara bersih dan mudah dibaca seolah-olah sinkron',
      'Mendeklarasikan variabel konstan yang nilainya ditentukan saat runtime',
      'Melakukan kompresi ukuran file gambar'
    ],
    correct_answer_index: 1,
    hint: 'Berhubungan dengan Future.',
    explanation: 'async dan await digunakan untuk mendefinisikan fungsi asynchronous dan menunggu hasil pemrosesan Future tanpa memblokir thread utama.'
  },
  {
    question: 'Metode siklus hidup (lifecycle) manakah yang dipanggil tepat sekali saat StatefulWidget dimasukkan ke dalam widget tree?',
    options: ['build()', 'initState()', 'dispose()', 'setState()'],
    correct_answer_index: 1,
    hint: 'Inisialisasi awal state.',
    explanation: 'initState() adalah metode pertama dari siklus hidup State yang dipanggil tepat satu kali saat widget pertama kali dibuat.'
  },
  {
    question: 'Apa fungsi dari widget SafeArea di Flutter?',
    options: [
      'Mengenkripsi data sensitif pengguna agar aman dari peretas',
      'Menghindari pemotongan UI oleh takik layar (notch), status bar, atau bilah navigasi bawah perangkat',
      'Mencegah aplikasi keluar secara tidak sengaja ketika tombol back ditekan',
      'Melakukan enkripsi SSL handshake secara otomatis'
    ],
    correct_answer_index: 1,
    hint: 'Mengamankan area tampilan UI dari gangguan notch hardware fisik.',
    explanation: 'SafeArea menyisipkan padding yang cukup pada widget anaknya agar tidak tertutup oleh status bar perangkat atau takik layar (notch).'
  },
  {
    question: 'Bagaimana cara mendefinisikan constructor konstan pada kelas di Dart?',
    options: [
      'Menggunakan kata kunci final sebelum nama constructor',
      'Menggunakan kata kunci const sebelum nama constructor dan memastikan seluruh property kelas bersifat final',
      'Menambahkan modifier static pada fungsi constructor',
      'Menambahkan kata kunci constant di akhir deklarasi kelas'
    ],
    correct_answer_index: 1,
    hint: 'Ingat aturan immutabilitas variabel dan constructor.',
    explanation: 'Untuk membuat constructor konstan di Dart, kita menggunakan kata kunci const sebelum nama constructor dan memastikan semua properti kelas bersifat final.'
  }
];

const mockBankCoffee = [
  {
    question: 'Spesies kopi manakah yang menyumbang sekitar 60-70% dari produksi kopi dunia dan dikenal dengan profil rasa yang lebih halus serta kompleks?',
    options: ['Coffea Canephora (Robusta)', 'Coffea Arabica (Arabika)', 'Coffea Liberica (Liberika)', 'Coffea Excelsa (Ekselsa)'],
    correct_answer_index: 1,
    hint: 'Tumbuh di dataran tinggi dengan cita rasa aromatik.',
    explanation: 'Kopi Arabika memiliki cita rasa yang lebih manis, kompleks, dan tingkat keasaman yang lebih tinggi dibanding Robusta.'
  },
  {
    question: 'Proses pasca-panen kopi di mana ceri kopi langsung dijemur di bawah sinar matahari tanpa dikupas kulitnya dinamakan...',
    options: ['Wet Process (Full Washed)', 'Dry/Natural Process', 'Honey/Pulped Natural Process', 'Semi-Washed (Giling Basah)'],
    correct_answer_index: 1,
    hint: 'Kopi dikeringkan secara utuh bersama buahnya.',
    explanation: 'Natural/Dry process adalah proses pengolahan kopi klasik di mana ceri kopi dikeringkan secara utuh di bawah matahari.'
  },
  {
    question: 'Kandungan kafein pada biji kopi Robusta rata-rata adalah...',
    options: ['Lebih rendah daripada biji Arabika', 'Hampir dua kali lipat lebih tinggi dibanding biji Arabika', 'Sama persis dengan Arabika', 'Nol persen karena Robusta bebas kafein'],
    correct_answer_index: 1,
    hint: 'Pikirkan tentang ketahanan tanaman Robusta terhadap hama karena zat kimia ini.',
    explanation: 'Robusta memiliki kadar kafein berkisar 2.2% - 2.7%, hampir dua kali lipat dibanding Arabika yang berkisar 1.2% - 1.5%.'
  },
  {
    question: 'Alat seduh manual (manual brew) berbentuk kerucut dengan sudut 60 derajat dan ulir spiral di dinding dalamnya adalah...',
    options: ['French Press', 'V60', 'AeroPress', 'Syphon'],
    correct_answer_index: 1,
    hint: 'Angka di namanya merujuk pada sudut kemiringannya.',
    explanation: 'Hario V60 dinamakan demikian karena memiliki corong berbentuk huruf V dengan sudut kemiringan 60 derajat.'
  },
  {
    question: 'Minuman espresso yang ditambahkan dengan susu bertekstur (steamed milk) dan lapisan busa susu tebal (milk foam) seimbang dinamakan...',
    options: ['Americano', 'Cappuccino', 'Caffè Latte', 'Macchiato'],
    correct_answer_index: 1,
    hint: 'Biasanya disajikan dengan taburan cokelat di atas busanya.',
    explanation: 'Cappuccino terdiri dari sepertiga espresso, sepertiga susu panas, dan sepertiga busa susu (foam).'
  }
];

const mockBankSolar = [
  {
    question: 'Planet manakah yang dikenal sebagai "Bintang Fajar" atau "Bintang Kejora" dan merupakan planet terpanas di Tata Surya kita?',
    options: ['Merkurius', 'Venus', 'Mars', 'Yupiter'],
    correct_answer_index: 1,
    hint: 'Memiliki atmosfer tebal yang memerangkap panas (efek rumah kaca ekstrem).',
    explanation: 'Venus adalah planet terpanas di Tata Surya dengan suhu permukaan mencapai 460°C akibat atmosfernya yang sangat tebal kaya CO2.'
  },
  {
    question: 'Apakah nama planet terbesar di Tata Surya kita yang memiliki satelit alami bernama Ganymede dan badai raksasa "Great Red Spot"?',
    options: ['Saturnus', 'Yupiter', 'Uranus', 'Neptunus'],
    correct_answer_index: 1,
    hint: 'Merupakan raksasa gas dengan gaya gravitasi terbesar di antara planet lainnya.',
    explanation: 'Yupiter adalah planet terbesar di Tata Surya. Satelit alaminya, Ganymede, bahkan berukuran lebih besar daripada planet Merkurius.'
  },
  {
    question: 'Sabuk Asteroid utama di Tata Surya kita terletak di antara orbit planet...',
    options: ['Bumi dan Mars', 'Mars dan Yupiter', 'Yupiter dan Saturnus', 'Venus dan Bumi'],
    correct_answer_index: 1,
    hint: 'Membatasi planet batuan dalam dan planet gas luar.',
    explanation: 'Sabuk Asteroid utama terletak di antara orbit Mars dan Yupiter, berisi jutaan objek berbatu yang mengitari matahari.'
  }
];

const mockBankHistory = [
  {
    question: 'Siapakah nama tokoh sejarah yang membacakan naskah teks Proklamasi Kemerdekaan Indonesia pada tanggal 17 Agustus 1945?',
    options: ['Drs. Mohammad Hatta', 'Ir. Soekarno', 'Sutan Sjahrir', 'Laksamana Maeda'],
    correct_answer_index: 1,
    hint: 'Presiden pertama Republik Indonesia.',
    explanation: 'Teks Proklamasi dibacakan oleh Ir. Soekarno didampingi oleh Drs. Mohammad Hatta di Pegangsaan Timur No. 56, Jakarta.'
  },
  {
    question: 'Kerajaan Hindu-Buddha terbesar di Indonesia yang berpusat di Jawa Timur dan berhasil menyatukan Nusantara di bawah Sumpah Palapa Patih Gajah Mada adalah...',
    options: ['Sriwijaya', 'Majapahit', 'Kutai Kartanegara', 'Singasari'],
    correct_answer_index: 1,
    hint: 'Didirikan oleh Raden Wijaya pada tahun 1293.',
    explanation: 'Majapahit mencapai puncak keemasannya di bawah pimpinan Hayam Wuruk dan Patih Gajah Mada.'
  }
];

function generateGenericQuestions(topic, count, level) {
  const capTopic = topic.charAt(0).toUpperCase() + topic.slice(1);
  const templates = [
    {
      question: `Apa yang menjadi pilar dasar utama ketika membahas konsep ${capTopic}?`,
      options: [
        'Struktur logis yang tidak memerlukan pembuktian empiris',
        'Kombinasi teori dasar, riset empiris, dan penerapan praktis secara berkala',
        'Hanya sekadar spekulasi tanpa kerangka kerja yang jelas',
        'Penggunaan perangkat keras komputer berteknologi super'
      ],
      correct_answer_index: 1,
      hint: 'Cari jawaban yang komprehensif menggabungkan aspek teori dan praktik.',
      explanation: `${capTopic} dibangun di atas fondasi kuat yang menyatukan teori dasar dengan pengujian empiris dan praktik langsung di lapangan.`
    },
    {
      question: `Manakah dari berikut ini yang merupakan manfaat utama dari mendalami topik ${capTopic}?`,
      options: [
        'Menghilangkan kebutuhan akan interaksi sosial manusia',
        'Memberikan keahlian analitis dan kemampuan memecahkan masalah terkait secara efektif',
        'Menjamin kekayaan materi instan tanpa kerja keras',
        'Membatasi sudut pandang hanya pada satu bidang akademis saja'
      ],
      correct_answer_index: 1,
      hint: 'Berpikir tentang pemecahan masalah dan kemampuan analitis.',
      explanation: `Mempelajari ${capTopic} memperluas cakrawala berpikir, mempertajam logika analitis, serta melatih kemampuan problem-solving di dunia nyata.`
    },
    {
      question: `Tantangan terbesar apa yang sering dihadapi para praktisi saat mencoba mengimplementasikan ${capTopic}?`,
      options: [
        'Kurangnya minat masyarakat pada hiburan media sosial',
        'Kompleksitas integrasi, kurva pembelajaran, serta adaptasi terhadap perubahan standar baru',
        'Biaya lisensi udara yang sangat mahal',
        'Tidak adanya referensi tulisan di internet'
      ],
      correct_answer_index: 1,
      hint: 'Masalah umum implementasi biasanya seputar integrasi dan adaptasi standar baru.',
      explanation: `Dalam ranah ${capTopic}, hambatan utama biasanya berasal dari perubahan standar yang dinamis serta kurva belajar yang membutuhkan dedikasi.`
    },
    {
      question: `Bagaimana cara terbaik untuk mempercepat penguasaan pemahaman di bidang ${capTopic}?`,
      options: [
        'Menghafal seluruh definisi tanpa melakukan latihan praktis',
        'Belajar secara konsisten, membuat proyek kecil mandiri, dan berdiskusi di komunitas sejenis',
        'Membaca satu buku teks sekali saja lalu tidak mengulanginya lagi',
        'Menunggu orang lain mengajarkan tanpa usaha belajar mandiri'
      ],
      correct_answer_index: 1,
      hint: 'Konsistensi dan pembelajaran berbasis proyek aktif.',
      explanation: `Metode paling efektif dalam menguasai ${capTopic} adalah mempraktikkan teori melalui eksperimen mandiri dan kolaborasi aktif.`
    },
    {
      question: `Aspek manakah dalam ${capTopic} yang sering disalahpahami oleh pemula?`,
      options: [
        'Nama pembuat konsep pertamanya',
        'Menganggap bahwa konsep ini bersifat instan tanpa membutuhkan latihan berulang',
        'Warna logo dari komunitas utamanya',
        'Bahwa mempelajari ini membutuhkan keahlian seni lukis tingkat tinggi'
      ],
      correct_answer_index: 1,
      hint: 'Terkait harapan instan atau fleksibilitas konsep.',
      explanation: `Banyak pemula beranggapan ${capTopic} dapat dikuasai instan. Faktanya, diperlukan kesabaran, keluwesan adaptasi, dan pengulangan berkala.`
    },
    {
      question: `Dalam konteks perkembangan modern saat ini, bagaimana prospek masa depan dari ${capTopic}?`,
      options: [
        'Akan segera ditinggalkan dalam kurun waktu satu tahun ke depan',
        'Terus berintegrasi dengan AI dan teknologi digital lainnya untuk menghadirkan solusi yang lebih cerdas',
        'Akan tetap statis tanpa ada pembaruan versi sama sekali',
        'Hanya akan digunakan oleh kalangan akademisi kuno'
      ],
      correct_answer_index: 1,
      hint: 'Carilah jawaban yang menyangkut integrasi dengan teknologi digital modern.',
      explanation: `${capTopic} memiliki masa depan yang cerah karena sifatnya yang dinamis dan berpotensi tinggi berkolaborasi dengan inovasi digital saat ini.`
    },
    {
      question: `Di bawah ini yang merupakan instrumen atau tools penunjang utama dalam mempelajari ${capTopic} adalah...`,
      options: [
        'Kalkulator mekanik kuno',
        'Dokumentasi resmi, forum diskusi online, editor teks, dan platform latihan interaktif',
        'Papan tulis kapur tanpa koneksi internet',
        'Kamera film analog'
      ],
      correct_answer_index: 1,
      hint: 'Alat digital modern untuk riset dan belajar.',
      explanation: `Dokumentasi terstruktur serta forum komunitas online adalah fondasi pendukung yang tak ternilai bagi siapa saja yang ingin mendalami ${capTopic}.`
    },
    {
      question: `Perbedaan utama antara level dasar (basic) dan level lanjutan (advanced) dalam topik ${capTopic} adalah...`,
      options: [
        'Level lanjutan hanya menggunakan istilah bahasa asing yang rumit',
        'Level lanjutan melibatkan penyelesaian masalah optimasi kompleks, integrasi multifaktor, dan efisiensi sistem',
        'Level dasar tidak memiliki aturan tertulis sama sekali',
        'Level dasar hanya diajarkan di tingkat sekolah dasar saja'
      ],
      correct_answer_index: 1,
      hint: 'Level lanjutan fokus pada optimasi dan integrasi kompleks.',
      explanation: `Naik ke tingkat advanced dalam ${capTopic} berarti Anda harus bisa menyelesaikan optimasi performa serta merancang sistem yang efisien dan kokoh.`
    },
    {
      question: `Bagaimanakah dampak kesalahan penerapan konsep ${capTopic} terhadap suatu sistem?`,
      options: [
        'Sistem akan menjadi lebih berwarna dan menarik',
        'Terjadinya inefisiensi, potensi kerentanan keamanan, serta kegagalan dalam memproses data secara akurat',
        'Sistem otomatis mati secara permanen dan tidak bisa dinyalakan lagi',
        'Tidak ada dampak negatif sama sekali'
      ],
      correct_answer_index: 1,
      hint: 'Salah penerapan biasanya berakibat pada performa dan keamanan.',
      explanation: `Penerapan yang serampangan pada konsep ${capTopic} dapat melemahkan struktur sistem, menciptakan bug tersembunyi, dan memperlambat kinerja.`
    },
    {
      question: `Siapa sajakah yang disarankan untuk memiliki pemahaman dasar tentang ${capTopic}?`,
      options: [
        'Hanya anak-anak usia prasekolah',
        'Pelajar, praktisi industri terkait, akademisi, dan siapa saja yang ingin meningkatkan literasi di bidang ini',
        'Hanya insinyur astronot saja',
        'Orang yang tidak menggunakan perangkat digital'
      ],
      correct_answer_index: 1,
      hint: 'Semua orang yang berminat mengembangkan pemahamannya.',
      explanation: `Literasi mengenai ${capTopic} sangat berguna bagi pelajar maupun profesional modern agar tetap relevan di era perkembangan yang cepat.`
    }
  ];

  // Shuffle and pick elements
  const shuffled = [...templates].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// Helper untuk mengacak posisi opsi jawaban (A, B, C, D) dan menyinkronkan correct_answer_index
function randomizeQuestionsOptions(questions) {
  if (!Array.isArray(questions)) return questions;
  return questions.map(q => {
    if (!q || !Array.isArray(q.options) || q.options.length < 2) return q;
    const rawIdx = typeof q.correct_answer_index === 'number' ? q.correct_answer_index : 0;
    const safeIdx = (rawIdx >= 0 && rawIdx < q.options.length) ? rawIdx : 0;
    const correctText = q.options[safeIdx];

    // Acak urutan opsi jawaban (Fisher-Yates shuffle)
    const shuffledOptions = [...q.options];
    for (let i = shuffledOptions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffledOptions[i], shuffledOptions[j]] = [shuffledOptions[j], shuffledOptions[i]];
    }

    const newIndex = shuffledOptions.indexOf(correctText);
    return {
      ...q,
      options: shuffledOptions,
      correct_answer_index: newIndex !== -1 ? newIndex : 0
    };
  });
}

function generateFallbackQuiz(topic, count, level) {
  const norm = topic.trim().toLowerCase();
  if (!norm || norm.length < 3 || isGibberish(norm)) {
    return {
      is_valid: false,
      error_message: 'Topik tidak jelas atau terlalu acak. Silakan masukkan topik belajar yang valid (contoh: "Flutter", "Sains", "Tata Surya", "Sejarah").'
    };
  }

  let questions = [];
  if (norm.includes('flutter') || norm.includes('dart')) {
    questions = [...mockBankFlutter];
  } else if (norm.includes('kopi') || norm.includes('coffee')) {
    questions = [...mockBankCoffee];
  } else if (norm.includes('tata surya') || norm.includes('solar') || norm.includes('planet')) {
    questions = [...mockBankSolar];
  } else if (norm.includes('sejarah') || norm.includes('indonesia')) {
    questions = [...mockBankHistory];
  } else {
    questions = generateGenericQuestions(topic, count, level);
  }

  // Shuffle questions order
  questions = questions.sort(() => 0.5 - Math.random());

  if (questions.length < count) {
    const extra = generateGenericQuestions(topic, count - questions.length, level);
    questions = questions.concat(extra);
  }

  // Acak posisi pilihan ganda (A, B, C, D) sehingga tidak menumpuk di B
  const randomizedQuestions = randomizeQuestionsOptions(questions.slice(0, count));

  const cleanTopic = topic.charAt(0).toUpperCase() + topic.slice(1);
  return {
    is_valid: true,
    topic: cleanTopic,
    questions: randomizedQuestions,
    is_fallback: true
  };
}

function generateFallbackStudyGuide(topic, incorrectQuestions) {
  const cleanTopic = topic ? (topic.charAt(0).toUpperCase() + topic.slice(1)) : 'Umum';

  if (!incorrectQuestions || !Array.isArray(incorrectQuestions) || incorrectQuestions.length === 0) {
    return `# 📚 Panduan Belajar AI Personalisasi: ${cleanTopic}
Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.

### 🎉 Luar Biasa! Nilai Sempurna!
Anda telah menjawab semua pertanyaan dengan benar. Tidak ada materi kesalahan yang perlu diulas.
Pertahankan performa Anda atau coba tingkatkan kesulitan kuis Anda ke level berikutnya!`;
  }

  let md = `# 📚 Panduan Belajar AI Personalisasi: ${cleanTopic}
Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.

## 💡 Ulasan Konsep yang Meleset
Berikut adalah rangkuman materi dari pertanyaan-pertanyaan yang belum terjawab dengan tepat:

`;

  incorrectQuestions.forEach((q, i) => {
    const correctOpt = (q.options && q.options[q.correct_answer_index ?? q.correctAnswerIndex]) || 'Opsi Benar';
    md += `### ${i + 1}. ${q.question || 'Pertanyaan'}
* **Jawaban Benar yang Seharusnya:** \`${correctOpt}\`
* **Penjelasan Detail:**
  > ${q.explanation || 'Konsep ini penting dipahami dalam kaitannya dengan dasar topik pembelajaran.'}

`;
  });

  md += `---
## 📖 Kamus Istilah Pintar (Glossary)
Berikut daftar kosakata penting yang sangat erat kaitannya dengan topik **${cleanTopic}**:
* **Konseptual**: Kerangka berpikir teoritis yang melandasi suatu topik pembahasan.
* **Empiris**: Bukti yang diperoleh melalui pengamatan, eksperimen, atau praktik nyata di lapangan.
* **Optimasi**: Proses membuat sesuatu (sistem atau kerja) menjadi seefisien dan seefektif mungkin.
* **Integrasi**: Upaya menyatukan komponen-komponen terpisah menjadi satu kesatuan yang harmonis.

---
> [!TIP]
> Cobalah tombol **"Tambahkan pertanyaan"** di halaman hasil kuis untuk berlatih lagi pada materi yang dinilai masih lemah.
`;

  return md;
}

// ==================== ENDPOINTS ====================

// Root & Health Check Endpoint (Berguna untuk testing di browser dan monitoring Vercel)
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'QuizYu PrepMaster AI API',
    message: '🚀 Server backend berjalan lancar!',
    gemini_configured: isValidGeminiApiKey(GEMINI_API_KEY),
    endpoints: ['/api/generate-quiz', '/api/generate-study-guide']
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Endpoint 1: Membuat Kuis (POST /api/generate-quiz)
app.post('/api/generate-quiz', async (req, res) => {
  try {
    const { topic, count, difficulty, modelVersion } = req.body;
    
    if (!topic || topic.trim().length === 0) {
      return res.json({
        is_valid: false,
        error_message: 'Topik belajar tidak boleh kosong.'
      });
    }

    let questionCount = parseInt(count) || 10;

    // Deteksi jika pengguna menuliskan jumlah soal secara spesifik di dalam topik prompt (misal: "buat soal pseudecode 20", "20 soal pseudocode")
    const match1 = topic.match(/(\d+)\s*(?:soal|pertanyaan|items?|buah)/i);
    const match2 = topic.match(/(?:soal|pertanyaan|items?|buah)\s+.*?\s*(\d+)/i);
    const match3 = topic.match(/\b(\d+)\b/);
    const extractedNum = match1?.[1] || match2?.[1] || match3?.[1];
    if (extractedNum) {
      const parsed = parseInt(extractedNum, 10);
      if (!isNaN(parsed) && parsed >= 1 && parsed <= 30) {
        questionCount = parsed;
      }
    }

    const level = difficulty || 'Sedang';

    // Jika API Key belum dikonfigurasi atau tidak valid, gunakan Smart Fallback Generator langsung
    if (!isValidGeminiApiKey(GEMINI_API_KEY) || !genAI) {
      console.log(`[PrepMaster API] ℹ️ Menggunakan Smart Fallback Generator untuk topik "${topic}" (${questionCount} soal, ${level})...`);
      const fallbackResult = generateFallbackQuiz(topic, questionCount, level);
      return res.json(fallbackResult);
    }

    // Jika API Key valid, coba panggil Google Gemini AI
    console.log(`[PrepMaster API] Generating ${questionCount} questions on "${topic}" (${level}) using Gemini AI...`);

    let responseText = null;
    const modelsToTry = ['gemini-3.5-flash', 'gemini-3.1-flash-lite', 'gemini-flash-latest', 'gemini-3.8-flash'];

    for (const mName of modelsToTry) {
      try {
        const model = genAI.getGenerativeModel({ 
          model: mName,
          systemInstruction: systemPromptQuiz
        });

        const promptText = `Buatkan kuis mengenai topik: "${topic}" dengan TEPAT ${questionCount} pertanyaan (Pastikan array "questions" berisi persis ${questionCount} item soal). Tingkat kesulitan: "${level}".`;

        const result = await model.generateContent({
          contents: [{ role: "user", parts: [{ text: promptText }] }],
          generationConfig: {
            responseMimeType: "application/json",
          }
        });

        responseText = result.response.text();
        if (responseText) break;
      } catch (err) {
        console.warn(`[PrepMaster API] Model ${mName} gagal: ${err.message}. Mencoba model alternatif...`);
      }
    }

    // Jika Gemini gagal (misal kuota habis, rate limit, atau error jaringan), gunakan fallback generator
    if (!responseText) {
      console.warn('[PrepMaster API] ⚠️ Seluruh model Gemini tidak dapat dijangkau. Mengaktifkan Smart Fallback Generator...');
      const fallbackResult = generateFallbackQuiz(topic, questionCount, level);
      return res.json(fallbackResult);
    }

    let sanitizedText = responseText.trim();
    
    // Extract JSON object from first '{' to last '}'
    const firstBrace = sanitizedText.indexOf('{');
    const lastBrace = sanitizedText.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      sanitizedText = sanitizedText.substring(firstBrace, lastBrace + 1);
    }

    let quizData;
    try {
      quizData = JSON.parse(sanitizedText.trim());
    } catch (parseErr) {
      console.warn('[PrepMaster API] Direct JSON.parse failed, cleaning trailing commas/control chars...', parseErr.message);
      let cleanedJSON = sanitizedText
        .trim()
        .replace(/,\s*([\]}])/g, '$1')
        .replace(/[\u0000-\u001F\u007F-\u009F]/g, (match) => {
          if (match === '\n') return '\\n';
          if (match === '\r') return '\\r';
          if (match === '\t') return '\\t';
          return '';
        });

      const fBrace = cleanedJSON.indexOf('{');
      const lBrace = cleanedJSON.lastIndexOf('}');
      if (fBrace !== -1 && lBrace !== -1 && lBrace > fBrace) {
        cleanedJSON = cleanedJSON.substring(fBrace, lBrace + 1);
      }

      quizData = JSON.parse(cleanedJSON);
    }

    // Pastikan pilihan jawaban selalu teracak merata di antara A, B, C, D
    if (quizData && Array.isArray(quizData.questions)) {
      quizData.questions = randomizeQuestionsOptions(quizData.questions);
    }

    return res.json(quizData);
  } catch (error) {
    console.error('[PrepMaster API] Error generating quiz:', error);
    // Fallback jika terjadi error runtime tidak terduga
    const fallbackResult = generateFallbackQuiz(req.body.topic || 'Umum', parseInt(req.body.count) || 10, req.body.difficulty || 'Sedang');
    return res.json(fallbackResult);
  }
});

// Endpoint 2: Membuat Panduan Belajar (POST /api/generate-study-guide)
app.post('/api/generate-study-guide', async (req, res) => {
  try {
    const { topic, incorrectQuestions } = req.body;

    if (!topic) {
      return res.status(400).send("Parameter 'topic' diperlukan.");
    }

    // Jika API Key belum valid, gunakan Fallback Study Guide Generator
    if (!isValidGeminiApiKey(GEMINI_API_KEY) || !genAI) {
      console.log(`[PrepMaster API] ℹ️ Menggunakan Smart Fallback Study Guide untuk "${topic}"...`);
      const fallbackGuide = generateFallbackStudyGuide(topic, incorrectQuestions);
      return res.send(fallbackGuide);
    }

    if (!incorrectQuestions || !Array.isArray(incorrectQuestions) || incorrectQuestions.length === 0) {
      const emptyGuide = `# 📚 Panduan Belajar AI Personalisasi: ${topic}
Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.

### 🎉 Luar Biasa! Nilai Sempurna!
Anda telah menjawab semua pertanyaan dengan benar. Tidak ada materi kesalahan yang perlu diulas.
Pertahankan performa Anda atau coba tingkatkan kesulitan kuis Anda ke level berikutnya!`;
      return res.send(emptyGuide);
    }

    console.log(`[PrepMaster API] Generating study guide for "${topic}" with ${incorrectQuestions.length} missed questions via Gemini...`);

    const modelsToTry = ['gemini-3.5-flash', 'gemini-3.1-flash-lite', 'gemini-flash-latest', 'gemini-3.8-flash'];
    let markdown = null;

    for (const mName of modelsToTry) {
      try {
        const model = genAI.getGenerativeModel({ 
          model: mName,
          systemInstruction: systemPromptStudyGuide
        });

        const promptText = `Topik: "${topic}"
Pertanyaan yang salah dijawab oleh pengguna:
${JSON.stringify(incorrectQuestions, null, 2)}`;

        const result = await model.generateContent({
          contents: [{ role: "user", parts: [{ text: promptText }] }]
        });

        markdown = result.response.text().trim();
        if (markdown) break;
      } catch (err) {
        console.warn(`[PrepMaster API] Study guide model ${mName} gagal: ${err.message}. Mencoba model alternatif...`);
      }
    }

    if (!markdown) {
      console.warn('[PrepMaster API] Mengaktifkan Fallback Study Guide Generator...');
      return res.send(generateFallbackStudyGuide(topic, incorrectQuestions));
    }

    // Pembersihan markdown wrapper jika ada
    if (markdown.startsWith("```markdown")) {
      markdown = markdown.substring(11);
    } else if (markdown.startsWith("```")) {
      markdown = markdown.substring(3);
    }
    if (markdown.endsWith("```")) {
      markdown = markdown.substring(0, markdown.length - 3);
    }

    return res.send(markdown.trim());
  } catch (error) {
    console.error('[PrepMaster API] Error generating study guide:', error);
    return res.send(generateFallbackStudyGuide(req.body?.topic || 'Umum', req.body?.incorrectQuestions || []));
  }
});

// Export Express app agar dapat dijalankan oleh Vercel
module.exports = app;

// Jalankan server lokal hanya saat development (node index.js / npm start)
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 PrepMaster Server berjalan di http://localhost:${PORT}`);
  });
}
