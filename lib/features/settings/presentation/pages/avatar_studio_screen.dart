import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class AvatarStudioScreen extends StatefulWidget {
  const AvatarStudioScreen({super.key});

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              final store = getIt<InMemoryStore>();
              final user = store.currentUser;
              if (user != null) {
                final fluttermojiCode = await FluttermojiFunctions().encodeMySVGtoString();
                
                store.currentUser = UserModel(
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  password: user.password,
                  photoUrl: null, // Reset photo to show avatar
                  fluttermojiCode: fluttermojiCode,
                );
                await store.saveToDisk();
              }
              if (context.mounted) context.pop();
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(20),
            Center(
              child: FluttermojiCircleAvatar(
                radius: 100,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const Gap(40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "CUSTOMIZE YOUR EXPLORER",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Gap(8),
            FluttermojiCustomizer(
              scaffoldHeight: 400,
              theme: FluttermojiThemeData(
                labelTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                primaryBgColor: Theme.of(context).scaffoldBackgroundColor,
                secondaryBgColor: Theme.of(context).colorScheme.surface,
                iconColor: Theme.of(context).colorScheme.primary,
                selectedIconColor: Theme.of(context).colorScheme.primary,
                unselectedIconColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
