// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/screens/auth_ui/register/register.dart';
import 'package:goodlobang/screens/auth_ui/reset_password.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/navigation_bar.dart';
import 'package:goodlobang/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login-screen';

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final formKey = GlobalKey<FormState>();
  String? email;
  String? password;

  // Google sign-in variables
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth auth = FirebaseAuth.instance;

  void login(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      try {
        await fbService.login(email!, password!);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BaseScreen(
              content: HomeScreen(searchQuery: ''),
              selectedIndex: 0,
            ),
          ),
        );
      } catch (error) {
        FocusScope.of(context).unfocus();
        String message = error.toString();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  // Function to handle Google sign-in
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await auth.signInWithCredential(credential);
      
        // Check if user is new or existing
        final User? user = userCredential.user;
        if (user != null) {
          // Save or update user data in Firestore
          await fbService.saveGoogleSignInUserData(user);

          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BaseScreen(
                content: HomeScreen(searchQuery: ''),
                selectedIndex: 0,
              ),
            ),
          );
        }
      } else {
        // Handle Google sign-in cancellation
        print('Google sign-in was canceled.');
      }
    } catch (error) {
      print('Error signing in with Google: $error');
      // Handle error, show snackbar, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or Icon (replace with your own)
            Image.asset('images/logo.png', height: 100),

            const SizedBox(height: 10),

            // Form
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please provide an email address.";
                      } else if (!value.contains('@')) {
                        return "Please provide a valid email address.";
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      email = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please provide a password.";
                      } else if (value.length < 6) {
                        return "Password must be at least 6 characters long.";
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      password = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      login(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBE1414),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(ResetPasswordScreen.routeName);
                      // Navigate to password recovery screen
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Text("Sign in with"),
                    ],
                  ),
                  const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      icon: Image.asset(
                        "images/google.png",
                        height: 24.0,
                      ),
                      label: const Text('Sign in with Google'),
                    ),
                  const SizedBox(height: 20),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Text("New user?"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RegisterScreen.routeName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBE1414),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create new account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}