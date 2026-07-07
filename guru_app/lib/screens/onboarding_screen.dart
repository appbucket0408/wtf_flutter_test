import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/auth_cubit.dart';

/// Two intro slides + DK profile form with trainer picker (spec §3A).
class OnboardingScreen extends StatefulWidget {
  final List<AppUser> trainers;
  const OnboardingScreen({super.key, required this.trainers});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController(text: 'DK');
  String? _selectedTrainerId;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.trainers.isNotEmpty) {
      _selectedTrainerId = widget.trainers.first.id;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() => _pageController.nextPage(
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);

  Widget _slide(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.all(Gap.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.1),
              child: Icon(icon, size: 56, color: AppColors.guruPrimary),
            ),
            const SizedBox(height: Gap.s24),
            Text(title, style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: Gap.s8),
            Text(body,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _profileForm() => Padding(
        padding: const EdgeInsets.all(Gap.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Gap.s24),
            Text(AppStrings.createProfile, style: AppTextStyles.h1),
            const SizedBox(height: Gap.s24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: AppStrings.yourName),
            ),
            const SizedBox(height: Gap.s24),
            Text(AppStrings.chooseTrainer, style: AppTextStyles.h2),
            const SizedBox(height: Gap.s8),
            RadioGroup<String>(
              groupValue: _selectedTrainerId,
              onChanged: (v) => setState(() => _selectedTrainerId = v),
              child: Column(
                children: [
                  for (final t in widget.trainers)
                    Card(
                      child: RadioListTile<String>(
                        value: t.id,
                        title: Text(t.name, style: AppTextStyles.body),
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.trainerPrimary,
                          foregroundColor: AppColors.white,
                          child: Text(t.name.substring(0, 1)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedTrainerId == null
                  ? null
                  : () => context.read<AuthCubit>().completeOnboarding(
                        name: _nameController.text.trim(),
                        trainerId: _selectedTrainerId!,
                      ),
              child: const Text(AppStrings.getStarted),
            ),
            const SizedBox(height: Gap.s16),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _slide(Icons.fitness_center, AppStrings.onboardTitle1,
                      AppStrings.onboardBody1),
                  _slide(Icons.video_chat, AppStrings.onboardTitle2,
                      AppStrings.onboardBody2),
                  _profileForm(),
                ],
              ),
            ),
            if (_page < 2)
              Padding(
                padding: const EdgeInsets.all(Gap.s24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            margin: const EdgeInsets.only(right: Gap.s4),
                            width: i == _page ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? AppColors.guruPrimary
                                  : AppColors.grey300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    TextButton(
                        onPressed: _next, child: const Text(AppStrings.next)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
