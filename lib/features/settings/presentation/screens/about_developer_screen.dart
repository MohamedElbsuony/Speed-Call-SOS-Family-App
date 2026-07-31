import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  final String developerName = 'Mohamed Sabry';
  final String email = 'mo1hamed1.sa1bry@gmail.com';
  final String phone = '+201507366570';
  final String linkedin = 'https://www.linkedin.com/in/mohamed-sabry-49080923b';

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Developer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(height: 12),

          // Developer Profile Avatar & Badge
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'MS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  developerName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lead Mobile Architect & Software Engineer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Connect & Get in Touch',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // WhatsApp Contact Tile
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.chat_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(phone),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _launchUrl('https://wa.me/${phone.replaceAll('+', '')}'),
            ),
          ),

          const SizedBox(height: 8),

          // LinkedIn Profile Tile
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0A66C2),
                child: Icon(Icons.work_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('LinkedIn Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Connect on LinkedIn'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _launchUrl(linkedin),
            ),
          ),

          const SizedBox(height: 8),

          // Email Contact Tile
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.email_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              title: const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(email),
              trailing: const Icon(Icons.send_rounded),
              onTap: () => _launchUrl('mailto:$email?subject=Speed%20Call%20App%20Inquiry'),
            ),
          ),

          const SizedBox(height: 8),

          // Direct Phone Call Tile
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.phone_rounded, color: theme.colorScheme.secondary, size: 20),
              ),
              title: const Text('Direct Phone Call', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(phone),
              trailing: const Icon(Icons.call_rounded),
              onTap: () => _launchUrl('tel:$phone'),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Speed Call App • Crafted with ❤️ by $developerName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
