import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:odakplan/app/notifications/notification_service.dart';
import 'package:odakplan/app/state/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _boxName = 'op_settings';

  static const _kThemeMode = 'theme_mode'; // system/light/dark
  static const _kSoftTheme = 'soft_theme'; // bool
  static const _kReminderEnabled = 'reminder_enabled';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kReminderDays = 'reminder_days'; // List<int> (1..7)
  static const _kReminderStyle = 'reminder_style'; // 0/1/2

  Box<dynamic>? _box;
  bool _loading = true;

  ThemeMode _themeMode = ThemeMode.system;
  bool _softTheme = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  Set<int> _days = {1, 2, 3, 4, 5};
  int _styleIndex = 1;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }

      _themeMode =
          _decodeThemeMode(_box!.get(_kThemeMode, defaultValue: 'system'));
      _softTheme = _box!.get(_kSoftTheme, defaultValue: false) as bool;
      _reminderEnabled =
          _box!.get(_kReminderEnabled, defaultValue: false) as bool;

      final hour = (_box!.get(_kReminderHour, defaultValue: 20) as int);
      final minute = (_box!.get(_kReminderMinute, defaultValue: 0) as int);
      _reminderTime = TimeOfDay(
        hour: hour.clamp(0, 23),
        minute: minute.clamp(0, 59),
      );

      final storedDays = _box!.get(_kReminderDays);
      if (storedDays is List) {
        final parsed = storedDays
            .whereType<int>()
            .where((d) => d >= 1 && d <= 7)
            .toSet();
        if (parsed.isNotEmpty) _days = parsed;
      }

      _styleIndex =
          (_box!.get(_kReminderStyle, defaultValue: 1) as int).clamp(0, 2);

      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box?.put(_kThemeMode, _encodeThemeMode(mode));
    if (mounted) setState(() {});
  }

  Future<void> _saveSoftTheme(bool value) async {
    _softTheme = value;
    await _box?.put(_kSoftTheme, value);
    if (mounted) setState(() {});
  }

  Future<void> _saveReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    await _box?.put(_kReminderEnabled, enabled);

    if (enabled) {
      // ✅ izin iste + schedule
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        _reminderEnabled = false;
        await _box?.put(_kReminderEnabled, false);
        if (mounted) {
          setState(() {});
          _snack(context, 'Bildirim izni verilmedi. Ayarlardan izin ver ✅');
        }
        return;
      }
      await _applyReminderSchedule();
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveReminderTime(TimeOfDay t) async {
    _reminderTime = t;
    await _box?.put(_kReminderHour, t.hour);
    await _box?.put(_kReminderMinute, t.minute);

    if (_reminderEnabled) {
      await _applyReminderSchedule();
      if (mounted) _snack(context, 'Hatırlatıcı saati güncellendi ✅');
    } else {
      // Kapalıysa sadece kaydet, açınca çalışır
      if (mounted) _snack(context, 'Saat kaydedildi. Hatırlatıcıyı açınca çalışır ✅');
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveDays(Set<int> days) async {
    _days = days.isEmpty ? {1, 2, 3, 4, 5} : days;
    await _box?.put(_kReminderDays, _days.toList()..sort());

    // Not: Şu an schedule "her gün" çalışıyor (DateTimeComponents.time).
    // Gün bazlı yapmak istersen sonra ekleriz.
    if (mounted) setState(() {});
  }

  Future<void> _saveStyle(int index) async {
    _styleIndex = index.clamp(0, 2);
    await _box?.put(_kReminderStyle, _styleIndex);
    if (_reminderEnabled) await _applyReminderSchedule();
    if (mounted) setState(() {});
  }

  Future<void> _applyReminderSchedule() async {
    final text = _styleText(_styleIndex);
    await NotificationService.instance.scheduleDailyReminder(
      _reminderTime,
      title: 'OdakPlan',
      body: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeaderCard(
              themeMode: _themeMode,
              softTheme: _softTheme,
              reminderEnabled: _reminderEnabled,
              reminderTime: _reminderTime,
            ),
            const SizedBox(height: 16),

            _sectionTitle(context, 'Görünüm'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: const Text('Tema',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sistem / Açık / Koyu',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          _ThemeModeChips(
                            value: _themeMode,
                            onChanged: _saveThemeMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsSwitchTile(
                    icon: Icons.tonality_outlined,
                    title: 'Soft Tema',
                    subtitle: 'Göz yormayan, yumuşak renkler',
                    value: _softTheme,
                    onChanged: _saveSoftTheme,
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.text_fields_outlined,
                    title: 'Arayüz yoğunluğu',
                    subtitle: 'Sade ve ferah görünüm',
                    onTap: () =>
                        _snack(context, 'Arayüz sadeleştirme zaten aktif ✅'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Bildirimler'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Günlük hatırlatıcı',
                    subtitle: _reminderEnabled
                        ? 'Açık • ${_reminderTime.format(context)}'
                        : 'Kapalı',
                    value: _reminderEnabled,
                    onChanged: _saveReminderEnabled,
                  ),
                  const Divider(height: 1),

                  // ✅ KRİTİK: Saat seçimi her zaman aktif (kapalıyken de seçilebilir)
                  _SettingsTile(
                    icon: Icons.schedule_outlined,
                    title: 'Bildirim saati',
                    subtitle: _reminderEnabled
                        ? 'Hatırlatma saati'
                        : 'Hatırlatıcı kapalı (saati yine de seçebilirsin)',
                    trailing: _Pill(text: _reminderTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (picked != null) await _saveReminderTime(picked);
                    },
                  ),

                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.date_range_outlined,
                    title: 'Gün seçimi',
                    subtitle: 'Hangi günlerde hatırlatsın?',
                    trailing: _Pill(text: _daysLabel(_days)),
                    onTap: () async {
                      final result = await showModalBottomSheet<Set<int>>(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => _DaysPickerSheet(initial: _days),
                      );
                      if (result != null) await _saveDays(result);
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Mesaj stili',
                    subtitle: _styleName(_styleIndex),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final res = await showModalBottomSheet<int>(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => _StylePickerSheet(selected: _styleIndex),
                      );
                      if (res != null) await _saveStyle(res);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Odak'),
            const SizedBox(height: 8),
            _BreakDurationCard(),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Veri ve Güvenlik'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.restart_alt_outlined,
                    title: 'Ayarları sıfırla',
                    subtitle: 'Tema ve bildirim ayarlarını sıfırlar',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _confirmReset(context),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Sürüm',
                    subtitle: 'OdakPlan • yerel depolama',
                    trailing: const _Pill(text: 'v1'),
                    onTap: () => _snack(context, 'Yakında: yedekleme/dışa aktarma 💾'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Center(
              child: Text(
                'Sade • Hızlı',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(.7),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ayarları sıfırla?'),
        content: const Text('Tema ve bildirim tercihleri varsayılanlara dönecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sıfırla')),
        ],
      ),
    );

    if (ok != true) return;

    await _box?.put(_kThemeMode, 'system');
    await _box?.put(_kSoftTheme, false);
    await _box?.put(_kReminderEnabled, false);
    await _box?.put(_kReminderHour, 20);
    await _box?.put(_kReminderMinute, 0);
    await _box?.put(_kReminderDays, <int>[1, 2, 3, 4, 5]);
    await _box?.put(_kReminderStyle, 1);

    await NotificationService.instance.cancelDailyReminder();

    _themeMode = ThemeMode.system;
    _softTheme = false;
    _reminderEnabled = false;
    _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    _days = {1, 2, 3, 4, 5};
    _styleIndex = 1;

    if (mounted) setState(() {});
    if (mounted) _snack(context, 'Ayarlar sıfırlandı ✅');
  }

  static Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static String _encodeThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  static ThemeMode _decodeThemeMode(dynamic s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  static String _styleName(int i) {
    switch (i) {
      case 0:
        return 'Kısa';
      case 2:
        return 'Disiplin';
      case 1:
      default:
        return 'Motive';
    }
  }

  static String _styleText(int i) {
    switch (i) {
      case 0:
        return 'Bugün 10 dk bile olsa odaklan ✅';
      case 2:
        return 'Odak zamanı. Başla, bitir, kazan 💪';
      case 1:
      default:
        return 'Küçük bir odak, büyük bir ilerleme ✨';
    }
  }

  static String _daysLabel(Set<int> days) {
    if (days.length >= 7) return 'Her gün';
    const names = {1: 'Pzt', 2: 'Sal', 3: 'Çar', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz'};
    final sorted = days.toList()..sort();
    return sorted.map((d) => names[d] ?? '?').join(', ');
  }
}

class _HeaderCard extends StatelessWidget {
  final ThemeMode themeMode;
  final bool softTheme;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  const _HeaderCard({
    required this.themeMode,
    required this.softTheme,
    required this.reminderEnabled,
    required this.reminderTime,
  });

  @override
  Widget build(BuildContext context) {
    final modeText = switch (themeMode) {
      ThemeMode.system => 'Sistem',
      ThemeMode.light => 'Açık',
      ThemeMode.dark => 'Koyu',
    };

    final remindText = reminderEnabled ? reminderTime.format(context) : 'Kapalı';

    final themeLabel = softTheme ? '$modeText • Soft' : modeText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.5)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary.withOpacity(.12),
            ),
            child: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OdakPlan Ayarları',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tema: $themeLabel • Bildirim: $remindText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(.75),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.5)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor;

    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: fg),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: enabled ? onTap : null,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(.12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeModeChips extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Sistem'),
          selected: value == ThemeMode.system,
          onSelected: (_) => onChanged(ThemeMode.system),
        ),
        ChoiceChip(
          label: const Text('Açık'),
          selected: value == ThemeMode.light,
          onSelected: (_) => onChanged(ThemeMode.light),
        ),
        ChoiceChip(
          label: const Text('Koyu'),
          selected: value == ThemeMode.dark,
          onSelected: (_) => onChanged(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _DaysPickerSheet extends StatefulWidget {
  final Set<int> initial;
  const _DaysPickerSheet({required this.initial});

  @override
  State<_DaysPickerSheet> createState() => _DaysPickerSheetState();
}

class _DaysPickerSheetState extends State<_DaysPickerSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    const items = <int, String>{
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Gün seçimi',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => _selected = {1, 2, 3, 4, 5, 6, 7}),
                  child: const Text('Hepsi'),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _selected = {1, 2, 3, 4, 5}),
                  child: const Text('Hafta içi'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ✅ Kaydırılabilir alanın içinde listeyi güvenli şekilde göster
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items.entries.map((e) {
                final checked = _selected.contains(e.key);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(e.key);
                      } else {
                        _selected.remove(e.key);
                      }
                    });
                  },
                  title: Text(e.value),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _StylePickerSheet extends StatelessWidget {
  final int selected;
  const _StylePickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Kısa', 'Bugün 10 dk bile olsa odaklan ✅', Icons.short_text),
      ('Motive', 'Küçük bir odak, büyük bir ilerleme ✨', Icons.auto_awesome),
      ('Disiplin', 'Odak zamanı. Başla, bitir, kazan 💪', Icons.fitness_center),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Mesaj stili',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++)
              ListTile(
                leading: Icon(items[i].$3),
                title: Text(items[i].$1,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(items[i].$2),
                trailing: selected == i ? const Icon(Icons.check_circle) : null,
                onTap: () => Navigator.pop(context, i),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BreakDurationCard extends ConsumerWidget {
  const _BreakDurationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakMinutes = ref.watch(breakMinutesProvider);

    return _SettingsCard(
      child: _SettingsTile(
        icon: Icons.timer_outlined,
        title: 'Mola süresi',
        subtitle: 'Mola modunda kullanılacak süre',
        trailing: _Pill(text: '$breakMinutes dk'),
        onTap: () async {
          final result = await showModalBottomSheet<int>(
            context: context,
            showDragHandle: true,
            builder: (_) => _BreakDurationPickerSheet(selected: breakMinutes),
          );
          if (result != null) {
            ref.read(breakMinutesProvider.notifier).setBreakMinutes(result);
          }
        },
      ),
    );
  }
}

class _BreakDurationPickerSheet extends StatelessWidget {
  final int selected;
  const _BreakDurationPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Mola süresi',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: 30,
                itemBuilder: (context, index) {
                  final minutes = index + 1;
                  final isSelected = minutes == selected;
                  return ListTile(
                    title: Text(
                      '$minutes dk',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle) : null,
                    onTap: () => Navigator.pop(context, minutes),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
