import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/materials_provider.dart';
import '../services/download_service.dart';

/// Student Course & Material Library Catalog Screen
class StudentMaterialsScreen extends ConsumerStatefulWidget {
  const StudentMaterialsScreen({super.key});

  @override
  ConsumerState<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends ConsumerState<StudentMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DownloadService _downloadService = DownloadService();

  bool _isGridView = false;
  final List<String> _categories = ['All', 'PDF', 'Video', 'Document', 'Link'];

  // Maps file_url -> progress (0.0 to 1.0)
  final Map<String, double> _downloadProgress = {};
  // Set of file_urls that are downloaded locally
  final Set<String> _downloadedUrls = {};

  @override
  void initState() {
    super.initState();
    _checkDownloadedFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDownloadedFiles() async {
    final state = ref.read(materialsNotifierProvider);
    for (final item in state.materials) {
      final url = item['file_url']?.toString();
      if (url != null && url.isNotEmpty) {
        final isDownloaded = await DownloadService.isFileDownloaded(url);
        if (isDownloaded && mounted) {
          setState(() {
            _downloadedUrls.add(url);
          });
        }
      }
    }
  }

  Future<void> _handleDownloadOrOpen(dynamic item) async {
    final url = item['file_url']?.toString();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material file URL unavailable.')),
      );
      return;
    }

    // 1. If file is already cached locally, open offline file
    final localPath = await DownloadService.getLocalFilePath(url);
    if (localPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening Cached Offline File: ${localPath.split('/').last}'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Otherwise start Dio file download with live progress callback
    final title = (item['title'] ?? 'material').toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileType = (item['file_type'] ?? 'pdf').toString().toLowerCase();
    final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.$fileType';

    setState(() {
      _downloadProgress[url] = 0.01;
    });

    final savedPath = await _downloadService.downloadFile(
      fileUrl: url,
      fileName: fileName,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() {
            _downloadProgress[url] = received / total;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _downloadProgress.remove(url);
        if (savedPath != null) {
          _downloadedUrls.add(url);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath != null
                ? 'File downloaded & saved offline!'
                : 'Download failed. Opening online stream...',
          ),
          backgroundColor: savedPath != null ? const Color(0xFF059669) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (savedPath == null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(materialsNotifierProvider);
    final notifier = ref.read(materialsNotifierProvider.notifier);

    final List<dynamic> filteredList = [];
    for (final dynamic item in state.materials) {
      final String title = (item['title'] ?? '').toString().toLowerCase();
      final String desc = (item['description'] ?? '').toString().toLowerCase();
      final String type = (item['file_type'] ?? '').toString().toLowerCase();
      final String query = state.searchQuery.toLowerCase();

      final bool matchesQuery = query.isEmpty || title.contains(query) || desc.contains(query);
      final bool matchesType = state.selectedType == 'All' || type.contains(state.selectedType.toLowerCase());

      if (matchesQuery && matchesType) {
        filteredList.add(item);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Course & Material Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF2563EB),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                notifier.setSearchQuery(val);
              },
              decoration: InputDecoration(
                hintText: 'Search formula notes, recorded lectures...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = state.selectedType == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat == 'All' ? 'All Formats' : cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      if (val) {
                        notifier.setSelectedType(cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No learning materials found.',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await notifier.loadMaterials();
                          _checkDownloadedFiles();
                        },
                        child: _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.82,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  return _buildMaterialGridTile(item);
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  return _buildMaterialListCard(item);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialListCard(dynamic item) {
    final fileType = (item['file_type'] ?? 'PDF').toString();
    final url = (item['file_url'] ?? '').toString();
    final isVideo = fileType.toLowerCase() == 'video';
    final isDownloaded = _downloadedUrls.contains(url);
    final progress = _downloadProgress[url];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDownloaded ? const Color(0xFF10B981) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isVideo ? const Color(0xFFFEF2F2) : const Color(0xFFE0EAFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                  color: isVideo ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Study Material',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item['target_batch'] ?? 'All Batches',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('SAVED OFFLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ),
                        ],
                      ],
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
          if (progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              color: const Color(0xFF2563EB),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 4),
            Text(
              'Downloading: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: progress != null ? null : () => _handleDownloadOrOpen(item),
              icon: Icon(
                isDownloaded
                    ? Icons.offline_pin_rounded
                    : isVideo
                        ? Icons.play_arrow_rounded
                        : Icons.file_download_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                isDownloaded
                    ? 'Open Offline File'
                    : isVideo
                        ? 'Watch Lecture'
                        : 'Download File',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDownloaded
                    ? const Color(0xFF059669)
                    : isVideo
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF2563EB),
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
  }

  Widget _buildMaterialGridTile(dynamic item) {
    final fileType = (item['file_type'] ?? 'PDF').toString();
    final url = (item['file_url'] ?? '').toString();
    final isVideo = fileType.toLowerCase() == 'video';
    final isDownloaded = _downloadedUrls.contains(url);

    return GestureDetector(
      onTap: () => _handleDownloadOrOpen(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDownloaded ? const Color(0xFF10B981) : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isVideo ? const Color(0xFFFEF2F2) : const Color(0xFFE0EAFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                    color: isVideo ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                if (isDownloaded)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['title'] ?? 'Material',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              isDownloaded ? 'SAVED OFFLINE' : item['target_batch'] ?? '',
              style: TextStyle(
                fontSize: 10,
                color: isDownloaded ? const Color(0xFF059669) : const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
