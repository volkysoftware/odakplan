import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/settings_state.dart';
import 'package:odakplan/app/state/selection_state.dart';

import 'state/today_plan_notifier.dart';
import 'widgets/plan_item_card.dart';
import 'models/activity_plan.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final target = ref.watch(dailyTargetProvider);
    final minutesMap = ref.watch(dailyMinutesMapProvider);
    final todayTotal = _getTodayMinutes(minutesMap);

    final plans = ref.watch(todayPlanProvider);
    final selectedId = ref.watch(selectedPlanIdProvider);

    final progress = target <= 0 ? 0.0 : (todayTotal / target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Hedefi düzenle',
            onPressed: () => _editTarget(context, ref, initial: target),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPlan(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          _HeaderCard(
            todayTotal: todayTotal,
            target: target,
            progress: progress,
            onEditTarget: () => _editTarget(context, ref, initial: target),
            onStartFocus: () => context.go('/focus'),
          ),
          const SizedBox(height: 16),

          _SectionTitle(
            title: 'Plan Kartları',
            subtitle: 'Seç → odakta tek tık başla (uzun bas: düzenle/sil)',
            trailing: TextButton.icon(
              onPressed: () => _addPlan(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ekle'),
            ),
          ),
          const SizedBox(height: 10),

          if (plans.isEmpty)
            _EmptyPlans(
              onAdd: () => _addPlan(context, ref),
            )
          else
            ...plans.map((p) {
              final isSelected = p.id == selectedId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlanItemCard(
                  title: p.title,
                  minutes: p.minutes,
                  selected: isSelected,
                  onTap: () {
                    // Seçili planı Odak sayfasına taşır (Focus bunu okuyor)
                    ref.read(selectedPlanIdProvider.notifier).state = p.id;
                    ref.read(selectedPlanNameProvider.notifier).state = p.title;
                    ref.read(selectedPlanMinutesProvider.notifier).state =
                        p.minutes;

                    // Mini feedback
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Seçildi: ${p.title} • ${p.minutes} dk'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                    context.go('/focus');

                  },
                  onLongPress: () => _showPlanActions(context, ref, p),
                ),
              );
            }),
        ],
      ),
    );
  }

  int _getTodayMinutes(Map<String, int> map) {
    // senin history_state formatına uyumlu olsun diye birkaç key deniyoruz
    if (map.containsKey('today')) return map['today'] ?? 0;

    final now = DateTime.now();
    final dash =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final compact =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    if (map.containsKey(dash)) return map[dash] ?? 0;
    if (map.containsKey(compact)) return map[compact] ?? 0;

    // son çare: benzer key
    for (final e in map.entries) {
      if (e.key.contains(dash) || e.key.contains(compact)) return e.value;
    }
    return 0;
  }

  Future<void> _showPlanActions(
      BuildContext context, WidgetRef ref, ActivityPlan plan) async {
    final action = await showModalBottomSheet<_PlanAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  plan.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Hedef: ${plan.minutes} dk'),
                leading: const Icon(Icons.view_agenda_rounded),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Düzenle'),
                onTap: () => Navigator.pop(ctx, _PlanAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Sil'),
                onTap: () => Navigator.pop(ctx, _PlanAction.delete),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    if (action == _PlanAction.edit) {
      await _editPlan(context, ref, plan);
      return;
    }

    if (action == _PlanAction.delete) {
      final ok = await _confirmDelete(context, plan.title);
      if (!ok) return;

      // seçili plan silinirse seçimi temizle
      final selectedId = ref.read(selectedPlanIdProvider);
      if (selectedId == plan.id) {
        ref.read(selectedPlanIdProvider.notifier).state = null;
        ref.read(selectedPlanNameProvider.notifier).state = null;
        ref.read(selectedPlanMinutesProvider.notifier).state = null;
      }

      await ref.read(todayPlanProvider.notifier).deletePlan(plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan silindi')),
        );
      }
    }
  }

  Future<void> _addPlan(BuildContext context, WidgetRef ref) async {
    final r = await _showPlanEditor(context, title: '', minutes: 25);
    if (r == null) return;

    await ref.read(todayPlanProvider.notifier).addPlan(r.title, r.minutes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan eklendi')),
      );
    }
  }

  Future<void> _editPlan(
      BuildContext context, WidgetRef ref, ActivityPlan plan) async {
    final r = await _showPlanEditor(
      context,
      title: plan.title,
      minutes: plan.minutes,
    );
    if (r == null) return;

    await ref
        .read(todayPlanProvider.notifier)
        .updatePlan(plan.id, r.title, r.minutes);

    // seçili plan güncellendiyse selection provider'larını da güncelle
    final selectedId = ref.read(selectedPlanIdProvider);
    if (selectedId == plan.id) {
      ref.read(selectedPlanNameProvider.notifier).state = r.title;
      ref.read(selectedPlanMinutesProvider.notifier).state = r.minutes;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan güncellendi')),
      );
    }
  }

  Future<void> _editTarget(BuildContext context, WidgetRef ref,
      {required int initial}) async {
    final theme = Theme.of(context);

    int temp = initial <= 0 ? 60 : initial;

    final newTarget = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Günlük hedef (dk)'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$temp dk',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: temp.toDouble(),
                    min: 5,
                    max: 300,
                    divisions: 59,
                    label: '$temp',
                    onChanged: (v) => setState(() => temp = v.round()),
                  ),
                  Text(
                    'İpucu: Orta seviye hedef 60–120 dk',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (newTarget == null) return;

    // settings_state içindeki notifier fonksiyonun farklı ise burada sadece state set edeceğiz
    // (senin projende provider StateNotifier olabilir; iki ihtimali de güvenli yönetiyoruz)
    try {
      // Eğer notifier'da setTarget varsa:
      ref.read(dailyTargetProvider.notifier).setTarget(newTarget);
    } catch (_) {
      // Değilse: direkt state
      ref.read(dailyTargetProvider.notifier).state = newTarget;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni hedef: $newTarget dk')),
      );
    }
  }

  Future<_PlanEditResult?> _showPlanEditor(
    BuildContext context, {
    required String title,
    required int minutes,
  }) async {
    final theme = Theme.of(context);

    final titleCtrl = TextEditingController(text: title);
    int tempMin = minutes <= 0 ? 25 : minutes;

    return showModalBottomSheet<_PlanEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.isEmpty ? 'Yeni Plan' : 'Planı Düzenle',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Plan adı',
                  hintText: 'Örn: Ders Çalışma',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Süre: $tempMin dk',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (tempMin > 5) tempMin -= 5;
                      (ctx as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      if (tempMin < 300) tempMin += 5;
                      (ctx as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              Slider(
                value: tempMin.toDouble(),
                min: 10,
                max: 300,
                divisions: 58,
                label: '$tempMin',
                onChanged: (v) {
                  tempMin = v.round();
                  (ctx as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        if (t.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plan adı boş olamaz')),
                          );
                          return;
                        }
                        Navigator.pop(ctx, _PlanEditResult(t, tempMin));
                      },
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan silinsin mi?'),
        content: Text('“$title” planını silmek üzeresin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

enum _PlanAction { edit, delete }

class _PlanEditResult {
  final String title;
  final int minutes;
  _PlanEditResult(this.title, this.minutes);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int todayTotal;
  final int target;
  final double progress;
  final VoidCallback onEditTarget;
  final VoidCallback onStartFocus;

  const _HeaderCard({
    required this.todayTotal,
    required this.target,
    required this.progress,
    required this.onEditTarget,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final left = target <= 0 ? 0 : (target - todayTotal);
    final leftText = target <= 0
        ? 'Hedef belirle'
        : left <= 0
            ? 'Hedef tamam 🎉'
            : '$left dk kaldı';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _ProgressRing(
            progress: progress,
            centerTop: '$todayTotal',
            centerBottom: 'dk',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün hedefin',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  target <= 0 ? '—' : '$target dk',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leftText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditTarget,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Hedef'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStartFocus,
                        icon: const Icon(Icons.timer_rounded),
                        label: const Text('Odak'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String centerTop;
  final String centerBottom;

  const _ProgressRing({
    required this.progress,
    required this.centerTop,
    required this.centerBottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                centerBottom,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPlans({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.view_agenda_outlined,
            size: 34,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'Henüz plan yok',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plan kartları ekleyip tek dokunuşla odak başlatabilirsin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk Planı Ekle'),
          ),
        ],
      ),
    );
  }
}
