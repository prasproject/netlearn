/// Menghitung streak harian berdasarkan tanggal aktivitas terakhir.
class StreakService {
  StreakService._();

  /// Hasil refresh streak saat pengguna membuka aplikasi.
  static StreakRefreshResult refresh({
    required int currentStreak,
    required DateTime lastActive,
    required DateTime now,
  }) {
    final today = _dateOnly(now.toLocal());
    final lastDay = _dateOnly(lastActive.toLocal());

    if (today.isBefore(lastDay)) {
      return StreakRefreshResult(streak: currentStreak, increased: false);
    }

    final dayGap = today.difference(lastDay).inDays;

    if (dayGap == 0) {
      // Hari pertama belajar: streak 0 dianggap hari ke-1.
      if (currentStreak == 0) {
        return const StreakRefreshResult(streak: 1, increased: true);
      }
      return StreakRefreshResult(streak: currentStreak, increased: false);
    }

    if (dayGap == 1) {
      final next = currentStreak <= 0 ? 1 : currentStreak + 1;
      return StreakRefreshResult(streak: next, increased: true);
    }

    // Lewat lebih dari 1 hari tanpa aktivitas: mulai lagi dari hari ke-1.
    return const StreakRefreshResult(streak: 1, increased: false);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

class StreakRefreshResult {
  final int streak;
  final bool increased;

  const StreakRefreshResult({
    required this.streak,
    required this.increased,
  });
}
