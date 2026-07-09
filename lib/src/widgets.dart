import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/theme.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: const Color(0xFFFFF2D5),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Mode démonstration — API mobile à connecter')),
        ],
      ),
    );
  }
}

class PatientTopBar extends StatelessWidget {
  const PatientTopBar({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Text(
                  "Gab'Pharma",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: GabColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  icon: const Badge(child: Icon(Icons.notifications_outlined)),
                  color: GabColors.primary,
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSwitchTab(4),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: GabColors.primary,
                    child: Text(
                      'GN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: GabColors.outlineVariant),
        ],
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = GabColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: GabColors.secondary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
