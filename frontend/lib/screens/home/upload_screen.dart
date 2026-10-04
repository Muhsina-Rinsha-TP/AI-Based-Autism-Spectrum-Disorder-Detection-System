import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:autism_project/services/token_storage.dart';
import 'package:autism_project/services/api_service.dart';
import 'package:intl/intl.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isAnalyzing = false;
  File? _selectedVideo;
  String? _videoName;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? _userReport;
  bool _isLoadingReport = false;

  final ImagePicker _picker = ImagePicker();

  // Pick video from gallery
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final videoFile = File(video.path);

        // Validate video using ApiService
        final validation = ApiService.validateVideoFile(videoFile);

        if (!validation['valid']) {
          _showErrorDialog('Invalid File', validation['error']);
          return;
        }

        setState(() {
          _selectedVideo = videoFile;
          _videoName = validation['fileName'];
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to pick video: $e');
    }
  }

  // Upload video using ApiService
  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;

    // Check if user is logged in
    final isLoggedIn = await TokenStorageService.isLoggedIn();
    if (!isLoggedIn) {
      _showErrorDialog('Not Logged In', 'Please login to upload videos');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.uploadVideo(
        videoFile: _selectedVideo!,
      );

      if (result['success']) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });

        // Show results with all new fields
        _showAnalysisResult(context, result);
      } else {
        throw Exception(result['error'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString();
      });

      _showErrorDialog('Upload Failed', e.toString());
    }
  }

  // Fetch user report
  Future<void> _fetchUserReport() async {
    setState(() {
      _isLoadingReport = true;
    });

    try {
      final result = await ApiService.getUserReport();

      if (result['success']) {
        setState(() {
          _userReport = result['data'];
          _isLoadingReport = false;
        });

        // Show report dialog
        _showUserReportDialog(context);
      } else {
        throw Exception(result['error'] ?? 'Failed to load report');
      }
    } catch (e) {
      setState(() {
        _isLoadingReport = false;
      });

      _showErrorDialog('Report Error', e.toString());
    }
  }

  // Clear selected video
  void _clearVideo() {
    setState(() {
      _selectedVideo = null;
      _videoName = null;
      _errorMessage = null;
      _analysisResult = null;
    });
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF2C3E50),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video Analysis',
          style: TextStyle(
            color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Report button
          // IconButton(
          //   icon: const Icon(Icons.assignment, color: Color(0xFF6B5B95)),
          //   onPressed: _fetchUserReport,
          //   tooltip: 'View My Report',
          // ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (!isLandscape) ...[
                Text(
                  'Upload Video',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : (isTablet ? 28 : 32),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a video of your child for AI analysis',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Upload Area
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                    isSmallScreen ? 20 : (isLandscape ? 15 : 30)
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Upload UI based on state
                    if (_isAnalyzing)
                      _buildAnalyzingProgress(isSmallScreen)
                    else if (_selectedVideo == null)
                      _buildUploadPrompt(isSmallScreen, isTablet)
                    else
                      _buildVideoPreview(isSmallScreen),

                    // Error message if any
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Analyze Button
              if (_selectedVideo != null && !_isAnalyzing)
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 50 : 55,
                  child: ElevatedButton(
                    onPressed: _uploadVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88B0D3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Start AI Analysis',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Quick Stats and Guidelines
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guidelines
                  Expanded(
                    flex: 2,
                    child: _buildGuidelines(),
                  ),

                  // Quick Stats Button
                  if (!isSmallScreen) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _buildQuickStatsCard(),
                    ),
                  ],
                ],
              ),

              if (isSmallScreen) ...[
                const SizedBox(height: 20),
                _buildQuickStatsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPrompt(bool isSmallScreen, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6B5B95).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: isSmallScreen ? 40 : 50,
            color: const Color(0xFF6B5B95),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tap to select video',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supported formats: MP4, MOV, AVI, MKV (Max 100MB)',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: isSmallScreen ? double.infinity : 300,
          height: isSmallScreen ? 45 : 50,
          child: ElevatedButton(
            onPressed: _pickVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5B95),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Files',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5B95).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Color(0xFF6B5B95),
                size: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.videocam,
                color: Color(0xFF6B5B95),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _videoName ?? 'Selected video',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Ready to analyze',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearVideo,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingProgress(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6B5B95).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5B95)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Analyzing video...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This may take a few moments',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF6B5B95), size: 20),
              SizedBox(width: 8),
              Text(
                '📋 Guidelines',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildGuideline('Record in a well-lit environment'),
          _buildGuideline('Ensure child is clearly visible'),
          _buildGuideline('Record for 2-3 minutes minimum'),
          _buildGuideline('Capture natural play behavior'),
          _buildGuideline('Avoid rapid camera movements'),
          _buildGuideline('Keep phone steady while recording'),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF6B5B95),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF6B5B95), size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Stats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildStatItem(Icons.assessment, 'Total Analyses', '5'),
          const Divider(height: 20),
          _buildStatItem(Icons.videocam, 'Videos Uploaded', '3'),
          const Divider(height: 20),
          _buildStatItem(Icons.quiz, 'Questionnaires', '2'),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingReport ? null : _fetchUserReport,
              icon: _isLoadingReport
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.visibility, size: 16),
              label: Text(_isLoadingReport ? 'Loading...' : 'View Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B5B95),
                side: const BorderSide(color: Color(0xFF6B5B95)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  // UPDATED: Enhanced analysis result dialog with all new fields
  void _showAnalysisResult(BuildContext context, Map<String, dynamic> result) {
    final prediction = result['prediction'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 0.0;
    final riskLevel = result['risk_level'] ?? 'Unknown';
    final suggestion = result['suggestion'] ?? '';
    final user = result['user'] ?? {};
    final recommendedDoctors = result['recommended_doctors'] as List? ?? [];

    Color resultColor;
    if (riskLevel.contains('High')) {
      resultColor = Colors.red;
    } else if (riskLevel.contains('Moderate') || riskLevel.contains('Mild')) {
      resultColor = Colors.orange;
    } else {
      resultColor = Colors.green;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with risk level color
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        riskLevel.contains('High') ? Icons.warning :
                        riskLevel.contains('Mild') ? Icons.info :
                        Icons.check_circle,
                        color: resultColor,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      prediction,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      riskLevel,
                      style: TextStyle(
                        fontSize: 16,
                        color: resultColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Body with details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Confidence score
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Confidence Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: resultColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${confidence.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Suggestion
                      if (suggestion.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Color(0xFF6B5B95), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Suggestion',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                suggestion,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Recommended Doctors
                      if (recommendedDoctors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Recommended Specialists',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recommendedDoctors.map((doctor) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B5B95).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  color: Color(0xFF6B5B95),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor['username'] ?? 'Doctor',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor['department'] ?? 'Specialist',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${doctor['experience'] ?? 0} years experience',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF88B0D3).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.phone_in_talk,
                                  color: Color(0xFF88B0D3),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],

                      // User info
                      if (user.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Color(0xFF6B5B95)),
                              const SizedBox(width: 8),
                              Text(
                                'Analysis for: ${user['username'] ?? 'User'}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearVideo();
                        },
                        child: const Text('Upload New'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchUserReport();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5B95),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('View Full Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Enhanced user report dialog with risk levels and suggestions
  void _showUserReportDialog(BuildContext context) {
    if (_userReport == null) return;

    final user = _userReport!['user'] ?? {};
    final answers = _userReport!['answers'] as List? ?? [];
    final detections = _userReport!['detections'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B5B95),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Complete Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.isNotEmpty)
                            Text(
                              user['username'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Overview
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildReportStat('Questions', answers.length.toString()),
                            _buildReportStat('Videos', detections.length.toString()),
                            _buildReportStat('Avg Confidence', _calculateAvgConfidence(detections)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Video Detections Section
                      if (detections.isNotEmpty) ...[
                        const Text(
                          'Video Analysis Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...detections.map((detection) => _buildDetectionCard(detection)).toList(),
                      ],

                      const SizedBox(height: 20),

                      // Questionnaire Answers Section
                      if (answers.isNotEmpty) ...[
                        const Text(
                          'Questionnaire Responses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...answers.map((answer) => _buildAnswerCard(answer)).toList(),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B5B95),
                          side: const BorderSide(color: Color(0xFF6B5B95)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to share or export
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5B95),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Share Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5B95),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // UPDATED: Enhanced detection card with risk level
  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final confidence = detection['confidence'] ?? 0.0;
    final prediction = detection['prediction'] ?? 'Unknown';
    final riskLevel = detection['risk_level'] ?? '';
    final suggestion = detection['suggestion'] ?? '';
    final createdAt = detection['created_at'] ?? '';

    Color confidenceColor;
    if (riskLevel.contains('High')) {
      confidenceColor = Colors.red;
    } else if (riskLevel.contains('Moderate') || riskLevel.contains('Mild')) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5B95).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam, color: Color(0xFF6B5B95), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (riskLevel.isNotEmpty)
                      Text(
                        riskLevel,
                        style: TextStyle(
                          fontSize: 11,
                          color: confidenceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatDate(createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer['question'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF88B0D3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  answer['answer'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF88B0D3),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(answer['created_at'] ?? ''),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateAvgConfidence(List detections) {
    if (detections.isEmpty) return '0%';

    double total = 0;
    for (var d in detections) {
      total += (d['confidence'] ?? 0.0).toDouble();
    }
    double avg = total / detections.length;
    return '${avg.toStringAsFixed(1)}%';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}