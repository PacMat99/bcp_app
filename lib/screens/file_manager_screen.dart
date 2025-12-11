import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/ble_service.dart';
import '../services/api_service.dart';
import '../models/file_info.dart';
import '../theme/app_theme.dart'; // Necessario per AppTheme.success

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
            Text('Downloading file...'),
          ],
        ),
      ),
    );

    final data = await bleService.downloadFile(file.name);
    
    if (mounted) Navigator.pop(context); // Chiude il dialog

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
            content: Text('Downloaded: ${file.name}'),
            backgroundColor: AppTheme.success, // Verde del tema
            action: SnackBarAction(
              label: 'UPLOAD',
              textColor: Colors.white,
              onPressed: () => _uploadToServer(file),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download failed'),
            backgroundColor: Theme.of(context).colorScheme.error, // Rosso del tema
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(FileInfo file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete ${file.name} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete', 
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
            SnackBar(content: Text('${file.name} deleted')),
          );
        }
      }
    }
  }

  Future<void> _uploadToServer(FileInfo file) async {
    if (file.localPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download the file first')),
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
            Text('Uploading to server...'),
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
      Navigator.pop(context); // Chiude il dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'File uploaded successfully' 
              : 'Upload failed'),
          backgroundColor: success ? AppTheme.success : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // HEADER CARD (Aggiunta per coerenza con le altre schermate)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.sd_storage_outlined,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SD Card Storage',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage telemetry logs',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LISTA FILE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_outlined, 
                              size: 64, 
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No logs found on SD Card',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: file.isDownloaded 
                                ? AppTheme.success.withValues(alpha: 0.05) 
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: file.isDownloaded
                                  ? BorderSide(color: AppTheme.success.withValues(alpha: 0.3), width: 1)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: Icon(
                                file.isDownloaded 
                                    ? Icons.check_circle 
                                    : Icons.insert_drive_file,
                                color: file.isDownloaded 
                                    ? AppTheme.success 
                                    : colorScheme.secondary, // Tech Blue
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${file.sizeFormatted}${file.date != null ? ' • ${file.date!.day}/${file.date!.month}/${file.date!.year}' : ''}',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                                        SizedBox(width: 12),
                                        Text('Download'),
                                      ],
                                    ),
                                  ),
                                  if (file.isDownloaded)
                                    const PopupMenuItem(
                                      value: 'upload',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cloud_upload),
                                          SizedBox(width: 12),
                                          Text('Upload to Server'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: colorScheme.error),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Delete', 
                                          style: TextStyle(color: colorScheme.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}