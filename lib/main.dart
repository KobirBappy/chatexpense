import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/gemini_service.dart';
import 'package:chatapp/home_screen.dart';
import 'package:chatapp/login_screen.dart';
import 'package:chatapp/notification_service.dart';
import 'package:chatapp/onboarding_screen.dart';
import 'package:chatapp/subscription_provider.dart';
import 'package:chatapp/theme_config.dart';
import 'package:chatapp/transaction_provider.dart';
import 'package:chatapp/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Services
  await NotificationService.initialize();
  GeminiService.initialize();
  
  // Check if onboarding is completed
  final prefs = await SharedPreferences.getInstance();
  final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  runApp(MyApp(isOnboardingCompleted: isOnboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool isOnboardingCompleted;
  
  const MyApp({super.key, required this.isOnboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'ChatExpense',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: isOnboardingCompleted 
            ? Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.isAuthenticated) {
                    return const HomeScreen();
                  }
                  return const LoginScreen();
                },
              )
            : const OnboardingScreen(),
      ),
    );
  }
}
