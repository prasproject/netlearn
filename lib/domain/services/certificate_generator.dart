import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../core/utils/file_export.dart';
import 'package:intl/date_symbol_data_local.dart';

/// NetLearn — PDF Certificate Generator
/// Generates a professional certificate PDF in landscape A4.
class CertificateGenerator {
  CertificateGenerator._();

  // Color constants for PDF
  static const _blue = PdfColor.fromInt(0xFF0D47A1);
  static const _blueDark = PdfColor.fromInt(0xFF0A3575);
  static const _blueLight = PdfColor.fromInt(0xFF90CAF9);
  static const _gold = PdfColor.fromInt(0xFFFFD54F);
  static const _gray = PdfColor.fromInt(0xFFB0BEC5);
  static const _grayDark = PdfColor.fromInt(0xFF78909C);
  static const _white05 = PdfColor.fromInt(0x0DFFFFFF);
  static const _white15 = PdfColor.fromInt(0x26FFFFFF);

  /// Generate certificate PDF and return the file path.
  static Future<String> generate({
    required String studentName,
    required int finalScore,
    required double nGain,
    required int totalXp,
    required int pretestScore,
    required int posttestScore,
  }) async {
    await initializeDateFormatting('id_ID', null);
    final pdf = pw.Document();
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());
    final nGainCategory = _getNGainCategory(nGain);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Stack(
            children: [
              // Background
              pw.Container(
                width: double.infinity, height: double.infinity,
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topCenter, end: pw.Alignment.bottomCenter,
                    colors: [_blue, _blueDark],
                  ),
                ),
              ),
              // Decorative circles
              pw.Positioned(top: -40, right: -40,
                child: pw.Container(width: 200, height: 200,
                  decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _white05))),
              pw.Positioned(bottom: -30, left: -30,
                child: pw.Container(width: 150, height: 150,
                  decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _white05))),
              // Content
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      pw.SizedBox(height: 8),
                      _divider(),
                      pw.SizedBox(height: 16),
                      pw.Text('SERTIFIKAT PENYELESAIAN',
                        style: pw.TextStyle(fontSize: 14, letterSpacing: 4, color: _blueLight)),
                      pw.SizedBox(height: 20),
                      pw.Text(studentName,
                        style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 12),
                      pw.Text('Telah berhasil menyelesaikan kursus',
                        style: pw.TextStyle(fontSize: 11, color: _gray)),
                      pw.SizedBox(height: 6),
                      pw.Text('Pembelajaran Jaringan Komputer & Internet',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _gold)),
                      pw.Text('Kelas X SMA Negeri 1 Nguter · Kurikulum Merdeka 2025',
                        style: pw.TextStyle(fontSize: 10, color: _blueLight)),
                      pw.SizedBox(height: 20),
                      _buildStatsRow(finalScore, nGain, nGainCategory, totalXp, pretestScore, posttestScore),
                      pw.SizedBox(height: 20),
                      _divider(),
                      pw.SizedBox(height: 12),
                      _buildFooter(dateStr),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'NetLearn_Sertifikat_${studentName.replaceAll(' ', '_')}.pdf';
    final path = await saveBytes(bytes: await pdf.save(), fileName: fileName);
    return path ?? fileName;
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 36, height: 36,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: _gold, width: 2),
          ),
          child: pw.Center(
            child: pw.Text('★', style: pw.TextStyle(fontSize: 18, color: _gold, fontWeight: pw.FontWeight.bold)),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('NetLearn',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text('Interactive Network Learning',
              style: pw.TextStyle(fontSize: 8, color: _blueLight)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatsRow(int score, double nGain, String category, int xp, int pre, int post) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _statBox('Skor Akhir', '$score / 100'),
        pw.SizedBox(width: 16),
        _statBox('N-Gain', '${nGain.toStringAsFixed(2)} ($category)'),
        pw.SizedBox(width: 16),
        _statBox('Pre → Post', '$pre → $post'),
        pw.SizedBox(width: 16),
        _statBox('Total XP', '$xp XP'),
      ],
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _blueDark,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _blueLight, width: 0.6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _gold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Tanggal: $date', style: pw.TextStyle(fontSize: 9, color: _gray)),
            pw.Text('ID: NL-${DateTime.now().millisecondsSinceEpoch}',
              style: pw.TextStyle(fontSize: 7, color: _grayDark)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Faridatus Shofiyah',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text('Guru Pembimbing', style: pw.TextStyle(fontSize: 8, color: _blueLight)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _divider() {
    return pw.Container(width: double.infinity, height: 1, color: _white15);
  }

  static String _getNGainCategory(double nGain) {
    if (nGain >= 0.7) return 'Tinggi';
    if (nGain >= 0.3) return 'Sedang';
    return 'Rendah';
  }
}
