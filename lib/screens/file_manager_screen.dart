import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/ble_service.dart';
import '../services/api_service.dart';
import '../models/file_info.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileInfo> _files = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    
    final bleService = context.read<BleService>();
    final files = await bleService.listFiles();
    
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _downloadFile(FileInfo file) async {
    final bleService = context.read<BleService>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Download in corso...'),
          ],
        ),
      ),
    );

    final data = await bleService.downloadFile(file.name);
    
    if (mounted) Navigator.pop(context);

    if (data != null) {
      // Salva file localmente
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/${file.name}');
      await localFile.writeAsBytes(data);

      setState(() {
        file.isDownloaded = true;
        file.localPath = localFile.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File scaricato: ${file.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Invia',
              textColor: Colors.white,
              onPressed: () => _uploadToServer(file),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il download'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(FileInfo file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Vuoi eliminare ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bleService = context.read<BleService>();
      final success = await bleService.deleteFile(file.name);

      if (success) {
        setState(() => _files.remove(file));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} eliminato')),
          );
        }
      }
    }
  }

  Future<void> _uploadToServer(FileInfo file) async {
    if (file.localPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scarica prima il file')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Invio al server...'),
          ],
        ),
      ),
    );

    final apiService = context.read<ApiService>();
    final success = await apiService.uploadFile(
      file: File(file.localPath!),
      sessionName: file.name,
    );

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'File e configurazione inviati con successo' 
              : 'Errore invio'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione File'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nessun file sulla SD Card'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          file.isDownloaded 
                              ? Icons.check_circle 
                              : Icons.insert_drive_file,
                          color: file.isDownloaded 
                              ? Colors.green 
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(file.name),
                        subtitle: Text(
                          '${file.sizeFormatted}${file.date != null ? ' • ${file.date!.day}/${file.date!.month}/${file.date!.year}' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'download':
                                _downloadFile(file);
                                break;
                              case 'upload':
                                _uploadToServer(file);
                                break;
                              case 'delete':
                                _deleteFile(file);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'download',
                              child: Row(
                                children: [
                                  Icon(Icons.download),
                                  SizedBox(width: 8),
                                  Text('Scarica'),
                                ],
                              ),
                            ),
                            if (file.isDownloaded)
                              const PopupMenuItem(
                                value: 'upload',
                                child: Row(
                                  children: [
                                    Icon(Icons.cloud_upload),
                                    SizedBox(width: 8),
                                    Text('Invia a Server'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Elimina'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
