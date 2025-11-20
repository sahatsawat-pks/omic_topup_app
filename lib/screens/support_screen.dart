import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: AppTheme.accentColor,
              child: const Column(
                children: [
                  Icon(Icons.support_agent, size: 60, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We\'re here to help with any questions',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'How do I make a purchase?',
                    'Browse our games, select a product, choose a package, and proceed to checkout. You\'ll need to provide your game UID and select a payment method.',
                  ),
                  _buildFAQItem(
                    'What payment methods do you accept?',
                    'We accept Credit/Debit Cards, True Wallet, Bank Transfer, PromptPay, and QR Payment.',
                  ),
                  _buildFAQItem(
                    'How long does delivery take?',
                    'Most top-ups are delivered instantly within 5 minutes. Some may take up to 30 minutes during peak hours.',
                  ),
                  _buildFAQItem(
                    'Can I get a refund?',
                    'Refunds are available within 24 hours if the top-up was not delivered to your account. Please contact support with your order details.',
                  ),
                  _buildFAQItem(
                    'How do I track my order?',
                    'Go to Profile > History to view all your orders and their status.',
                  ),
                  const SizedBox(height: 32),

                  // Contact Methods
                  Text(
                    'Contact Us',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          Icons.email,
                          'Email',
                          'support@omicgames.com',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContactCard(
                          Icons.phone,
                          'Phone',
                          '+66 2-XXX-XXXX',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          Icons.chat,
                          'Live Chat',
                          'Available 9AM-6PM',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContactCard(
                          Icons.facebook,
                          'Facebook',
                          '@OMiCGames',
                          Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Contact Form
                  Text(
                    'Send us a message',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'General Inquiry', child: Text('General Inquiry')),
                                DropdownMenuItem(value: 'Order Issue', child: Text('Order Issue')),
                                DropdownMenuItem(value: 'Payment Problem', child: Text('Payment Problem')),
                                DropdownMenuItem(value: 'Account Issue', child: Text('Account Issue')),
                                DropdownMenuItem(value: 'Technical Support', child: Text('Technical Support')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectController,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.subject),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a subject';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 80),
                                  child: Icon(Icons.message),
                                ),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your message';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Send Message'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                                onPressed: _submitForm,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully! We\'ll get back to you soon.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'General Inquiry';
      });
    }
  }
}
