/// Petunjuk penggunaan simulasi per topologi.
class SimulationTutorial {
  final String topologyName;
  final String aboutTopology;
  final List<String> goalSteps;
  final String tip;

  const SimulationTutorial({
    required this.topologyName,
    required this.aboutTopology,
    required this.goalSteps,
    required this.tip,
  });
}

class SimulationTutorials {
  SimulationTutorials._();

  static const List<String> commonControls = [
    'Pilih topologi pada chip di atas (Bus, Ring, Tree, Mesh, Star).',
    'Garis hijau tebal = jalur paket yang akan digunakan.',
    'Tombol acak (ikon shuffle) = ganti rute alternatif jika tersedia.',
    'Kirim Paket = jalankan animasi pengiriman data.',
    'Tombol refresh = reset jalur dan status simulasi.',
    'Seret ikon perangkat untuk mengatur posisi di kanvas.',
  ];

  static const Map<String, SimulationTutorial> byId = {
    'sim-bus': SimulationTutorial(
      topologyName: 'Topologi Bus',
      aboutTopology:
          'Semua PC terhubung ke kabel utama (bus) melalui T-Connector. Paket bergerak sepanjang bus dan dapat didengar oleh semua node.',
      goalSteps: [
        'Baca tugas: kirim paket dari PC 1 ke PC 3.',
        'Pastikan jalur hijau melewati PC 1 → T-Connector → bus → PC 3.',
        'Tekan Kirim Paket dan amati titik oranye bergerak di setiap hop.',
        'Jika gagal, tekan refresh lalu kirim ulang.',
      ],
      tip: 'Di topologi bus, gangguan pada kabel utama dapat memutus seluruh jaringan.',
    ),
    'sim-ring': SimulationTutorial(
      topologyName: 'Topologi Ring',
      aboutTopology:
          'Node tersusun membentuk lingkaran. Paket berputar dari satu PC ke PC berikutnya sampai mencapai tujuan.',
      goalSteps: [
        'Baca tugas: kirim paket dari PC Atas ke PC Kiri.',
        'Perhatikan jalur hijau — bisa searah jarum jam atau melalui sisi ring lain.',
        'Gunakan tombol acak untuk melihat rute ring alternatif.',
        'Tekan Kirim Paket dan ikuti animasi paket di setiap PC.',
      ],
      tip: 'Ring punya dua arah potensial; pilih rute yang ditandai hijau sebelum mengirim.',
    ),
    'sim-tree': SimulationTutorial(
      topologyName: 'Topologi Tree',
      aboutTopology:
          'Struktur bertingkat: root switch di atas, switch distribusi di tengah, PC di cabang bawah.',
      goalSteps: [
        'Baca tugas: kirim paket dari PC Cabang Kiri ke PC Cabang Kanan.',
        'Paket naik ke Distribusi Kiri → Root Switch → Distribusi Kanan → PC Kanan.',
        'Pastikan jalur hijau mengikuti hierarki tree, bukan memotong level.',
        'Tekan Kirim Paket untuk melihat alur paket antar tingkat.',
      ],
      tip: 'Tree efisien untuk jaringan besar karena lalu lintas terpusat di node root.',
    ),
    'sim-mesh': SimulationTutorial(
      topologyName: 'Topologi Mesh',
      aboutTopology:
          'Setiap node terhubung ke banyak node lain. Ada beberapa jalur antara sumber dan tujuan.',
      goalSteps: [
        'Baca tugas: kirim paket dari Node A ke Node D.',
        'Jalur hijau bisa langsung A→D atau melalui node perantara (B atau C).',
        'Tekan tombol acak untuk membandingkan jalur mesh pendek vs tidak langsung.',
        'Kirim paket dan bandingkan jumlah hop di bilah status bawah.',
      ],
      tip: 'Mesh punya redundansi tinggi — jika satu link putus, masih ada jalur lain.',
    ),
    'sim-star': SimulationTutorial(
      topologyName: 'Topologi Star',
      aboutTopology:
          'Semua perangkat terhubung ke switch pusat. Lalu lintas selalu melewati switch sebelum ke tujuan.',
      goalSteps: [
        'Baca tugas: kirim paket dari PC Kiri ke Server.',
        'Jalur hijau harus melalui Switch Utama (titik pusat).',
        'Tekan Kirim Paket — paket bergerak PC → Switch → Server.',
        'Coba tombol acak jika ingin melihat rute dari PC Kanan ke Server.',
      ],
      tip: 'Switch pusat adalah titik kritis; jika switch mati, seluruh segmen star terputus.',
    ),
  };

  static SimulationTutorial? forSimulation(String id) => byId[id];
}
