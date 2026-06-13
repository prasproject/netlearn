import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/header_back_button.dart';

/// Layar streaming video pembelajaran (YouTube).
class MaterialLearningVideoScreen extends StatefulWidget {
  const MaterialLearningVideoScreen({super.key});

  static const String youtubeVideoId = 'jIeJ0MpQKSg';
  static const String youtubeUrl = 'https://www.youtube.com/watch?v=$youtubeVideoId';

  @override
  State<MaterialLearningVideoScreen> createState() => _MaterialLearningVideoScreenState();
}

class _MaterialLearningVideoScreenState extends State<MaterialLearningVideoScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: MaterialLearningVideoScreen.youtubeVideoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    const HeaderBackButton(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Video Pembelajaran',
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIDEO PEMBELAJARAN',
                    style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryBlue, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tonton video tambahan untuk memperdalam materi jaringan komputer.',
                    style: AppTextStyles.paragraph.copyWith(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: _controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
