import 'dart:convert';
import 'package:http/http.dart' as http;

/// Enrollment Service - Business Logic & Data Management
class EnrollmentService {
  // Points to the folder in XAMPP htdocs
  static const String _baseUrl = "http://localhost/obc_api";

  static final List<Map<String, dynamic>> enrolledStudents = [];

  // --- EMAIL VALIDATION ---
  static bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  // --- LOGIN LOGIC ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    String emailInput = email.trim().toLowerCase();
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/login.php"),
            body: {"email": emailInput, "password": password},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "success": data['status'] == "success",
          "message": data['message'],
        };
      }
      return {
        "success": false,
        "message": "Server Error: ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Check XAMPP connection: $e"};
    }
  }

  // --- REGISTRATION LOGIC ---
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
    String emailInput = email.trim().toLowerCase();
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/register.php"),
            body: {"email": emailInput, "password": password},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "success": data['status'] == "success",
          "message": data['message'],
        };
      }
      return {"success": false, "message": "Registration failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // --- DELETE ACCOUNT LOGIC ---
  static Future<Map<String, dynamic>> deleteAccount(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/delete_account.php"),
        body: {"email": email},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "success": data['status'] == "success",
          "message": data['message'],
        };
      }
      return {"success": false, "message": "Failed to delete"};
    } catch (e) {
      return {"success": false, "message": "Error deleting: $e"};
    }
  }

  // --- CHANGE PASSWORD LOGIC (ADD THIS PART HERE) ---
  static Future<Map<String, dynamic>> changePassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/change_password.php"),
            body: {
              "email": email.trim().toLowerCase(),
              "new_password": newPassword,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "success": data['status'] == "success",
          "message": data['message'],
        };
      }
      return {"success": false, "message": "Failed to update password"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // --- FORM VALIDATION ---
  static FormValidationResult validateEnrollmentForm({
    required String studentName,
    required String studentAge,
    required String studentContact,
    required String studentBirthday,
    required String guardianName,
    required String guardianContact,
    required String guardianBirthday,
  }) {
    if (studentName.isEmpty || studentAge.isEmpty) {
      return FormValidationResult(valid: false, message: "Name/Age required");
    }
    if (studentContact.length != 11) {
      return FormValidationResult(
        valid: false,
        message: "Contact must be 11 digits",
      );
    }
    return FormValidationResult(valid: true, message: "Valid");
  }

  // --- ENROLLMENT SUBMISSION ---
  static EnrollmentResult submitEnrollment({
    required String studentType,
    required String studentName,
    required String studentAge,
    required String studentBirthday,
    required String studentAddress,
    required String studentContact,
    required String guardianName,
    required String guardianBirthday,
    required String guardianContact,
    required String guardianAddress,
    String? studentId,
  }) {
    final enrollment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentName': studentName,
      'studentType': studentType,
      'studentAge': studentAge,
      'studentAddress': studentAddress,
      'studentId': studentId ?? 'AUTO-${DateTime.now().day}',
      'submittedAt': DateTime.now().toIso8601String(),
    };
    enrolledStudents.add(enrollment);
    return EnrollmentResult(
      success: true,
      message: "Success",
      enrollmentData: enrollment,
    );
  }

  static Map<String, dynamic>? getLastEnrollment() =>
      enrolledStudents.isEmpty ? null : enrolledStudents.last;
}

// --- RESULT CLASSES (Defined ONLY ONCE at the bottom) ---

class FormValidationResult {
  final bool valid;
  final String message;
  FormValidationResult({required this.valid, required this.message});
}

class EnrollmentResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? enrollmentData;
  EnrollmentResult({
    required this.success,
    required this.message,
    this.enrollmentData,
  });
}
