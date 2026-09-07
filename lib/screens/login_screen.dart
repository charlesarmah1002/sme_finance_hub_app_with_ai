import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(auth.errorMessage!, style: TextStyle(color: ThemeData.light().colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.status == AuthStatus.loading ? null : _login,
                      child: auth.status == AuthStatus.loading ? const CircularProgressIndicator() : const Text('Login'),
                    ),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Create an account')),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(email: emailController.text.trim(), password: passwordController.text);
  }
}