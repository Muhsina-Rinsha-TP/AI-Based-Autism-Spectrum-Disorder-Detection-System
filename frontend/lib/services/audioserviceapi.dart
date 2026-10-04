import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:autism_project/services/token_storage.dart';

class AudioService {
  static const String baseUrl = 'http://192.168.1.31:8000/api';
  static const String analyzeVoiceEndpoint = '$baseUrl/analyze-voice/';

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  StreamSubscription<RecordState>? _recordStateSubscription;

  // Check microphone permission
  static Future<bool> checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Check permission
      bool hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Check if already recording
      if (_isRecording) {
        print('⚠️ Already recording');
        return false;
      }

      // Get temp directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/recording_$timestamp.m4a';

      // Configure recording
      const encoder = AudioEncoder.aacLc; // Good quality and compression
      final config = RecordConfig(encoder: encoder);

      // Start recording
      await _audioRecorder.start(config, path: _recordingPath!);
      _isRecording = true;

      print('✅ Recording started: $_recordingPath');

      // Listen to recording state changes
      _recordStateSubscription = _audioRecorder.onStateChanged().listen((recordState) {
        print('🎙️ Recording state: $recordState');
      });

      return true;
    } catch (e) {
      print('❌ Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️ Not recording');
        return null;
      }

      // Stop recording
      final path = await _audioRecorder.stop();
      _isRecording = false;

      // Cancel subscription
      await _recordStateSubscription?.cancel();
      _recordStateSubscription = null;

      print('✅ Recording stopped: $path');
      return path;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Cancel recording (discard)
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }

      // Cancel subscription
      await _recordStateSubscription?.cancel();
      _recordStateSubscription = null;

      // Delete temp file if exists
      if (_recordingPath != null && File(_recordingPath!).existsSync()) {
        File(_recordingPath!).deleteSync();
        print('🗑️ Recording discarded: $_recordingPath');
      }

      _recordingPath = null;
    } catch (e) {
      print('❌ Error canceling recording: $e');
    }
  }

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Analyze voice by sending to backend
  static Future<Map<String, dynamic>> analyzeVoice(File audioFile) async {
    try {
      print('🚀 Analyzing voice: $analyzeVoiceEndpoint');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      // Check if token exists
      if (token == null) {
        print('❌ No token found! User not authenticated.');
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
        };
      }

      print('✅ Token retrieved successfully');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(analyzeVoiceEndpoint),
      );

      // Add token to headers
      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });

      // Add audio file
      final fileStream = http.MultipartFile(
        'audio',
        audioFile.openRead(),
        await audioFile.length(),
        filename: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
        contentType: MediaType('audio', 'wav'),
      );

      request.files.add(fileStream);

      print('📤 Audio file added: ${audioFile.path}');
      print('📤 File size: ${await audioFile.length()} bytes');

      // Send request
      var streamedResponse = await request.send();

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        return {
          'success': true,
          'status': responseData['status'],
          'analysis_status': responseData['analysis_status'],
          'message': responseData['message'],
          'features': responseData['features'],
          'observations': responseData['observations'],
          'note': responseData['note'],
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = 'Analysis failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? 'Server error';
        } catch (_) {}

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Voice analysis error: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  // Validate audio file
  static Map<String, dynamic> validateAudioFile(File audioFile) {
    final String fileName = audioFile.path.split('/').last;
    final String extension = fileName.split('.').last.toLowerCase();
    final int fileSize = audioFile.lengthSync();

    // Check supported formats
    final supportedFormats = ['wav', 'mp3', 'ogg', 'm4a'];
    if (!supportedFormats.contains(extension)) {
      return {
        'valid': false,
        'error': 'Unsupported format. Please use WAV, MP3, OGG, or M4A',
      };
    }

    // Check file size (10MB max for audio)
    if (fileSize > 10 * 1024 * 1024) {
      return {
        'valid': false,
        'error': 'File too large. Maximum size is 10MB',
      };
    }

    return {
      'valid': true,
      'fileName': fileName,
      'fileSize': fileSize,
      'extension': extension,
    };
  }

  // Dispose method
  void dispose() {
    _recordStateSubscription?.cancel();
    _audioRecorder.dispose();
  }
}