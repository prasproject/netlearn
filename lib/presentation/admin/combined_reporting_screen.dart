import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_colors.dart';
import '../../core/utils/file_export.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/user_model.dart';
import '../../data/seed/seed_data.dart';
import '../../domain/providers/repository_providers.dart';

class CombinedReportingScreen extends ConsumerStatefulWidget {
  const CombinedReportingScreen({super.key});

  @override
  ConsumerState<CombinedReportingScreen> createState() => _CombinedReportingScreenState();
}

enum _SortField { name, pretest, posttest, progress, lastActive }

class _CombinedReportingScreenState extends ConsumerState<CombinedReportingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _exportingPdf = false;
  bool _exportingExcel = false;
  List<_ReportRow> _rows = [];
  String _searchQuery = '';
  _SortField _sortField = _SortField.name;
  bool _sortAsc = true;
  static const double _tableMinWidth = 980;

  List<_ReportRow> get _filteredRows {
    final keyword = _searchQuery.trim().toLowerCase();
    final rows = keyword.isEmpty
        ? List<_ReportRow>.from(_rows)
        : _rows.where((row) {
            return row.user.displayName.toLowerCase().contains(keyword) ||
                row.user.id.toLowerCase().contains(keyword) ||
                row.user.phoneNumber.toLowerCase().contains(keyword);
          }).toList();

    rows.sort((a, b) {
      int result;
      switch (_sortField) {
        case _SortField.name:
          result = a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase());
          break;
        case _SortField.pretest:
          result = a.pretestScore.compareTo(b.pretestScore);
          break;
        case _SortField.posttest:
          result = a.posttestScore.compareTo(b.posttestScore);
          break;
        case _SortField.progress:
          result = a.progressPercent.compareTo(b.progressPercent);
          break;
        case _SortField.lastActive:
          result = a.user.lastActive.compareTo(b.user.lastActive);
          break;
      }
      return _sortAsc ? result : -result;
    });
    return rows;
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final users = await ref.read(authRepositoryProvider).getAllUsers();
    final students = users.where((u) => u.role != 'admin').toList();
    final progressRepo = ref.read(progressRepositoryProvider);
    final rows = await Future.wait(students.map((user) async {
      final progressList = await progressRepo.getProgress(user.id);
      return _buildReportRow(user, progressList);
    }));
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  _ReportRow _buildReportRow(UserModel user, List<ProgressModel> progressList) {
    final unitProgress = progressList.where((p) => p.unitId != '__overall__').toList();
    final overall = progressList.cast<ProgressModel?>().firstWhere(
          (p) => p?.unitId == '__overall__',
          orElse: () => null,
        );
    final totalMaterials = unitProgress.fold<int>(0, (sum, p) => sum + p.totalMaterials);
    final completedMaterials = unitProgress.fold<int>(0, (sum, p) => sum + p.materialsCompleted);
    final progressPercent = totalMaterials > 0 ? (completedMaterials / totalMaterials) * 100 : 0.0;

    final collectedPretests = unitProgress.map((p) => p.pretestScore).whereType<int>().toList();
    final averageUnitPretest = collectedPretests.isEmpty
        ? 0
        : (collectedPretests.reduce((a, b) => a + b) / collectedPretests.length).round();

    final finalScores = unitProgress.map((p) => p.finalScore ?? p.checkpointAverage).whereType<int>().toList();
    final averageUnitPosttest = finalScores.isEmpty
        ? 0
        : (finalScores.reduce((a, b) => a + b) / finalScores.length).round();

    return _ReportRow(
      user: user,
      pretestScore: overall?.pretestScore ?? averageUnitPretest,
      posttestScore: overall?.finalScore ?? averageUnitPosttest,
      completedMaterials: completedMaterials,
      totalMaterials: totalMaterials,
      progressPercent: progressPercent,
      unitProgress: unitProgress,
      overall: overall,
    );
  }

  String _unitTitle(String unitId) {
    final unit = SeedData.materials.cast<dynamic>().firstWhere(
          (m) => m.id == unitId,
          orElse: () => null,
        );
    final title = unit?.title;
    return (title == null || title.trim().isEmpty) ? unitId : title;
  }

  Future<void> _showUserDetail(_ReportRow row) async {
    final user = row.user;
    final progressList = row.unitProgress.toList()
      ..sort((a, b) => a.unitId.compareTo(b.unitId));
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(user.displayName, style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Username: ${user.id}', style: AppTextStyles.bodySmall),
                Text('WA: ${user.phoneNumber}', style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Pretest', '${row.pretestScore}'),
                    _chip('Posttest', '${row.posttestScore}'),
                    _chip('Progress', '${row.progressPercent.toStringAsFixed(1)}%'),
                    _chip('Materi', '${row.completedMaterials}/${row.totalMaterials}'),
                    _chip('Aktif', dateFmt.format(user.lastActive)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Detail per Unit', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                ...progressList.map((p) {
                  final completedAt = p.completedAt == null ? '-' : DateFormat('dd/MM/yyyy').format(p.completedAt!);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(_unitTitle(p.unitId), style: AppTextStyles.heading),
                      subtitle: Text(
                        'Materi ${p.materialsCompleted}/${p.totalMaterials} • Pre ${p.pretestScore ?? 0} • '
                        'Checkpoint ${p.checkpointAverage ?? 0} • Final ${p.finalScore ?? 0}\n'
                        'Selesai: $completedAt',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_filteredRows.isEmpty) {
      _showInfo('Data kosong, tidak ada yang bisa diexport.');
      return;
    }
    setState(() => _exportingPdf = true);
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final formatter = DateFormat('dd MMM yyyy HH:mm');
      final headers = [
        'Nama',
        'Username',
        'WA',
        'Pretest',
        'Posttest',
        'Progress',
        'Materi',
        'Last Active',
      ];
      final data = _filteredRows
          .map(
            (row) => [
              row.user.displayName,
              row.user.id,
              row.user.phoneNumber,
              '${row.pretestScore}',
              '${row.posttestScore}',
              '${row.progressPercent.toStringAsFixed(1)}%',
              '${row.completedMaterials}/${row.totalMaterials}',
              DateFormat('dd/MM/yyyy').format(row.user.lastActive),
            ],
          )
          .toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              'Laporan Gabungan Siswa - NetLearn',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Diexport pada ${formatter.format(now)}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'laporan_gabungan_$timestamp.pdf';
      final path = await saveBytes(bytes: await pdf.save(), fileName: fileName);
      if (path != null && !isWebExport) {
        await openSavedFile(path);
      }
      _showInfo(isWebExport ? 'PDF berhasil diunduh.' : 'PDF berhasil dibuat.');
    } catch (e) {
      _showInfo('Gagal export PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_filteredRows.isEmpty) {
      _showInfo('Data kosong, tidak ada yang bisa diexport.');
      return;
    }
    setState(() => _exportingExcel = true);
    try {
      final excel = xl.Excel.createExcel();
      final summarySheet = excel['Ringkasan'];
      final perUnitSheet = excel['DetailUnit'];
      final headers = [
        'Nama',
        'Username',
        'No WA',
        'Pretest',
        'Posttest',
        'Progress %',
        'Materi Selesai',
        'Last Active',
      ];
      summarySheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());
      for (final row in _filteredRows) {
        summarySheet.appendRow([
          xl.TextCellValue(row.user.displayName),
          xl.TextCellValue(row.user.id),
          xl.TextCellValue(row.user.phoneNumber),
          xl.IntCellValue(row.pretestScore),
          xl.IntCellValue(row.posttestScore),
          xl.DoubleCellValue(row.progressPercent),
          xl.TextCellValue('${row.completedMaterials}/${row.totalMaterials}'),
          xl.TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(row.user.lastActive)),
        ]);
      }

      perUnitSheet.appendRow([
        xl.TextCellValue('Nama'),
        xl.TextCellValue('Username'),
        xl.TextCellValue('Unit ID'),
        xl.TextCellValue('Unit'),
        xl.TextCellValue('Materi'),
        xl.TextCellValue('Pretest'),
        xl.TextCellValue('Checkpoint Avg'),
        xl.TextCellValue('Final'),
        xl.TextCellValue('Selesai Pada'),
      ]);
      for (final row in _filteredRows) {
        final sortedUnits = row.unitProgress.toList()..sort((a, b) => a.unitId.compareTo(b.unitId));
        for (final p in sortedUnits) {
          perUnitSheet.appendRow([
            xl.TextCellValue(row.user.displayName),
            xl.TextCellValue(row.user.id),
            xl.TextCellValue(p.unitId),
            xl.TextCellValue(_unitTitle(p.unitId)),
            xl.TextCellValue('${p.materialsCompleted}/${p.totalMaterials}'),
            xl.IntCellValue(p.pretestScore ?? 0),
            xl.IntCellValue(p.checkpointAverage ?? 0),
            xl.IntCellValue(p.finalScore ?? 0),
            xl.TextCellValue(p.completedAt == null ? '' : DateFormat('dd/MM/yyyy').format(p.completedAt!)),
          ]);
        }
      }

      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'laporan_gabungan_$timestamp.xlsx';
      final encoded = excel.encode();
      if (encoded == null) {
        throw Exception('File excel gagal dibuat');
      }
      final path = await saveBytes(bytes: encoded, fileName: fileName);
      if (path != null && !isWebExport) {
        await openSavedFile(path);
      }
      _showInfo(isWebExport ? 'Excel berhasil diunduh.' : 'Excel berhasil dibuat.');
    } catch (e) {
      _showInfo('Gagal export Excel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  void _showInfo(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.secondaryGreen,
      ),
    );
  }

  Widget _reportTableCard(List<_ReportRow> rows) {
    final headingStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.primaryBlueDark,
      fontWeight: FontWeight.w900,
    );
    final dataStyle = AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _tableMinWidth),
            child: DataTableTheme(
              data: DataTableThemeData(
                headingRowColor: WidgetStatePropertyAll(AppColors.primaryBlueSurface),
                dividerThickness: 0.8,
                headingTextStyle: headingStyle,
                dataTextStyle: dataStyle,
                horizontalMargin: 14,
                columnSpacing: 18,
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('WA')),
                  DataColumn(label: Text('Pre')),
                  DataColumn(label: Text('Post')),
                  DataColumn(label: Text('Progress')),
                  DataColumn(label: Text('Materi')),
                  DataColumn(label: Text('Aktif')),
                ],
                rows: rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  final baseColor = i.isEven ? Colors.white : AppColors.postSurface;
                  return DataRow(
                    color: WidgetStatePropertyAll(baseColor),
                    onSelectChanged: (selected) {
                      if (selected == true) _showUserDetail(row);
                    },
                    cells: [
                      DataCell(Text(row.user.displayName)),
                      DataCell(Text(row.user.id)),
                      DataCell(Text(row.user.phoneNumber)),
                      DataCell(Text('${row.pretestScore}')),
                      DataCell(Text('${row.posttestScore}')),
                      DataCell(Text('${row.progressPercent.toStringAsFixed(1)}%')),
                      DataCell(Text('${row.completedMaterials}/${row.totalMaterials}')),
                      DataCell(Text(DateFormat('dd/MM/yy').format(row.user.lastActive))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reporting Gabungan', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Gabungan data user, pretest, posttest, dan progress belajar.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cari nama, username, atau WA',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<_SortField>(
                          value: _sortField,
                          decoration: InputDecoration(
                            labelText: 'Urutkan berdasarkan',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: _SortField.name, child: Text('Nama')),
                            DropdownMenuItem(value: _SortField.pretest, child: Text('Pretest')),
                            DropdownMenuItem(value: _SortField.posttest, child: Text('Posttest')),
                            DropdownMenuItem(value: _SortField.progress, child: Text('Progress')),
                            DropdownMenuItem(value: _SortField.lastActive, child: Text('Aktif terakhir')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _sortField = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => setState(() => _sortAsc = !_sortAsc),
                        icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                        tooltip: _sortAsc ? 'Ascending' : 'Descending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _exportingExcel ? null : _exportExcel,
                          icon: _exportingExcel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.table_view),
                          label: Text(_exportingExcel ? 'Export...' : 'Export Excel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _exportingPdf ? null : _exportPdf,
                          icon: _exportingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.picture_as_pdf),
                          label: Text(_exportingPdf ? 'Export...' : 'Export PDF'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total data: ${_filteredRows.length} (tap baris untuk detail)',
                    style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_filteredRows.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('Tidak ada data yang cocok.'),
                      ),
                    )
                  else
                    _reportTableCard(_filteredRows),
                ],
              ),
            ),
    );
  }
}

class _ReportRow {
  final UserModel user;
  final int pretestScore;
  final int posttestScore;
  final int completedMaterials;
  final int totalMaterials;
  final double progressPercent;
  final List<ProgressModel> unitProgress;
  final ProgressModel? overall;

  const _ReportRow({
    required this.user,
    required this.pretestScore,
    required this.posttestScore,
    required this.completedMaterials,
    required this.totalMaterials,
    required this.progressPercent,
    required this.unitProgress,
    required this.overall,
  });
}
