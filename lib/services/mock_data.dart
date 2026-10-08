import 'dart:async';
import 'dart:math';
import '../models/quiz_question.dart';

class MockDataService {
  static final Random _random = Random();

  /// Simulates calling the backend endpoint `POST /generate-quiz`.
  /// If the topic is invalid or gibberish, it returns a validation error.
  /// Otherwise, it returns a structured JSON map.
  static Future<Map<String, dynamic>> generateQuiz({
    required String topic,
    required int count,
    required String difficulty,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final normalizedTopic = topic.trim().toLowerCase();

    // Check for gibberish/invalid inputs
    if (normalizedTopic.isEmpty ||
        normalizedTopic.length < 3 ||
        _isGibberish(normalizedTopic)) {
      return {
        'is_valid': false,
        'error_message': 'Topik tidak jelas atau terlalu acak. Silakan masukkan topik belajar yang valid (contoh: "Flutter", "Sains", "Tata Surya", "Sejarah").',
      };
    }

    // Generate questions
    List<Map<String, dynamic>> questions = [];

    // Check if we have pre-defined high-quality questions for the topic
    if (normalizedTopic.contains('flutter') || normalizedTopic.contains('dart')) {
      questions = _getFlutterQuestions(count, difficulty);
    } else if (normalizedTopic.contains('kopi') || normalizedTopic.contains('coffee')) {
      questions = _getCoffeeQuestions(count, difficulty);
    } else if (normalizedTopic.contains('tata surya') || normalizedTopic.contains('solar system') || normalizedTopic.contains('planet')) {
      questions = _getSolarSystemQuestions(count, difficulty);
    } else if (normalizedTopic.contains('sejarah') || normalizedTopic.contains('indonesia')) {
      questions = _getHistoryQuestions(count, difficulty);
    } else {
      // Fallback: Generate dynamic generic questions themed with the user's topic
      questions = _generateGenericQuestions(topic, count, difficulty);
    }

    // Ensure we return exactly the requested count
    if (questions.length > count) {
      questions = questions.sublist(0, count);
    } else if (questions.length < count) {
      // If we don't have enough, pad with generic questions
      final extraNeeded = count - questions.length;
      final extra = _generateGenericQuestions(topic, extraNeeded, difficulty);
      questions.addAll(extra);
    }

    // Acak urutan pilihan jawaban untuk setiap soal agar tersebar merata (A, B, C, D)
    final randomizedQuestions = questions.map((q) {
      final options = List<String>.from(q['options'] ?? []);
      final rawIndex = q['correct_answer_index'] as int? ?? 0;
      if (options.length <= 1) return q;

      final safeIdx = (rawIndex >= 0 && rawIndex < options.length) ? rawIndex : 0;
      final correctText = options[safeIdx];

      final shuffled = List<String>.from(options)..shuffle(_random);
      final newIndex = shuffled.indexOf(correctText);

      return {
        ...q,
        'options': shuffled,
        'correct_answer_index': newIndex != -1 ? newIndex : 0,
      };
    }).toList();

    return {
      'is_valid': true,
      'topic': topic,
      'questions': randomizedQuestions,
    };
  }

  /// Simple check for typical random/gibberish keyboard typing
  static bool _isGibberish(String input) {
    final cleaned = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return true;

    // 1. Check if it contains only numbers and special characters (no letters)
    if (!RegExp(r'[a-z]').hasMatch(cleaned)) {
      return true;
    }

    // 2. Check for repetitive single characters (e.g. "aaaa", "zzzzz")
    if (RegExp(r'(.)\1{2,}').hasMatch(cleaned)) {
      return true;
    }

    // 3. Check for repetitive patterns (e.g., "asdasd", "qweqwe", "abcabc")
    if (cleaned.length >= 6) {
      final half = cleaned.length ~/ 2;
      final part1 = cleaned.substring(0, half);
      final part2 = cleaned.substring(half);
      if (part1 == part2) return true;
      
      final third = cleaned.length ~/ 3;
      final p1 = cleaned.substring(0, third);
      final p2 = cleaned.substring(third, third * 2);
      final p3 = cleaned.substring(third * 2);
      if (p1 == p2 && p2 == p3) return true;
    }

    // 4. Count vowels (a, e, i, o, u)
    // Note: 'y' is sometimes a vowel in English but let's count it as a vowel to be safe
    final vowels = RegExp(r'[aeiouy]');
    final vowelCount = vowels.allMatches(cleaned).length;
    final totalLetters = RegExp(r'[a-z]').allMatches(cleaned).length;

    if (totalLetters > 0) {
      final vowelRatio = vowelCount / totalLetters;
      // If the word has length >= 4 and has no vowels at all, it's gibberish
      if (vowelCount == 0 && totalLetters >= 3) {
        return true;
      }
      // If the word is long (>= 6 letters) and has very few vowels (e.g., less than 15% vowels)
      if (totalLetters >= 6 && vowelRatio < 0.15) {
        return true;
      }
    }

    // 5. Check for consecutive consonant runs of 4 or more (e.g., "dsfgh", "lkjh", "qwrt")
    final consonantRun = RegExp(r'[bcdfghjklmnpqrstvwxz]{4,}');
    if (consonantRun.hasMatch(cleaned)) {
      return true;
    }

    // 6. Check common keyboard sliding keys
    final smashPatterns = [
      'asdf', 'sdfg', 'dfgh', 'fghj', 'ghjk', 'hjkl',
      'qwer', 'wert', 'erty', 'rtyu', 'tyui', 'yuio', 'uiop',
      'zxcv', 'xcvb', 'cvbn', 'vbnm',
      'qaz', 'wsx', 'edc', 'rfv', 'tgb', 'yhn', 'ujm', 'ikol',
      'asd', 'qwe', 'zxc', 'jkl', 'mnb', 'poi', 'uyt', 'rew'
    ];
    for (var pattern in smashPatterns) {
      if (cleaned.contains(pattern)) {
        return true;
      }
    }

    // 7. Check if it's just random punctuation or symbols mixed with very few letters
    final letterCount = RegExp(r'[a-z]').allMatches(cleaned).length;
    if (letterCount < cleaned.length * 0.4) {
      return true; // More than 60% of the input is numbers/symbols
    }

    return false;
  }

  /// High quality mock questions for "Flutter"
  static List<Map<String, dynamic>> _getFlutterQuestions(int count, String difficulty) {
    return [
      {
        'question': 'Apa peran utama dari Widget dalam framework Flutter?',
        'options': [
          'Mengatur database lokal aplikasi',
          'Mendefinisikan elemen antarmuka pengguna (UI) secara deklaratif',
          'Mengompilasi kode Dart menjadi kode mesin',
          'Mengelola request HTTP secara asynchronous'
        ],
        'correct_answer_index': 1,
        'hint': 'Semua hal di Flutter adalah...',
        'explanation': 'Dalam Flutter, hampir semua hal adalah Widget. Widget mendefinisikan tampilan dan struktur UI secara deklaratif.'
      },
      {
        'question': 'Mengapa Riverpod dianggap lebih aman dibandingkan Provider tradisional?',
        'options': [
          'Riverpod tidak membutuhkan context untuk membaca state, sehingga menghindari error runtime saat UI dibangun',
          'Riverpod secara otomatis melakukan enkripsi pada penyimpanan data lokal',
          'Riverpod ditulis menggunakan bahasa C++ sehingga lebih cepat',
          'Riverpod hanya bekerja di platform iOS untuk keamanan ekstra'
        ],
        'correct_answer_index': 0,
        'hint': 'Pikirkan tentang ketergantungan pada BuildContext.',
        'explanation': 'Riverpod tidak bergantung pada Flutter Widget Tree (BuildContext) untuk membaca provider, sehingga meminimalkan error runtime dan aman saat kompilasi (compile-safe).'
      },
      {
        'question': 'Bagaimanakah Hot Reload berbeda dari Hot Restart di Flutter?',
        'options': [
          'Hot Reload merestart seluruh aplikasi dari awal, sedangkan Hot Restart hanya memperbarui logika',
          'Hot Reload menyuntikkan perubahan kode ke dalam VM Dart dan mempertahankan state, sementara Hot Restart membangun ulang aplikasi dan menyetel ulang state',
          'Hot Reload memerlukan instalasi ulang SDK Flutter',
          'Hot Reload hanya bekerja pada emulator Android'
        ],
        'correct_answer_index': 1,
        'hint': 'Mana yang mempertahankan data/variabel yang sedang aktif di layar?',
        'explanation': 'Hot Reload menyuntikkan kode baru ke VM Dart tanpa merestart aplikasi sehingga state layar saat itu tetap terjaga. Hot Restart menyetel ulang state aplikasi ke kondisi awal.'
      },
      {
        'question': 'Package manakah yang paling sering digunakan untuk melakukan request HTTP secara handal dengan fitur Interceptors di Flutter?',
        'options': [
          'http',
          'dio',
          'shared_preferences',
          'path_provider'
        ],
        'correct_answer_index': 1,
        'hint': 'Disebutkan dalam PRD untuk networking.',
        'explanation': 'Dio adalah library HTTP client yang powerful untuk Dart/Flutter yang mendukung Interceptors, Global Configuration, FormData, Request Cancellation, dan File Downloading.'
      },
      {
        'question': 'Manakah dari berikut ini yang merupakan deskripsi tepat dari StatelessWidget?',
        'options': [
          'Widget yang tampilannya tidak dapat berubah sepanjang siklus hidupnya setelah dibangun',
          'Widget yang memiliki animasi dinamis secara otomatis',
          'Widget yang terhubung langsung ke database cloud',
          'Widget yang menyimpan state internal yang dapat diubah menggunakan setState'
        ],
        'correct_answer_index': 0,
        'hint': 'Kata kuncinya adalah "Stateless" (tanpa keadaan/state dinamis).',
        'explanation': 'StatelessWidget adalah kelas widget immutable yang konfigurasinya tidak berubah sepanjang siklus hidupnya setelah dirender di layar.'
      },
      {
        'question': 'Fungsi utama dari filepubspec.yaml adalah untuk...',
        'options': [
          'Menulis kode logika backend Node.js',
          'Mengonfigurasi package dependencies, asset gambar, custom font, dan metadata aplikasi',
          'Mendefinisikan skema database SQLite',
          'Mengompilasi file Dart menjadi file APK'
        ],
        'correct_answer_index': 1,
        'hint': 'Tempat kita menambahkan library eksternal.',
        'explanation': 'File pubspec.yaml adalah file konfigurasi utama proyek Flutter di mana dependensi, aset, font, versi proyek, dan pengaturan SDK dideklarasikan.'
      },
      {
        'question': 'Apa kegunaan dari kata kunci "async" dan "await" pada Dart?',
        'options': [
          'Membuat eksekusi kode menjadi sinkron dan memblokir thread UI',
          'Menangani operasi asynchronous secara bersih dan mudah dibaca seolah-olah sinkron',
          'Mendeklarasikan variabel konstan yang nilainya ditentukan saat runtime',
          'Melakukan kompresi ukuran file gambar'
        ],
        'correct_answer_index': 1,
        'hint': 'Berhubungan dengan Future.',
        'explanation': 'async dan await digunakan untuk mendefinisikan fungsi asynchronous dan menunggu hasil pemrosesan Future tanpa memblokir thread utama, membuat kode asinkron lebih mudah dipahami.'
      },
      {
        'question': 'Metode siklus hidup (lifecycle) manakah yang dipanggil tepat sekali saat StatefulWidget dimasukkan ke dalam widget tree?',
        'options': [
          'build()',
          'initState()',
          'dispose()',
          'setState()'
        ],
        'correct_answer_index': 1,
        'hint': 'Inisialisasi awal state.',
        'explanation': 'initState() adalah metode pertama dari siklus hidup State yang dipanggil tepat satu kali saat widget pertama kali dibuat untuk inisialisasi awal variabel atau listener.'
      },
      {
        'question': 'Apa fungsi dari widget SafeArea?',
        'options': [
          'Mengenkripsi data sensitif pengguna agar aman dari peretas',
          'Menghindari pemotongan UI oleh takik layar (notch), status bar, atau bilah navigasi bawah perangkat',
          'Mencegah aplikasi keluar secara tidak sengaja ketika tombol back ditekan',
          'Melakukan enkripsi SSL handshake secara otomatis'
        ],
        'correct_answer_index': 1,
        'hint': 'Mengamankan area tampilan UI dari gangguan perangkat fisik.',
        'explanation': 'SafeArea menyisipkan padding yang cukup pada widget anaknya agar tidak tertutup oleh status bar perangkat, takik (notch), sudut melengkung, atau fitur hardware layar lainnya.'
      },
      {
        'question': 'Bagaimana cara mendefinisikan constructor konstan pada kelas di Dart?',
        'options': [
          'Menggunakan kata kunci final sebelum nama constructor',
          'Menggunakan kata kunci const sebelum nama constructor dan memastikan seluruh property kelas bersifat final',
          'Menambahkan modifier static pada fungsi constructor',
          'Menambahkan kata kunci constant di akhir deklarasi kelas'
        ],
        'correct_answer_index': 1,
        'hint': 'Ingat aturan immutabilitas variabel dan constructor.',
        'explanation': 'Untuk membuat constructor konstan di Dart, kita menggunakan kata kunci const sebelum nama constructor dan memastikan semua field/property dari kelas tersebut ditandai sebagai final.'
      }
    ];
  }

  /// High quality mock questions for "Kopi"
  static List<Map<String, dynamic>> _getCoffeeQuestions(int count, String difficulty) {
    return [
      {
        'question': 'Spesies kopi manakah yang menyumbang sekitar 60-70% dari produksi kopi dunia dan dikenal dengan profil rasa yang lebih halus serta kompleks?',
        'options': [
          'Coffea Canephora (Robusta)',
          'Coffea Arabica (Arabika)',
          'Coffea Liberica (Liberika)',
          'Coffea Excelsa (Ekselsa)'
        ],
        'correct_answer_index': 1,
        'hint': 'Tumbuh di dataran tinggi dengan cita rasa aromatik.',
        'explanation': 'Kopi Arabika memiliki cita rasa yang lebih manis, kompleks, dan tingkat keasaman yang lebih tinggi dibanding Robusta, serta mendominasi pasar dunia.'
      },
      {
        'question': 'Proses pasca-panen kopi di mana ceri kopi langsung dijemur di bawah sinar matahari tanpa dikupas kulitnya dinamakan...',
        'options': [
          'Wet Process (Full Washed)',
          'Dry/Natural Process',
          'Honey/Pulped Natural Process',
          'Semi-Washed (Giling Basah)'
        ],
        'correct_answer_index': 1,
        'hint': 'Kopi dikeringkan secara utuh bersama buahnya.',
        'explanation': 'Natural/Dry process adalah proses pengolahan kopi paling klasik di mana ceri kopi dikeringkan secara utuh di bawah matahari sebelum biji hijaunya dipisahkan.'
      },
      {
        'question': 'Kandungan kafein pada biji kopi Robusta rata-rata adalah...',
        'options': [
          'Lebih rendah daripada biji Arabika',
          'Hampir dua kali lipat lebih tinggi dibanding biji Arabika',
          'Sama persis dengan Arabika',
          'Nol persen karena Robusta bebas kafein'
        ],
        'correct_answer_index': 1,
        'hint': 'Pikirkan tentang ketahanan tanaman Robusta terhadap hama karena zat kimia ini.',
        'explanation': 'Robusta memiliki kadar kafein berkisar 2.2% - 2.7%, hampir dua kali lipat dibanding Arabika yang berkisar 1.2% - 1.5%. Kafein tinggi ini juga berfungsi sebagai pestisida alami.'
      },
      {
        'question': 'Alat seduh manual (manual brew) berbentuk kerucut dengan sudut 60 derajat dan ulir spiral di dinding dalamnya adalah...',
        'options': [
          'French Press',
          'V60',
          'AeroPress',
          'Syphon'
        ],
        'correct_answer_index': 1,
        'hint': 'Angka di namanya merujuk pada sudut kemiringannya.',
        'explanation': 'Hario V60 dinamakan demikian karena memiliki corong berbentuk huruf V dengan sudut kemiringan 60 derajat, menghasilkan ekstraksi kopi yang jernih dan beraroma.'
      },
      {
        'question': 'Minuman espresso yang ditambahkan dengan susu bertekstur (steamed milk) dan lapisan busa susu tebal (milk foam) di atasnya dalam proporsi seimbang dinamakan...',
        'options': [
          'Americano',
          'Cappuccino',
          'Caffè Latte',
          'Macchiato'
        ],
        'correct_answer_index': 1,
        'hint': 'Biasanya disajikan dengan taburan cokelat atau kayu manis di atas busanya.',
        'explanation': 'Cappuccino terdiri dari sepertiga espresso, sepertiga susu panas, dan sepertiga busa susu. Lapisan foam pada cappuccino lebih tebal daripada caffè latte.'
      }
    ];
  }

  /// High quality mock questions for "Tata Surya"
  static List<Map<String, dynamic>> _getSolarSystemQuestions(int count, String difficulty) {
    return [
      {
        'question': 'Planet manakah yang dikenal sebagai "Bintang Fajar" atau "Bintang Kejora" dan merupakan planet terpanas di Tata Surya kita?',
        'options': [
          'Merkurius',
          'Venus',
          'Mars',
          'Yupiter'
        ],
        'correct_answer_index': 1,
        'hint': 'Memiliki atmosfer tebal yang memerangkap panas (efek rumah kaca ekstrem).',
        'explanation': 'Venus adalah planet terpanas di Tata Surya dengan suhu permukaan mencapai 460°C akibat atmosfernya yang sangat tebal dan kaya akan karbon dioksida.'
      },
      {
        'question': 'Apakah nama planet terbesar di Tata Surya kita yang memiliki satelit alami bernama Ganymede dan badai raksasa "Great Red Spot"?',
        'options': [
          'Saturnus',
          'Yupiter',
          'Uranus',
          'Neptunus'
        ],
        'correct_answer_index': 1,
        'hint': 'Merupakan raksasa gas dengan gaya gravitasi terbesar di antara planet lainnya.',
        'explanation': 'Yupiter adalah planet terbesar di Tata Surya. Satelit alaminya, Ganymede, bahkan berukuran lebih besar daripada planet Merkurius.'
      },
      {
        'question': 'Sabuk Asteroid utama di Tata Surya kita terletak di antara orbit planet...',
        'options': [
          'Bumi dan Mars',
          'Mars dan Yupiter',
          'Yupiter dan Saturnus',
          'Venus dan Bumi'
        ],
        'correct_answer_index': 1,
        'hint': 'Membatasi planet batuan dalam dan planet gas luar.',
        'explanation': 'Sabuk Asteroid utama terletak di antara orbit Mars dan Yupiter, berisi jutaan objek berbatu yang mengitari matahari.'
      }
    ];
  }

  /// High quality mock questions for "Sejarah Indonesia"
  static List<Map<String, dynamic>> _getHistoryQuestions(int count, String difficulty) {
    return [
      {
        'question': 'Siapakah nama tokoh sejarah yang membacakan naskah teks Proklamasi Kemerdekaan Indonesia pada tanggal 17 Agustus 1945?',
        'options': [
          'Drs. Mohammad Hatta',
          'Ir. Soekarno',
          'Sutan Sjahrir',
          'Laksamana Maeda'
        ],
        'correct_answer_index': 1,
        'hint': 'Presiden pertama Republik Indonesia.',
        'explanation': 'Teks Proklamasi dibacakan oleh Ir. Soekarno didampingi oleh Drs. Mohammad Hatta di Jalan Pegangsaan Timur No. 56, Jakarta.'
      },
      {
        'question': 'Kerajaan Hindu-Buddha terbesar di Indonesia yang berpusat di Jawa Timur dan berhasil menyatukan Nusantara di bawah Sumpah Palapa Patih Gajah Mada adalah...',
        'options': [
          'Sriwijaya',
          'Majapahit',
          'Kutai Kartanegara',
          'Singasari'
        ],
        'correct_answer_index': 1,
        'hint': 'Didirikan oleh Raden Wijaya pada tahun 1293.',
        'explanation': 'Majapahit mencapai puncak keemasannya di bawah pimpinan Hayam Wuruk dan Patih Gajah Mada, menguasai wilayah luas di Asia Tenggara.'
      }
    ];
  }

  /// Generic dynamic question generator based on custom input topic
  static List<Map<String, dynamic>> _generateGenericQuestions(String topic, int count, String difficulty) {
    final capitalizedTopic = topic[0].toUpperCase() + topic.substring(1);

    List<Map<String, dynamic>> templates = [
      {
        'question': 'Apa yang menjadi pilar dasar utama ketika membahas konsep $capitalizedTopic?',
        'options': [
          'Struktur logis yang tidak memerlukan pembuktian empiris',
          'Kombinasi teori dasar, riset empiris, dan penerapan praktis secara berkala',
          'Hanya sekadar spekulasi tanpa kerangka kerja yang jelas',
          'Penggunaan perangkat keras komputer berteknologi super'
        ],
        'correct_answer_index': 1,
        'hint': 'Cari jawaban yang komprehensif menggabungkan aspek teori dan praktik.',
        'explanation': '$capitalizedTopic dibangun di atas fondasi kuat yang menyatukan teori dasar dengan pengujian empiris dan praktik langsung di lapangan.'
      },
      {
        'question': 'Manakah dari berikut ini yang merupakan manfaat utama dari mendalami topik $capitalizedTopic?',
        'options': [
          'Menghilangkan kebutuhan akan interaksi sosial manusia',
          'Memberikan keahlian analitis dan kemampuan memecahkan masalah terkait secara efektif',
          'Menjamin kekayaan materi instan tanpa kerja keras',
          'Membatasi sudut pandang hanya pada satu bidang akademis saja'
        ],
        'correct_answer_index': 1,
        'hint': 'Berpikir tentang pemecahan masalah dan kemampuan analitis.',
        'explanation': 'Mempelajari $capitalizedTopic memperluas cakrawala berpikir, mempertajam logika analitis, serta melatih kemampuan problem-solving di dunia nyata.'
      },
      {
        'question': 'Tantangan terbesar apa yang sering dihadapi para praktisi saat mencoba mengimplementasikan $capitalizedTopic?',
        'options': [
          'Kurangnya minat masyarakat pada hiburan media sosial',
          'Kompleksitas integrasi, kurva pembelajaran yang curam, serta adaptasi terhadap perubahan standar baru',
          'Biaya lisensi udara yang sangat mahal',
          'Tidak adanya referensi tulisan di internet'
        ],
        'correct_answer_index': 1,
        'hint': 'Masalah umum implementasi biasanya seputar integrasi dan adaptasi standar baru.',
        'explanation': 'Dalam ranah $capitalizedTopic, hambatan utama biasanya berasal dari perubahan standar yang dinamis serta kurva belajar yang membutuhkan dedikasi tinggi.'
      },
      {
        'question': 'Bagaimana cara terbaik untuk mempercepat penguasaan pemahaman di bidang $capitalizedTopic?',
        'options': [
          'Menghafal seluruh definisi tanpa melakukan latihan praktis',
          'Belajar secara konsisten, membuat proyek kecil mandiri, dan berdiskusi di komunitas sejenis',
          'Membaca satu buku teks sekali saja lalu tidak mengulanginya lagi',
          'Menunggu orang lain mengajarkan tanpa usaha belajar mandiri'
        ],
        'correct_answer_index': 1,
        'hint': 'Konsistensi dan pembelajaran berbasis proyek aktif.',
        'explanation': 'Metode paling efektif dalam menguasai $capitalizedTopic adalah mempraktikkan teori melalui eksperimen mandiri dan kolaborasi aktif.'
      },
      {
        'question': 'Aspek manakah dalam $capitalizedTopic yang sering disalahpahami oleh pemula?',
        'options': [
          'Nama pembuat konsep pertamanya',
          'Menganggap bahwa konsep ini bersifat kaku dan instan tanpa membutuhkan latihan berulang',
          'Warna logo dari komunitas utamanya',
          'Bahwa mempelajari ini membutuhkan keahlian seni lukis tingkat tinggi'
        ],
        'correct_answer_index': 1,
        'hint': 'Terkait harapan instan atau fleksibilitas konsep.',
        'explanation': 'Banyak pemula beranggapan $capitalizedTopic dapat dikuasai instan. Faktanya, diperlukan kesabaran, keluwesan adaptasi, dan pengulangan berkala.'
      },
      {
        'question': 'Dalam konteks perkembangan modern saat ini, bagaimana prospek masa depan dari $capitalizedTopic?',
        'options': [
          'Akan segera ditinggalkan dalam kurun waktu satu tahun ke depan',
          'Terus berintegrasi dengan AI dan teknologi digital lainnya untuk menghadirkan solusi yang lebih cerdas',
          'Akan tetap statis tanpa ada pembaruan versi sama sekali',
          'Hanya akan digunakan oleh kalangan akademisi kuno'
        ],
        'correct_answer_index': 1,
        'hint': 'Carilah jawaban yang menyangkut integrasi dengan teknologi digital modern.',
        'explanation': '$capitalizedTopic memiliki masa depan yang cerah karena sifatnya yang dinamis dan berpotensi tinggi berkolaborasi dengan inovasi digital saat ini.'
      },
      {
        'question': 'Di bawah ini yang merupakan instrumen atau tools penunjang utama dalam mempelajari $capitalizedTopic adalah...',
        'options': [
          'Kalkulator mekanik kuno',
          'Dokumentasi resmi, forum diskusi online, editor teks, dan platform latihan interaktif',
          'Papan tulis kapur tanpa koneksi internet',
          'Kamera film analog'
        ],
        'correct_answer_index': 1,
        'hint': 'Alat digital modern untuk riset dan belajar.',
        'explanation': 'Dokumentasi terstruktur serta forum komunitas online adalah fondasi pendukung yang tak ternilai bagi siapa saja yang ingin mendalami $capitalizedTopic.'
      },
      {
        'question': 'Perbedaan utama antara level dasar (basic) dan level lanjutan (advanced) dalam topik $capitalizedTopic adalah...',
        'options': [
          'Level lanjutan hanya menggunakan istilah bahasa asing yang rumit',
          'Level lanjutan melibatkan penyelesaian masalah optimasi kompleks, integrasi multifaktor, dan efisiensi sistem',
          'Level dasar tidak memiliki aturan tertulis sama sekali',
          'Level dasar hanya diajarkan di tingkat sekolah dasar saja'
        ],
        'correct_answer_index': 1,
        'hint': 'Level lanjutan fokus pada optimasi dan integrasi kompleks.',
        'explanation': 'Naik ke tingkat advanced dalam $capitalizedTopic berarti Anda harus bisa menyelesaikan optimasi performa serta merancang sistem yang efisien dan kokoh.'
      },
      {
        'question': 'Bagaimanakah dampak penyalahgunaan konsep $capitalizedTopic terhadap suatu sistem?',
        'options': [
          'Sistem akan menjadi lebih berwarna dan menarik',
          'Terjadinya inefisiensi, kerentanan keamanan, serta kegagalan sistem dalam memproses data secara akurat',
          'Sistem otomatis mati secara permanen dan tidak bisa dinyalakan lagi',
          'Tidak ada dampak negatif sama sekali'
        ],
        'correct_answer_index': 1,
        'hint': 'Salah penerapan biasanya berakibat pada performa dan keamanan.',
        'explanation': 'Penerapan yang serampangan pada konsep $capitalizedTopic dapat melemahkan struktur sistem, menciptakan bug tersembunyi, dan memperlambat kinerja.'
      },
      {
        'question': 'Siapa sajakah yang disarankan untuk memiliki pemahaman dasar tentang $capitalizedTopic?',
        'options': [
          'Hanya anak-anak usia prasekolah',
          'Pelajar, praktisi industri terkait, akademisi, dan siapa saja yang ingin meningkatkan literasi tentang topik ini',
          'Hanya insinyur astronot saja',
          'Orang yang tidak menggunakan perangkat digital'
        ],
        'correct_answer_index': 1,
        'hint': 'Semua orang yang berminat mengembangkan pemahamannya.',
        'explanation': 'Literasi mengenai $capitalizedTopic sangat berguna bagi pelajar maupun profesional modern agar tetap relevan di era perkembangan yang cepat.'
      },
      {
        'question': 'Bagaimana cara mengevaluasi tingkat keberhasilan atau efektivitas dari penerapan $capitalizedTopic?',
        'options': [
          'Hanya berdasarkan intuisi tanpa data pendukung',
          'Melakukan pengukuran parameter performa, audit sistem, dan analisis feedback secara berkala',
          'Membandingkannya dengan topik akademis yang tidak relevan',
          'Menghentikan seluruh operasional untuk melihat dampaknya'
        ],
        'correct_answer_index': 1,
        'hint': 'Evaluasi membutuhkan data terukur, audit, dan feedback.',
        'explanation': 'Keberhasilan implementasi $capitalizedTopic diukur secara objektif melalui indikator performa utama (KPI) serta umpan balik berkala.'
      },
      {
        'question': 'Dalam memecahkan masalah kompleks menggunakan $capitalizedTopic, langkah pertama yang wajib dilakukan adalah...',
        'options': [
          'Mencari solusi instan di internet tanpa analisis',
          'Menganalisis akar permasalahan, mengumpulkan data awal, dan menetapkan batasan masalah',
          'Menyalahkan kegagalan sistem sebelumnya',
          'Mengabaikan detail kecil dan langsung membuat kesimpulan'
        ],
        'correct_answer_index': 1,
        'hint': 'Analisis akar masalah dan pengumpulan data adalah langkah awal yang krusial.',
        'explanation': 'Sebelum menerapkan solusi berbasis $capitalizedTopic, penting untuk memahami masalah secara mendalam dengan mengidentifikasi akar penyebabnya.'
      },
      {
        'question': 'Di era digital saat ini, faktor manakah yang paling mempercepat evolusi dari $capitalizedTopic?',
        'options': [
          'Penurunan minat masyarakat terhadap teknologi',
          'Ketersediaan data besar (Big Data), komputasi awan, dan adopsi kecerdasan buatan (AI)',
          'Penggunaan metode pencatatan manual di atas kertas',
          'Pembatasan akses informasi secara global'
        ],
        'correct_answer_index': 1,
        'hint': 'Pikirkan tentang teknologi modern seperti AI, Big Data, dan cloud.',
        'explanation': 'Kemajuan teknologi komputasi, akses informasi yang cepat, serta AI secara dramatis mempercepat perkembangan dan penerapan $capitalizedTopic.'
      },
      {
        'question': 'Mengapa penting untuk terus memperbarui pengetahuan kita mengenai standar terbaru dalam $capitalizedTopic?',
        'options': [
          'Hanya untuk sekadar formalitas sertifikat saja',
          'Agar tetap relevan, aman, dan mampu menerapkan praktik terbaik (best practices) yang efisien',
          'Karena standar lama otomatis merusak perangkat keras',
          'Untuk membingungkan rekan kerja lainnya'
        ],
        'correct_answer_index': 1,
        'hint': 'Agar relevan, aman, dan efisien.',
        'explanation': 'Industri yang melibatkan $capitalizedTopic terus berkembang; mengikuti standar terbaru menjamin keamanan dan optimalitas sistem.'
      },
      {
        'question': 'Bagaimanakah keterkaitan erat antara konsep $capitalizedTopic dengan peningkatan efisiensi kerja?',
        'options': [
          'Tidak ada kaitan sama sekali karena keduanya berjalan terpisah',
          'Penerapan prinsip terstruktur mengurangi redundansi proses dan mengoptimalkan sumber daya',
          'Dengan menambah beban kerja manual bagi semua anggota tim',
          'Dengan memperpanjang birokrasi pengambilan keputusan'
        ],
        'correct_answer_index': 1,
        'hint': 'Mengurangi redundansi dan mengoptimalkan sumber daya.',
        'explanation': 'Prinsip-prinsip dalam $capitalizedTopic berfokus pada efisiensi proses, pengurangan pemborosan waktu, dan pemanfaatan aset secara maksimal.'
      },
      {
        'question': 'Dalam merancang sebuah strategi yang melibatkan $capitalizedTopic, aspek utama apa yang harus diprioritaskan?',
        'options': [
          'Tampilan visual tanpa memperhatikan fungsi dasarnya',
          'Keselarasan dengan tujuan jangka panjang, skalabilitas, dan pengelolaan risiko',
          'Biaya termurah tanpa memikirkan kualitas',
          'Opini subjektif dari satu pihak saja'
        ],
        'correct_answer_index': 1,
        'hint': 'Skalabilitas, keselarasan jangka panjang, dan manajemen risiko.',
        'explanation': 'Desain strategi $capitalizedTopic yang solid harus berorientasi pada masa depan (skalabel) dan memperhitungkan mitigasi risiko.'
      },
      {
        'question': 'Salah satu kesalahan umum yang sering diabaikan saat mempelajari $capitalizedTopic adalah...',
        'options': [
          'Belajar terlalu detail dan melakukan banyak latihan praktis',
          'Mengabaikan pemahaman konsep teoritis fundamental dan langsung melompat ke praktik tingkat lanjut',
          'Mengikuti tutorial dari dokumentasi resmi',
          'Berdiskusi dengan para ahli di bidangnya'
        ],
        'correct_answer_index': 1,
        'hint': 'Melewatkan konsep dasar demi hasil instan.',
        'explanation': 'Tanpa fondasi teori dasar yang kuat pada $capitalizedTopic, praktisi akan kesulitan memecahkan masalah kompleks yang tidak tercakup dalam tutorial standar.'
      },
      {
        'question': 'Bagaimana pengaruh langsung dari $capitalizedTopic terhadap pengambilan keputusan strategis di industri?',
        'options': [
          'Membuat keputusan menjadi lebih lambat dan tidak terarah',
          'Menyediakan data analitis, prediksi tren, dan kerangka kerja logis untuk meminimalkan spekulasi',
          'Menghapus wewenang pimpinan perusahaan',
          'Mewajibkan semua keputusan diambil oleh kecerdasan buatan sepenuhnya'
        ],
        'correct_answer_index': 1,
        'hint': 'Menyediakan analisis data dan prediksi tren untuk meminimalkan tebakan.',
        'explanation': 'Implementasi $capitalizedTopic memberikan landasan berbasis data (data-driven) yang kuat sehingga keputusan bisnis lebih akurat dan terukur.'
      },
      {
        'question': 'Manakah dari karakteristik berikut yang paling mendefinisikan kualitas terbaik dalam ekosistem $capitalizedTopic?',
        'options': [
          'Sifatnya yang tertutup dan tidak menerima masukan baru',
          'Fleksibilitas terhadap perubahan, keamanan yang kokoh, dan interoperabilitas tinggi',
          'Ketergantungan penuh pada satu vendor saja',
          'Kompleksitas tinggi yang sulit dipahami oleh siapa pun'
        ],
        'correct_answer_index': 1,
        'hint': 'Fleksibel, aman, dan mudah terintegrasi.',
        'explanation': 'Sistem $capitalizedTopic yang andal harus adaptif terhadap perkembangan teknologi baru serta menjamin keamanan data yang diolah.'
      },
      {
        'question': 'Mengapa pemahaman etika dan regulasi menjadi penting dalam implementasi praktis $capitalizedTopic?',
        'options': [
          'Hanya untuk menghindari denda finansial semata',
          'Untuk melindungi privasi pengguna, menjamin keadilan, dan menjaga kepercayaan publik',
          'Karena etika membatasi kreativitas inovasi secara total',
          'Untuk membuat proses implementasi menjadi rumit'
        ],
        'correct_answer_index': 1,
        'hint': 'Melindungi privasi dan membangun kepercayaan publik.',
        'explanation': 'Penerapan etika dan kepatuhan regulasi dalam $capitalizedTopic memastikan bahwa inovasi yang dihasilkan memberikan dampak positif tanpa merugikan hak-hak individu.'
      },
      {
        'question': 'Bagaimana cara mengidentifikasi kegagalan awal dalam sebuah sistem yang menerapkan $capitalizedTopic?',
        'options': [
          'Menunggu sampai seluruh sistem mengalami kerusakan total',
          'Melakukan pemantauan metrik (monitoring) secara real-time dan menganalisis log aktivitas',
          'Mengasumsikan bahwa sistem selalu berjalan tanpa kesalahan',
          'Menghapus semua file log untuk menyembunyikan masalah'
        ],
        'correct_answer_index': 1,
        'hint': 'Pemantauan real-time dan analisis log aktivitas.',
        'explanation': 'Deteksi dini kegagalan pada $capitalizedTopic bergantung pada sistem monitoring yang proaktif dan analisis log secara cermat.'
      },
      {
        'question': 'Apa kontribusi paling signifikan dari $capitalizedTopic terhadap perkembangan ilmu pengetahuan modern?',
        'options': [
          'Menyediakan hiburan instan tanpa nilai edukasi',
          'Menciptakan metodologi baru untuk memproses informasi dan memecahkan masalah secara terstruktur',
          'Menggantikan seluruh teori fisika klasik secara total',
          'Membatasi riset hanya pada satu lembaga riset saja'
        ],
        'correct_answer_index': 1,
        'hint': 'Metodologi pemecahan masalah secara terstruktur.',
        'explanation': 'Secara ilmiah, $capitalizedTopic memperkaya cara pandang peneliti dalam memodelkan masalah kompleks secara logis dan terukur.'
      },
      {
        'question': 'Dalam mengoptimalkan performa $capitalizedTopic, parameter kunci manakah yang harus diukur secara berkala?',
        'options': [
          'Jumlah warna yang digunakan dalam diagram presentasi',
          'Waktu respons, konsumsi sumber daya, throughput, dan tingkat akurasi keluaran',
          'Opini dari pihak luar yang tidak menggunakan sistem',
          'Merek perangkat keras yang digunakan oleh tim pengembang'
        ],
        'correct_answer_index': 1,
        'hint': 'Responsivitas, pemakaian daya/sumber daya, throughput, akurasi.',
        'explanation': 'Optimasi performa $capitalizedTopic membutuhkan data kuantitatif mengenai kecepatan proses, efisiensi resource, dan tingkat error.'
      },
      {
        'question': 'Faktor eksternal manakah yang paling sering menghambat penyebaran pemahaman tentang $capitalizedTopic?',
        'options': [
          'Kurangnya materi gratis di internet',
          'Kesenjangan infrastruktur teknologi dan kurangnya kurikulum pendidikan yang adaptif',
          'Minat masyarakat yang terlalu tinggi untuk belajar',
          'Biaya pembuatan akun media sosial'
        ],
        'correct_answer_index': 1,
        'hint': 'Masalah infrastruktur dan kurikulum pendidikan.',
        'explanation': 'Adopsi pemahaman $capitalizedTopic seringkali terhambat oleh akses teknologi yang tidak merata serta lambatnya pembaruan materi ajar di lembaga pendidikan.'
      },
      {
        'question': 'Bagaimana pendekatan terbaik untuk mengajarkan konsep dasar $capitalizedTopic kepada orang awam?',
        'options': [
          'Menggunakan jargon-jargon teknis yang rumit sejak hari pertama',
          'Menghubungkannya dengan analogi kehidupan sehari-hari dan memberikan contoh kasus sederhana',
          'Meminta mereka menghafal formula matematika yang kompleks',
          'Langsung memberikan tugas pemrograman tingkat lanjut'
        ],
        'correct_answer_index': 1,
        'hint': 'Analogi sehari-hari dan contoh sederhana.',
        'explanation': 'Pemahaman awal $capitalizedTopic lebih mudah terbentuk jika dikaitkan dengan pengalaman nyata yang sudah akrab dengan kehidupan sehari-hari.'
      },
      {
        'question': 'Manakah di bawah ini yang merupakan mitos yang salah mengenai cara kerja $capitalizedTopic?',
        'options': [
          'Membutuhkan proses belajar yang berkelanjutan',
          'Bahwa konsep ini dapat menyelesaikan semua masalah secara instan tanpa konfigurasi kustom',
          'Membutuhkan pemikiran logis dan analisis data',
          'Dapat diintegrasikan dengan teknologi modern'
        ],
        'correct_answer_index': 1,
        'hint': 'Mitos seputar penyelesaian instan (silver bullet).',
        'explanation': 'Tidak ada solusi tunggal (silver bullet). Penerapan $capitalizedTopic selalu menuntut penyesuaian (tuning) agar sesuai kebutuhan spesifik.'
      },
      {
        'question': 'Bagaimanakah cara mengintegrasikan $capitalizedTopic dengan disiplin ilmu atau bidang kerja lainnya?',
        'options': [
          'Menolak kolaborasi lintas bidang dan fokus pada satu disiplin saja',
          'Membangun antarmuka (interface) penghubung, menyelaraskan format data, dan berkolaborasi tim multidisiplin',
          'Memaksa bidang lain mengikuti seluruh aturan teknis kita secara kaku',
          'Menghentikan penggunaan teknologi di bidang lain tersebut'
        ],
        'correct_answer_index': 1,
        'hint': 'Membangun interface, format data sama, kolaborasi tim.',
        'explanation': 'Keberhasilan integrasi $capitalizedTopic dengan domain lain membutuhkan keluwesan komunikasi, standardisasi data, dan kerja sama tim lintas keahlian.'
      },
      {
        'question': 'Dalam jangka panjang, bagaimana investasi waktu untuk mempelajari $capitalizedTopic memberikan hasil?',
        'options': [
          'Tidak memberikan hasil apa pun karena ilmu ini cepat usang',
          'Meningkatkan daya saing profesional, membuka peluang karier baru, dan mempermudah inovasi mandiri',
          'Menyebabkan kelelahan mental tanpa keuntungan finansial atau intelektual',
          'Hanya berguna untuk lulus ujian sekolah saja'
        ],
        'correct_answer_index': 1,
        'hint': 'Peluang karir, daya saing profesional, dan inovasi.',
        'explanation': 'Menguasai $capitalizedTopic adalah investasi bernilai tinggi karena keterampilannya sangat dicari di era industri modern berbasis teknologi.'
      },
      {
        'question': 'Fase kritis manakah dalam siklus hidup $capitalizedTopic yang membutuhkan perhatian paling mendalam?',
        'options': [
          'Fase perayaan peluncuran produk saja',
          'Fase perencanaan awal, pengujian kualitas, serta pemeliharaan pasca-rilis',
          'Saat memilih nama logo proyek',
          'Saat mencetak dokumen laporan akhir'
        ],
        'correct_answer_index': 1,
        'hint': 'Perencanaan awal, pengetesan kualitas, dan perawatan jangka panjang.',
        'explanation': 'Kegagalan pada fase perencanaan atau pengabaian pada tahap pemeliharaan sistem $capitalizedTopic sering menjadi penyebab utama crash fatal di kemudian hari.'
      },
      {
        'question': 'Apa kesimpulan utama yang dapat diambil setelah menganalisis tren perkembangan $capitalizedTopic tren saat ini?',
        'options': [
          'Perkembangannya telah stagnan dan tidak akan ada inovasi baru lagi',
          'Penerapannya kian meluas, didorong oleh kolaborasi digital, dan menuntut adaptabilitas tinggi dari para praktisi',
          'Hanya negara maju saja yang dapat memanfaatkannya',
          'Semua teori lamanya terbukti salah secara keseluruhan'
        ],
        'correct_answer_index': 1,
        'hint': 'Adopsi meluas dan perlunya adaptasi yang tinggi.',
        'explanation': 'Tren menunjukkan $capitalizedTopic menjadi fondasi penting di berbagai sektor, menuntut kita untuk terus belajar dan beradaptasi dengan perubahan.'
      }
    ];

    // Shuffle and pick elements based on count
    final List<Map<String, dynamic>> results = List.from(templates);
    results.shuffle(_random);

    return results.take(count).toList();
  }

  /// Generates the AI Study Guide Markdown based on the quiz session's missed questions
  static Future<String> generateStudyGuide({
    required String topic,
    required List<QuizQuestion> incorrectQuestions,
  }) async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final buffer = StringBuffer();
    buffer.writeln('# 📚 Panduan Belajar AI Personalisasi: $topic');
    buffer.writeln('Diulas berdasarkan hasil evaluasi kuis Anda di sesi ini.');
    buffer.writeln();

    if (incorrectQuestions.isEmpty) {
      buffer.writeln('### 🎉 Luar Biasa! Nilai Sempurna!');
      buffer.writeln('Anda telah menjawab semua pertanyaan dengan benar. Tidak ada materi kesalahan yang perlu diulas.');
      buffer.writeln('Pertahankan performa Anda atau coba tingkatkan kesulitan kuis Anda ke level berikutnya!');
      return buffer.toString();
    }

    buffer.writeln('## 💡 Ulasan Konsep yang Meleset');
    buffer.writeln('Berikut adalah rangkuman materi dari pertanyaan-pertanyaan yang belum terjawab dengan tepat. Silakan pelajari poin-poin berikut:');
    buffer.writeln();

    for (int i = 0; i < incorrectQuestions.length; i++) {
      final question = incorrectQuestions[i];
      buffer.writeln('### ${i + 1}. ${question.question}');
      buffer.writeln('* **Jawaban Benar yang Seharusnya:** `${question.options[question.correctAnswerIndex]}`');
      buffer.writeln('* **Penjelasan Detail:**');
      buffer.writeln('  > ${question.explanation}');
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('## 📖 Kamus Istilah Pintar (Glossary)');
    buffer.writeln('Berikut beberapa daftar kosakata penting yang sangat erat kaitannya dengan topik **$topic** agar Anda lebih memahaminya:');
    buffer.writeln();

    if (topic.toLowerCase().contains('flutter')) {
      buffer.writeln('* **Widget**: Komponen penyusun dasar UI di Flutter yang merepresentasikan konfigurasi visual.');
      buffer.writeln('* **Riverpod**: Solusi state management modern untuk Dart & Flutter yang compile-safe dan unidirectional.');
      buffer.writeln('* **Asynchronous (async/await)**: Pola pemrograman yang memungkinkan tugas-tugas berat (seperti fetch API) berjalan di latar belakang tanpa mengunci interface pengguna.');
      buffer.writeln('* **Hot Reload**: Mekanisme menyuntikkan kode baru ke VM Dart tanpa mereset status widget di emulator.');
    } else if (topic.toLowerCase().contains('kopi')) {
      buffer.writeln('* **Arabica**: Spesies kopi dataran tinggi yang terkenal akan cita rasa buah, keasaman tinggi, dan kafein lebih rendah.');
      buffer.writeln('* **Robusta**: Kopi dataran rendah dengan rasa pahit pekat (bold) yang kaya akan kafein dan tubuh (body) yang tebal.');
      buffer.writeln('* **Manual Brew**: Metode menyeduh kopi secara manual tanpa mesin listrik (misalnya tuang air melalui filter kertas V60).');
      buffer.writeln('* **Espresso**: Ekstraksi bubuk kopi padat menggunakan air panas bertekanan tinggi dalam waktu singkat (sekitar 20-30 detik).');
    } else if (topic.toLowerCase().contains('tata surya') || topic.toLowerCase().contains('planet')) {
      buffer.writeln('* **Efek Rumah Kaca**: Fenomena di mana gas atmosfer menahan radiasi infra merah matahari sehingga memicu kenaikan suhu ekstrem, seperti yang terjadi di Venus.');
      buffer.writeln('* **Sabuk Asteroid**: Wilayah berbentuk cincin di antara Mars dan Yupiter yang dipadati oleh bebatuan luar angkasa sisa pembentukan tata surya.');
      buffer.writeln('* **Satelit Alami**: Benda angkasa yang mengitari sebuah planet (seperti Bulan bagi Bumi atau Ganymede bagi Yupiter).');
    } else {
      buffer.writeln('* **Konseptual**: Kerangka berpikir teoritis yang melandasi suatu topik pembahasan.');
      buffer.writeln('* **Empiris**: Bukti yang diperoleh melalui pengamatan, eksperimen, atau praktik nyata di lapangan.');
      buffer.writeln('* **Optimasi**: Proses membuat sesuatu (sistem, algoritma, atau kerja) menjadi seefisien dan seefektif mungkin.');
      buffer.writeln('* **Integrasi**: Upaya menyatukan komponen-komponen terpisah menjadi satu kesatuan sistem yang harmonis.');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('> [!TIP]');
    buffer.writeln('> Cobalah tombol **"Tambahkan pertanyaan"** di halaman hasil kuis untuk berlatih lagi pada materi yang dinilai masih lemah (fokus pada **Peluang perbaikan**).');

    return buffer.toString();
  }
}
