import '../models/material_model.dart';
import '../models/quiz_model.dart';
import '../models/simulation_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';

/// NetLearn — Seed Data for 5 units of networking curriculum.
class SeedData {
  SeedData._();

  // ── Demo User ──
  static final UserModel demoUser = UserModel(
    id: 'demo-user-1',
    displayName: 'Faridatus Shofiyah',
    phoneNumber: '081234567890',
    xp: 120,
    level: 2,
    streak: 3,
    lastActive: DateTime.now(),
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    unlockedBadgeIds: ['badge-1', 'badge-2'],
    role: 'student',
  );

  // ── Demo Admin ──
  static final UserModel demoAdmin = UserModel(
    id: 'demo-admin-1',
    displayName: 'Admin NetLearn',
    phoneNumber: '080000000000',
    xp: 9999,
    level: 99,
    streak: 99,
    lastActive: DateTime.now(),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    role: 'admin',
  );

  // ── Materials (5 Units) ──
  static final List<MaterialModel> materials = [
    MaterialModel(
      id: 'unit-1', unitNumber: 1, order: 0, iconEmoji: '🌐',
      title: 'Pengantar Jaringan Komputer',
      description: 'Dasar-dasar jaringan komputer dan internet',
      slides: [
        const MaterialSlide(
          title: 'Apa itu Jaringan Komputer?',
          content: 'Jaringan komputer adalah kumpulan dua atau lebih komputer yang saling terhubung untuk berbagi data dan sumber daya. Jaringan memungkinkan komunikasi antar perangkat.',
          imageDescription: 'Ilustrasi beberapa komputer terhubung',
          keywords: ['jaringan', 'komputer', 'koneksi'],
        ),
        const MaterialSlide(
          title: 'Jenis-Jenis Jaringan',
          content: 'LAN (Local Area Network): Jaringan lokal dalam satu gedung.\nMAN (Metropolitan Area Network): Jaringan antar gedung dalam satu kota.\nWAN (Wide Area Network): Jaringan antar kota atau negara.\nInternet: Jaringan global terbesar.',
          keywords: ['LAN', 'MAN', 'WAN', 'Internet'],
        ),
        const MaterialSlide(
          title: 'Topologi Jaringan',
          content: 'Topologi Bus: Semua perangkat terhubung ke satu kabel utama.\nTopologi Star: Semua perangkat terhubung ke hub/switch pusat.\nTopologi Ring: Perangkat terhubung membentuk lingkaran.\nTopologi Mesh: Setiap perangkat terhubung langsung satu sama lain.',
          keywords: ['topologi', 'bus', 'star', 'ring', 'mesh'],
        ),
        const MaterialSlide(
          title: 'Perangkat Jaringan',
          content: 'Hub: Menghubungkan perangkat, mengirim data ke semua port.\nSwitch: Seperti hub tapi lebih pintar, mengirim data ke port tujuan.\nRouter: Menghubungkan dua jaringan berbeda.\nModem: Mengubah sinyal digital ke analog dan sebaliknya.',
          keywords: ['hub', 'switch', 'router', 'modem'],
        ),
      ],
    ),
    MaterialModel(
      id: 'unit-2', unitNumber: 2, order: 1, iconEmoji: '🔢',
      title: 'IP Addressing',
      description: 'Memahami alamat IP dan subnetting',
      slides: [
        const MaterialSlide(
          title: 'Apa itu IP Address?',
          content: 'IP Address adalah alamat unik yang diberikan kepada setiap perangkat dalam jaringan komputer, seperti alamat rumah yang memungkinkan paket data sampai ke tujuan yang tepat.',
          imageDescription: 'Diagram PC-Router-Server dengan IP address',
          keywords: ['IP', 'address', 'IPv4'],
        ),
        const MaterialSlide(
          title: 'Kelas IP Address',
          content: 'Kelas A: 1.0.0.0 - 126.255.255.255 (jaringan besar)\nKelas B: 128.0.0.0 - 191.255.255.255 (menengah)\nKelas C: 192.0.0.0 - 223.255.255.255 (kecil)\nKelas D: Multicast\nKelas E: Eksperimental',
          keywords: ['kelas', 'A', 'B', 'C'],
        ),
        const MaterialSlide(
          title: 'Subnet Mask',
          content: 'Subnet mask memisahkan bagian network dan host dari IP address. Contoh subnet mask: 255.255.255.0 (/24). Network ID mengidentifikasi jaringan, Host ID mengidentifikasi perangkat.',
          keywords: ['subnet', 'mask', 'network', 'host'],
        ),
        const MaterialSlide(
          title: 'IPv4 vs IPv6',
          content: 'IPv4: 32-bit, format desimal bertitik (192.168.1.1)\nIPv6: 128-bit, format heksadesimal (2001:0db8::1)\nIPv6 dibuat karena alamat IPv4 hampir habis.',
          keywords: ['IPv4', 'IPv6'],
        ),
        const MaterialSlide(
          title: 'IP Private vs Public',
          content: 'IP Private: Digunakan dalam jaringan lokal (10.x.x.x, 172.16-31.x.x, 192.168.x.x)\nIP Public: Digunakan di internet, unik secara global.\nNAT: Mengubah IP private ke public agar bisa mengakses internet.',
          keywords: ['private', 'public', 'NAT'],
        ),
      ],
    ),
    MaterialModel(
      id: 'unit-3', unitNumber: 3, order: 2, iconEmoji: '🔄',
      title: 'Routing Dasar',
      description: 'Konsep routing dan forwarding paket data',
      slides: [
        const MaterialSlide(
          title: 'Apa itu Routing?',
          content: 'Routing adalah proses memilih jalur terbaik untuk mengirim paket data dari sumber ke tujuan melalui jaringan. Router menggunakan tabel routing untuk menentukan jalur.',
          keywords: ['routing', 'jalur', 'paket'],
        ),
        const MaterialSlide(
          title: 'Routing Statis vs Dinamis',
          content: 'Routing Statis: Administrator mengatur rute secara manual. Cocok untuk jaringan kecil.\nRouting Dinamis: Router saling bertukar informasi rute secara otomatis. Cocok untuk jaringan besar.',
          keywords: ['statis', 'dinamis'],
        ),
        const MaterialSlide(
          title: 'Tabel Routing',
          content: 'Tabel routing berisi: Network tujuan, Subnet mask, Gateway (next hop), Interface, Metric (jarak). Router membaca tabel ini untuk menentukan ke mana paket dikirim.',
          keywords: ['tabel', 'gateway', 'metric'],
        ),
      ],
    ),
    MaterialModel(
      id: 'unit-4', unitNumber: 4, order: 3, iconEmoji: '🔗',
      title: 'Konektivitas & Protokol',
      description: 'Protokol jaringan dan model OSI/TCP-IP',
      isLocked: false,
      slides: [
        const MaterialSlide(
          title: 'Model OSI 7 Layer',
          content: '7. Application - HTTP, FTP\n6. Presentation - Enkripsi\n5. Session - Sesi komunikasi\n4. Transport - TCP, UDP\n3. Network - IP, Routing\n2. Data Link - MAC Address\n1. Physical - Kabel, sinyal',
          keywords: ['OSI', 'layer', 'model'],
        ),
        const MaterialSlide(
          title: 'Protokol TCP vs UDP',
          content: 'TCP (Transmission Control Protocol): Reliable, connection-oriented, lambat. Contoh: web browsing, email.\nUDP (User Datagram Protocol): Unreliable, connectionless, cepat. Contoh: streaming video, game online.',
          keywords: ['TCP', 'UDP', 'protokol'],
        ),
        const MaterialSlide(
          title: 'HTTP dan DNS',
          content: 'HTTP: Protokol untuk mengakses web. HTTPS menambahkan enkripsi.\nDNS: Mengubah nama domain (google.com) menjadi IP address (142.250.x.x). Seperti buku telepon internet.',
          keywords: ['HTTP', 'DNS', 'domain'],
        ),
      ],
    ),
    MaterialModel(
      id: 'unit-5', unitNumber: 5, order: 4, iconEmoji: '🔒',
      title: 'Keamanan Jaringan',
      description: 'Enkripsi data dan keamanan jaringan',
      isLocked: true,
      slides: [
        const MaterialSlide(
          title: 'Ancaman Keamanan Jaringan',
          content: 'Malware: Virus, worm, trojan\nPhishing: Penipuan untuk mencuri data\nDDoS: Serangan membanjiri server\nMan-in-the-Middle: Menyadap komunikasi',
          keywords: ['malware', 'phishing', 'DDoS'],
        ),
        const MaterialSlide(
          title: 'Firewall dan Enkripsi',
          content: 'Firewall: Memfilter lalu lintas jaringan berdasarkan aturan keamanan.\nEnkripsi: Mengubah data menjadi kode rahasia. Contoh: AES, RSA.\nSSL/TLS: Enkripsi untuk koneksi web (HTTPS).',
          keywords: ['firewall', 'enkripsi', 'SSL'],
        ),
      ],
    ),
  ];

  // ── Quizzes ──
  static final List<QuizModel> quizzes = [
    // Pre-Test (covers all topics)
    QuizModel(
      id: 'pretest-1', type: QuizType.pretest, title: 'Pre-Test',
      timeLimitSeconds: 900, xpReward: 15,
      questions: [
        const QuizQuestion(question: 'Perangkat yang menghubungkan dua jaringan berbeda disebut...', options: ['Hub', 'Router', 'Switch', 'Modem'], correctIndex: 1, explanation: 'Router menghubungkan dua jaringan berbeda dan menentukan jalur terbaik untuk mengirim data.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Berapa oktet yang dimiliki sebuah alamat IPv4?', options: ['2 oktet', '4 oktet', '6 oktet', '8 oktet'], correctIndex: 1, explanation: 'IPv4 memiliki 4 oktet, masing-masing 8 bit, total 32 bit.', topic: 'IP Address'),
        const QuizQuestion(question: 'Kelas IP Address yang digunakan untuk jaringan skala besar adalah...', options: ['Kelas A (1–126.x.x.x)', 'Kelas B (128–191.x.x.x)', 'Kelas C (192–223.x.x.x)', 'Kelas D (224–239.x.x.x)'], correctIndex: 0, explanation: 'Kelas A mendukung jutaan host per jaringan.', topic: 'IP Address'),
        const QuizQuestion(question: 'Topologi jaringan di mana semua perangkat terhubung ke satu perangkat pusat adalah...', options: ['Bus', 'Star', 'Ring', 'Mesh'], correctIndex: 1, explanation: 'Topologi Star menggunakan hub/switch sebagai pusat.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Protokol yang menjamin pengiriman data secara reliable adalah...', options: ['UDP', 'TCP', 'ICMP', 'ARP'], correctIndex: 1, explanation: 'TCP memastikan data sampai dengan benar melalui handshake dan acknowledgment.', topic: 'Protokol'),
        const QuizQuestion(question: 'LAN adalah singkatan dari...', options: ['Large Area Network', 'Local Area Network', 'Long Area Network', 'Linked Area Network'], correctIndex: 1, explanation: 'LAN = Local Area Network, jaringan dalam area terbatas.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Subnet mask default untuk kelas C adalah...', options: ['255.0.0.0', '255.255.0.0', '255.255.255.0', '255.255.255.255'], correctIndex: 2, explanation: 'Kelas C menggunakan /24 atau 255.255.255.0.', topic: 'IP Address'),
        const QuizQuestion(question: 'Fungsi DNS adalah...', options: ['Mengirim email', 'Mengubah nama domain menjadi IP', 'Mengenkripsi data', 'Menyimpan file'], correctIndex: 1, explanation: 'DNS menerjemahkan nama domain ke alamat IP.', topic: 'Protokol'),
        const QuizQuestion(question: 'Routing statis cocok untuk...', options: ['Jaringan besar', 'Jaringan kecil', 'Internet', 'Cloud'], correctIndex: 1, explanation: 'Routing statis mudah dikonfigurasi untuk jaringan kecil.', topic: 'Routing'),
        const QuizQuestion(question: 'Firewall berfungsi untuk...', options: ['Mempercepat koneksi', 'Memfilter lalu lintas jaringan', 'Menyimpan data', 'Mengirim email'], correctIndex: 1, explanation: 'Firewall memfilter lalu lintas berdasarkan aturan keamanan.', topic: 'Keamanan'),
      ],
    ),
    // Post-Test (same bank as Pre-Test, order will be randomized per attempt)
    QuizModel(
      id: 'posttest-1', type: QuizType.posttest, title: 'Post-Test',
      timeLimitSeconds: 900, xpReward: 15,
      questions: [
        const QuizQuestion(question: 'Perangkat yang menghubungkan dua jaringan berbeda disebut...', options: ['Hub', 'Router', 'Switch', 'Modem'], correctIndex: 1, explanation: 'Router menghubungkan dua jaringan berbeda dan menentukan jalur terbaik untuk mengirim data.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Berapa oktet yang dimiliki sebuah alamat IPv4?', options: ['2 oktet', '4 oktet', '6 oktet', '8 oktet'], correctIndex: 1, explanation: 'IPv4 memiliki 4 oktet, masing-masing 8 bit, total 32 bit.', topic: 'IP Address'),
        const QuizQuestion(question: 'Kelas IP Address yang digunakan untuk jaringan skala besar adalah...', options: ['Kelas A (1–126.x.x.x)', 'Kelas B (128–191.x.x.x)', 'Kelas C (192–223.x.x.x)', 'Kelas D (224–239.x.x.x)'], correctIndex: 0, explanation: 'Kelas A mendukung jutaan host per jaringan.', topic: 'IP Address'),
        const QuizQuestion(question: 'Topologi jaringan di mana semua perangkat terhubung ke satu perangkat pusat adalah...', options: ['Bus', 'Star', 'Ring', 'Mesh'], correctIndex: 1, explanation: 'Topologi Star menggunakan hub/switch sebagai pusat.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Protokol yang menjamin pengiriman data secara reliable adalah...', options: ['UDP', 'TCP', 'ICMP', 'ARP'], correctIndex: 1, explanation: 'TCP memastikan data sampai dengan benar melalui handshake dan acknowledgment.', topic: 'Protokol'),
        const QuizQuestion(question: 'LAN adalah singkatan dari...', options: ['Large Area Network', 'Local Area Network', 'Long Area Network', 'Linked Area Network'], correctIndex: 1, explanation: 'LAN = Local Area Network, jaringan dalam area terbatas.', topic: 'Pengantar'),
        const QuizQuestion(question: 'Subnet mask default untuk kelas C adalah...', options: ['255.0.0.0', '255.255.0.0', '255.255.255.0', '255.255.255.255'], correctIndex: 2, explanation: 'Kelas C menggunakan /24 atau 255.255.255.0.', topic: 'IP Address'),
        const QuizQuestion(question: 'Fungsi DNS adalah...', options: ['Mengirim email', 'Mengubah nama domain menjadi IP', 'Mengenkripsi data', 'Menyimpan file'], correctIndex: 1, explanation: 'DNS menerjemahkan nama domain ke alamat IP.', topic: 'Protokol'),
        const QuizQuestion(question: 'Routing statis cocok untuk...', options: ['Jaringan besar', 'Jaringan kecil', 'Internet', 'Cloud'], correctIndex: 1, explanation: 'Routing statis mudah dikonfigurasi untuk jaringan kecil.', topic: 'Routing'),
        const QuizQuestion(question: 'Firewall berfungsi untuk...', options: ['Mempercepat koneksi', 'Memfilter lalu lintas jaringan', 'Menyimpan data', 'Mengirim email'], correctIndex: 1, explanation: 'Firewall memfilter lalu lintas berdasarkan aturan keamanan.', topic: 'Keamanan'),
      ],
    ),
    // Checkpoint Unit 1
    QuizModel(
      id: 'chk-unit1', type: QuizType.checkpoint, unitId: 'unit-1',
      title: 'Checkpoint Unit 1', timeLimitSeconds: 300, xpReward: 10,
      questions: [
        const QuizQuestion(question: 'Switch mengirim data ke...', options: ['Semua port', 'Port tujuan saja', 'Port acak', 'Tidak mengirim'], correctIndex: 1, explanation: 'Switch lebih pintar dari hub, mengirim data hanya ke port tujuan.'),
        const QuizQuestion(question: 'Topologi di mana perangkat membentuk lingkaran adalah...', options: ['Star', 'Bus', 'Ring', 'Mesh'], correctIndex: 2, explanation: 'Topologi Ring menghubungkan perangkat dalam bentuk lingkaran.'),
        const QuizQuestion(question: 'WAN menghubungkan jaringan...', options: ['Dalam satu ruangan', 'Dalam satu gedung', 'Antar kota/negara', 'Dalam satu lantai'], correctIndex: 2, explanation: 'WAN (Wide Area Network) mencakup area geografis yang luas.'),
      ],
    ),
    // Checkpoint Unit 2
    QuizModel(
      id: 'chk-unit2', type: QuizType.checkpoint, unitId: 'unit-2',
      title: 'Checkpoint Unit 2', timeLimitSeconds: 300, xpReward: 10,
      questions: [
        const QuizQuestion(question: 'Berapa oktet dalam IPv4?', options: ['2', '4', '6', '8'], correctIndex: 1, explanation: 'IPv4 terdiri dari 4 oktet (32 bit).'),
        const QuizQuestion(question: 'IP 192.168.1.1 termasuk kelas...', options: ['A', 'B', 'C', 'D'], correctIndex: 2, explanation: 'Range 192-223 adalah Kelas C.'),
        const QuizQuestion(question: 'NAT berfungsi untuk...', options: ['Mengenkripsi data', 'Mengubah IP private ke public', 'Mempercepat internet', 'Menyimpan file'], correctIndex: 1, explanation: 'NAT menerjemahkan IP private ke IP public.'),
      ],
    ),
    // Final Quiz Unit 2
    QuizModel(
      id: 'quiz-unit2', type: QuizType.finalQuiz, unitId: 'unit-2',
      title: 'Quiz Unit 2', timeLimitSeconds: 600, xpReward: 20,
      questions: [
        const QuizQuestion(question: 'IPv6 menggunakan berapa bit?', options: ['32', '64', '128', '256'], correctIndex: 2, explanation: 'IPv6 menggunakan 128 bit untuk mengatasi keterbatasan IPv4.'),
        const QuizQuestion(question: 'IP address 10.0.0.1 adalah IP...', options: ['Public', 'Private', 'Multicast', 'Broadcast'], correctIndex: 1, explanation: '10.x.x.x adalah range IP private.'),
        const QuizQuestion(question: 'Subnet mask /24 sama dengan...', options: ['255.0.0.0', '255.255.0.0', '255.255.255.0', '255.255.255.128'], correctIndex: 2, explanation: '/24 berarti 24 bit pertama adalah network = 255.255.255.0'),
        const QuizQuestion(question: 'Kelas A mendukung berapa host?', options: ['254', '65.534', '16.777.214', '4.294.967.294'], correctIndex: 2, explanation: 'Kelas A: 2^24 - 2 = 16.777.214 host per jaringan.'),
        const QuizQuestion(question: 'Format penulisan IPv6 yang benar adalah...', options: ['192.168.1.1', '2001:0db8::1', '255.255.255.0', 'AA:BB:CC:DD:EE:FF'], correctIndex: 1, explanation: 'IPv6 menggunakan format heksadesimal dengan tanda titik dua.'),
      ],
    ),
    // Checkpoint Unit 3 — Routing
    QuizModel(
      id: 'chk-unit3', type: QuizType.checkpoint, unitId: 'unit-3',
      title: 'Checkpoint Unit 3', timeLimitSeconds: 300, xpReward: 10,
      questions: [
        const QuizQuestion(question: 'Routing statis diatur oleh...', options: ['Router otomatis', 'Administrator manual', 'ISP', 'DNS'], correctIndex: 1, explanation: 'Routing statis dikonfigurasi manual oleh administrator.'),
        const QuizQuestion(question: 'Tabel routing berisi informasi...', options: ['Email pengguna', 'Network tujuan dan gateway', 'Password WiFi', 'Nama komputer'], correctIndex: 1, explanation: 'Tabel routing menyimpan network tujuan, subnet mask, gateway, dan metric.'),
        const QuizQuestion(question: 'Gateway dalam routing adalah...', options: ['Pintu masuk jaringan', 'Alamat next-hop router', 'Nama domain', 'Tipe kabel'], correctIndex: 1, explanation: 'Gateway/next-hop adalah alamat router berikutnya untuk meneruskan paket.'),
      ],
    ),
    // Final Quiz Unit 3 — Routing
    QuizModel(
      id: 'quiz-unit3', type: QuizType.finalQuiz, unitId: 'unit-3',
      title: 'Quiz Unit 3', timeLimitSeconds: 600, xpReward: 20,
      questions: [
        const QuizQuestion(question: 'Metric dalam tabel routing menunjukkan...', options: ['Kecepatan internet', 'Jarak/cost ke tujuan', 'Nama router', 'Jumlah user'], correctIndex: 1, explanation: 'Metric menunjukkan biaya/jarak ke jaringan tujuan.'),
        const QuizQuestion(question: 'Routing dinamis menggunakan protokol seperti...', options: ['HTTP, FTP', 'RIP, OSPF', 'TCP, UDP', 'DNS, DHCP'], correctIndex: 1, explanation: 'RIP dan OSPF adalah protokol routing dinamis yang populer.'),
        const QuizQuestion(question: 'Default route (0.0.0.0/0) digunakan ketika...', options: ['Tidak ada rute spesifik cocok', 'Koneksi terputus', 'Router restart', 'IP habis'], correctIndex: 0, explanation: 'Default route adalah rute terakhir yang digunakan jika tidak ada rute spesifik.'),
        const QuizQuestion(question: 'Hop count dalam routing adalah...', options: ['Jumlah kabel', 'Jumlah router yang dilewati', 'Jumlah user', 'Kecepatan koneksi'], correctIndex: 1, explanation: 'Hop count = jumlah router yang harus dilewati paket.'),
      ],
    ),
    // Checkpoint Unit 4 — Protokol
    QuizModel(
      id: 'chk-unit4', type: QuizType.checkpoint, unitId: 'unit-4',
      title: 'Checkpoint Unit 4', timeLimitSeconds: 300, xpReward: 10,
      questions: [
        const QuizQuestion(question: 'Model OSI memiliki berapa layer?', options: ['4', '5', '7', '10'], correctIndex: 2, explanation: 'Model OSI memiliki 7 layer dari Physical hingga Application.'),
        const QuizQuestion(question: 'TCP bersifat...', options: ['Connectionless', 'Connection-oriented', 'Wireless', 'Encrypted'], correctIndex: 1, explanation: 'TCP membangun koneksi terlebih dahulu (3-way handshake) sebelum mengirim data.'),
        const QuizQuestion(question: 'Layer ke-3 OSI adalah...', options: ['Transport', 'Network', 'Data Link', 'Session'], correctIndex: 1, explanation: 'Layer 3 = Network layer, bertanggung jawab atas routing dan IP addressing.'),
      ],
    ),
    // Final Quiz Unit 4 — Protokol
    QuizModel(
      id: 'quiz-unit4', type: QuizType.finalQuiz, unitId: 'unit-4',
      title: 'Quiz Unit 4', timeLimitSeconds: 600, xpReward: 20,
      questions: [
        const QuizQuestion(question: 'UDP cocok digunakan untuk...', options: ['Transfer file besar', 'Video streaming', 'Email', 'Web browsing'], correctIndex: 1, explanation: 'UDP lebih cepat karena tidak ada handshake, cocok untuk streaming.'),
        const QuizQuestion(question: 'HTTPS berbeda dari HTTP karena...', options: ['Lebih lambat', 'Menggunakan enkripsi SSL/TLS', 'Gratis', 'Hanya untuk email'], correctIndex: 1, explanation: 'HTTPS menambahkan lapisan keamanan SSL/TLS untuk enkripsi data.'),
        const QuizQuestion(question: 'MAC Address berada di layer OSI ke...', options: ['1', '2', '3', '4'], correctIndex: 1, explanation: 'MAC Address berada di Data Link layer (layer 2).'),
        const QuizQuestion(question: 'Port default HTTP adalah...', options: ['21', '25', '80', '443'], correctIndex: 2, explanation: 'HTTP menggunakan port 80, sedangkan HTTPS menggunakan port 443.'),
        const QuizQuestion(question: '3-way handshake TCP terdiri dari...', options: ['SYN-ACK-FIN', 'SYN-SYN/ACK-ACK', 'GET-POST-PUT', 'PING-PONG-ACK'], correctIndex: 1, explanation: 'TCP handshake: SYN → SYN/ACK → ACK.'),
      ],
    ),
    // Checkpoint Unit 5 — Keamanan
    QuizModel(
      id: 'chk-unit5', type: QuizType.checkpoint, unitId: 'unit-5',
      title: 'Checkpoint Unit 5', timeLimitSeconds: 300, xpReward: 10,
      questions: [
        const QuizQuestion(question: 'DDoS attack bertujuan untuk...', options: ['Mencuri password', 'Membanjiri server hingga down', 'Menghapus file', 'Mengirim spam'], correctIndex: 1, explanation: 'DDoS (Distributed Denial of Service) membanjiri server dengan trafik berlebihan.'),
        const QuizQuestion(question: 'SSL/TLS digunakan pada protokol...', options: ['FTP', 'HTTPS', 'SMTP', 'DNS'], correctIndex: 1, explanation: 'SSL/TLS mengamankan koneksi HTTPS dengan enkripsi.'),
        const QuizQuestion(question: 'Phishing adalah serangan melalui...', options: ['Kabel jaringan', 'Email/situs palsu', 'Router', 'Firewall'], correctIndex: 1, explanation: 'Phishing menggunakan email atau situs palsu untuk mencuri informasi sensitif.'),
      ],
    ),
    // Final Quiz Unit 5 — Keamanan
    QuizModel(
      id: 'quiz-unit5', type: QuizType.finalQuiz, unitId: 'unit-5',
      title: 'Quiz Unit 5', timeLimitSeconds: 600, xpReward: 20,
      questions: [
        const QuizQuestion(question: 'Firewall bekerja dengan cara...', options: ['Mempercepat koneksi', 'Memfilter trafik berdasarkan aturan', 'Menyimpan password', 'Mengirim email'], correctIndex: 1, explanation: 'Firewall memfilter paket data berdasarkan rules yang ditentukan.'),
        const QuizQuestion(question: 'Enkripsi AES adalah jenis enkripsi...', options: ['Asimetris', 'Simetris', 'Hash', 'Digital signature'], correctIndex: 1, explanation: 'AES adalah enkripsi simetris yang menggunakan kunci yang sama untuk enkripsi dan dekripsi.'),
        const QuizQuestion(question: 'VPN berfungsi untuk...', options: ['Mempercepat internet', 'Membuat koneksi aman lewat jaringan publik', 'Menghapus virus', 'Mengirim file'], correctIndex: 1, explanation: 'VPN membuat tunnel terenkripsi melalui jaringan publik (internet).'),
        const QuizQuestion(question: 'Man-in-the-Middle attack menyadap komunikasi antara...', options: ['2 router', '2 pihak yang berkomunikasi', '2 switch', '2 firewall'], correctIndex: 1, explanation: 'MitM attack menyadap dan bisa memodifikasi data antara dua pihak.'),
      ],
    ),
  ];

  // ── Simulations ──
  static final List<SimulationModel> simulations = [
    SimulationModel(
    id: 'sim-bus',
    title: 'Topologi Bus',
    description: 'Kirim paket data antar PC di topologi Bus',
    task: '📡 Tugas: Kirim paket dari PC 1 ke PC 3 melewati kabel utama (bus).',
    nodes: [
      const NetworkNode(id: 'pc1', type: NodeType.pc, label: 'PC 1', ipAddress: '192.168.1.2', x: 0.1, y: 0.2),
      const NetworkNode(id: 'pc2', type: NodeType.pc, label: 'PC 2', ipAddress: '192.168.1.3', x: 0.4, y: 0.2),
      const NetworkNode(id: 'pc3', type: NodeType.pc, label: 'PC 3', ipAddress: '192.168.1.4', x: 0.7, y: 0.2),
      const NetworkNode(id: 'bus-hub1', type: NodeType.switchDevice, label: 'T-Connector', ipAddress: 'Bus', x: 0.1, y: 0.5),
      const NetworkNode(id: 'bus-hub2', type: NodeType.switchDevice, label: 'T-Connector', ipAddress: 'Bus', x: 0.4, y: 0.5),
      const NetworkNode(id: 'bus-hub3', type: NodeType.switchDevice, label: 'T-Connector', ipAddress: 'Bus', x: 0.7, y: 0.5),
    ],
    connections: [
      const NetworkConnection(fromNodeId: 'pc1', toNodeId: 'bus-hub1'),
      const NetworkConnection(fromNodeId: 'pc2', toNodeId: 'bus-hub2'),
      const NetworkConnection(fromNodeId: 'pc3', toNodeId: 'bus-hub3'),
      const NetworkConnection(fromNodeId: 'bus-hub1', toNodeId: 'bus-hub2'),
      const NetworkConnection(fromNodeId: 'bus-hub2', toNodeId: 'bus-hub3'),
    ],
    scenarios: [
      const SimulationScenario(fromNodeId: 'pc1', toNodeId: 'pc3', correctPath: ['pc1', 'bus-hub1', 'bus-hub2', 'bus-hub3', 'pc3']),
    ],
  ),
    SimulationModel(
    id: 'sim-ring',
    title: 'Topologi Ring',
    description: 'Paket berputar melewati ring',
    task: '📡 Tugas: Kirim paket dari PC Atas ke PC Kiri melewati ring.',
    nodes: [
      const NetworkNode(id: 'pc-top', type: NodeType.pc, label: 'PC Atas', ipAddress: '172.16.0.1', x: 0.4, y: 0.1),
      const NetworkNode(id: 'pc-right', type: NodeType.pc, label: 'PC Kanan', ipAddress: '172.16.0.2', x: 0.7, y: 0.4),
      const NetworkNode(id: 'pc-bottom', type: NodeType.pc, label: 'PC Bawah', ipAddress: '172.16.0.3', x: 0.4, y: 0.7),
      const NetworkNode(id: 'pc-left', type: NodeType.pc, label: 'PC Kiri', ipAddress: '172.16.0.4', x: 0.1, y: 0.4),
    ],
    connections: [
      const NetworkConnection(fromNodeId: 'pc-top', toNodeId: 'pc-right'),
      const NetworkConnection(fromNodeId: 'pc-right', toNodeId: 'pc-bottom'),
      const NetworkConnection(fromNodeId: 'pc-bottom', toNodeId: 'pc-left'),
      const NetworkConnection(fromNodeId: 'pc-left', toNodeId: 'pc-top'),
    ],
    scenarios: [
      const SimulationScenario(fromNodeId: 'pc-top', toNodeId: 'pc-left', correctPath: ['pc-top', 'pc-right', 'pc-bottom', 'pc-left']),
      const SimulationScenario(fromNodeId: 'pc-top', toNodeId: 'pc-left', correctPath: ['pc-top', 'pc-left']),
    ],
  ),
    SimulationModel(
      id: 'sim-tree',
      title: 'Topologi Tree',
      description: 'Paket melewati struktur bertingkat root dan cabang',
      task: '📡 Tugas: Kirim paket dari PC Cabang Kiri ke PC Cabang Kanan melalui node root.',
      nodes: [
        const NetworkNode(id: 'tree-root', type: NodeType.switchDevice, label: 'Root Switch', ipAddress: '192.168.20.1', x: 0.4, y: 0.08),
        const NetworkNode(id: 'tree-dist-left', type: NodeType.switchDevice, label: 'Distribusi Kiri', ipAddress: '192.168.20.2', x: 0.2, y: 0.32),
        const NetworkNode(id: 'tree-dist-right', type: NodeType.switchDevice, label: 'Distribusi Kanan', ipAddress: '192.168.20.3', x: 0.6, y: 0.32),
        const NetworkNode(id: 'tree-pc-left', type: NodeType.pc, label: 'PC Kiri', ipAddress: '192.168.20.11', x: 0.1, y: 0.62),
        const NetworkNode(id: 'tree-pc-right', type: NodeType.pc, label: 'PC Kanan', ipAddress: '192.168.20.12', x: 0.7, y: 0.62),
      ],
      connections: [
        const NetworkConnection(fromNodeId: 'tree-root', toNodeId: 'tree-dist-left'),
        const NetworkConnection(fromNodeId: 'tree-root', toNodeId: 'tree-dist-right'),
        const NetworkConnection(fromNodeId: 'tree-dist-left', toNodeId: 'tree-pc-left'),
        const NetworkConnection(fromNodeId: 'tree-dist-right', toNodeId: 'tree-pc-right'),
      ],
      scenarios: [
        const SimulationScenario(
          fromNodeId: 'tree-pc-left',
          toNodeId: 'tree-pc-right',
          correctPath: ['tree-pc-left', 'tree-dist-left', 'tree-root', 'tree-dist-right', 'tree-pc-right'],
        ),
      ],
    ),
    SimulationModel(
      id: 'sim-mesh',
      title: 'Topologi Mesh',
      description: 'Setiap node saling terhubung membentuk banyak jalur',
      task: '📡 Tugas: Kirim paket dari Node A ke Node D melalui jalur mesh.',
      nodes: [
        const NetworkNode(id: 'mesh-a', type: NodeType.pc, label: 'Node A', ipAddress: '10.10.0.1', x: 0.12, y: 0.18),
        const NetworkNode(id: 'mesh-b', type: NodeType.pc, label: 'Node B', ipAddress: '10.10.0.2', x: 0.62, y: 0.18),
        const NetworkNode(id: 'mesh-c', type: NodeType.pc, label: 'Node C', ipAddress: '10.10.0.3', x: 0.12, y: 0.62),
        const NetworkNode(id: 'mesh-d', type: NodeType.pc, label: 'Node D', ipAddress: '10.10.0.4', x: 0.62, y: 0.62),
      ],
      connections: [
        const NetworkConnection(fromNodeId: 'mesh-a', toNodeId: 'mesh-b'),
        const NetworkConnection(fromNodeId: 'mesh-a', toNodeId: 'mesh-c'),
        const NetworkConnection(fromNodeId: 'mesh-b', toNodeId: 'mesh-d'),
        const NetworkConnection(fromNodeId: 'mesh-c', toNodeId: 'mesh-d'),
        const NetworkConnection(fromNodeId: 'mesh-a', toNodeId: 'mesh-d'),
        const NetworkConnection(fromNodeId: 'mesh-b', toNodeId: 'mesh-c'),
      ],
      scenarios: [
        const SimulationScenario(fromNodeId: 'mesh-a', toNodeId: 'mesh-d', correctPath: ['mesh-a', 'mesh-d']),
        const SimulationScenario(fromNodeId: 'mesh-a', toNodeId: 'mesh-d', correctPath: ['mesh-a', 'mesh-b', 'mesh-d']),
      ],
    ),
    SimulationModel(
      id: 'sim-star',
      title: 'Topologi Star',
      description: 'Kirim paket data dengan Switch pusat',
      task: '📡 Tugas: Kirim paket dari PC Kiri ke Server via Switch Utama.',
      nodes: [
        const NetworkNode(id: 'pc-left', type: NodeType.pc, label: 'PC Kiri', ipAddress: '10.0.0.2', x: 0.1, y: 0.5),
        const NetworkNode(id: 'pc-right', type: NodeType.pc, label: 'PC Kanan', ipAddress: '10.0.0.3', x: 0.7, y: 0.5),
        const NetworkNode(id: 'switch-star', type: NodeType.switchDevice, label: 'Switch Utama', ipAddress: '10.0.0.1', x: 0.4, y: 0.35),
        const NetworkNode(id: 'server-star', type: NodeType.server, label: 'Server', ipAddress: '10.0.0.100', x: 0.4, y: 0.1),
      ],
      connections: [
        const NetworkConnection(fromNodeId: 'pc-left', toNodeId: 'switch-star'),
        const NetworkConnection(fromNodeId: 'pc-right', toNodeId: 'switch-star'),
        const NetworkConnection(fromNodeId: 'switch-star', toNodeId: 'server-star'),
      ],
      scenarios: [
        const SimulationScenario(fromNodeId: 'pc-left', toNodeId: 'server-star', correctPath: ['pc-left', 'switch-star', 'server-star']),
        const SimulationScenario(fromNodeId: 'pc-right', toNodeId: 'server-star', correctPath: ['pc-right', 'switch-star', 'server-star']),
      ],
    ),
  ];
  static final SimulationModel defaultSimulation = simulations.first;

  // ── Progress ──
  static final List<ProgressModel> demoProgress = [
    const ProgressModel(unitId: 'unit-1', materialsCompleted: 4, totalMaterials: 4, pretestScore: 45, checkpointScores: [80], finalScore: 85),
    const ProgressModel(unitId: 'unit-2', materialsCompleted: 3, totalMaterials: 5, pretestScore: 40, checkpointScores: [70]),
    const ProgressModel(unitId: 'unit-3', materialsCompleted: 2, totalMaterials: 3, pretestScore: 35),
    const ProgressModel(unitId: 'unit-4', materialsCompleted: 0, totalMaterials: 3),
    const ProgressModel(unitId: 'unit-5', materialsCompleted: 0, totalMaterials: 2),
  ];

  // ── Achievements ──
  static final List<AchievementModel> achievements = [
    const AchievementModel(
      id: 'badge-materi-1',
      name: 'Pemula Jaringan',
      description: 'Selesaikan topik Pengantar Jaringan Komputer',
      iconEmoji: '⭐️',
      tier: AchievementTier.bronze,
    ),
    const AchievementModel(
      id: 'badge-materi-2',
      name: 'Master IP',
      description: 'Selesaikan topik IP Addressing',
      iconEmoji: '🎯',
      tier: AchievementTier.bronze,
    ),
    const AchievementModel(
      id: 'badge-materi-3',
      name: 'Juara Routing',
      description: 'Selesaikan topik Routing Dasar',
      iconEmoji: '🏆',
      tier: AchievementTier.silver,
    ),
    const AchievementModel(
      id: 'badge-materi-4',
      name: 'Diamond Protokol',
      description: 'Selesaikan topik Konektivitas & Protokol',
      iconEmoji: '💎',
      tier: AchievementTier.silver,
    ),
    const AchievementModel(
      id: 'badge-materi-5',
      name: 'Api Keamanan',
      description: 'Selesaikan topik Keamanan Jaringan',
      iconEmoji: '🔥',
      tier: AchievementTier.gold,
    ),
    const AchievementModel(
      id: 'badge-quiz',
      name: 'Badge Quiz',
      description: 'Selesaikan quiz unit',
      iconEmoji: '🧠',
      tier: AchievementTier.gold,
    ),
    const AchievementModel(
      id: 'badge-simulasi',
      name: 'Badge Simulasi',
      description: 'Selesaikan simulasi jaringan',
      iconEmoji: '🧩',
      tier: AchievementTier.gold,
    ),
  ];
}
