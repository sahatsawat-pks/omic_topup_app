import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/icon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.sports_esports, size: 100, color: Colors.white);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'OMiC Games',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Trusted Gaming Top-Up Platform',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission
                  _buildSection(
                    context,
                    Icons.rocket_launch,
                    'Our Mission',
                    'To provide gamers with the fastest, most secure, and most reliable game top-up service. We believe in making digital gaming accessible to everyone.',
                  ),
                  const SizedBox(height: 24),

                  // Vision
                  _buildSection(
                    context,
                    Icons.visibility,
                    'Our Vision',
                    'To become the leading gaming top-up platform in Southeast Asia, offering seamless transactions and exceptional customer service to millions of gamers.',
                  ),
                  const SizedBox(height: 24),

                  // Why Choose Us
                  Text(
                    'Why Choose OMiC Games?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.flash_on,
                    'Instant Delivery',
                    'Most top-ups are delivered within 5 minutes',
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    Icons.security,
                    'Secure Payments',
                    'Multiple secure payment options with encryption',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    Icons.support_agent,
                    '24/7 Support',
                    'Our dedicated team is always here to help',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    Icons.verified_user,
                    'Trusted Service',
                    'Thousands of satisfied customers',
                    Colors.purple,
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  Text(
                    'Our Numbers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('10K+', 'Happy Customers'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('50K+', 'Successful Orders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('100+', 'Games Supported'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('4.9★', 'Average Rating'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Team Section
                  Text(
                    'Our Team',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.accentColor,
                            child: Icon(Icons.people, size: 40, color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Passionate Team',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Our team consists of gaming enthusiasts who understand what gamers need. We\'re committed to providing the best service possible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact
                  Card(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(Icons.email, size: 40, color: AppTheme.accentColor),
                          const SizedBox(height: 16),
                          const Text(
                            'Get in Touch',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Have questions? We\'d love to hear from you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.support),
                            label: const Text('Contact Support'),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/support');
                            },
                          ),
                        ],
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

  Widget _buildSection(BuildContext context, IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 30),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Card(
      color: AppTheme.accentColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
