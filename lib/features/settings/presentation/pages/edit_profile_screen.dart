import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../main.dart';
import '../../../../models/user_model.dart';
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
  bool _isSaving = false;

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
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

  Future<void> _save() async {
    final store = getIt<InMemoryStore>();
    final currentUser = store.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user session found.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalPhotoUrl = _currentPhoto;

      // 1. If photo is local, upload to Cloudinary
      if (_currentPhoto != null && !_currentPhoto!.startsWith('http')) {
        // Simple check for local path
        final uploadedUrl = await CloudinaryService.uploadImage(_currentPhoto!);
        if (uploadedUrl != null) {
          finalPhotoUrl = uploadedUrl;
        }
      }

      // 2. Update Local Store
      store.currentUser = UserModel(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: currentUser.password,
        photoUrl: finalPhotoUrl,
        fluttermojiCode: currentUser.fluttermojiCode,
      );
      await store.saveToDisk();

      // 3. Sync to Firestore using verified Firebase UID
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
         throw Exception('Critical error: No active Firebase session found.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'photoUrl': finalPhotoUrl,
          });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _getAvatarWidget() {
    final store = getIt<InMemoryStore>();
    final user = store.currentUser;

    if (_currentPhoto != null && _currentPhoto!.isNotEmpty) {
      final isNetwork = _currentPhoto!.startsWith('http');
      return CircleAvatar(
        radius: 70,
        backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
        child: ClipOval(
          child: isNetwork
              ? Image.network(
                  _currentPhoto!,
                  fit: BoxFit.cover,
                  width: 140,
                  height: 140,
                  errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50),
                )
              : Image.file(
                  File(_currentPhoto!),
                  fit: BoxFit.cover,
                  width: 140,
                  height: 140,
                  errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50),
                ),
        ),
      );
    }

    if (user?.fluttermojiCode != null && user!.fluttermojiCode!.isNotEmpty) {
      final svgString = FluttermojiFunctions().decodeFluttermojifromString(user.fluttermojiCode!);
      return CircleAvatar(
        radius: 70,
        backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
        child: ClipOval(
          child: SvgPicture.string(
            svgString,
            width: 140,
            height: 140,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 70,
      backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_outline,
        size: 70,
        color: AppTheme.accentCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
                        child: const Icon(
                          Icons.add_a_photo,
                          size: 20,
                          color: Colors.white,
                        ),
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
                  _currentPhoto =
                      null; // Clear photo to show updated fluttermoji
                });
              },
              icon: const Icon(Icons.face),
              label: const Text('CUSTOMIZE AVATAR'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentCyan,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const Gap(48),
            TextFormField(
              stylusHandwritingEnabled: false,
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Gap(16),
            TextFormField(
              stylusHandwritingEnabled: false,
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
