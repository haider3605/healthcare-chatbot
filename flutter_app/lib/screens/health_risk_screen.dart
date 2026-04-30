import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HealthRiskScreen extends StatefulWidget {
  const HealthRiskScreen({super.key});

  @override
  State<HealthRiskScreen> createState() => _HealthRiskScreenState();
}

class _HealthRiskScreenState extends State<HealthRiskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  bool _isLoading = false;

  // ================= DIABETES CONTROLLERS =================
  final glucose = TextEditingController();
  final bmi = TextEditingController();
  final age = TextEditingController();
  final bp = TextEditingController();

  // ================= HEART CONTROLLERS =================
  final h_age = TextEditingController();
  final chol = TextEditingController();
  final thalach = TextEditingController();

  int sex = 1;
  int cp = 0;

  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ================= API CALLS =================

  Future<void> _predictDiabetes() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final res = await _api.predictDiabetes({
        "pregnancies": 0,
        "glucose": double.tryParse(glucose.text) ?? 0,
        "blood_pressure": double.tryParse(bp.text) ?? 0,
        "skin_thickness": 0,
        "insulin": 0,
        "bmi": double.tryParse(bmi.text) ?? 0,
        "diabetes_pedigree": 0.5,
        "age": double.tryParse(age.text) ?? 0,
      });

      setState(() => result = res);
    } catch (e) {
      _showError();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predictHeart() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final res = await _api.predictHeart({
        "age": double.tryParse(h_age.text) ?? 0,
        "sex": sex,
        "cp": cp,
        "trestbps": 120,
        "chol": double.tryParse(chol.text) ?? 0,
        "fbs": 0,
        "restecg": 1,
        "thalach": double.tryParse(thalach.text) ?? 0,
        "exang": 0,
        "oldpeak": 1.0,
        "slope": 2,
        "ca": 0,
        "thal": 2,
      });

      setState(() => result = res);
    } catch (e) {
      _showError();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Health Risk", style: GoogleFonts.inter()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Diabetes"),
            Tab(text: "Heart"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDiabetes(), _buildHeart()],
      ),
    );
  }

  // ================= DIABETES UI =================

  Widget _buildDiabetes() {
    return _buildForm([
      _input(glucose, "Glucose"),
      _input(bp, "Blood Pressure"),
      _input(bmi, "BMI"),
      _input(age, "Age"),
      _button("Check Diabetes Risk", _predictDiabetes),
      _buildResult(),
    ]);
  }

  // ================= HEART UI =================

  Widget _buildHeart() {
    return _buildForm([
      _input(h_age, "Age"),
      _input(chol, "Cholesterol"),
      _input(thalach, "Max Heart Rate"),

      const SizedBox(height: 10),

      _dropdown("Sex", sex, {
        "Male": 1,
        "Female": 0,
      }, (val) => setState(() => sex = val)),

      _dropdown("Chest Pain Type", cp, {
        "Typical": 0,
        "Atypical": 1,
        "Non-anginal": 2,
        "Asymptomatic": 3,
      }, (val) => setState(() => cp = val)),

      _button("Check Heart Risk", _predictHeart),
      _buildResult(),
    ]);
  }

  // ================= COMMON UI =================

  Widget _buildForm(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    int value,
    Map<String, int> items,
    Function(int) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: value,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ================= RESULT =================

  Widget _buildResult() {
    if (result == null) return const SizedBox();

    final resultText = result!['result'];
    final confidence = result!['confidence'];

    final isDisease =
        resultText.toLowerCase().contains("diabetes") ||
        resultText.toLowerCase().contains("heart disease");

    final color = isDisease ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            "Prediction Result",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 6),

          // Result
          Text(
            resultText,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            isDisease
                ? "⚠️ Please consult a doctor for further evaluation."
                : "✅ Your results look normal. Maintain a healthy lifestyle.",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 10),

          // Confidence text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Confidence",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                "$confidence%",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
