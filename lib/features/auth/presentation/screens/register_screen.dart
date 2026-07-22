import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/circleveya_brand.dart';
import '../../../../core/icons/company_building_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_screen_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  ProfileAccountType _accountType = ProfileAccountType.standard;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          userType: _accountType.signupValue,
        );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error.toString())),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _accountType.isEventOrganizer
              ? 'Event-Profil erstellt. Bitte bestätige ggf. deine E-Mail und melde dich an.'
              : 'Konto erstellt. Bitte bestätige ggf. deine E-Mail und melde dich an.',
        ),
      ),
    );
    TextInput.finishAutofillContext(shouldSave: true);
    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AuthScreenScaffold(
      showBackButton: true,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CircleVeyaBrand(logoHeight: 44),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.registerTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.brandNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.accountTypeHint,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.brandNavy.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.accountType,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _AccountTypeCard(
              selected: _accountType == ProfileAccountType.standard,
              icon: Icon(
                Icons.person_outline,
                size: 28,
                color: _accountType == ProfileAccountType.standard
                    ? AppColors.seed
                    : theme.colorScheme.onSurface,
              ),
              title: l10n.privatePerson,
              subtitle: l10n.privatePersonDesc,
              onTap: isLoading
                  ? null
                  : () => setState(
                        () => _accountType = ProfileAccountType.standard,
                      ),
            ),
            const SizedBox(height: 10),
            _AccountTypeCard(
              selected: _accountType == ProfileAccountType.event,
              icon: CompanyBuildingIcon(
                size: 28,
                color: _accountType == ProfileAccountType.event
                    ? AppColors.seed
                    : theme.colorScheme.onSurface,
              ),
              title: l10n.eventProfile,
              subtitle: l10n.eventProfileDesc,
              onTap: isLoading
                  ? null
                  : () => setState(
                        () => _accountType = ProfileAccountType.event,
                      ),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _usernameController,
              hintText: _accountType.isEventOrganizer
                  ? l10n.nameOrBrand
                  : l10n.username,
              prefixIcon: Icons.person_outline,
              autofillHints: const [AutofillHints.name, AutofillHints.username],
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nameRequired;
                }
                if (value.trim().length < 3) {
                  return l10n.nameMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailController,
              hintText: l10n.email,
              prefixIcon: Icons.email_outlined,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.emailRequired;
                }
                if (!value.contains('@')) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              hintText: l10n.password,
              prefixIcon: Icons.lock_outline,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordRequired;
                }
                if (value.length < 6) {
                  return l10n.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: _accountType.isEventOrganizer
                  ? l10n.createEventProfile
                  : l10n.registerTitle,
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            AuthFooterLink(
              fullText: l10n.haveAccount,
              onPressed: isLoading ? null : () => context.goNamed('login'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppColors.seed.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.seed
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? AppColors.seed
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
