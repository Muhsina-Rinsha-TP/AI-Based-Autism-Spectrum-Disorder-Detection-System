import 'package:flutter/material.dart';
import 'package:autism_project/services/api_service.dart';
import 'package:autism_project/services/token_storage.dart';
import 'package:autism_project/screens/login_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestion = 0;
  final Map<int, Map<String, dynamic>> _answers = {};
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isAuthError = false;
  Map<String, dynamic>? _resultData;

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchQuestions();
  }

  Future<void> _checkAuthAndFetchQuestions() async {
    final isLoggedIn = await TokenStorageService.isLoggedIn();
    if (!isLoggedIn) {
      setState(() {
        _isAuthError = true;
        _errorMessage = 'Please login to access the questionnaire';
        _isLoading = false;
      });
      return;
    }
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAuthError = false;
    });

    print('📱 Fetching questions from screen...');
    final result = await ApiService.fetchQuestions();
    print('📱 Fetch result: $result');

    if (result['success']) {
      final questionsData = result['data'];

      if (questionsData is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(questionsData);
          _isLoading = false;
        });
        print('📱 Loaded ${_questions.length} questions successfully');
      } else {
        setState(() {
          _errorMessage = 'Invalid data format received';
          _isLoading = false;
        });
      }
    } else {
      // Check if it's an authentication error
      if (result['statusCode'] == 401) {
        setState(() {
          _isAuthError = true;
          _errorMessage = result['error'] ?? 'Authentication failed. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load questions';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAnswers() async {
    setState(() {
      _isSubmitting = true;
    });

    // Prepare answers in the required format
    final List<Map<String, dynamic>> answers = _answers.values.map((answer) {
      return {
        'question_id': answer['question_id'],
        'option_id': answer['option_id'],
      };
    }).toList();

    final result = await ApiService.submitAnswers(answers: answers);

    setState(() {
      _isSubmitting = false;
    });

    if (result['success']) {
      setState(() {
        _isCompleted = true;
        _resultData = result['data'];
      });
    } else {
      // Show error dialog
      _showErrorDialog(result['error'] ?? 'Failed to submit answers');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _resetQuestionnaire() {
    setState(() {
      _isCompleted = false;
      _currentQuestion = 0;
      _answers.clear();
      _resultData = null;
    });
    _fetchQuestions();
  }

  // Calculate risk score based on answers
  double _calculateRiskScore() {
    if (_answers.isEmpty) return 0.0;

    int totalScore = 0;
    _answers.forEach((index, answer) {
      // Simple scoring based on option_id
      // You can customize this logic based on your requirements
      // totalScore += answer['option_id'] % 4 + 1;
    });

    return (totalScore / (_answers.length * 4)) * 100;
  }

  String _getRiskLevel(double score) {
    if (score < 30) {
      return 'Low Risk';
    } else if (score < 60) {
      return 'Moderate Risk';
    } else {
      return 'High Risk';
    }
  }

  Color _getRiskColor(double score) {
    if (score < 30) {
      return Colors.green;
    } else if (score < 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return 'Your child shows typical developmental patterns. Continue to monitor and provide a supportive environment.';
      case 'Moderate Risk':
        return 'Some developmental differences observed. Consider consulting a specialist for a comprehensive evaluation.';
      case 'High Risk':
        return 'Significant developmental concerns detected. We strongly recommend seeking professional evaluation and support.';
      default:
        return 'Based on your responses, we recommend consulting with a healthcare professional.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    final isLargeScreen = screenSize.width >= 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
        title: Text(
          'Developmental Questionnaire',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingScreen(isSmallScreen)
            : _errorMessage != null
            ? _buildErrorScreen(isSmallScreen)
            : _isCompleted
            ? _buildResultsScreen(isSmallScreen, isMediumScreen, isLargeScreen)
            : _buildQuestionnaireScreen(isSmallScreen, isMediumScreen, isLargeScreen),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5B95)),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading questions...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAuthError ? Icons.lock_outline : Icons.error_outline,
              size: isSmallScreen ? 60 : 80,
              color: _isAuthError ? Colors.orange.shade300 : Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              _isAuthError ? 'Authentication Required' : 'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Failed to load questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            if (_isAuthError)
              ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5B95),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 30 : 40,
                    vertical: isSmallScreen ? 12 : 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _fetchQuestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 30 : 40,
                        vertical: isSmallScreen ? 12 : 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireScreen(bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : (isMediumScreen ? 24 : 32)),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Developmental Questionnaire',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Answer these questions about your child\'s behavior',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B5B95)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of ${_questions.length}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5B95).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${((_currentQuestion + 1) / _questions.length * 100).toInt()}% Complete',
                      style: TextStyle(
                        color: const Color(0xFF6B5B95),
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Question Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B5B95).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${_currentQuestion + 1}',
                        style: TextStyle(
                          color: const Color(0xFF6B5B95),
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _questions[_currentQuestion]['text'],
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Options
                    ...(_questions[_currentQuestion]['options'] as List).map((option) {
                      final optionMap = option as Map<String, dynamic>;
                      final isSelected = _answers[_currentQuestion]?['option_id'] == optionMap['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _answers[_currentQuestion] = {
                              'question_id': _questions[_currentQuestion]['id'],
                              'option_id': optionMap['id'],
                              'option_text': optionMap['text'],
                            };
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6B5B95).withOpacity(0.1)
                                : Colors.grey.shade50,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6B5B95)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFF6B5B95)
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionMap['text'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF6B5B95)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestion--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B5B95),
                          side: const BorderSide(color: Color(0xFF6B5B95)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 15,
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestion > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _isSubmitting
                        ? Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B5B95).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                        : ElevatedButton(
                      onPressed: _answers[_currentQuestion] == null
                          ? null
                          : () {
                        if (_currentQuestion == _questions.length - 1) {
                          _submitAnswers();
                        } else {
                          setState(() {
                            _currentQuestion++;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5B95),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 15,
                        ),
                      ),
                      child: Text(
                        _currentQuestion == _questions.length - 1
                            ? 'Submit'
                            : 'Next',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Progress dots for mobile
              if (isSmallScreen && _questions.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _questions.length,
                          (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentQuestion
                              ? const Color(0xFF6B5B95)
                              : _answers.containsKey(index)
                              ? const Color(0xFF6B5B95).withOpacity(0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen(bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    final double riskScore = _calculateRiskScore();
    final String riskLevel = _getRiskLevel(riskScore);
    final Color riskColor = _getRiskColor(riskScore);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : (isMediumScreen ? 24 : 32)),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 600 : double.infinity,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5 * value,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: riskColor,
                        size: isSmallScreen ? 60 : 80,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                'Questionnaire Completed!',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Based on your responses, we\'ve calculated a risk assessment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),

              // Risk Score Card
              // Container(
              //   width: double.infinity,
              //   padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(20),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.grey.withOpacity(0.1),
              //         blurRadius: 10,
              //         offset: const Offset(0, 5),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     children: [
              //       const Text(
              //         'Risk Assessment Score',
              //         style: TextStyle(
              //           fontSize: 16,
              //           color: Colors.grey,
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       Text(
              //         '${riskScore.toStringAsFixed(1)}%',
              //         style: TextStyle(
              //           fontSize: isSmallScreen ? 40 : 48,
              //           fontWeight: FontWeight.bold,
              //           color: riskColor,
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(10),
              //         child: LinearProgressIndicator(
              //           value: riskScore / 100,
              //           backgroundColor: Colors.grey.shade200,
              //           valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              //           minHeight: 10,
              //         ),
              //       ),
              //       const SizedBox(height: 20),
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 20,
              //           vertical: 8,
              //         ),
              //         decoration: BoxDecoration(
              //           color: riskColor.withOpacity(0.1),
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         child: Text(
              //           riskLevel,
              //           style: TextStyle(
              //             fontSize: isSmallScreen ? 14 : 16,
              //             fontWeight: FontWeight.w600,
              //             color: riskColor,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 20),
              //       Text(
              //         _getRiskDescription(riskLevel),
              //         textAlign: TextAlign.center,
              //         style: TextStyle(
              //           color: Colors.grey.shade600,
              //           fontSize: isSmallScreen ? 14 : 16,
              //         ),
              //       ),
              //
              //       if (!isSmallScreen) ...[
              //         const SizedBox(height: 20),
              //         const Divider(),
              //         const SizedBox(height: 10),
              //         const Text(
              //           'Your Responses',
              //           style: TextStyle(
              //             fontSize: 16,
              //             fontWeight: FontWeight.bold,
              //             color: Color(0xFF2C3E50),
              //           ),
              //         ),
              //         const SizedBox(height: 10),
              //         ..._answers.entries.map((entry) {
              //           final question = _questions[entry.key];
              //           final answer = entry.value;
              //           return Padding(
              //             padding: const EdgeInsets.only(bottom: 8),
              //             child: Row(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Container(
              //                   width: 24,
              //                   height: 24,
              //                   decoration: BoxDecoration(
              //                     color: const Color(0xFF6B5B95).withOpacity(0.1),
              //                     shape: BoxShape.circle,
              //                   ),
              //                   child: Center(
              //                     child: Text(
              //                       '${entry.key + 1}',
              //                       style: const TextStyle(
              //                         fontSize: 12,
              //                         fontWeight: FontWeight.bold,
              //                         color: Color(0xFF6B5B95),
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //                 const SizedBox(width: 12),
              //                 Expanded(
              //                   child: Column(
              //                     crossAxisAlignment: CrossAxisAlignment.start,
              //                     children: [
              //                       Text(
              //                         question['text'],
              //                         style: const TextStyle(
              //                           fontSize: 14,
              //                           fontWeight: FontWeight.w500,
              //                         ),
              //                         maxLines: 2,
              //                         overflow: TextOverflow.ellipsis,
              //                       ),
              //                       Text(
              //                         'Answer: ${answer['option_text']}',
              //                         style: TextStyle(
              //                           fontSize: 12,
              //                           color: Colors.grey.shade600,
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           );
              //         }).toList(),
              //       ],
              //     ],
              //   ),
              // ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetQuestionnaire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5B95),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Take Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Find Specialists - Coming Soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B5B95),
                        side: const BorderSide(color: Color(0xFF6B5B95)),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Find Specialists'),
                    ),
                  ),
                ],
              ),

              if (isLargeScreen) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download Report - Coming Soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, color: Color(0xFF6B5B95)),
                  label: const Text(
                    'Download Report',
                    style: TextStyle(color: Color(0xFF6B5B95)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}