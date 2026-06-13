import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/repositories.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_providers.dart';
import 'business_providers.dart';

class BusinessEditorScreen extends ConsumerStatefulWidget {
  const BusinessEditorScreen({super.key, this.businessId});
  final String? businessId;

  @override
  ConsumerState<BusinessEditorScreen> createState() =>
      _BusinessEditorScreenState();
}

class _BusinessEditorScreenState extends ConsumerState<BusinessEditorScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _products = TextEditingController();
  final _services = TextEditingController();

  String _category = AppConfig.industries.first;
  String _logoUrl = '';
  bool _busy = false;
  bool _prefilled = false;

  bool get _isEdit => widget.businessId != null;

  @override
  void dispose() {
    for (final c in [
      _name, _desc, _phone, _email, _whatsapp, _address, _website,
      _products, _services
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _pickLogo() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref
          .read(mediaServiceProvider)
          .pickAndUploadImage(uid: uid, category: 'business');
      if (item != null) setState(() => _logoUrl = item.url);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null || _name.text.trim().isEmpty) {
      _toast('Give your business a name.');
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(businessRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(
          widget.businessId!,
          name: _name.text.trim(),
          category: _category,
          description: _desc.text.trim(),
          logoUrl: _logoUrl,
          products: _lines(_products),
          services: _lines(_services),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          whatsapp: _whatsapp.text.trim(),
          address: _address.text.trim(),
          website: _website.text.trim(),
        );
      } else {
        await repo.create(
          ownerId: uid,
          name: _name.text.trim(),
          category: _category,
          description: _desc.text.trim(),
          logoUrl: _logoUrl,
          products: _lines(_products),
          services: _lines(_services),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          whatsapp: _whatsapp.text.trim(),
          address: _address.text.trim(),
          website: _website.text.trim(),
        );
      }
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
    // Prefill once when editing.
    if (_isEdit && !_prefilled) {
      final b = ref.watch(businessProvider(widget.businessId!)).value;
      if (b != null) {
        _prefilled = true;
        _name.text = b.name;
        _desc.text = b.description;
        _category = AppConfig.industries.contains(b.category)
            ? b.category
            : AppConfig.industries.first;
        _logoUrl = b.logoUrl;
        _products.text = b.products.join('\n');
        _services.text = b.services.join('\n');
        _phone.text = b.phone;
        _email.text = b.email;
        _whatsapp.text = b.whatsapp;
        _address.text = b.address;
        _website.text = b.website;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit business' : 'Add a business')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                    photoUrl: _logoUrl,
                    name: _name.text.isEmpty ? '?' : _name.text,
                    radius: 36),
                IconButton.filledTonal(
                  onPressed: _busy ? null : _pickLogo,
                  icon: const Icon(Icons.camera_alt, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Business name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in AppConfig.industries)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(
              controller: _products,
              minLines: 1,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Products (one per line)')),
          const SizedBox(height: 12),
          TextField(
              controller: _services,
              minLines: 1,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Services (one per line)')),
          const Divider(height: 28),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp number')),
          const SizedBox(height: 12),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Website')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEdit ? 'Save changes' : 'Create business'),
          ),
        ],
      ),
    );
  }
}
