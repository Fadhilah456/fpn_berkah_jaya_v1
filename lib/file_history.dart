import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'utils.dart';

class FileHistoryScreen extends StatefulWidget {
  const FileHistoryScreen({super.key});

  @override
  State<FileHistoryScreen> createState() => _FileHistoryScreenState();
}

class _FileHistoryScreenState extends State<FileHistoryScreen> {
  List<File> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await listSavedFiles();
    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _share(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bon/Struk: ${file.uri.pathSegments.last}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal bagikan: $e')),
        );
      }
    }
  }

  Future<void> _copyPath(File file) async {
    await Clipboard.setData(ClipboardData(text: file.path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path file disalin ke clipboard!')),
      );
    }
  }

  Future<void> _delete(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus File?'),
        content: Text('Hapus "${file.uri.pathSegments.last}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await file.delete();
        _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File dihapus!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 Riwayat File'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada file.\nCetak bon/struk dulu ya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final name = file.uri.pathSegments.last;
                      final size = file.statSync().size;
                      final mod = file.statSync().modified;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.description,
                              color: Colors.blue, size: 36),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${formatBytes(size)} • '
                            '${mod.day}/${mod.month}/${mod.year} '
                            '${mod.hour}:${mod.minute.toString().padLeft(2, "0")}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.green),
                                tooltip: 'Bagikan',
                                onPressed: () => _share(file),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    color: Colors.orange),
                                tooltip: 'Salin Path',
                                onPressed: () => _copyPath(file),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                tooltip: 'Hapus',
                                onPressed: () => _delete(file),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}