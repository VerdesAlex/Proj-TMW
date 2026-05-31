import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool submitted = false;

  String selectedGoalMode = "Slabit";
  String selectedGender = "Feminin";
  String selectedActivityLevel = "Sedentar";

  static const navy = Color(0xFF0B1120);
  static const deepNavy = Color(0xFF0F172A);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final targetWeightController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cardNavy,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: green, width: 1),
        ),
      ),
    );
  }

  void goToHome(String goalMode) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(goalMode: goalMode),
      ),
    );
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, "0")}.${date.month.toString().padLeft(2, "0")}.${date.year}";
  }

  DateTime? parseBirthDate(String value) {
    final parts = value.split(".");
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    try {
      final date = DateTime(year, month, day);

      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }

      return date;
    } catch (e) {
      return null;
    }
  }

  Future<void> pickBirthDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate = parseBirthDate(birthDateController.text.trim()) ??
        DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 12, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: "Select birth date",
      cancelText: "Cancel",
      confirmText: "Select",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: green,
              onPrimary: navyText,
              surface: cardNavy,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: cardNavy,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    setState(() {
      birthDateController.text = formatDate(selectedDate);
    });
  }

  int calculateAge(String birthDate) {
    final date = parseBirthDate(birthDate);

    if (date == null) return 0;

    final today = DateTime.now();

    if (date.isAfter(today)) return 0;

    int age = today.year - date.year;

    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      age--;
    }

    return age;
  }

  String? validateRequiredName(String? value, String fieldName) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "$fieldName is required.";
    if (text.length < 2) return "$fieldName must have at least 2 characters.";
    if (!RegExp(r"^[a-zA-ZăâîșțĂÂÎȘȚ\s-]+$").hasMatch(text)) {
      return "$fieldName can contain only letters.";
    }

    return null;
  }

  String? validateBirthDate(String? value) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "Birth date is required.";
    if (!RegExp(r"^\d{2}\.\d{2}\.\d{4}$").hasMatch(text)) {
      return "Use format dd.mm.yyyy.";
    }

    final age = calculateAge(text);

    if (age <= 0) return "Enter a valid birth date.";
    if (age < 12) return "You must be at least 12 years old.";
    if (age > 100) return "Enter a realistic birth date.";

    return null;
  }

  String? validateNumber(
    String? value,
    String fieldName,
    double min,
    double max,
  ) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "$fieldName is required.";

    final number = double.tryParse(text.replaceAll(",", "."));

    if (number == null) return "$fieldName must be a number.";
    if (number < min || number > max) {
      return "$fieldName must be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}.";
    }

    return null;
  }

  String? validateEmail(String? value) {
    final text = value?.trim().toLowerCase() ?? "";

    if (text.isEmpty) return "Email is required.";

    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");

    if (!emailRegex.hasMatch(text)) return "Enter a valid email address.";

    return null;
  }

  String? validatePassword(String? value) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "Password is required.";
    if (text.length < 6) return "Password must have at least 6 characters.";
    if (!RegExp(r"[A-Za-z]").hasMatch(text)) {
      return "Password must contain at least one letter.";
    }
    if (!RegExp(r"\d").hasMatch(text)) {
      return "Password must contain at least one number.";
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "Confirm your password.";
    if (text != passwordController.text.trim()) return "Passwords do not match.";

    return null;
  }

  Future<void> registerUser() async {
    final usersBox = Hive.box('usersBox');
    final settingsBox = Hive.box('settingsBox');

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final birthDate = birthDateController.text.trim();
    final height = heightController.text.trim().replaceAll(",", ".");
    final weight = weightController.text.trim().replaceAll(",", ".");
    final targetWeight = targetWeightController.text.trim().replaceAll(",", ".");
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (usersBox.containsKey(email)) {
      showMessage("An account with this email already exists.");
      return;
    }

    final user = {
      "firstName": firstName,
      "lastName": lastName,
      "birthDate": birthDate,
      "height": height,
      "weight": weight,
      "initialWeight": weight,
      "targetWeight": targetWeight,
      "gender": selectedGender,
      "activityLevel": selectedActivityLevel,
      "goalMode": selectedGoalMode,
      "email": email,
      "password": password,
      "createdAt": DateTime.now().toIso8601String(),
    };

    await usersBox.put(email, user);
    await settingsBox.put("currentUserEmail", email);
    await settingsBox.put("goalMode", selectedGoalMode);

    showMessage("Account created successfully.");
    goToHome(selectedGoalMode);
  }

  Future<void> loginUser() async {
    final usersBox = Hive.box('usersBox');
    final settingsBox = Hive.box('settingsBox');

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (!usersBox.containsKey(email)) {
      showMessage("No account found with this email.");
      return;
    }

    final userData = usersBox.get(email);

    if (userData == null) {
      showMessage("Account could not be found.");
      return;
    }

    final user = Map<String, dynamic>.from(userData);

    if (user["password"] != password) {
      showMessage("Incorrect password.");
      return;
    }

    if (!user.containsKey("initialWeight")) {
      user["initialWeight"] = user["weight"];
      await usersBox.put(email, user);
    }

    await settingsBox.put("currentUserEmail", email);
    await settingsBox.put("goalMode", user["goalMode"]);

    showMessage("Welcome back.");
    goToHome(user["goalMode"]);
  }

  Future<void> handleAuth() async {
    FocusScope.of(context).unfocus();

    setState(() {
      submitted = true;
    });

    if (!(formKey.currentState?.validate() ?? false)) return;

    if (isLogin) {
      await loginUser();
    } else {
      await registerUser();
    }
  }

  void switchAuthMode() {
    setState(() {
      isLogin = !isLogin;
      submitted = false;
      firstNameController.clear();
      lastNameController.clear();
      birthDateController.clear();
      heightController.clear();
      weightController.clear();
      targetWeightController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      selectedGoalMode = "Slabit";
      selectedGender = "Feminin";
      selectedActivityLevel = "Sedentar";
      obscurePassword = true;
      obscureConfirmPassword = true;
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    heightController.dispose();
    weightController.dispose();
    targetWeightController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: green.withOpacity(0.45),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: green,
                  size: 46,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "FitJourney",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Track your health. Reach your goals.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: deepNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: "Login",
                        selected: isLogin,
                        onTap: () {
                          if (!isLogin) switchAuthMode();
                        },
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: "Register",
                        selected: !isLogin,
                        onTap: () {
                          if (isLogin) switchAuthMode();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardNavy,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  autovalidateMode: submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLogin ? "Welcome back" : "Create account",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        isLogin
                            ? "Sign in and continue your progress."
                            : "Set your profile and start your journey.",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isLogin) ...[
                        _AuthInput(
                          controller: firstNameController,
                          label: "First name",
                          icon: Icons.person_outline_rounded,
                          validator: (value) =>
                              validateRequiredName(value, "First name"),
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: lastNameController,
                          label: "Last name",
                          icon: Icons.badge_outlined,
                          validator: (value) =>
                              validateRequiredName(value, "Last name"),
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: birthDateController,
                          label: "Birth date",
                          hint: "dd.mm.yyyy",
                          icon: Icons.calendar_month_outlined,
                          validator: validateBirthDate,
                          keyboardType: TextInputType.none,
                          readOnly: true,
                          onTap: pickBirthDate,
                        ),
                        const SizedBox(height: 16),
                        _GenderDropdown(
                          value: selectedGender,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value ?? "Feminin";
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: heightController,
                          label: "Height",
                          icon: Icons.height_rounded,
                          validator: (value) =>
                              validateNumber(value, "Height", 100, 230),
                          keyboardType: TextInputType.number,
                          suffix: "cm",
                        ),
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: weightController,
                          label: "Current weight",
                          icon: Icons.monitor_weight_outlined,
                          validator: (value) =>
                              validateNumber(value, "Current weight", 30, 250),
                          keyboardType: TextInputType.number,
                          suffix: "kg",
                        ),
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: targetWeightController,
                          label: "Target weight",
                          icon: Icons.flag_outlined,
                          validator: (value) =>
                              validateNumber(value, "Target weight", 30, 250),
                          keyboardType: TextInputType.number,
                          suffix: "kg",
                        ),
                        const SizedBox(height: 16),
                        _ActivityDropdown(
                          value: selectedActivityLevel,
                          onChanged: (value) {
                            setState(() {
                              selectedActivityLevel = value ?? "Sedentar";
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _GoalDropdown(
                          value: selectedGoalMode,
                          onChanged: (value) {
                            setState(() {
                              selectedGoalMode = value ?? "Slabit";
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _AuthInput(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _AuthInput(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        validator: validatePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        _AuthInput(
                          controller: confirmPasswordController,
                          label: "Confirm password",
                          icon: Icons.lock_reset_rounded,
                          obscureText: obscureConfirmPassword,
                          validator: validateConfirmPassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: navyText,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isLogin ? "Sign in" : "Create account",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: switchAuthMode,
                          child: Text(
                            isLogin
                                ? "New here? Create an account"
                                : "Already have an account? Sign in",
                            style: const TextStyle(
                              color: green,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? green : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? navyText : Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? suffix;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const _AuthInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      cursorColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: green),
        suffixText: suffix,
        suffixIcon: suffixIcon,
        suffixStyle: const TextStyle(color: Colors.white60),
        errorStyle: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
    );
  }
}

class _GoalDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _GoalDropdown({
    required this.value,
    required this.onChanged,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: (value) {
        if (value == null || value.isEmpty) return "Goal is required.";
        return null;
      },
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        labelText: "Goal",
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(
          Icons.track_changes_outlined,
          color: green,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
      items: const ["Slabit", "Gains"].map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item == "Slabit" ? "Weight Loss" : "Muscle Gain"),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return const ["Slabit", "Gains"].map((item) {
          return Text(item == "Slabit" ? "Weight Loss" : "Muscle Gain");
        }).toList();
      },
      onChanged: onChanged,
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({
    required this.value,
    required this.onChanged,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: (value) {
        if (value == null || value.isEmpty) return "Gender is required.";
        return null;
      },
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        labelText: "Gender",
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(
          Icons.wc_rounded,
          color: green,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: "Feminin",
          child: Text("Female"),
        ),
        DropdownMenuItem(
          value: "Masculin",
          child: Text("Male"),
        ),
        DropdownMenuItem(
          value: "Prefer sa nu spun",
          child: Text("Prefer not to say"),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _ActivityDropdown({
    required this.value,
    required this.onChanged,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Activity level is required.";
        }
        return null;
      },
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        labelText: "Activity level",
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(
          Icons.directions_run_rounded,
          color: green,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: "Sedentar",
          child: Text("Sedentary"),
        ),
        DropdownMenuItem(
          value: "Usor activ",
          child: Text("Lightly active"),
        ),
        DropdownMenuItem(
          value: "Moderat activ",
          child: Text("Moderately active"),
        ),
        DropdownMenuItem(
          value: "Foarte activ",
          child: Text("Very active"),
        ),
      ],
      onChanged: onChanged,
    );
  }
}