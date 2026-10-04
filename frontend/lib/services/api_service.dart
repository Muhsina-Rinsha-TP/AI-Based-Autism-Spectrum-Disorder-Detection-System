import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:autism_project/services/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ApiService class with all methods
class ApiService {
  static const String baseUrl = 'http://192.168.1.31:8000/api';

  static const String userRegisterEndpoint = '$baseUrl/user-register/';
  static const String doctorRegisterEndpoint = '$baseUrl/doctor-register/';
  static const String loginEndpoint = '$baseUrl/login/';
  static const String logoutEndpoint = '$baseUrl/logout/';
  static const String questionsEndpoint = '$baseUrl/questions/';
  static const String submitAnswersEndpoint = '$baseUrl/submit-answers/';
  static const String detectAutismEndpoint = '$baseUrl/detect-autism/';
  static const String userReportEndpoint = '$baseUrl/user-report/';
  static const String doctorUsersReportEndpoint = '$baseUrl/doctor/users-report/';
  static const String createSlotEndpoint = '$baseUrl/doctor/create-slot/';
  static const String createdoctorslotEndpoint = '$baseUrl/doctor/slots/';
  static const String doctorListEndpoint = '$baseUrl/doctor/list/';
  static const String bookAppointmentEndpoint = '$baseUrl/appointment/book/';
  static const String docseeAppointmentEndpoint = '$baseUrl/doctor/appointments';
  static const String userseeAppointmentEndpoint = '$baseUrl/user/appointments/';
  static const String chatbotEndpoint = '$baseUrl/chatbot/';


  //*********************************************************************************************************
  // User Registration
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('🚀 Making request to: $userRegisterEndpoint');

      final requestBody = {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(userRegisterEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRFToken': 'nocsrftoken',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check if the server is running',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Doctor Registration
  static Future<Map<String, dynamic>> registerDoctor({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String department,
    required int experienceYears,
  }) async {
    try {
      print('🚀 Making request to: $doctorRegisterEndpoint');

      final requestBody = {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'department': department,
        'experience_years': experienceYears,
      };

      final response = await http.post(
        Uri.parse(doctorRegisterEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRFToken': 'nocsrftoken',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check if the server is running',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 Making request to: $loginEndpoint');

      final requestBody = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRFToken': 'nocsrftoken',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check if the server is running',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('🚀 Making request to: $logoutEndpoint');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      final response = await http.post(
        Uri.parse(logoutEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token != null ? 'Token $token' : '',
          'X-CSRFToken': 'nocsrftoken',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Logout response status code: ${response.statusCode}');
      print('📥 Logout response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Logout network error: $e');
      // Return success even if network error to allow local logout
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  //*********************************************************************************************************

  // Fetch Questions
  static Future<Map<String, dynamic>> fetchQuestions() async {
    try {
      print('🚀 Fetching questions from: $questionsEndpoint');

      // Get token for authorization
      final token = await TokenStorageService.getToken();
      print('🔑 Token: $token');

      final response = await http.get(
        Uri.parse(questionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token != null ? 'Token $token' : '',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Questions response status: ${response.statusCode}');
      print('📥 Questions response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true &&
            jsonResponse.containsKey('data')) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load questions. Status code: ${response
              .statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching questions: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Submit Answers
  static Future<Map<String, dynamic>> submitAnswers({
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      print('🚀 Submitting answers to: $submitAnswersEndpoint');
      print('📤 Request body: $answers');

      // Get token for authorization
      final token = await TokenStorageService.getToken();

      final response = await http.post(
        Uri.parse(submitAnswersEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token != null ? 'Token $token' : '',
        },
        body: json.encode({'answers': answers}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Submit response status: ${response.statusCode}');
      print('📥 Submit response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'data': jsonResponse,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = 'Failed to submit answers';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? errorResponse['error'] ??
              errorMessage;
        } catch (_) {}

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error submitting answers: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // VIDEO UPLOAD METHOD WITH TOKEN
  static Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
  }) async {
    try {
      print('🚀 Uploading video to: $detectAutismEndpoint');

      // GET TOKEN FROM STORAGE
      final token = await TokenStorageService.getToken();

      // CHECK IF TOKEN EXISTS
      if (token == null) {
        print('❌ No token found! User not authenticated.');
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
        };
      }

      print('✅ Token retrieved successfully');
      print('🔑 Token: $token'); // Be careful with this in production

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(detectAutismEndpoint),
      );

      // ADD TOKEN TO HEADERS
      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });

      print('📤 Request headers with token added');

      // Add video file
      final fileStream = http.MultipartFile(
        'video',
        videoFile.openRead(),
        await videoFile.length(),
        filename: videoFile.path
            .split('/')
            .last,
        contentType: MediaType('video', _getVideoExtension(videoFile.path)),
      );

      request.files.add(fileStream);

      print('📤 Video file added: ${videoFile.path}');
      print('📤 File size: ${await videoFile.length()} bytes');

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
          'user': responseData['user'],
          'prediction': responseData['prediction'],
          'confidence': responseData['confidence'],
          'risk_level': responseData['risk_level'],
          'suggestion': responseData['suggestion'],
          'recommended_doctors': responseData['recommended_doctors'],
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
        String errorMessage = 'Upload failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Server error';
        } catch (_) {}

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Video upload error: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Helper method to get video extension
  static String _getVideoExtension(String filePath) {
    final extension = filePath
        .split('.')
        .last
        .toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'mp4';
      case 'mov':
        return 'quicktime';
      case 'avi':
        return 'x-msvideo';
      case 'mkv':
        return 'x-matroska';
      default:
        return 'mp4';
    }
  }

  // Validate video file
  static Map<String, dynamic> validateVideoFile(File videoFile) {
    final String fileName = videoFile.path
        .split('/')
        .last;
    final String extension = fileName
        .split('.')
        .last
        .toLowerCase();
    final int fileSize = videoFile.lengthSync();

    // Check supported formats
    final supportedFormats = ['mp4', 'mov', 'avi', 'mkv'];
    if (!supportedFormats.contains(extension)) {
      return {
        'valid': false,
        'error': 'Unsupported format. Please use MP4, MOV, AVI, or MKV',
      };
    }

    // Check file size (100MB max)
    if (fileSize > 100 * 1024 * 1024) {
      return {
        'valid': false,
        'error': 'File too large. Maximum size is 100MB',
      };
    }

    return {
      'valid': true,
      'fileName': fileName,
      'fileSize': fileSize,
      'extension': extension,
    };
  }

  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> responseData;
    try {
      responseData = json.decode(response.body);
    } catch (e) {
      responseData = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Success',
        'data': responseData,
        'statusCode': response.statusCode,
      };
    } else {
      String errorMessage = _parseDjangoError(responseData);
      return {
        'success': false,
        'error': errorMessage,
        'data': responseData,
        'statusCode': response.statusCode,
      };
    }
  }

  static String _parseDjangoError(Map<String, dynamic> responseData) {
    try {
      if (responseData.containsKey('username')) {
        final usernameError = responseData['username'];
        if (usernameError is List && usernameError.isNotEmpty) {
          return 'Username: ${usernameError[0]}';
        }
        return 'Username: $usernameError';
      }

      if (responseData.containsKey('email')) {
        final emailError = responseData['email'];
        if (emailError is List && emailError.isNotEmpty) {
          return 'Email: ${emailError[0]}';
        }
        return 'Email: $emailError';
      }

      if (responseData.containsKey('phone')) {
        final phoneError = responseData['phone'];
        if (phoneError is List && phoneError.isNotEmpty) {
          return 'Phone: ${phoneError[0]}';
        }
        return 'Phone: $phoneError';
      }

      if (responseData.containsKey('password')) {
        final passwordError = responseData['password'];
        if (passwordError is List && passwordError.isNotEmpty) {
          return 'Password: ${passwordError[0]}';
        }
        return 'Password: $passwordError';
      }

      if (responseData.containsKey('non_field_errors')) {
        final nonFieldErrors = responseData['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          return nonFieldErrors[0].toString();
        }
      }

      if (responseData.containsKey('message')) {
        return responseData['message'].toString();
      }

      if (responseData.containsKey('error')) {
        return responseData['error'].toString();
      }

      if (responseData.containsKey('detail')) {
        return responseData['detail'].toString();
      }

      if (responseData.values.isNotEmpty) {
        final firstValue = responseData.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue[0].toString();
        }
        return firstValue.toString();
      }

      return responseData.toString();
    } catch (e) {
      return 'Operation failed. Please try again.';
    }
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  //*********************************************************************************************************

  // Get user report
  static Future<Map<String, dynamic>> getUserReport() async {
    try {
      print('🚀 Fetching user report from: $userReportEndpoint');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse(userReportEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 User report response status: ${response.statusCode}');
      print('📥 User report response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true &&
            jsonResponse.containsKey('data')) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load report. Status code: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching user report: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  //*********************************************************************************************************

  // Get doctor users report
  static Future<Map<String, dynamic>> getDoctorUsersReport() async {
    try {
      print('🚀 Fetching doctor users report from: $doctorUsersReportEndpoint');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse(doctorUsersReportEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Doctor users report response status: ${response.statusCode}');
      print('📥 Doctor users report response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true &&
            jsonResponse.containsKey('data')) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'total_users': jsonResponse['total_users'] ?? 0,
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load users report. Status code: ${response
              .statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching doctor users report: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

  //****************************************************************************************************************************

  // CREATE SLOT METHOD FOR DOCTOR - UPDATED WITH DEBUG LOGS
  static Future<Map<String, dynamic>> createSlotBulk(
      List<Map<String, String>> slots) async {
    try {
      print('🚀 Creating bulk slots at: $createSlotEndpoint');
      print('📤 Slots data to send: ${json.encode(slots)}');

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

      print('✅ Token found: ${token.substring(
          0, token.length > 10 ? 10 : token.length)}...');

      final requestBody = {
        'slots': slots,
      };

      final requestJson = json.encode(requestBody);
      print('📤 Request body: $requestJson');

      final response = await http.post(
        Uri.parse(createSlotEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
          'X-CSRFToken': 'nocsrftoken',
        },
        body: requestJson,
      ).timeout(const Duration(seconds: 30));

      print('📥 Create bulk slots response status: ${response.statusCode}');
      print('📥 Create bulk slots response headers: ${response.headers}');
      print('📥 Create bulk slots response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('✅ Slots created successfully!');
        print('📥 Parsed response: $jsonResponse');

        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Slots created successfully',
          'created_count': jsonResponse['created_count'] ?? 0,
          'skipped_count': jsonResponse['skipped_count'] ?? 0,
          'data': jsonResponse,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token expired');
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = 'Failed to create slots';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          errorMessage = errorResponse['error'] ??
              errorResponse['message'] ??
              errorResponse['detail'] ??
              'Server error (${response.statusCode})';
          print('❌ Server error: $errorMessage');
        } catch (_) {
          print('❌ Could not parse error response');
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } catch (e) {
      print('❌ Create bulk slots error: $e');
      if (e is http.ClientException) {
        print('❌ ClientException - Check your internet connection');
      } else if (e is TimeoutException) {
        print('❌ TimeoutException - Server took too long to respond');
      }
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//*********************************************************************************************
// Add this method to your ApiService class (after the createSlotBulk method)
//*********************************************************************************************
// GET DOCTOR SLOTS - NEW METHOD
  static Future<Map<String, dynamic>> getDoctorSlots() async {
    try {
      print('🚀 Fetching doctor slots from: $baseUrl/doctor/slots/');

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

      print('✅ Token found: ${token.substring(
          0, token.length > 10 ? 10 : token.length)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/doctor/slots/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Get slots response status: ${response.statusCode}');
      print('📥 Get slots response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'] ?? [],
            'total_slots': jsonResponse['total_slots'] ?? 0,
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load slots. Status code: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching doctor slots: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//*********************************************************************************************

//*********************************************************************************************
  static Future<Map<String, dynamic>> getDoctorList() async {
    try {
      print('🚀 Fetching doctor list from: $doctorListEndpoint');

      // Get token from storage (optional - if authentication is required)
      final token = await TokenStorageService.getToken();

      final response = await http.get(
        Uri.parse(doctorListEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Doctor list response status: ${response.statusCode}');
      print('📥 Doctor list response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true &&
            jsonResponse.containsKey('data')) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load doctors. Status code: ${response
              .statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching doctor list: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//*********************************************************************************************
// NEW METHOD: BOOK APPOINTMENT
//*********************************************************************************************
  static Future<Map<String, dynamic>> bookAppointment({
    required int slotId,
  }) async {
    try {
      print('🚀 Booking appointment at: $bookAppointmentEndpoint');
      print('📤 Slot ID: $slotId');

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

      print('✅ Token found: ${token.substring(
          0, token.length > 10 ? 10 : token.length)}...');

      final requestBody = {
        'slot_id': slotId,
      };

      final requestJson = json.encode(requestBody);
      print('📤 Request body: $requestJson');

      final response = await http.post(
        Uri.parse(bookAppointmentEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
          'X-CSRFToken': 'nocsrftoken',
        },
        body: requestJson,
      ).timeout(const Duration(seconds: 30));

      print('📥 Book appointment response status: ${response.statusCode}');
      print('📥 Book appointment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('✅ Appointment booked successfully!');
        print('📥 Parsed response: $jsonResponse');

        return {
          'success': true,
          'message': jsonResponse['message'] ??
              'Appointment booked successfully',
          'status': jsonResponse['status'],
          'data': jsonResponse,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token expired');
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = 'Failed to book appointment';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          errorMessage = errorResponse['error'] ??
              errorResponse['message'] ??
              errorResponse['detail'] ??
              'Server error (${response.statusCode})';
          print('❌ Server error: $errorMessage');
        } catch (_) {
          print('❌ Could not parse error response');
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } catch (e) {
      print('❌ Book appointment error: $e');
      if (e is http.ClientException) {
        print('❌ ClientException - Check your internet connection');
      } else if (e is TimeoutException) {
        print('❌ TimeoutException - Server took too long to respond');
      }
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//*********************************************************************************************
// NEW METHOD: GET DOCTOR APPOINTMENTS
//*********************************************************************************************
  static Future<Map<String, dynamic>> getDoctorAppointments() async {
    try {
      print(
          '🚀 Fetching doctor appointments from: $baseUrl/doctor/appointments/');

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

      print('✅ Token found: ${token.substring(
          0, token.length > 10 ? 10 : token.length)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/doctor/appointments/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Get appointments response status: ${response.statusCode}');
      print('📥 Get appointments response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'] ?? [],
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load appointments. Status code: ${response
              .statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching doctor appointments: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//************************************************************************************************************

// Add this method to your ApiService class
  static Future<Map<String, dynamic>> getUserAppointments() async {
    try {
      print('🚀 Fetching user appointments from: $baseUrl/user/appointments/');

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

      print('✅ Token found: ${token.substring(
          0, token.length > 10 ? 10 : token.length)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/user/appointments/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Get user appointments response status: ${response.statusCode}');
      print('📥 Get user appointments response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'] ?? [],
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load appointments. Status code: ${response
              .statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching user appointments: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
      };
    }
  }

//***********************************************************************************************************************


// CHATBOT API METHODS
//*********************************************************************************************************
// In your ApiService class, make sure these methods are correct:

//*********************************************************************************************************
// CHATBOT API METHODS - WITH PROPER TOKEN AUTHENTICATION
//*********************************************************************************************************
// In your ApiService class, make sure these methods are correct:

//*********************************************************************************************************
// CHATBOT API METHODS - WITH PROPER TOKEN AUTHENTICATION
//*********************************************************************************************************

// GET chatbot info
  static Future<Map<String, dynamic>> getChatbotInfo() async {
    try {
      print('🚀 Fetching chatbot info from: $chatbotEndpoint');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      // Check if token exists
      if (token == null) {
        print('❌ No token found! User not authenticated.');
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
          'statusCode': 401,
        };
      }

      final response = await http.get(
        Uri.parse(chatbotEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Chatbot info response status: ${response.statusCode}');
      print('📥 Chatbot info response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'data': jsonResponse,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load chatbot info. Status code: ${response.statusCode}',
          'statusCode': response.statusCode,
          'data': response.statusCode == 401 ? {'detail': 'Authentication failed'} : null,
        };
      }
    } catch (e) {
      print('❌ Error fetching chatbot info: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
        'statusCode': 500,
      };
    }
  }

// POST message to chatbot
  static Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
  }) async {
    try {
      print('🚀 Sending message to chatbot at: $chatbotEndpoint');
      print('📤 Message: $message');

      // Get token from storage
      final token = await TokenStorageService.getToken();

      // Check if token exists
      if (token == null) {
        print('❌ No token found! User not authenticated.');
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
          'statusCode': 401,
        };
      }

      final requestBody = {
        'message': message,
      };

      final response = await http.post(
        Uri.parse(chatbotEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📥 Chatbot response status: ${response.statusCode}');
      print('📥 Chatbot response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'data': jsonResponse,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = 'Failed to get response from chatbot';
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          errorMessage = errorResponse['error'] ??
              errorResponse['message'] ??
              errorResponse['detail'] ??
              'Server error (${response.statusCode})';
        } catch (_) {}

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error sending message to chatbot: $e');
      return {
        'success': false,
        'error': 'Connection failed. Please check your internet connection.',
        'details': e.toString(),
        'statusCode': 500,
      };
    }
  }


}