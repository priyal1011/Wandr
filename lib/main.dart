import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/in_memory_store.dart';
import 'core/routing/app_router.dart';
import 'theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'models/user_model.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }
  
  final store = InMemoryStore();
  getIt.registerSingleton<InMemoryStore>(store);
  
  // Register AuthCubit
  getIt.registerSingleton<AuthCubit>(AuthCubit());
  
  await store.loadFromDisk();

  try {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      if (!rememberMe) {
        await FirebaseAuth.instance.signOut();
      } else {
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          store.currentUser = UserModel(
            id: currentUser.uid,
            name: doc['name'] ?? 'Explorer',
            email: currentUser.email ?? '',
            password: '',
            photoUrl: doc.data()!.containsKey('photoUrl') ? doc['photoUrl'] : null,
          );
          store.hasSeenOnboarding = true;
          // Notify AuthCubit of success
          getIt<AuthCubit>().setAuthenticated();
        }
      }
    }
  } catch (e) {
    debugPrint('Auth Hydration Error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Immersive Edge-to-Edge System UI Strategy
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  await setup();
  runApp(const WandrApp());
}

class WandrApp extends StatefulWidget {
  const WandrApp({super.key});

  @override
  State<WandrApp> createState() => WandrAppState();
}

class WandrAppState extends State<WandrApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    final isDark = getIt<InMemoryStore>().settings.isDarkMode;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Wandr',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
