// chatbot_page.dart - FINAL FIXED VERSION (No keyboard blinking/hiding)

import 'dart:async';
import 'package:autism_project/services/api_service.dart';
import 'package:autism_project/services/token_storage.dart';
import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;
  bool _isSending = false;
  List<String> _suggestedQuestions = [];
  bool _isAuthenticated = true;

  @override
  void initState() {
    super.initState();

    // Add listener to controller to rebuild when text changes
    _messageController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to update send button state
      }
    });

    _checkAuthAndInitialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndInitialize() async {
    final token = await TokenStorageService.getToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _isAuthenticated = false;
        _addMessage("Please login to use the chatbot assistant.", false, true);
      });
      return;
    }
    _initializeChatbot();
  }

  void _addMessage(String text, bool isUser, [bool isError = false]) {
    _messages.add({
      'text': text,
      'isUser': isUser,
      'time': DateTime.now(),
      'isError': isError,
    });
  }

  Future<void> _initializeChatbot() async {
    setState(() => _isLoading = true);

    try {
      _addMessage("Hello! I'm your Autism Detection Assistant. How can I help you today?", false);

      final response = await ApiService.getChatbotInfo();
      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data['available_questions'] != null) {
          setState(() {
            _suggestedQuestions = List<String>.from(data['available_questions']);
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _scrollToBottom();
  }

  String _formatDoctorsList(List doctors) {
    if (doctors.isEmpty) return '';

    StringBuffer formattedDoctors = StringBuffer();
    formattedDoctors.writeln('📋 **AVAILABLE DOCTORS**');
    formattedDoctors.writeln('═' * 35);

    for (int i = 0; i < doctors.length; i++) {
      var doctor = doctors[i];
      formattedDoctors.writeln('\n${i + 1}. 👨‍⚕️ **${doctor['doctor_name']}**');
      formattedDoctors.writeln('   🏥 Department: ${doctor['department']}');
      formattedDoctors.writeln('   ⭐ Experience: ${doctor['experience']} years');

      // Add additional fields if available
      if (doctor['qualification'] != null && doctor['qualification'].toString().isNotEmpty) {
        formattedDoctors.writeln('   🎓 Qualification: ${doctor['qualification']}');
      }
      if (doctor['fee'] != null && doctor['fee'].toString().isNotEmpty) {
        formattedDoctors.writeln('   💰 Consultation Fee: ${doctor['fee']}');
      }
      if (doctor['availability'] != null && doctor['availability'].toString().isNotEmpty) {
        formattedDoctors.writeln('   📅 Availability: ${doctor['availability']}');
      }

      if (i < doctors.length - 1) {
        formattedDoctors.writeln('   ' + '─' * 30);
      }
    }

    formattedDoctors.writeln('\n' + '═' * 35);

    return formattedDoctors.toString();
  }

  String _formatSlotsList(List slots) {
    if (slots.isEmpty) return '';

    StringBuffer formattedSlots = StringBuffer();
    formattedSlots.writeln('📅 **AVAILABLE APPOINTMENT SLOTS**');
    formattedSlots.writeln('═' * 40);

    // Group slots by doctor
    Map<String, List<Map<String, dynamic>>> slotsByDoctor = {};
    for (var slot in slots) {
      String doctorName = slot['doctor_name'] ?? 'Unknown Doctor';
      if (!slotsByDoctor.containsKey(doctorName)) {
        slotsByDoctor[doctorName] = [];
      }
      slotsByDoctor[doctorName]!.add(slot);
    }

    int slotNumber = 1;
    slotsByDoctor.forEach((doctorName, doctorSlots) {
      // Get department from first slot
      String department = doctorSlots.first['department'] ?? 'Department not specified';

      formattedSlots.writeln('\n👨‍⚕️ **$doctorName**');
      formattedSlots.writeln('   🏥 $department');
      formattedSlots.writeln('   ' + '─' * 35);

      // Sort slots by date (assuming date format YYYY-MM-DD)
      doctorSlots.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date'] ?? '2000-01-01');
        DateTime dateB = DateTime.parse(b['date'] ?? '2000-01-01');
        return dateA.compareTo(dateB);
      });

      for (var slot in doctorSlots) {
        String date = slot['date'] ?? 'Date not specified';
        String time = slot['start_time'] ?? 'Time not specified';

        // Format date to be more readable (e.g., "March 13, 2026")
        try {
          DateTime dateTime = DateTime.parse(date);
          date = _formatDate(dateTime);
        } catch (e) {
          // Keep original date if parsing fails
        }

        formattedSlots.writeln('\n   ${slotNumber++}. 🗓️ **$date**');
        formattedSlots.writeln('      🕐 at $time');

        if (slot['duration'] != null) {
          formattedSlots.writeln('      ⏱️ Duration: ${slot['duration']} min');
        }
        if (slot['type'] != null) {
          formattedSlots.writeln('      📋 Type: ${slot['type']}');
        }
      }
      formattedSlots.writeln('   ' + '─' * 35);
    });

    formattedSlots.writeln('\n' + '═' * 40);
    formattedSlots.writeln('💡 To book a slot, please type "Book appointment with [doctor name]"');

    return formattedSlots.toString();
  }

  String _formatDate(DateTime dateTime) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending || !_isAuthenticated) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _addMessage(userMessage, true);
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await ApiService.sendChatbotMessage(message: userMessage);
      if (!mounted) return;

      setState(() => _isSending = false);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Extract bot response based on your API structure
        String botResponse = '';
        if (data['bot_response'] != null) {
          if (data['bot_response']['message'] != null) {
            botResponse = data['bot_response']['message'].toString();
          }

          // Update suggested questions if options are returned
          if (data['bot_response']['options'] != null) {
            setState(() {
              _suggestedQuestions = List<String>.from(data['bot_response']['options']);
            });
          }

          // Handle doctors list with proper formatting
          if (data['bot_response']['doctors'] != null) {
            final doctors = data['bot_response']['doctors'] as List;
            if (doctors.isNotEmpty) {
              // If there's already a message, add a separator
              if (botResponse.isNotEmpty) {
                botResponse += '\n\n';
              }
              botResponse += _formatDoctorsList(doctors);
            }
          }

          // Handle slots display with proper formatting
          if (data['bot_response']['slots'] != null) {
            final slots = data['bot_response']['slots'] as List;
            if (slots.isNotEmpty) {
              // If there's already a message, add a separator
              if (botResponse.isNotEmpty) {
                botResponse += '\n\n';
              }
              botResponse += _formatSlotsList(slots);
            }
          }
        } else {
          botResponse = data['message'] ?? "I received your message.";
        }

        _addMessage(botResponse, false);
      } else {
        _addMessage("Sorry, I'm having trouble connecting.", false, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
      }
      _addMessage("Network error. Please check your connection.", false, true);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper method to determine if send button should be enabled
  bool get _canSendMessage {
    return _isAuthenticated &&
        _messageController.text.trim().isNotEmpty &&
        !_isSending;
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF6B5B95);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: Icon(Icons.refresh, color: themeColor),
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _isLoading = true;
                });
                _initializeChatbot();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: themeColor))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, themeColor);
              },
            ),
          ),

          // Suggested questions - now always visible when available
          if (_isAuthenticated &&
              _suggestedQuestions.isNotEmpty &&
              !_isSending)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _messageController.text = _suggestedQuestions[index];
                      _sendMessage();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          _suggestedQuestions[index],
                          style: TextStyle(color: themeColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Typing indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Assistant is typing...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: _isAuthenticated ? 'Type a message...' : 'Please login',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isAuthenticated,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _canSendMessage ? themeColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _canSendMessage ? Colors.white : Colors.grey[600],
                    ),
                    onPressed: _canSendMessage ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, Color themeColor) {
    final isUser = msg['isUser'] as bool;
    final text = msg['text'] as String;
    final isError = msg['isError'] as bool? ?? false;

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? themeColor : (isError ? themeColor.withOpacity(0.1) : Colors.white),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : (isError ? themeColor : Colors.black87),
                      height: 1.3,
                      fontWeight: text.contains('**') ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg['time'] as DateTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}