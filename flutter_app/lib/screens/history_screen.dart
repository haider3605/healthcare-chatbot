import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  final String? _userId = Supabase.instance.client.auth.currentUser?.id;

  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_userId == null) return;

    try {
      final data = await _api.getHistory(_userId!);
      debugPrint("RAW DATA: $data");

      final predictions = data['predictions'] as List? ?? [];
      final chats = data['chats'] as List? ?? [];

      setState(() {
        final predictions = (data['predictions'] as List? ?? [])
            .map(
              (p) => Map<String, dynamic>.from({
                ...p,
                'record_type': 'prediction',
              }),
            )
            .toList();
        final chats = (data['chats'] as List? ?? [])
            .map(
              (c) => Map<String, dynamic>.from({...c, 'record_type': 'chat'}),
            )
            .toList();

        _history = [...predictions, ...chats];
        _history.sort(
          (a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''),
        );
      });
    } catch (e) {
      debugPrint("History error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("History", style: GoogleFonts.inter()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? _buildEmpty()
          : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        "No history yet",
        style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(_history[index]);
          return _buildCard(item);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final recordType = item['record_type'] ?? 'prediction';
    final bool isChat = recordType == 'chat';

    if (isChat) {
      return _buildChatCard(item);
    } else {
      return _buildPredictionCard(item);
    }
  }

  Widget _buildPredictionCard(Map<String, dynamic> item) {
    final disease = item['predicted_disease'] ?? 'Unknown';
    final confidence = (item['confidence'] ?? 0).toDouble();
    final type = item['disease_type'] ?? 'general';
    final date = (item['created_at'] ?? '').split('T')[0];
    final isDisease = !disease.toLowerCase().contains('no');
    final color = isDisease ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    disease,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                '${confidence.toInt()}%',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            type.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> item) {
    final message = item['message'] ?? '';
    final response = item['response'] ?? '';
    final date = (item['created_at'] ?? '').split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 6),
              Text(
                'Chat',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            response,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
