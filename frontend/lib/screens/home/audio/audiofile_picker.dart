import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:autism_project/services/audioserviceapi.dart';
import 'package:autism_project/screens/home/audio/audio_analysis.dart';

class AudioPickerDialog extends StatefulWidget {
  const AudioPickerDialog({super.key});

  @override
  State<AudioPickerDialog> createState() => _AudioPickerDialogState();
}

class _AudioPickerDialogState extends State<AudioPickerDialog> {
  bool _isProcessing = false;
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  bool _isValidFile = true;
  String? _errorMessage;

  // Simplified permission check
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        print('Android SDK version: $sdkInt');

        // For Android 13+ (API 33+)
        if (sdkInt >= 33) {
          print('Requesting Android 13+ permissions');

          // For Android 13+, we need different permissions based on what we're accessing
          PermissionStatus audioStatus = await Permission.audio.request();
          print('Audio permission status: ${audioStatus.name}');

          // Also request notification permission for better UX
          PermissionStatus notificationStatus = await Permission.notification.request();
          print('Notification permission status: ${notificationStatus.name}');

          return audioStatus.isGranted;
        }
        // For Android 11-12 (API 30-32)
        else if (sdkInt >= 30) {
          print('Android 11-12: Using MANAGE_EXTERNAL_STORAGE for broader access');
          // For Android 11+, we can use the storage permission
          PermissionStatus status = await Permission.storage.request();
          print('Storage permission status: ${status.name}');

          if (!status.isGranted) {
            // Try managing external storage as fallback
            PermissionStatus manageStatus = await Permission.manageExternalStorage.request();
            print('Manage external storage status: ${manageStatus.name}');
            return manageStatus.isGranted;
          }
          return status.isGranted;
        }
        // For Android 10 and below
        else {
          print('Requesting storage permission for Android < 11');
          PermissionStatus status = await Permission.storage.request();
          print('Storage permission status: ${status.name}');
          return status.isGranted;
        }
      } catch (e) {
        print('Error checking permissions: $e');
        return true; // Try to proceed anyway
      }
    }
    return true;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Storage permission is required to access audio files. '
                'Please grant permission in app settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    print('========== START FILE PICKING ==========');
    print('_pickAudioFile called');

    try {
      // Check permissions first
      bool hasPermission = await _checkAndRequestPermissions();
      print('Has permission: $hasPermission');

      if (!hasPermission) {
        _showPermissionDeniedDialog();
        return;
      }

      setState(() {
        _errorMessage = null;
        _isProcessing = false;
      });

      print('Attempting to pick audio file...');

      // Try different FilePicker configurations
      FilePickerResult? result;

      // Method 1: Try with custom filter
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac', 'amr'],
          allowMultiple: false,
          allowCompression: false, // Don't compress audio files
        );
        print('Method 1 (custom) result: ${result != null ? 'Files picked' : 'Cancelled'}');
      } catch (e) {
        print('Method 1 failed: $e');

        // Method 2: Try with audio type
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            allowMultiple: false,
          );
          print('Method 2 (audio) result: ${result != null ? 'Files picked' : 'Cancelled'}');
        } catch (e) {
          print('Method 2 failed: $e');

          // Method 3: Try with any file type as last resort
          try {
            result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
            );
            print('Method 3 (any) result: ${result != null ? 'Files picked' : 'Cancelled'}');
          } catch (e) {
            print('Method 3 failed: $e');
            throw Exception('All file picking methods failed');
          }
        }
      }

      if (result != null && result.files.isNotEmpty) {
        print('Files picked count: ${result.files.length}');
        print('First file name: ${result.files.first.name}');
        print('First file path: ${result.files.first.path}');
        print('First file size: ${result.files.first.size}');
        print('First file extension: ${result.files.first.extension}');

        final file = result.files.first;

        if (file.path != null) {
          final filePath = file.path!;
          final audioFile = File(filePath);

          // Check if file exists
          final exists = await audioFile.exists();
          print('File exists: $exists');

          if (exists) {
            // Validate file extension
            final extension = file.extension?.toLowerCase() ?? '';
            final validExtensions = ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac', 'amr'];

            setState(() {
              _selectedFile = audioFile;
              _fileName = file.name;
              _fileSize = file.size;
              _isValidFile = validExtensions.contains(extension) || extension.isEmpty;
              if (!_isValidFile) {
                _errorMessage = 'File format may not be supported. Supported: ${validExtensions.join(', ')}';
              } else {
                _errorMessage = null;
              }
            });

            print('File selected successfully: $_fileName (${_formatFileSize(_fileSize ?? 0)})');
          } else {
            print('Error: File does not exist at path: $filePath');
            setState(() {
              _errorMessage = 'Selected file could not be accessed';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not access the selected file'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          print('Error: File path is null');
          setState(() {
            _errorMessage = 'Could not get file path';
          });
        }
      } else {
        print('User cancelled file picking');
      }
    } catch (e, stackTrace) {
      print('Error in _pickAudioFile: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isValidFile = false;
        _errorMessage = 'Error picking file: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    print('========== END FILE PICKING ==========');
  }

  Future<void> _analyzeAudio() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print('Starting audio analysis for: ${_selectedFile!.path}');

      final result = await AudioService.analyzeVoice(_selectedFile!);

      if (mounted) {
        Navigator.pop(context); // Close dialog

        if (result['success'] == true) {
          print('Analysis successful, navigating to results');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioAnalysisResultScreen(
                result: result,
              ),
            ),
          );
        } else {
          print('Analysis failed: ${result['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Analysis failed'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error during analysis: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during analysis: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Audio File',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an audio file from your device',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // File picker area
            if (_selectedFile == null) ...[
              // Browse button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickAudioFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5B95),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Alternative tap area
              GestureDetector(
                onTap: _isProcessing ? null : _pickAudioFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5B95).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6B5B95).withOpacity(0.3),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: const Color(0xFF6B5B95).withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Or tap here to browse',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports: MP3, WAV, M4A, OGG, AAC, FLAC',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Selected file info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isValidFile
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isValidFile
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValidFile ? Icons.audiotrack : Icons.error,
                      color: _isValidFile ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_fileSize ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isValidFile)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _fileName = null;
                            _fileSize = null;
                            _isValidFile = true;
                            _errorMessage = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isProcessing ? null : _pickAudioFile,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Choose another file'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B5B95),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing audio...'),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedFile != null && _isValidFile && !_isProcessing
                          ? _analyzeAudio
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5B95),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text('Analyze'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}