import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/repositories.dart';
import '../../domain/entities/founder_journey.dart';
import '../profile/user_providers.dart';

const _currencies = ['USD', 'KES', 'NGN', 'GHS', 'ZAR', 'TZS', 'UGX'];

class JourneyEditorScreen extends ConsumerStatefulWidget {
  const JourneyEditorScreen({super.key});

  @override
  ConsumerState<JourneyEditorScreen> createState() => _JourneyEditorScreenState();
}

class _JourneyEditorScreenState extends ConsumerState<JourneyEditorScreen> {
  final _title = TextEditingController();
  final _capital = TextEditingController();
  final _challenges = TextEditingController();
  final _mistakes = TextEditingController();
  final _lessons = TextEditingController();

  String _industry = AppConfig.industries.first;
  JourneyStage _stage = JourneyStage.idea;
  String _currency = 'USD';
  bool _disclosed = true;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _capital.dispose();
    _challenges.dispose();
    _mistakes.dispose();
    _lessons.dispose();
    super.dispose();
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final author = ref.read(currentAuthorRefProvider);
    if (author == null || _title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(journeyRepositoryProvider).create(
            author: author,
            title: _title.text.trim(),
            industry: _industry,
            stage: _stage,
            capitalAmount: num.tryParse(_capital.text.trim()) ?? 0,
            capitalCurrency: _currency,
            capitalDisclosed: _disclosed,
            challenges: _lines(_challenges),
            mistakes: _lines(_mistakes),
            lessons: _lines(_lessons),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share your journey')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Headline (e.g. "From \$200 to 12 staff")'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _industry,
            decoration: const InputDecoration(labelText: 'Industry'),
            items: [
              for (final i in AppConfig.industries)
                DropdownMenuItem(value: i, child: Text(i))
            ],
            onChanged: (v) => setState(() => _industry = v ?? _industry),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<JourneyStage>(
            value: _stage,
            decoration: const InputDecoration(labelText: 'Current stage'),
            items: [
              for (final s in JourneyStage.values)
                DropdownMenuItem(value: s, child: Text(journeyStageLabels[s]!))
            ],
            onChanged: (v) => setState(() => _stage = v ?? _stage),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _capital,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Startup capital'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: [
                    for (final c in _currencies)
                      DropdownMenuItem(value: c, child: Text(c))
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? _currency),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show my startup capital publicly'),
            value: _disclosed,
            onChanged: (v) => setState(() => _disclosed = v),
          ),
          _multiline(_challenges, 'Challenges you faced (one per line)'),
          _multiline(_mistakes, 'Mistakes you made (one per line)'),
          _multiline(_lessons, 'Lessons learned (one per line)'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish journey'),
          ),
        ],
      ),
    );
  }

  Widget _multiline(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
