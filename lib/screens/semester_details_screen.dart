import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db/database_helper.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';

class SemesterDetailsScreen extends StatefulWidget {
  final int semester;

  const SemesterDetailsScreen({
    super.key,
    required this.semester,
  });

  @override
  State<SemesterDetailsScreen> createState() =>
      _SemesterDetailsScreenState();
}

class _SemesterDetailsScreenState extends State<SemesterDetailsScreen> {
  String? resultPath;
  List<String> backlogPaths = [];

  final DatabaseHelper db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadSavedData() async {
    final res = await db.getResult(widget.semester);
    final backs = await db.getBacklogs(widget.semester);

    setState(() {
      resultPath = res;
      backlogPaths = backs;
    });
  }

  // ================= FILE HELPERS =================
  Future<String> _saveFileLocally(
    PlatformFile pickedFile, {
    required String prefix,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final ext = pickedFile.extension!;
    final fileName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final savedFile = File('${appDir.path}/$fileName');
    await File(pickedFile.path!).copy(savedFile.path);

    return savedFile.path;
  }

  Widget _fileLeadingWidget(String path) {
    final ext = path.split('.').last.toLowerCase();

    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(Icons.picture_as_pdf,
        size: 38, color: Colors.redAccent);
  }

  void _openFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(filePath: path),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(imagePath: path),
        ),
      );
    }
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ================= SHARE =================
  Future<void> _shareAllFiles() async {
    final List<XFile> files = [];

    if (resultPath != null) files.add(XFile(resultPath!));
    for (final p in backlogPaths) {
      files.add(XFile(p));
    }

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files to share')),
      );
      return;
    }

    await Share.shareXFiles(
      files,
      text: 'Semester ${widget.semester} documents',
    );
  }

  // ================= RENAME =================
  Future<void> _renameFile({
    required String oldPath,
    required bool isResult,
  }) async {
    final controller = TextEditingController(
      text: oldPath.split('/').last.split('.').first,
    );
    final ext = oldPath.split('.').last;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Rename file',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final dir = File(oldPath).parent;
              final newPath = '${dir.path}/$newName.$ext';

              await File(oldPath).rename(newPath);

              if (isResult) {
                await db.updateResultPath(
                    widget.semester, newPath);
                setState(() => resultPath = newPath);
              } else {
                await db.updateBacklogPath(oldPath, newPath);
                final index = backlogPaths.indexOf(oldPath);
                setState(() => backlogPaths[index] = newPath);
              }

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File renamed')),
              );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  // ================= RESULT =================
  Future<void> _pickResult() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (picked == null) return;

    final path = await _saveFileLocally(
      picked.files.single,
      prefix: 'semester_${widget.semester}_result',
    );

    await db.saveResult(widget.semester, path);

    setState(() => resultPath = path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result added')),
    );

    _openFile(path);
  }

  Future<void> _deleteResult() async {
    if (resultPath == null) return;

    await db.deleteResult(widget.semester);
    await _deleteFile(resultPath!);

    setState(() => resultPath = null);
  }

  // ================= BACKLOG =================
  Future<void> _pickBacklog() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (picked == null) return;

    final path = await _saveFileLocally(
      picked.files.single,
      prefix: 'semester_${widget.semester}_backlog',
    );

    await db.addBacklog(widget.semester, path);

    setState(() => backlogPaths.add(path));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backlog added')),
    );
  }

  Future<void> _deleteBacklog(String path) async {
    await db.deleteBacklog(path);
    await _deleteFile(path);

    setState(() => backlogPaths.remove(path));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Semester ${widget.semester}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share files',
            onPressed: _shareAllFiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== RESULT =====
            const Text(
              'Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: resultPath == null
                    ? const Icon(Icons.assignment,
                        size: 40, color: Colors.indigo)
                    : _fileLeadingWidget(resultPath!),
                title: Text(
                  resultPath == null
                      ? 'Add Result'
                      : 'Semester Result',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  resultPath == null
                      ? 'PDF or Image'
                      : 'Tap to open • Long press for options',
                ),
                onTap: resultPath == null
                    ? _pickResult
                    : () => _openFile(resultPath!),
                onLongPress: resultPath == null
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text(
                              'Result Options',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _renameFile(
                                    oldPath: resultPath!,
                                    isResult: true,
                                  );
                                },
                                child: const Text('Rename'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _deleteResult();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                      color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
              ),
            ),

            const SizedBox(height: 28),

            // ===== BACKLOGS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Backlogs',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _pickBacklog,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (backlogPaths.isEmpty)
              Column(
                children: const [
                  SizedBox(height: 12),
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No backlogs added',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

            ...backlogPaths.map(
              (path) => Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                  leading: _fileLeadingWidget(path),
                  title: Text(
                    'Backlog ${backlogPaths.indexOf(path) + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                      'Tap to open • Long press for options'),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: () => _openFile(path),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text(
                          'Backlog Options',
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _renameFile(
                                oldPath: path,
                                isResult: false,
                              );
                            },
                            child: const Text('Rename'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _deleteBacklog(path);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                  color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
