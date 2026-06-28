import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  bool _isExplaining = false;
  Map<String, dynamic>? result;
  String? _explanation;

  // Diabetes controllers
  final glucose = TextEditingController();
  final bmi = TextEditingController();
  final age = TextEditingController();
  final bp = TextEditingController();

  // Heart controllers
  final h_age = TextEditingController();
  final chol = TextEditingController();
  final thalach = TextEditingController();

  int sex = 1;
  int cp = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        result = null;
        _explanation = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    glucose.dispose();
    bmi.dispose();
    age.dispose();
    bp.dispose();
    h_age.dispose();
    chol.dispose();
    thalach.dispose();
    super.dispose();
  }

  // API calls
  Future<void> _predictDiabetes() async {
    if (_isLoading) return;

    if (glucose.text.isEmpty ||
        bmi.text.isEmpty ||
        age.text.isEmpty ||
        bp.text.isEmpty) {
      _showSnackbar('Please fill in all fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      result = null;
      _explanation = null;
    });

    try {
      final res = await _api.predictDiabetes({
        "pregnancies": 0,
        "glucose": double.tryParse(glucose.text) ?? 0,
        "blood_pressure": double.tryParse(bp.text) ?? 0,
        "skin_thickness": 20.0,
        "insulin": 79.0,
        "bmi": double.tryParse(bmi.text) ?? 0,
        "diabetes_pedigree": 0.5,
        "age": double.tryParse(age.text) ?? 0,
      });
      setState(() => result = res);
    } catch (e) {
      _showSnackbar('Prediction failed. Check your connection.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predictHeart() async {
    if (_isLoading) return;

    if (h_age.text.isEmpty || chol.text.isEmpty || thalach.text.isEmpty) {
      _showSnackbar('Please fill in all fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      result = null;
      _explanation = null;
    });

    try {
      final res = await _api.predictHeart({
        "age": double.tryParse(h_age.text) ?? 0,
        "sex": sex.toDouble(),
        "cp": cp.toDouble(),
        "trestbps": 120.0,
        "chol": double.tryParse(chol.text) ?? 0,
        "fbs": 0.0,
        "restecg": 1.0,
        "thalach": double.tryParse(thalach.text) ?? 0,
        "exang": 0.0,
        "oldpeak": 1.0,
        "slope": 2.0,
        "ca": 0.0,
        "thal": 2.0,
      });
      setState(() => result = res);
    } catch (e) {
      _showSnackbar('Prediction failed. Check your connection.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _explainResult() async {
    if (result == null) return;
    setState(() => _isExplaining = true);
    try {
      final disease = result!['result'] as String;
      final confidence = (result!['confidence'] as num).toDouble();
      final explanation = await _api.explainDisease(disease, confidence);
      setState(() => _explanation = explanation);
    } catch (e) {
      _showSnackbar('Could not get explanation.', isError: true);
    } finally {
      setState(() => _isExplaining = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Risk Assessment',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF1F5F9),
              ),
            ),
            Text(
              'Diabetes & Heart Disease screening',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              tabs: const [
                Tab(text: '🩸  Diabetes'),
                Tab(text: '❤️  Heart'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDiabetes(), _buildHeart()],
      ),
    );
  }

  // Diabetes form
  Widget _buildDiabetes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner(
            'Enter your medical values below for diabetes risk screening.',
          ),
          const SizedBox(height: 16),
          _inputCard(
            controller: glucose,
            label: 'Glucose Level',
            hint: 'e.g. 120',
            tooltip: 'Normal fasting glucose is 70–100 mg/dL',
            unit: 'mg/dL',
          ),
          _inputCard(
            controller: bp,
            label: 'Blood Pressure',
            hint: 'e.g. 80',
            tooltip: 'Diastolic blood pressure in mm Hg',
            unit: 'mm Hg',
          ),
          _inputCard(
            controller: bmi,
            label: 'BMI',
            hint: 'e.g. 25.0',
            tooltip: 'Body Mass Index. Normal range: 18.5–24.9',
            unit: 'kg/m²',
          ),
          _inputCard(
            controller: age,
            label: 'Age',
            hint: 'e.g. 35',
            tooltip: 'Your age in years',
            unit: 'years',
          ),
          const SizedBox(height: 8),
          _assessButton('Assess Diabetes Risk', _predictDiabetes),
          _buildResult(),
        ],
      ),
    );
  }

  // Heart form
  Widget _buildHeart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner(
            'Enter your medical values below for heart disease risk screening.',
          ),
          const SizedBox(height: 16),
          _inputCard(
            controller: h_age,
            label: 'Age',
            hint: 'e.g. 52',
            tooltip: 'Your age in years',
            unit: 'years',
          ),
          _inputCard(
            controller: chol,
            label: 'Cholesterol',
            hint: 'e.g. 200',
            tooltip: 'Total serum cholesterol in mg/dL. Normal: below 200',
            unit: 'mg/dL',
          ),
          _inputCard(
            controller: thalach,
            label: 'Max Heart Rate',
            hint: 'e.g. 150',
            tooltip: 'Maximum heart rate achieved during exercise',
            unit: 'bpm',
          ),
          const SizedBox(height: 4),
          _selectorCard(
            label: 'Sex',
            tooltip: 'Biological sex',
            options: {'Male': 1, 'Female': 0},
            selected: sex,
            onChanged: (v) => setState(() => sex = v),
          ),
          const SizedBox(height: 12),
          _selectorCard(
            label: 'Chest Pain Type',
            tooltip: 'Type of chest pain experienced. Asymptomatic = no pain',
            options: {'None': 0, 'Mild': 1, 'Moderate': 2, 'Severe': 3},
            selected: cp,
            onChanged: (v) => setState(() => cp = v),
          ),
          const SizedBox(height: 16),
          _assessButton('Assess Heart Risk', _predictHeart),
          _buildResult(),
        ],
      ),
    );
  }

  // Info banner
  Widget _infoBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF0D9488)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Input card with tooltip and unit
  Widget _inputCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String tooltip,
    required String unit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip,
                child: const Icon(
                  Icons.help_outline,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              color: const Color(0xFFF1F5F9),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Selector card for sex and chest pain
  Widget _selectorCard({
    required String label,
    required String tooltip,
    required Map<String, int> options,
    required int selected,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip,
                child: const Icon(
                  Icons.help_outline,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              final isSelected = selected == e.value;
              return GestureDetector(
                onTap: () => onChanged(e.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Text(
                    e.key,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Assess button
  Widget _assessButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          disabledBackgroundColor: const Color(0xFF334155),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Result card
  Widget _buildResult() {
    if (result == null) return const SizedBox();

    final resultText = result!['result'] as String;
    final confidence = (result!['confidence'] as num).toDouble();

    final isDisease = !resultText.toLowerCase().contains('no');

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
          // Result header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDisease
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resultText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${confidence.toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            isDisease
                ? '⚠️ Please consult a doctor for further evaluation.'
                : '✅ Results look normal. Maintain a healthy lifestyle.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 10),

          // Confidence bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence Level',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                '${confidence.toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 14),

          // Explain button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExplaining ? null : _explainResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFF0D9488)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: _isExplaining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D9488),
                      ),
                    )
                  : const Icon(
                      Icons.info_outline,
                      color: Color(0xFF0D9488),
                      size: 18,
                    ),
              label: Text(
                _isExplaining ? 'Getting explanation...' : 'Explain Result',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0D9488),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Explanation
          if (_explanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: MarkdownBody(
                data: _explanation!,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFE2E8F0),
                    height: 1.5,
                  ),
                  h2: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF1F5F9),
                  ),
                  listBullet: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
