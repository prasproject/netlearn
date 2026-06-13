/// NetLearn — UI Strings (Bahasa Indonesia)
/// Centralized for easy localization in the future.
class AppStrings {
  AppStrings._();

  // ── App ──
  static const String appName = 'NetLearn';
  static const String appTagline = 'Belajar Jaringan Jadi Mudah';
  static const String appVersion = 'v1.0 · Kelas X SMA · Kurikulum Merdeka';
  static const String appAuthor = 'Faridatus Shofiyah';

  // ── Auth ──
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String whatsappNumber = 'Nomor WhatsApp';
  static const String whatsappHint = '08xxxxxxxxxx';
  static const String password = 'Password';
  static const String confirmPassword = 'Konfirmasi Password';
  static const String fullName = 'Nama Lengkap';
  static const String forgotPassword = 'Lupa password?';
  static const String noAccount = 'Belum punya akun?';
  static const String hasAccount = 'Sudah punya akun?';
  static const String registerSubtitle = 'Buat akun untuk mulai belajar';
  static const String loginSubtitle = 'Masuk ke akunmu';

  // ── Home ──
  static const String welcomeBack = 'Selamat datang kembali!';
  static const String hello = 'Halo';
  static const String progressThisWeek = 'Progress Minggu Ini';
  static const String continueLearning = 'Lanjut Belajar';
  static const String mainMenu = 'Menu Utama';
  static const String badgeCollection = 'Koleksi Badge';
  static const String continueButton = 'Lanjut';

  // ── Navigation ──
  static const String navHome = 'Beranda';
  static const String navMaterial = 'Materi';
  static const String navSimulation = 'Simulasi';
  static const String navProgress = 'Progress';
  static const String navProfile = 'Profil';

  // ── Menu Cards ──
  static const String materiMenu = 'Materi';
  static const String materiSub = '5 unit tersedia';
  static const String simulasiMenu = 'Simulasi';
  static const String simulasiSub = 'IP & Routing interaktif';
  static const String quizMenu = 'Quiz';
  static const String quizSub = 'Uji pemahamanmu';
  static const String progressMenu = 'Progress';
  static const String progressSub = 'Nilai & pencapaianmu';

  // ── Streak & XP ──
  static const String days = 'Hari';
  static const String xp = 'XP';

  // ── Quiz ──
  static const String preTest = 'Pre-Test';
  static const String postTest = 'Post-Test';
  static const String checkpoint = 'Checkpoint';
  static const String finalQuiz = 'Quiz Final';
  static const String nextQuestion = 'Lanjut';
  static const String submitAnswer = 'Kirim Jawaban';
  static const String confirmAnswer = 'Konfirmasi Jawaban';
  static const String questionOf = 'Soal %d dari %d';
  static const String correct = 'Benar';
  static const String incorrect = 'Salah';
  static const String remaining = 'Sisa';

  // ── Material ──
  static const String watchVideo = 'Lihat Video';
  static const String nextSlide = 'Lanjut';
  static const String basicConcept = 'Konsep Dasar';
  static const String newBadge = 'Baru';

  // ── Simulation ──
  static const String interaktif = 'Interaktif';
  static const String sendPacket = 'Kirim Paket';
  static const String tapToRoute = 'Tap jalur untuk pilih rute berbeda';
  static const String packetSentVia = 'Status: Paket dikirim via %s ✓';
  static const String hopCount = 'Hop: %d | Jalur: %s';

  // ── Feedback ──
  static const String excellent = 'Luar Biasa!';
  static const String great = 'Bagus Sekali!';
  static const String good = 'Bagus!';
  static const String keepTrying = 'Terus Semangat!';
  static const String xpGained = '+%d XP didapat!';
  static const String newBadgeUnlocked = 'Badge Baru: %s!';
  static const String continueToNext = 'Lanjut ke Unit %d';

  // ── Progress ──
  static const String learningProgress = 'Progress Belajar';
  static const String unitsCompleted = 'Unit Selesai';
  static const String progress = 'Progress';
  static const String totalXP = 'Total XP';
  static const String learningUnits = 'Unit Belajar';
  static const String nGainTemporary = 'N-Gain Sementara';
  static const String low = 'Rendah';
  static const String medium = 'Sedang';
  static const String high = 'Tinggi';

  // ── Post-Test ──
  static const String postTestResult = 'Hasil Post-Test';
  static const String scoreComparison = 'Perbandingan Skor';
  static const String nGainScore = 'N-Gain Score';
  static const String topicScores = 'Nilai per Topik';
  static const String getCertificate = 'Ambil Sertifikat';

  // ── Certificate ──
  static const String congratulations = 'Selamat, kamu telah menyelesaikan';
  static const String certificateCourse =
      'Pembelajaran Jaringan Komputer & Internet';
  static const String certificateSchool =
      'Kelas X SMA Negeri 1 Nguter · Kurikulum Merdeka 2025';
  static const String finalScore = 'Skor Akhir';
  static const String nGain = 'N-Gain';
  static const String save = 'Simpan';
  static const String home = 'Beranda';

  // ── Profile ──
  static const String profile = 'Profil';
  static const String settings = 'Pengaturan';
  static const String darkMode = 'Mode Gelap';
  static const String audioSettings = 'Efek Suara';
  static const String musicSettings = 'Musik Latar';
  static const String language = 'Bahasa';
  static const String logout = 'Keluar';
  static const String editProfile = 'Edit Profil';
  static const String about = 'Tentang Aplikasi';

  // ── Gamification ──
  static const String level = 'Level';
  static const String streak = 'Streak';
  static const String badges = 'Badge';
  static const String dailyStreak = 'Streak Harian';
  static const String leaderboard = 'Papan Peringkat';

  // ── Motivational Messages ──
  static String getFeedbackMessage(int score) {
    if (score >= 90) {
      return 'Kamu berhasil menyelesaikan quiz dengan nilai tinggi. Tetap semangat!';
    } else if (score >= 70) {
      return 'Kerja bagus! Kamu sudah menguasai sebagian besar materi. Tingkatkan lagi!';
    } else if (score >= 50) {
      return 'Cukup baik! Coba review materi lagi untuk hasil yang lebih baik.';
    } else {
      return 'Jangan menyerah! Pelajari kembali materinya dan coba lagi.';
    }
  }

  static String getFeedbackTitle(int score) {
    if (score >= 90) return excellent;
    if (score >= 70) return great;
    if (score >= 50) return good;
    return keepTrying;
  }
}
