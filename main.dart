import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/enrollment_service.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SimpleEnrollmentApp(),
    ),
  );
}

class SimpleEnrollmentApp extends StatefulWidget {
  const SimpleEnrollmentApp({super.key});

  @override
  State<SimpleEnrollmentApp> createState() => _SimpleEnrollmentAppState();
}

class _SimpleEnrollmentAppState extends State<SimpleEnrollmentApp>
    with TickerProviderStateMixin {
  // --- UI STATE ---
  bool isLoggedIn = false;
  bool isSubmitting = false;
  bool _isPasswordVisible = false; // For Change Password toggle
  String currentScreen = "login";
  String studentType = "";
  String? loginEmailError;
  String? regEmailError;

  // --- ANIMATIONS ---
  late AnimationController _logoAnimController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut),
    );
    _logoAnimController.forward();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    emailController.dispose();
    passwordController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regConfirmPasswordController.dispose();
    studentNameController.dispose();
    studentAgeController.dispose();
    guardianNameController.dispose();
    studentContactController.dispose();
    guardianContactController.dispose();
    studentIdController.dispose();
    studentAddressController.dispose();
    guardianAddressController.dispose();
    super.dispose();
  }

  // --- COLORS ---
  final Color obcYellow = const Color(0xFFFFD700);
  final Color obcBlack = const Color(0xFF1A1A1A);

  // --- TEXT CONTROLLERS ---
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regConfirmPasswordController = TextEditingController();

  final studentNameController = TextEditingController();
  final studentAgeController = TextEditingController();
  final guardianNameController = TextEditingController();
  final studentContactController = TextEditingController();
  final guardianContactController = TextEditingController();
  final studentIdController = TextEditingController();
  final studentAddressController = TextEditingController();
  final guardianAddressController = TextEditingController();

  String studentBirthday = '';
  String guardianBirthday = '';

  // --- UI HELPERS ---
  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: obcBlack,
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _clearFormControllers() {
    studentNameController.clear();
    studentAgeController.clear();
    guardianNameController.clear();
    studentContactController.clear();
    guardianContactController.clear();
    studentIdController.clear();
    studentAddressController.clear();
    guardianAddressController.clear();
    studentBirthday = '';
    guardianBirthday = '';
  }

  // --- BUSINESS LOGIC HANDLERS ---

  void _handleLogin() async {
    setState(() => loginEmailError = null);
    final result = await EnrollmentService.login(
      emailController.text,
      passwordController.text,
    );

    if (result['success']) {
      setState(() {
        isLoggedIn = true;
        currentScreen = "selection";
      });
      _showMsg("Login Successful!");
    } else {
      _showDialog("Login Failed", result['message']);
    }
  }

  void _handleRegistration() async {
    setState(() => regEmailError = null);
    if (regPasswordController.text != regConfirmPasswordController.text) {
      _showDialog("Error", "Passwords do not match");
      return;
    }

    final result = await EnrollmentService.register(
      regEmailController.text,
      regPasswordController.text,
    );

    if (result['success']) {
      setState(() => currentScreen = "login");
      _showMsg("Account created! Please log in.");
      regEmailController.clear();
      regPasswordController.clear();
      regConfirmPasswordController.clear();
    } else {
      _showDialog("Registration Failed", result['message']);
    }
  }

  void _handleDeleteAccount() async {
    _showMsg("Processing request...");
    final result = await EnrollmentService.deleteAccount(emailController.text);

    if (result['success']) {
      _showMsg("Account permanently deleted.");
      _handleLogout();
    } else {
      _showDialog("Error", result['message']);
    }
  }

  // --- NEW: CHANGE PASSWORD HANDLER ---
  void _showChangePasswordDialog() {
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Added to support the eye toggle inside dialog
        builder: (context, setState) => AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your new password below:"),
              const SizedBox(height: 15),
              TextField(
                controller: newPassController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                if (newPassController.text.isNotEmpty) {
                  final result = await EnrollmentService.changePassword(
                    emailController.text,
                    newPassController.text,
                  );
                  Navigator.pop(context);
                  _showMsg(result['message']);
                } else {
                  _showMsg("Password cannot be empty");
                }
              },
              child: const Text(
                "UPDATE",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStudentTypeSelection(String type) {
    setState(() {
      studentType = type;
      currentScreen = "form";
    });
  }

  void _handleFormSubmission() async {
    final validation = EnrollmentService.validateEnrollmentForm(
      studentName: studentNameController.text,
      studentAge: studentAgeController.text,
      studentContact: studentContactController.text,
      studentBirthday: studentBirthday,
      guardianName: guardianNameController.text,
      guardianContact: guardianContactController.text,
      guardianBirthday: guardianBirthday,
    );

    if (!validation.valid) {
      _showMsg(validation.message);
      return;
    }

    setState(() => isSubmitting = true);
    final result = EnrollmentService.submitEnrollment(
      studentType: studentType,
      studentName: studentNameController.text,
      studentAge: studentAgeController.text,
      studentBirthday: studentBirthday,
      studentAddress: studentAddressController.text,
      studentContact: studentContactController.text,
      guardianName: guardianNameController.text,
      guardianBirthday: guardianBirthday,
      guardianContact: guardianContactController.text,
      guardianAddress: guardianAddressController.text,
      studentId: studentIdController.text.isNotEmpty
          ? studentIdController.text
          : null,
    );

    setState(() => isSubmitting = false);
    if (result.success) {
      setState(() => currentScreen = "summary");
    } else {
      _showDialog("Submission Failed", result.message);
    }
  }

  void _handleLogout() {
    setState(() {
      isLoggedIn = false;
      currentScreen = "login";
      emailController.clear();
      passwordController.clear();
      _clearFormControllers();
    });
  }

  void _handleNewEntry() {
    setState(() {
      currentScreen = "selection";
      _clearFormControllers();
    });
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    Widget activeWidget;
    if (!isLoggedIn) {
      activeWidget = currentScreen == "registration"
          ? _buildRegistrationScreen()
          : _buildLoginScreen();
    } else if (currentScreen == "selection") {
      activeWidget = _buildSelectionScreen();
    } else if (currentScreen == "form") {
      activeWidget = _buildFormScreen();
    } else if (currentScreen == "settings") {
      activeWidget = _buildSettingsScreen();
    } else {
      activeWidget = _buildSummaryScreen();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: activeWidget,
      ),
      bottomNavigationBar: isLoggedIn ? _buildBottomNavBar() : null,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: obcBlack,
      selectedItemColor: obcYellow,
      unselectedItemColor: Colors.grey,
      currentIndex: _getNavIndex(),
      onTap: (index) {
        setState(() {
          if (index == 0)
            currentScreen = "selection";
          else if (index == 1)
            currentScreen = "settings";
          else if (index == 2)
            _handleLogout();
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
      ],
    );
  }

  int _getNavIndex() {
    if (currentScreen == "selection" ||
        currentScreen == "form" ||
        currentScreen == "summary")
      return 0;
    if (currentScreen == "settings") return 1;
    return 0;
  }

  // --- SCREEN BUILDERS (PREVIOUSLY PROVIDED) ---

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: obcBlack,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'images/School_Logo.jpg',
                    height: 100,
                    errorBuilder: (context, e, s) =>
                        Icon(Icons.school, size: 80, color: obcYellow),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "ORO BIBLE COLLEGE",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Student Enrollment Portal",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                _AnimatedButtonWidget(
                  label: "LOGIN",
                  onPressed: _handleLogin,
                  backgroundColor: obcYellow,
                  foregroundColor: obcBlack,
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () =>
                      setState(() => currentScreen = "registration"),
                  child: const Text("Create Account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationScreen() {
    return Scaffold(
      backgroundColor: obcBlack,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.blue),
                const Text(
                  "NEW ACCOUNT",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: regEmailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: regPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: regConfirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                _AnimatedButtonWidget(
                  label: "REGISTER",
                  onPressed: _handleRegistration,
                  backgroundColor: obcBlack,
                  foregroundColor: Colors.white,
                ),
                TextButton(
                  onPressed: () => setState(() => currentScreen = "login"),
                  child: const Text("Already have account?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enrollment Type"),
        backgroundColor: obcYellow,
        foregroundColor: obcBlack,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Type Of Student",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 280,
              child: _AnimatedTileWidget(
                icon: Icons.person_add,
                title: "NEW STUDENT",
                onTap: () => _handleStudentTypeSelection("NEW"),
                iconColor: obcYellow,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 280,
              child: _AnimatedTileWidget(
                icon: Icons.history_edu,
                title: "RETURNING",
                onTap: () => _handleStudentTypeSelection("RETURNING"),
                iconColor: obcYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text("$studentType Student"),
        backgroundColor: obcYellow,
        foregroundColor: obcBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "STUDENT INFO",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextField(
            controller: studentNameController,
            decoration: const InputDecoration(labelText: "Full Name"),
          ),
          TextField(
            controller: studentAgeController,
            decoration: const InputDecoration(labelText: "Age"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: studentBirthday),
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "Birthday",
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2010),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (picked != null)
                setState(
                  () => studentBirthday =
                      "${picked.month}/${picked.day}/${picked.year}",
                );
            },
          ),
          const SizedBox(height: 30),
          if (isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: obcBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
              onPressed: _handleFormSubmission,
              child: const Text("SUBMIT ENROLLMENT"),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final lastEnrollment = EnrollmentService.getLastEnrollment();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: obcYellow),
            const Text(
              "SUBMITTED!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (lastEnrollment != null)
              Text("Student: ${lastEnrollment['studentName']}"),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _handleNewEntry,
                  child: const Text("NEW ENTRY"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("LOGOUT"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        backgroundColor: obcYellow,
        foregroundColor: obcBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "ACCOUNT MANAGEMENT",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListTile(
            tileColor: Colors.grey[100],
            title: const Text("Logged In As:"),
            subtitle: Text(emailController.text),
          ),
          const SizedBox(height: 30),
          const Text(
            "ACCOUNT OPTIONS",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),

          // --- UPDATED CHANGE PASSWORD BUTTON ---
          ElevatedButton.icon(
            icon: const Icon(Icons.lock),
            label: const Text("Change Password"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: _showChangePasswordDialog,
          ),

          const SizedBox(height: 15),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete Account"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Permanently delete your account? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- SHARED ANIMATED WIDGETS ---

class _AnimatedButtonWidget extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  const _AnimatedButtonWidget({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  State<_AnimatedButtonWidget> createState() => _AnimatedButtonWidgetState();
}

class _AnimatedButtonWidgetState extends State<_AnimatedButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () async {
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
        child: Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AnimatedTileWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  const _AnimatedTileWidget({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });

  @override
  State<_AnimatedTileWidget> createState() => _AnimatedTileWidgetState();
}

class _AnimatedTileWidgetState extends State<_AnimatedTileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black),
        ),
        leading: Icon(widget.icon, color: widget.iconColor, size: 30),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          await _controller.forward();
          await _controller.reverse();
          widget.onTap();
        },
      ),
    );
  }
}
