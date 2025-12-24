import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/screens/auth_ui/change_password.dart';
import 'package:goodlobang/screens/auth_ui/reset_password.dart';
import 'package:goodlobang/screens/payment.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:goodlobang/screens/add_listing.dart';
import 'package:goodlobang/screens/auth_ui/login/login.dart';
import 'package:goodlobang/screens/auth_ui/register/register.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/listing_screen.dart';
import 'package:goodlobang/screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goodlobang/firebase_options.dart';
import 'package:goodlobang/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load();
  GetIt.instance.registerLazySingleton(() => FirebaseService());
  GetIt.instance.registerLazySingleton(() => ThemeService());

  // Set the publishable key for Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

    @override
  Widget build(BuildContext context) {
    final ThemeService themeService = GetIt.instance<ThemeService>();
    themeService.loadTheme();
    
    return StreamBuilder<ThemeData>(
      stream: themeService.getThemeStream(),
      builder: (context, snapshot) {
        return MaterialApp(
          theme: snapshot.data ?? ThemeData.light(),
          home: const LoginScreen(),
          routes: {
            RegisterScreen.routeName: (_) => const RegisterScreen(),
            LoginScreen.routeName: (_) => const LoginScreen(),
            ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
            HomeScreen.routeName: (_) => const HomeScreen(),
            AddListingScreen.routeName: (_) => const AddListingScreen(),
            ListingScreen.routeName: (_) => const ListingScreen(),
            ProfileScreen.routeName: (_) => const ProfileScreen(),
            PaymentScreen.routeName: (_) => const PaymentScreen(),
            ChangePasswordScreen.routeName: (_) => const ChangePasswordScreen(),
          },
        );
      },
    );
  }
}

