import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day 👋',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        user?.email?.split('@')[0] ?? 'User',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Banner card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Health Assistant',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Get instant guidance for\n5 common diseases',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.health_and_safety,
                      size: 56,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'What would you like to do?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 16),

              // Feature cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _FeatureCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'AI Chat',
                      subtitle: 'Describe symptoms\nor ask questions',
                      color: const Color(0xFF0D9488),
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                    _FeatureCard(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Health Risk',
                      subtitle: 'Check Diabetes &\nHeart Disease',
                      color: const Color(0xFFEF4444),
                      onTap: () => Navigator.pushNamed(context, '/health-risk'),
                    ),
                    _FeatureCard(
                      icon: Icons.history_rounded,
                      title: 'History',
                      subtitle: 'View past\npredictions',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.pushNamed(context, '/history'),
                    ),
                    _FeatureCard(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: '5 diseases\ncovered',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Diseases Covered',
          style: GoogleFonts.inter(
            color: const Color(0xFFF1F5F9),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    '🦟 Malaria',
                    '🤒 Typhoid',
                    '🫁 Pneumonia',
                    '🩸 Diabetes',
                    '❤️ Heart Disease',
                  ]
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            d,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE2E8F0),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: const Color(0xFF0D9488)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
