import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final businessController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    businessController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: businessController, decoration: const InputDecoration(labelText: 'Business name'), validator: _required),
                const SizedBox(height: 16),
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
                const SizedBox(height: 16),
                TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 16),
                TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(auth.errorMessage!, style: TextStyle(color: ThemeData.light().colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.status == AuthStatus.loading ? null : _register,
                  child: auth.status == AuthStatus.loading ? const CircularProgressIndicator() : const Text('Register'),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;
    final registered = await context.read<AuthProvider>().register(
      businessName: businessController.text.trim(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
    );
    if (registered && mounted) Navigator.of(context).pop();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
}