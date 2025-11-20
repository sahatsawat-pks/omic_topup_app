import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.policy, size: 80, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: November 18, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly to us when you create an account, make a purchase, or contact our support team. This includes your name, email address, phone number, and payment information.',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use the information we collect to:\n'
                  '• Process your transactions and send you related information\n'
                  '• Send you technical notices and support messages\n'
                  '• Respond to your comments and questions\n'
                  '• Improve our services and develop new features',
            ),
            _buildSection(
              context,
              '3. Information Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information with trusted partners who assist us in operating our platform, conducting our business, or servicing you.',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information. However, no method of transmission over the Internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              context,
              '5. Your Rights',
              'You have the right to:\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Object to processing of your data\n'
                  '• Export your data',
            ),
            _buildSection(
              context,
              '6. Cookies',
              'We use cookies and similar tracking technologies to track activity on our service and hold certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
            ),
            _buildSection(
              context,
              '7. Children\'s Privacy',
              'Our service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.',
            ),
            _buildSection(
              context,
              '8. Changes to This Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
            ),
            _buildSection(
              context,
              '9. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: support@omicgames.com\n'
                  'Phone: +66 (0) 2-XXX-XXXX',
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Home'),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
