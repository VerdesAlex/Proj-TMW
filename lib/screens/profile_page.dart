import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final targetWeightController = TextEditingController();

  String selectedGender = "Feminin";
  String selectedActivityLevel = "Sedentar";
  String selectedGoalMode = "Slabit";

  Map<String, dynamic>? getCurrentUser() {
    final usersBox = Hive.box('usersBox');
    final settingsBox = Hive.box('settingsBox');

    final email = settingsBox.get("currentUserEmail");

    if (email == null || !usersBox.containsKey(email)) {
      return null;
    }

    return Map<String, dynamic>.from(usersBox.get(email));
  }

  String displayGender(String value) {
    if (value == "Feminin") return "Female";
    if (value == "Masculin") return "Male";
    if (value == "Prefer sa nu spun") return "Prefer not to say";
    return value;
  }

  String displayActivityLevel(String value) {
    if (value == "Sedentar") return "Sedentary";
    if (value == "Usor activ") return "Lightly active";
    if (value == "Moderat activ") return "Moderately active";
    if (value == "Foarte activ") return "Very active";
    return value;
  }

  String displayGoalMode(String value) {
    if (value == "Slabit") return "Weight Loss";
    if (value == "Gains") return "Muscle Gain";
    return value;
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

  double calculateBmi(double weight, double heightCm) {
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  String getBmiStatus(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obesity";
  }

  double calculateBmr({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender == "Masculin") {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    }

    if (gender == "Feminin") {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }

    return 10 * weight + 6.25 * height - 5 * age - 78;
  }

  double getActivityFactor(String activityLevel) {
    if (activityLevel == "Usor activ") return 1.375;
    if (activityLevel == "Moderat activ") return 1.55;
    if (activityLevel == "Foarte activ") return 1.725;
    return 1.2;
  }

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

  void openEditProfileDialog(Map<String, dynamic> user) {
    firstNameController.text = user["firstName"]?.toString() ?? "";
    lastNameController.text = user["lastName"]?.toString() ?? "";
    birthDateController.text = user["birthDate"]?.toString() ?? "";
    heightController.text = user["height"]?.toString() ?? "";
    weightController.text = user["weight"]?.toString() ?? "";
    targetWeightController.text = user["targetWeight"]?.toString() ?? "";
    selectedGender = user["gender"]?.toString() ?? "Feminin";
    selectedActivityLevel = user["activityLevel"]?.toString() ?? "Sedentar";
    selectedGoalMode = user["goalMode"]?.toString() ?? "Slabit";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 46,
                        height: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ProfileInput(
                      controller: firstNameController,
                      label: "First Name",
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),
                    _ProfileInput(
                      controller: lastNameController,
                      label: "Last Name",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),
                    _ProfileInput(
                      controller: birthDateController,
                      label: "Birth Date",
                      hint: "dd.mm.yyyy",
                      icon: Icons.calendar_month_outlined,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      onTap: pickBirthDate,
                    ),
                    const SizedBox(height: 14),
                    _ProfileDropdown(
                      label: "Gender",
                      icon: Icons.wc,
                      value: selectedGender,
                      items: const [
                        "Feminin",
                        "Masculin",
                        "Prefer sa nu spun",
                      ],
                      itemTextBuilder: displayGender,
                      onChanged: (value) {
                        setModalState(() {
                          selectedGender = value ?? "Feminin";
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _ProfileInput(
                      controller: heightController,
                      label: "Height",
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      suffix: "cm",
                    ),
                    const SizedBox(height: 14),
                    _ProfileInput(
                      controller: weightController,
                      label: "Current Weight",
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      suffix: "kg",
                    ),
                    const SizedBox(height: 14),
                    _ProfileInput(
                      controller: targetWeightController,
                      label: "Target Weight",
                      icon: Icons.flag_outlined,
                      keyboardType: TextInputType.number,
                      suffix: "kg",
                    ),
                    const SizedBox(height: 14),
                    _ProfileDropdown(
                      label: "Activity Level",
                      icon: Icons.directions_run,
                      value: selectedActivityLevel,
                      items: const [
                        "Sedentar",
                        "Usor activ",
                        "Moderat activ",
                        "Foarte activ",
                      ],
                      itemTextBuilder: displayActivityLevel,
                      onChanged: (value) {
                        setModalState(() {
                          selectedActivityLevel = value ?? "Sedentar";
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _ProfileDropdown(
                      label: "Goal",
                      icon: Icons.track_changes_outlined,
                      value: selectedGoalMode,
                      items: const [
                        "Slabit",
                        "Gains",
                      ],
                      itemTextBuilder: displayGoalMode,
                      onChanged: (value) {
                        setModalState(() {
                          selectedGoalMode = value ?? "Slabit";
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => saveProfile(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: navyText,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> saveProfile(Map<String, dynamic> oldUser) async {
    final usersBox = Hive.box('usersBox');
    final settingsBox = Hive.box('settingsBox');

    final email = settingsBox.get("currentUserEmail");

    if (email == null || !usersBox.containsKey(email)) {
      showMessage("User not found.");
      return;
    }

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final birthDate = birthDateController.text.trim();
    final height = heightController.text.trim().replaceAll(",", ".");
    final weight = weightController.text.trim().replaceAll(",", ".");
    final targetWeight = targetWeightController.text.trim().replaceAll(",", ".");

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        birthDate.isEmpty ||
        height.isEmpty ||
        weight.isEmpty ||
        targetWeight.isEmpty) {
      showMessage("Please complete all fields.");
      return;
    }

    if (double.tryParse(height) == null ||
        double.tryParse(weight) == null ||
        double.tryParse(targetWeight) == null) {
      showMessage("Height and weights must be numbers.");
      return;
    }

    if (calculateAge(birthDate) == 0) {
      showMessage("Birth date must use dd.mm.yyyy format.");
      return;
    }

    final updatedUser = {
      ...oldUser,
      "firstName": firstName,
      "lastName": lastName,
      "birthDate": birthDate,
      "height": height,
      "weight": weight,
      "targetWeight": targetWeight,
      "gender": selectedGender,
      "activityLevel": selectedActivityLevel,
      "goalMode": selectedGoalMode,
      "updatedAt": DateTime.now().toIso8601String(),
    };

    await usersBox.put(email, updatedUser);
    await settingsBox.put("goalMode", selectedGoalMode);

    if (!mounted) return;

    Navigator.pop(context);
    setState(() {});
    showMessage("Profile updated successfully.");
  }

  void logout(BuildContext context) async {
    final settingsBox = Hive.box('settingsBox');
    await settingsBox.delete("currentUserEmail");
    await settingsBox.delete("goalMode");

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    heightController.dispose();
    weightController.dispose();
    targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = getCurrentUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: navy,
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(
          child: Text(
            "No authenticated user found.",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    final firstName = user["firstName"] ?? "";
    final lastName = user["lastName"] ?? "";
    final email = user["email"] ?? "";
    final birthDate = user["birthDate"] ?? "";
    final gender = user["gender"] ?? "Prefer sa nu spun";
    final activityLevel = user["activityLevel"] ?? "Sedentar";
    final goalMode = user["goalMode"] ?? "Slabit";

    final height = double.tryParse(user["height"].toString()) ?? 0;
    final weight = double.tryParse(user["weight"].toString()) ?? 0;
    final targetWeight = double.tryParse(user["targetWeight"].toString()) ?? 0;

    final age = calculateAge(birthDate);
    final double bmi =
        height > 0 && weight > 0 ? calculateBmi(weight, height) : 0;
    final bmr = age > 0 && height > 0 && weight > 0
        ? calculateBmr(weight: weight, height: height, age: age, gender: gender)
        : 0;
    final tdee = bmr * getActivityFactor(activityLevel);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    shape: BoxShape.circle,
                    border: Border.all(color: green, width: 2),
                  ),
                  child: const Icon(Icons.person, color: green, size: 62),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "$firstName $lastName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => openEditProfileDialog(user),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Profile"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: "BMI",
                      value: bmi == 0 ? "--" : bmi.toStringAsFixed(1),
                      subtitle: bmi == 0 ? "N/A" : getBmiStatus(bmi),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      title: "Age",
                      value: age == 0 ? "--" : "$age",
                      subtitle: "years",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: "BMR",
                      value: bmr == 0 ? "--" : bmr.round().toString(),
                      subtitle: "kcal",
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      title: "TDEE",
                      value: tdee == 0 ? "--" : tdee.round().toString(),
                      subtitle: "kcal/day",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _InfoCard(
                rows: [
                  _InfoRowData("Birth Date", birthDate),
                  _InfoRowData("Gender", displayGender(gender)),
                  _InfoRowData("Height", "${height.toStringAsFixed(0)} cm"),
                  _InfoRowData(
                    "Current Weight",
                    "${weight.toStringAsFixed(1)} kg",
                  ),
                  _InfoRowData(
                    "Target Weight",
                    "${targetWeight.toStringAsFixed(1)} kg",
                  ),
                  _InfoRowData(
                    "Activity Level",
                    displayActivityLevel(activityLevel),
                  ),
                  _InfoRowData("Goal", displayGoalMode(goalMode)),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: navyText,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

class _ProfileInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  const _ProfileInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.hint,
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  static const navy = Color(0xFF0B1120);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: navy,
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: green),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String) itemTextBuilder;

  const _ProfileDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemTextBuilder,
  });

  static const navy = Color(0xFF0B1120);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: navy,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: navy,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(itemTextBuilder(item)),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Text(itemTextBuilder(item));
        }).toList();
      },
      onChanged: onChanged,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: green,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoCard({required this.rows});

  static const cardNavy = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
                Text(
                  row.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;

  const _InfoRowData(this.label, this.value);
}