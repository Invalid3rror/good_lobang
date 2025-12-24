// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/screens/auth_ui/login/login.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/navigation_bar.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static String routeName = '/register';

  @override
  _RegisterScreen createState() => _RegisterScreen();
}

class _RegisterScreen extends State<RegisterScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final formKey = GlobalKey<FormState>();
  String? name;
  String? username;
  String? email;
  String? password;
  String? confirmPassword;

  void register(BuildContext context) async {
    bool isValid = formKey.currentState!.validate();
    if (isValid) {
      formKey.currentState!.save();
      if (password != confirmPassword) {
        _showSnackBar('Password and Confirm Password do not match!');
        return;
      }

      // Check if username is unique
      bool isUsernameUnique = await fbService.isUsernameUnique(username!);
      if (!isUsernameUnique) {
        _showSnackBar('Username is already taken. Please choose another.');
        return;
      }

      try {
        await fbService.register(name!, username!, email!, password!);
        _showSnackBar('User Registered successfully!');
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      } catch (error) {
        _showSnackBar(error.toString());
      }
    }
  }

  void _showSnackBar(String message) {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to handle Google sign-in
  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

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
      _showSnackBar('Error signing in with Google: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('images/logo.png', height: 100),
              const SizedBox(height: 10),
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
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please provide your name.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        name = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please provide a username.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        username = value;
                      },
                    ),
                    const SizedBox(height: 10),
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
                        }
                        return null;
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
                        }
                        return null;
                      },
                      onSaved: (value) {
                        password = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your password.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        confirmPassword = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        register(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBE1414),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create new account'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed('/login-screen');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBD2E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // Navigate to password recovery screen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.black,
                      ),
                      child: const Text('Sign up with'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      icon: Image.asset(
                        "images/google.png",
                        height: 24.0,
                      ),
                      label: const Text('Sign up with Google'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
