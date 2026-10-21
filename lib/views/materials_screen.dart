import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/materials_provider.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _selectedBatchFilter = 'All';
  final List<String> _batches = [
    'All',
    'Grade 12 Physics (Batch A)',
    'Grade 12 Physics (Batch B)',
    'Grade 11 Physics (Batch C)',
    'NEET Droppers Batch',
  ];

  Future<void> _openMaterialUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material file link unavailable.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Stream & Open Material'),
          content: SelectableText(url, style: const TextStyle(color: Color(0xFF2563EB))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showUploadMaterialModal(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedBatch = _batches[1]; // Default to Grade 12 Physics
    String selectedFileType = 'PDF';
    String? selectedFilePath;
    String? selectedFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload Study Material',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Title
                    const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Electromagnetic Waves Formula Sheet',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Key notes for upcoming unit test',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target Batch Dropdown
                    const Text('Target Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedBatch,
                      items: _batches
                          .where((b) => b != 'All')
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedBatch = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    ),
                    const SizedBox(height: 12),

                    // File Type Choice Chips
                    const Text('Material Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['PDF', 'Document', 'Link', 'Video'].map((type) {
                        final isSelected = selectedFileType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedFileType = type);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // File Picker Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'mp4', 'png', 'jpg'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setModalState(() {
                            selectedFilePath = result.files.first.path;
                            selectedFileName = result.files.first.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file, color: Color(0xFF2563EB)),
                      label: Text(
                        selectedFileName != null ? 'Selected: $selectedFileName' : 'Attach File / PDF Document',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Upload Button
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a title for the study material')),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close modal

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(color: Color(0xFF2563EB)),
                                SizedBox(width: 16),
                                Text('Uploading study material...'),
                              ],
                            ),
                          ),
                        );

                        final success = await ref.read(materialsProvider.notifier).uploadMaterial(
                              title: title,
                              description: descriptionController.text.trim(),
                              targetBatch: selectedBatch,
                              fileType: selectedFileType,
                              filePath: selectedFilePath,
                            );

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Study material uploaded successfully!'
                                    : 'Upload failed. Please try again.',
                              ),
                              backgroundColor: success ? const Color(0xFF059669) : Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Upload & Share with Batch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userMap = ref.watch(authControllerProvider.notifier).currentUser;
    final isTeacher = (userMap?['role'] as String?)?.toLowerCase() == 'teacher';

    final materialsState = ref.watch(materialsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Study Materials & Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadMaterialModal(context),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
              label: const Text('Upload Material', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          // 1. Batch Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _batches.map((batch) {
                final isSelected = _selectedBatchFilter == batch;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      batch == 'All' ? 'All Batches' : batch,
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
                      setState(() {
                        _selectedBatchFilter = batch;
                      });
                      ref.read(materialsProvider.notifier).fetchMaterials(targetBatch: batch);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Materials List View
          Expanded(
            child: materialsState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : materialsState.errorMessage != null
                    ? Center(
                        child: Text('Error loading materials: ${materialsState.errorMessage}'),
                      )
                    : (() {
                        final materials = materialsState.materials;
                        final filteredList = (_selectedBatchFilter == 'All')
                            ? materials
                            : materials.where((m) => (m['target_batch'] ?? '') == _selectedBatchFilter).toList();

                        if (filteredList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No materials found for $_selectedBatchFilter',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(materialsProvider.notifier).fetchMaterials(targetBatch: _selectedBatchFilter);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildMaterialCard(filteredList[index]);
                            },
                          ),
                        );
                      })(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(dynamic item) {
    final title = (item['title'] ?? 'Material').toString();
    final description = (item['description'] ?? '').toString();
    final targetBatch = (item['target_batch'] ?? 'All Batches').toString();
    final fileType = (item['file_type'] ?? 'PDF').toString();
    final fileUrl = item['file_url']?.toString();
    final isVideo = fileType.toLowerCase() == 'video';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetBatch,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openMaterialUrl(fileUrl),
              icon: Icon(
                isVideo ? Icons.play_arrow_rounded : Icons.file_download_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: Text(isVideo ? 'Watch Lecture' : 'Open Material', style: const TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isVideo ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
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
}
