import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/auth_cubit.dart';

/// Mock login (spec §3A) — email prefilled, any password works.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'aarav@wtf.fit');
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.trainerPrimary,
                foregroundColor: AppColors.white,
                child: Icon(Icons.fitness_center, size: 40),
              ),
              const SizedBox(height: Gap.s24),
              Text('WTF ${AppStrings.trainerBadge}',
                  style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: Gap.s32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: AppStrings.email),
              ),
              const SizedBox(height: Gap.s16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: AppStrings.password),
              ),
              const SizedBox(height: Gap.s24),
              ElevatedButton(
                onPressed: () => context.read<AuthCubit>().login(),
                child: const Text(AppStrings.login),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
