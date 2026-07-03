import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationInterval _selected = NotificationInterval.disabled;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final interval = await NotificationInterval.load();
    if (!mounted) return;
    setState(() {
      _selected = interval;
      _loading = false;
    });
  }

  Future<void> _seleccionar(NotificationInterval interval) async {
    setState(() => _selected = interval);
    await interval.save();

    if (interval != NotificationInterval.disabled) {
      await NotificationService.instance.requestNotificationPermission();
    }

    await NotificationService.instance.schedule(interval);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          interval == NotificationInterval.disabled
              ? 'Notificaciones desactivadas'
              : 'Notificaciones programadas ${interval.label.toLowerCase()}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryFixed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recibirás un recordatorio para mantener tu billetera al día.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSecondaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Frecuencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...NotificationInterval.values.map((interval) {
                  final selected = _selected == interval;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _seleccionar(interval),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryFixed
                              : AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              interval.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    await NotificationService.instance
                        .requestNotificationPermission();
                    await NotificationService.instance.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificación de prueba enviada'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Enviar notificación de prueba'),
                ),
              ],
            ),
    );
  }
}
