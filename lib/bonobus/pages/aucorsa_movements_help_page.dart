import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';

/// Explains, step by step, everything AUCORSA requires before the movement
/// history of a bonobus can be shown inside the app.
class AucorsaMovementsHelpPage extends StatelessWidget {
  static const path = '/aucorsa-movements-help';

  const AucorsaMovementsHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              context.l10n.aucorsaMovementsHelpTitle,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16).copyWith(top: 0),
            sliver: SliverList.list(
              children: [
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Text(
                    context.l10n.aucorsaMovementsHelpIntro,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 24),
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Text(
                    context.l10n.aucorsaMovementsHelpStepsTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 20,
                    children: [
                      _HelpStep(
                        step: 1,
                        title:
                            context.l10n.aucorsaMovementsHelpStepAccountTitle,
                        subtitle: context
                            .l10n
                            .aucorsaMovementsHelpStepAccountSubtitle,
                      ),
                      _HelpStep(
                        step: 2,
                        title:
                            context.l10n.aucorsaMovementsHelpStepActivateTitle,
                        subtitle: context
                            .l10n
                            .aucorsaMovementsHelpStepActivateSubtitle,
                      ),
                      _HelpStep(
                        step: 3,
                        title: context.l10n.aucorsaMovementsHelpStepCardTitle,
                        subtitle:
                            context.l10n.aucorsaMovementsHelpStepCardSubtitle,
                      ),
                      _HelpStep(
                        step: 4,
                        title: context.l10n.aucorsaMovementsHelpStepSignInTitle,
                        subtitle:
                            context.l10n.aucorsaMovementsHelpStepSignInSubtitle,
                      ),
                      _HelpStep(
                        step: 5,
                        title:
                            context.l10n.aucorsaMovementsHelpStepRefreshTitle,
                        subtitle: context
                            .l10n
                            .aucorsaMovementsHelpStepRefreshSubtitle,
                      ),
                    ],
                  ),
                ),
                const SafeArea(top: false, child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single numbered step of the guide, laid out as plain text so the page
/// reads like a document instead of a list of settings.
class _HelpStep extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;

  const _HelpStep({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          '$step.',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
