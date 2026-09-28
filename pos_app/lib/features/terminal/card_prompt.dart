import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/app_theme.dart';

class CardPrompt extends StatelessWidget {
  const CardPrompt({
    super.key,
    required this.language,
    required this.animation,
    required this.onLanguageChanged,
    required this.tts,
  });

  final String language;
  final Animation<double> animation;
  final ValueChanged<String> onLanguageChanged;
  final FlutterTts tts;

  String get prompt => switch (language) {
    'Pashto' => 'مهرباني وکړئ خپل کارت وکاروئ',
    'Dari' => 'لطفاً از کارت خود استفاده کنید',
    _ => 'Please use your card',
  };

  Future<void> _announce() async {
    await tts.setLanguage(switch (language) {
      'Pashto' => 'ps-AF',
      'Dari' => 'fa-AF',
      _ => 'en-US',
    });
    await tts.setSpeechRate(0.42);
    await tts.speak(prompt);
  }

  @override
  Widget build(BuildContext context) => Card(
    color: PosColors.soft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: const InputDecoration(labelText: 'Prompt language'),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Pashto', child: Text('پښتو')),
              DropdownMenuItem(value: 'Dari', child: Text('دری / فارسی')),
            ],
            onChanged: (value) => onLanguageChanged(value ?? 'English'),
          ),
          const SizedBox(height: 12),
          ScaleTransition(
            scale: animation,
            child: const Icon(
              Icons.contactless_rounded,
              size: 58,
              color: PosColors.accent,
            ),
          ),
          Text(
            prompt,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const Text(
            'Tap, insert, or swipe only on the certified reader. Never enter PIN in this app.',
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: _announce,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Play instruction'),
          ),
        ],
      ),
    ),
  );
}
