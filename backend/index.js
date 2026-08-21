const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_GEMINI_API_KEY_HERE') {
  console.warn("⚠️ PERINGATAN: GEMINI_API_KEY belum dikonfigurasi di file .env!");
}

// Inisialisasi Google Generative AI
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY || "");

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
   - Tentukan indeks jawaban benar (correct_answer_index) dari 0 sampai 3 (0=opsi ke-1, 1=opsi ke-2, dll).
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
    const isPro = modelVersion === 'Pro';
    
    // Pilih model kandidat dengan daftar fallback
    const modelCandidate = isPro ? 'gemini-3.5-flash' : 'gemini-3.5-flash';
    console.log(`[PrepMaster API] Generating ${questionCount} questions on "${topic}" (${level}) using model ${modelCandidate}...`);

    let responseText = null;
    let isOfflineError = false;
    const modelsToTry = [modelCandidate, 'gemini-flash-latest', 'gemini-2.0-flash-lite', 'gemini-3.1-flash-lite'];

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
        console.warn(`[PrepMaster API] Model ${mName} failed: ${err.message}. Trying next model...`);
        if (isNetworkError(err)) {
          isOfflineError = true;
          break; // Stop retrying if host has no internet connection
        }
      }
    }

    if (!responseText) {
      if (isOfflineError) {
        return res.status(503).json({
          is_valid: false,
          error_message: "[OFFLINE] Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi."
        });
      }
      return res.status(429).json({
        is_valid: false,
        error_message: "[QUOTA_EXCEEDED] Batas Kuota Gratis AI Gemini Terlampaui (Rate Limit 429). Silakan tunggu sekitar 30 detik lalu tekan Coba Lagi."
      });
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
    return res.json(quizData);
  } catch (error) {
    console.error('[PrepMaster API] Error generating quiz:', error);
    if (isNetworkError(error)) {
      return res.status(503).json({
        is_valid: false,
        error_message: "[OFFLINE] Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi."
      });
    }
    const isQuota = error.message && error.message.includes('429');
    return res.json({
      is_valid: false,
      error_message: isQuota
        ? '[QUOTA_EXCEEDED] Batas Kuota Gratis AI Gemini Terlampaui (Rate Limit 429). Silakan tunggu 30 detik dan coba lagi.'
        : `[SYSTEM_ERROR] Gagal membuat kuis karena kesalahan server: ${error.message || error}`
    });
  }
});

// Endpoint 2: Membuat Panduan Belajar (POST /api/generate-study-guide)
app.post('/api/generate-study-guide', async (req, res) => {
  try {
    const { topic, incorrectQuestions } = req.body;

    if (!topic) {
      return res.status(400).send("Parameter 'topic' diperlukan.");
    }

    if (!incorrectQuestions || !Array.isArray(incorrectQuestions) || incorrectQuestions.length === 0) {
      const emptyGuide = `# 📚 Panduan Belajar AI Personalisasi: ${topic}
Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.

### 🎉 Luar Biasa! Nilai Sempurna!
Anda telah menjawab semua pertanyaan dengan benar. Tidak ada materi kesalahan yang perlu diulas.
Pertahankan performa Anda atau coba tingkatkan kesulitan kuis Anda ke level berikutnya!`;
      return res.send(emptyGuide);
    }

    console.log(`[PrepMaster API] Generating study guide for "${topic}" with ${incorrectQuestions.length} missed questions...`);

    const modelsToTry = ['gemini-3.5-flash', 'gemini-flash-latest', 'gemini-2.0-flash-lite', 'gemini-3.1-flash-lite'];
    let markdown = null;
    let isOfflineError = false;

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
        console.warn(`[PrepMaster API] Study guide model ${mName} failed: ${err.message}. Trying next model...`);
        if (isNetworkError(err)) {
          isOfflineError = true;
          break;
        }
      }
    }

    if (!markdown) {
      if (isOfflineError) {
        return res.status(503).send("[OFFLINE] Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi.");
      }
      return res.status(429).send("[QUOTA_EXCEEDED] Batas Kuota Gratis AI Gemini Terlampaui (Rate Limit 429). Silakan tunggu 30 detik lalu tekan Coba Lagi.");
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
    if (isNetworkError(error)) {
      return res.status(503).send("[OFFLINE] Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi.");
    }
    return res.status(500).send(`[SYSTEM_ERROR] Batas pemanggilan AI terlampaui. Silakan tunggu 30 detik lalu tekan Coba Lagi.`);
  }
});

// Jalankan Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
