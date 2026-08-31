import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttermoji/fluttermoji.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import '../../../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _currentPhoto;

  @override
  void initState() {
    super.initState();
    final user = getIt<InMemoryStore>().currentUser;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _currentPhoto = user?.photoUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _currentPhoto = image.path;
      });
    }
  }

  void _save() {
    final store = getIt<InMemoryStore>();
    final currentUser = store.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user session found.')));
      return;
    }
    store.currentUser = UserModel(
      id: currentUser.id,
      name: _nameController.text,
      email: _emailController.text,
      password: currentUser.password,
      photoUrl: _currentPhoto,
      fluttermojiCode: currentUser.fluttermojiCode,
    );
    store.saveToDisk();
    context.pop();
  }

  Widget _getAvatarWidget() {
    if (_currentPhoto != null && _currentPhoto!.isNotEmpty) {
      final isNetwork = _currentPhoto!.startsWith('http');
      return CircleAvatar(
        radius: 70,
        backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
        child: ClipOval(
          child: isNetwork 
            ? Image.network(_currentPhoto!, fit: BoxFit.cover, width: 140, height: 140, errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50))
            : Image.file(File(_currentPhoto!), fit: BoxFit.cover, width: 140, height: 140, errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50)),
        ),
      );
    }
    
    return FluttermojiCircleAvatar(
      radius: 70,
      backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  _getAvatarWidget(),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            TextButton.icon(
              onPressed: () async {
                await context.push('/settings/avatar-studio');
                setState(() {
                  _currentPhoto = null; // Clear photo to show updated fluttermoji
                });
              },
              icon: const Icon(Icons.face),
              label: const Text('CUSTOMIZE AVATAR'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentCyan,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
              ),
            ),
            const Gap(48),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const Gap(16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}