import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'video_player_screen.dart';

class RecordedClassesScreen extends ConsumerStatefulWidget {
  const RecordedClassesScreen({super.key});

  @override
  ConsumerState<RecordedClassesScreen> createState() => _RecordedClassesScreenState();
}

class _RecordedClassesScreenState extends ConsumerState<RecordedClassesScreen> {
  bool _isLoading = false;
  List<dynamic> _recordings = [];

  @override
  void initState() {
    super.initState();
    _fetchRecordings();
  }

  Future<void> _fetchRecordings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      _recordings = await apiService.getClassroomRecordings(classroomId: 84920);
    } catch (_) {
      _recordings = [
        {
          'id': 1,
          'title': 'Physics: Wave Optics Interference & Fringe Width',
          'description': 'Full recorded live lecture covering Young\'s Double Slit Experiment derivation.',
          'file_type': 'Video',
          'file_url': 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4',
          'duration': '42m 15s',
          'upload_date': 'Oct 24, 2026',
        },
        {
          'id': 2,
          'title': 'Physics: Electromagnetic Waves & Spectrum',
          'description': 'Displacement current, Maxwell\'s equations, and electromagnetic spectrum characteristics.',
          'file_type': 'Video',
          'file_url': 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4',
          'duration': '50m 00s',
          'upload_date': 'Oct 22, 2026',
        },
      ];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openPlaybackPlayer(dynamic item) {
    final videoUrl = item['file_url'] ?? 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4';
    final title = item['title'] ?? 'Recorded Session Playback';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: videoUrl, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Recorded Class Sessions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _recordings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No class recordings available yet.',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRecordings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final item = _recordings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? 'Lecture Recording',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Recorded on ${item['upload_date'] ?? 'Oct 2026'} • Duration: ${item['duration'] ?? '45 mins'}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item['description'],
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _openPlaybackPlayer(item),
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                label: const Text('Play Recording', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
