import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/repositories.dart';
import '../../core/widgets/user_avatar.dart';
import '../../domain/entities/account_type.dart';
import '../auth/auth_providers.dart';
import 'user_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  AccountType _type = AccountType.personal;
  String _industry = AppConfig.industries.first;
  String _photoUrl = '';
  bool _prefilled = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref
          .read(mediaServiceProvider)
          .pickAndUploadImage(uid: uid, category: 'avatar');
      if (item != null) setState(() => _photoUrl = item.url);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(
            uid: uid,
            displayName:
                _name.text.trim().isEmpty ? 'New Member' : _name.text.trim(),
            accountType: _type,
            industry: _industry,
            bio: _bio.text.trim(),
            photoUrl: _photoUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    if (!_prefilled && user != null) {
      _prefilled = true;
      _name.text = user.displayName;
      _bio.text = user.bio;
      _type = user.accountType;
      _industry = AppConfig.industries.contains(user.industry)
          ? user.industry
          : AppConfig.industries.first;
      _photoUrl = user.photoUrl;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                    photoUrl: _photoUrl,
                    name: _name.text.isEmpty ? '?' : _name.text,
                    radius: 40),
                IconButton.filledTonal(
                  onPressed: _busy ? null : _pickPhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Account type'),
            items: [
              for (final a in AccountType.values)
                DropdownMenuItem(value: a, child: Text(a.label)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _industry,
            decoration: const InputDecoration(labelText: 'Industry'),
            items: [
              for (final i in AppConfig.industries)
                DropdownMenuItem(value: i, child: Text(i)),
            ],
            onChanged: (v) => setState(() => _industry = v ?? _industry),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _bio,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
