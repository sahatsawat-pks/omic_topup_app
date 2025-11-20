import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Membership Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Membership',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Guest',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: AppTheme.accentColor),
                        SizedBox(width: 8),
                        Text(
                          'Bronze Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '150 Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Membership Tiers
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Tiers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTierCard(
                    'Bronze',
                    '0 - 299 Points',
                    '5% Discount',
                    Icons.emoji_events,
                    const Color(0xFFCD7F32),
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    'Silver',
                    '300 - 999 Points',
                    '10% Discount',
                    Icons.emoji_events,
                    const Color(0xFFC0C0C0),
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    'Gold',
                    '1,000 - 2,999 Points',
                    '15% Discount',
                    Icons.emoji_events,
                    const Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    'Platinum',
                    '3,000+ Points',
                    '20% Discount + Exclusive Perks',
                    Icons.emoji_events,
                    const Color(0xFFE5E4E2),
                  ),
                  const SizedBox(height: 24),
                  
                  // How to Earn Points
                  Text(
                    'How to Earn Points',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPointsInfoCard(
                    Icons.shopping_cart,
                    'Make Purchases',
                    'Earn 1 point for every ฿10 spent',
                  ),
                  const SizedBox(height: 12),
                  _buildPointsInfoCard(
                    Icons.card_giftcard,
                    'Daily Login',
                    'Get 5 bonus points for daily check-in',
                  ),
                  const SizedBox(height: 12),
                  _buildPointsInfoCard(
                    Icons.share,
                    'Refer Friends',
                    'Earn 50 points for each friend who signs up',
                  ),
                  const SizedBox(height: 12),
                  _buildPointsInfoCard(
                    Icons.rate_review,
                    'Write Reviews',
                    'Get 10 points for each product review',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(String tier, String range, String benefit, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          tier,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(range),
            Text(
              benefit,
              style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPointsInfoCard(IconData icon, String title, String description) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.accentColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
      ),
    );
  }
}
