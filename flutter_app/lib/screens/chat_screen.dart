import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = ApiService();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _pendingSymptoms = [];
  bool _showSymptomConfirmation = false;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hello! I'm HealthAI 👋\n\nI can help you with:\n• Malaria, Typhoid, Pneumonia\n• Diabetes & Heart Disease\n\nDescribe your symptoms or ask me a health question.",
    );
  }

  void _addBotMessage(
    String text, {
    bool isResult = false,
    Map<String, dynamic>? prediction,
  }) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: false,
          isResult: isResult,
          prediction: prediction,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _containsSymptomKeywords(String message) {
    final keywords = [
      'fever',
      'cough',
      'pain',
      'chills',
      'tired',
      'fatigue',
      'vomit',
      'nausea',
      'breathless',
      'headache',
      'sweating',
      'diarrhea',
      'chest',
      'ache',
      'sore',
      'weak',
      'dizzy',
      'i have',
      'i feel',
      'i am experiencing',
      'suffering',
      'having',
      'feeling sick',
      'not feeling well',
      'muscle',
      'constipation',
      'phlegm',
      'rusty',
      'malaise',
    ];
    final lower = message.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    _addUserMessage(message);
    setState(() => _isLoading = true);

    try {
      if (_containsSymptomKeywords(message)) {
        // Extract symptoms
        final symptoms = await _apiService.extractSymptoms(message);

        if (symptoms.isNotEmpty) {
          setState(() {
            _pendingSymptoms = symptoms;
            _showSymptomConfirmation = true;
          });
          _addBotMessage(
            "I detected these symptoms from your message. Please confirm or edit them before I analyze:",
          );
        } else {
          // No symptoms extracted — fall back to chat
          final response = await _apiService.chat(message);
          _addBotMessage(response);
          _saveChat(message, response);
        }
      } else {
        // General chat
        final response = await _apiService.chat(message);
        _addBotMessage(response);
        _saveChat(message, response);
      }
    } catch (e) {
      _addBotMessage(
        "Sorry, I couldn't process that. Please check your connection and try again.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeSymptoms() async {
    if (_isLoading) return;
    if (_pendingSymptoms.isEmpty) return;

    setState(() {
      _showSymptomConfirmation = false;
      _isLoading = true;
    });

    try {
      // ✅ STEP 1: Prediction
      final prediction = await _apiService.predictSymptoms(_pendingSymptoms);
      final disease = prediction['disease'] as String;
      final confidence = (prediction['confidence'] as num).toDouble();

      // ✅ STEP 2: Explanation
      final explanation = await _apiService.explainDisease(disease, confidence);

      // ✅ STEP 3: Show result (THIS IS SUCCESS POINT)
      _addBotMessage(
        explanation,
        isResult: true,
        prediction: {
          'disease': disease,
          'confidence': confidence,
          'probabilities': prediction['all_probabilities'],
        },
      );

      // ✅ STEP 4: Save (NON-CRITICAL — separate try)
      if (_userId != null) {
        try {
          await _apiService.savePrediction(
            userId: _userId!,
            diseaseType: 'symptoms',
            symptoms: _pendingSymptoms,
            predictedDisease: disease,
            confidence: confidence,
            explanation: explanation,
          );
        } catch (e) {
          // ❌ DO NOTHING (silent fail)
          debugPrint("Save prediction failed: $e");
        }
      }

      _pendingSymptoms = [];
    } catch (e) {
      // ❗ Only triggers if prediction/explanation fails
      _addBotMessage("Sorry, analysis failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChat(String message, String response) async {
    if (_userId != null) {
      try {
        await _apiService.saveChat(
          userId: _userId!,
          message: message,
          response: response,
        );
      } catch (_) {}
    }
    Future<void> _saveChat(String message, String response) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      print('Saving chat for user: $userId'); // add this
      if (userId != null) {
        try {
          await _apiService.saveChat(
            userId: userId,
            message: message,
            response: response,
          );
          print('Chat saved successfully'); // add this
        } catch (e) {
          print('Save chat error: $e'); // add this
        }
      } else {
        print('User ID is null - not saving'); // add this
      }
    }
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
              'HealthAI Assistant',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF1F5F9),
              ),
            ),
            Text(
              'Powered by AI · Not medical advice',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF334155)),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Symptom confirmation
          if (_showSymptomConfirmation) _buildSymptomConfirmation(),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildDot(0),
                        const SizedBox(width: 4),
                        _buildDot(1),
                        const SizedBox(width: 4),
                        _buildDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0D9488),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: MarkdownBody(
            data: message.text,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFE2E8F0),
                height: 1.5,
              ),
              h2: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF1F5F9),
              ),
              listBullet: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      );
    }

    // Bot message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot icon
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HealthAI',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Message bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: message.isResult
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF334155),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isResult && message.prediction != null) ...[
                    // Result header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.prediction!['disease'],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${message.prediction!['confidence'].toInt()}% confidence',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Confidence bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: message.prediction!['confidence'] / 100,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEF4444),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFE2E8F0),
                        height: 1.5,
                      ),
                      h2: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF1F5F9),
                      ),
                      listBullet: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomConfirmation() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 6),
              Text(
                'Detected symptoms',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pendingSymptoms.map((symptom) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0D9488)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      symptom.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _pendingSymptoms.remove(symptom);
                          if (_pendingSymptoms.isEmpty) {
                            _showSymptomConfirmation = false;
                          }
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzeSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Analyze Symptoms',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(
                  color: const Color(0xFFF1F5F9),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isResult;
  final Map<String, dynamic>? prediction;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isResult = false,
    this.prediction,
  });
}
