import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/image_to_base64.dart';
import '../../data/models/material_model.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/quiz_provider.dart';

class ManageMaterialsScreen extends ConsumerStatefulWidget {
  const ManageMaterialsScreen({super.key});

  @override
  ConsumerState<ManageMaterialsScreen> createState() => _ManageMaterialsScreenState();
}

class _ManageMaterialsScreenState extends ConsumerState<ManageMaterialsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _uuid = const Uuid();
  List<QuizModel> _quizzes = [];
  bool _isLoadingQuizzes = true;
  static const int _kDefaultPrePostQuestionCount = 10;
  final _quizTitleC = TextEditingController(text: 'Pre/Post Test');
  final _quizTimeLimitC = TextEditingController(text: '900');
  bool _quizBankInitialized = false;
  List<TextEditingController> _qQuestionC = [];
  List<List<TextEditingController>> _qOptionC = [];
  List<TextEditingController> _qImageBase64C = [];
  List<TextEditingController> _qExplanationC = [];
  List<TextEditingController> _qTopicC = [];
  List<int> _qCorrectIndex = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      // Rebuild so FAB label/action updates immediately on tab change.
      setState(() {});
    });
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoadingQuizzes = true);
    final quizzes = await ref.read(quizProvider.notifier).getAllQuizzes();
    // Admin screen expectation: only manage pre-test & post-test here.
    final filtered = quizzes
        .where((q) => q.type == QuizType.pretest || q.type == QuizType.posttest)
        .toList();
    filtered.sort((a, b) => a.title.compareTo(b.title));
    if (!mounted) return;
    setState(() {
      _quizzes = filtered;
      _isLoadingQuizzes = false;
    });
    _initPrePostBankFromExisting();
  }

  @override
  void dispose() {
    _quizTitleC.dispose();
    _quizTimeLimitC.dispose();
    for (final c in _qQuestionC) {
      c.dispose();
    }
    for (final row in _qOptionC) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final c in _qImageBase64C) {
      c.dispose();
    }
    for (final c in _qExplanationC) {
      c.dispose();
    }
    for (final c in _qTopicC) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialsState = ref.watch(materialProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kelola Materi & Pre/Post Test', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Materi'),
            Tab(text: 'Pre/Post Test'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialTab(materialsState.materials),
          _buildQuizTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 0) {
            await _openMaterialDialog();
            return;
          }
          _jumpToFirstEmptyQuestion();
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Tambah Materi' : 'Tambah Soal',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _initPrePostBankFromExisting() {
    if (_quizBankInitialized) return;

    QuizModel? pre = _quizzes.where((q) => q.type == QuizType.pretest).firstOrNull;
    QuizModel? post = _quizzes.where((q) => q.type == QuizType.posttest).firstOrNull;
    final source = pre ?? post;

    _quizTitleC.text = source?.title ?? 'Pre/Post Test';
    _quizTimeLimitC.text = '${source?.timeLimitSeconds ?? 900}';

    final questions = source?.questions ?? const <QuizQuestion>[];

    _qQuestionC = List.generate(
      _kDefaultPrePostQuestionCount,
      (i) => TextEditingController(text: questions.elementAtOrNull(i)?.question ?? ''),
    );
    _qOptionC = List.generate(_kDefaultPrePostQuestionCount, (i) {
      final opts = questions.elementAtOrNull(i)?.options ?? const <String>[];
      return List.generate(
        4,
        (j) => TextEditingController(text: opts.elementAtOrNull(j) ?? ''),
      );
    });
    _qImageBase64C = List.generate(
      _kDefaultPrePostQuestionCount,
      (i) => TextEditingController(text: questions.elementAtOrNull(i)?.imageBase64 ?? ''),
    );
    _qExplanationC = List.generate(
      _kDefaultPrePostQuestionCount,
      (i) => TextEditingController(text: questions.elementAtOrNull(i)?.explanation ?? ''),
    );
    _qTopicC = List.generate(
      _kDefaultPrePostQuestionCount,
      (i) => TextEditingController(text: questions.elementAtOrNull(i)?.topic ?? ''),
    );
    _qCorrectIndex = List.generate(
      _kDefaultPrePostQuestionCount,
      (i) => (questions.elementAtOrNull(i)?.correctIndex ?? 0).clamp(0, 3),
    );

    _quizBankInitialized = true;
    if (mounted) setState(() {});
  }

  void _jumpToFirstEmptyQuestion() {
    _initPrePostBankFromExisting();
    final idx = _qQuestionC.indexWhere((c) => c.text.trim().isEmpty);
    if (idx == -1) {
      _showSnack('Semua 10 soal sudah ada. Silakan edit lalu tekan Simpan.');
      return;
    }
    _showSnack('Silakan isi Soal ${idx + 1}.');
  }

  Widget _buildMaterialTab(List<MaterialModel> materials) {
    if (materials.isEmpty) return const Center(child: Text('Belum ada materi.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlueLight,
              child: Text(material.iconEmoji ?? '📘'),
            ),
            title: Text(material.title, style: AppTextStyles.heading),
            subtitle: Text(
              'Unit ${material.unitNumber} • ${material.slides.length} slide',
              style: AppTextStyles.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  onPressed: () => _openMaterialDialog(existing: material),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMaterial(material),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTab() {
    if (_isLoadingQuizzes) {
      return const Center(child: CircularProgressIndicator());
    }

    _initPrePostBankFromExisting();

    if (!_quizBankInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Soal Pre/Post Test (10 pertanyaan)',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-test dan post-test akan mengambil soal yang sama, lalu diacak saat dikerjakan.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quizTimeLimitC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Batas Waktu (detik)'),
          ),
          const SizedBox(height: 12),
          const Divider(height: 24),
          const SizedBox(height: 8),
          for (int i = 0; i < _kDefaultPrePostQuestionCount; i++) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soal ${i + 1}', style: AppTextStyles.heading),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qQuestionC[i],
                      decoration: const InputDecoration(labelText: 'Pertanyaan'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    for (int opt = 0; opt < 4; opt++) ...[
                      TextField(
                        controller: _qOptionC[i][opt],
                        decoration: InputDecoration(labelText: 'Opsi ${opt + 1}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      value: _qCorrectIndex[i],
                      decoration: const InputDecoration(labelText: 'Jawaban Benar'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Opsi 1')),
                        DropdownMenuItem(value: 1, child: Text('Opsi 2')),
                        DropdownMenuItem(value: 2, child: Text('Opsi 3')),
                        DropdownMenuItem(value: 3, child: Text('Opsi 4')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _qCorrectIndex[i] = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qTopicC[i],
                      decoration: const InputDecoration(labelText: 'Topik (opsional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qExplanationC[i],
                      decoration: const InputDecoration(labelText: 'Penjelasan (opsional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _Base64ImagePicker(
                      label: 'Gambar Soal (opsional)',
                      controller: _qImageBase64C[i],
                    ),
                    const SizedBox(height: 12),
                    _Base64Preview(controller: _qImageBase64C[i]),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savePrePostBank,
              icon: const Icon(Icons.save),
              label: const Text('Simpan 10 Soal'),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _savePrePostBank() async {
    final timeLimit = int.tryParse(_quizTimeLimitC.text.trim()) ?? 900;

    final builtQuestions = List.generate(_kDefaultPrePostQuestionCount, (i) {
      return QuizQuestion(
        question: _qQuestionC[i].text.trim(),
        options: List.generate(4, (j) => _qOptionC[i][j].text.trim()),
        correctIndex: _qCorrectIndex[i],
        imageBase64: _qImageBase64C[i].text.trim().isEmpty ? null : _qImageBase64C[i].text.trim(),
        explanation: _qExplanationC[i].text.trim().isEmpty ? null : _qExplanationC[i].text.trim(),
        topic: _qTopicC[i].text.trim().isEmpty ? null : _qTopicC[i].text.trim(),
      );
    });

    final hasInvalid = builtQuestions.any((q) {
      if (q.question.trim().isEmpty) return true;
      if (q.options.length != 4) return true;
      if (q.options.any((o) => o.trim().isEmpty)) return true;
      if (q.correctIndex < 0 || q.correctIndex > 3) return true;
      return false;
    });
    if (hasInvalid) {
      _showSnack('Mohon lengkapi pertanyaan + 4 opsi untuk semua 10 soal (jawaban benar wajib).');
      return;
    }

    final preExisting = _quizzes.where((q) => q.type == QuizType.pretest).firstOrNull;
    final postExisting = _quizzes.where((q) => q.type == QuizType.posttest).firstOrNull;

    final pre = QuizModel(
      id: preExisting?.id ?? 'pretest-${_uuid.v4().substring(0, 8)}',
      type: QuizType.pretest,
      unitId: null,
      title: preExisting?.title ?? 'Pre-Test',
      timeLimitSeconds: timeLimit,
      xpReward: preExisting?.xpReward ?? 15,
      questions: builtQuestions,
    );
    final post = QuizModel(
      id: postExisting?.id ?? 'posttest-${_uuid.v4().substring(0, 8)}',
      type: QuizType.posttest,
      unitId: null,
      title: postExisting?.title ?? 'Post-Test',
      timeLimitSeconds: timeLimit,
      xpReward: postExisting?.xpReward ?? 15,
      questions: builtQuestions,
    );

    if (preExisting == null) {
      await ref.read(quizProvider.notifier).createQuiz(pre);
    } else {
      await ref.read(quizProvider.notifier).updateQuiz(pre);
    }

    if (postExisting == null) {
      await ref.read(quizProvider.notifier).createQuiz(post);
    } else {
      await ref.read(quizProvider.notifier).updateQuiz(post);
    }

    _showSnack('Bank soal pre/post berhasil disimpan (10 soal).');
    await _loadQuizzes();
  }

  Future<void> _openMaterialDialog({MaterialModel? existing}) async {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final descriptionC = TextEditingController(text: existing?.description ?? '');
    final iconC = TextEditingController(text: existing?.iconEmoji ?? '📘');
    final unitC = TextEditingController(text: '${existing?.unitNumber ?? 1}');
    final initialSlides = (existing?.slides.isNotEmpty ?? false) ? existing!.slides : null;
    final slides = <({
      TextEditingController title,
      TextEditingController content,
      TextEditingController imageBase64,
    })>[
      for (final s in (initialSlides ?? const <MaterialSlide>[MaterialSlide(title: '', content: '')]))
        (
          title: TextEditingController(text: s.title),
          content: TextEditingController(text: s.content),
          imageBase64: TextEditingController(text: s.imageBase64 ?? ''),
        ),
    ];

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Materi' : 'Edit Materi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Judul Materi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionC,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconC,
                  decoration: const InputDecoration(labelText: 'Icon Emoji'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nomor Unit'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Slides (${slides.length})', style: AppTextStyles.heading),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          slides.add((
                            title: TextEditingController(),
                            content: TextEditingController(),
                            imageBase64: TextEditingController(),
                          ));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Slide'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < slides.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Slide ${i + 1}', style: AppTextStyles.heading),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Hapus slide',
                                onPressed: slides.length <= 1
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          slides.removeAt(i);
                                        });
                                      },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: slides[i].title,
                            decoration: InputDecoration(labelText: 'Judul Slide ${i + 1}'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: slides[i].content,
                            decoration: InputDecoration(labelText: 'Konten Slide ${i + 1}'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _Base64ImagePicker(
                            label: 'Gambar Slide ${i + 1} (opsional)',
                            controller: slides[i].imageBase64,
                          ),
                          const SizedBox(height: 12),
                          _Base64Preview(controller: slides[i].imageBase64),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (submit != true) return;
    final unit = int.tryParse(unitC.text.trim()) ?? 1;
    final builtSlides = slides
        .map(
          (s) => MaterialSlide(
            title: s.title.text.trim(),
            content: s.content.text.trim(),
            imageBase64: s.imageBase64.text.trim().isEmpty ? null : s.imageBase64.text.trim(),
          ),
        )
        .toList();
    final hasEmptySlide = builtSlides.any((s) => s.title.trim().isEmpty || s.content.trim().isEmpty);
    if (builtSlides.isEmpty || hasEmptySlide) {
      _showSnack('Mohon lengkapi judul & konten untuk semua slide.');
      return;
    }
    final material = MaterialModel(
      id: existing?.id ?? 'unit-${_uuid.v4().substring(0, 8)}',
      unitNumber: unit,
      title: titleC.text.trim(),
      description: descriptionC.text.trim(),
      order: existing?.order ?? unit - 1,
      isLocked: existing?.isLocked ?? false,
      iconEmoji: iconC.text.trim(),
      slides: builtSlides,
    );

    if (existing == null) {
      await ref.read(materialProvider.notifier).createMaterial(material);
      _showSnack('Materi berhasil dibuat.');
    } else {
      await ref.read(materialProvider.notifier).updateMaterial(material);
      _showSnack('Materi berhasil diperbarui.');
    }
  }

  Future<void> _deleteMaterial(MaterialModel material) async {
    final confirmed = await _confirmDelete('Hapus materi "${material.title}"?');
    if (!confirmed) return;
    await ref.read(materialProvider.notifier).deleteMaterial(material.id);
    _showSnack('Materi berhasil dihapus.');
  }

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Base64Preview extends StatelessWidget {
  final TextEditingController controller;

  const _Base64Preview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final base64Text = value.text.trim();
        if (base64Text.isEmpty) return const SizedBox.shrink();
        try {
          final bytes = base64Decode(base64Text);
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, height: 80, width: double.infinity, fit: BoxFit.cover),
          );
        } catch (_) {
          return const Text('Base64 tidak valid', style: TextStyle(color: Colors.red));
        }
      },
    );
  }
}

class _Base64ImagePicker extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _Base64ImagePicker({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasImage = value.text.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final encoded = await ImageToBase64.pickFromGalleryAndEncode();
                    if (encoded == null) return;
                    controller.text = encoded;
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih dari Galeri'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final encoded = await ImageToBase64.pickFromCameraAndEncode();
                    if (encoded == null) return;
                    controller.text = encoded;
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
