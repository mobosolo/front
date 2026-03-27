import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/notifications/models/app_notification_model.dart';
import 'package:front/features/notifications/providers/app_notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loading = true;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(appNotificationServiceProvider);
      final data = await service.getNotifications();
      if (!mounted) return;
      setState(() => _notifications = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement notifications: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification notif) async {
    if (notif.isRead) return;
    try {
      final service = ref.read(appNotificationServiceProvider);
      await service.markRead(notif.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.id == notif.id ? AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  data: n.data,
                  isRead: true,
                  createdAt: n.createdAt,
                ) : n)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final service = ref.read(appNotificationServiceProvider);
      await service.markAllRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  data: n.data,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur mise a jour: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final role = authState.user?.role ?? 'CLIENT';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: BottomNav(activeTab: role == 'MERCHANT' ? 'profile' : 'profile', role: role),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? const Center(child: Text('Aucune notification'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final notif = _notifications[index];
                              return _NotificationCard(
                                notification: notif,
                                onTap: () => _markRead(notif),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: _notifications.length,
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _notifications.any((n) => !n.isRead)
          ? FloatingActionButton.extended(
              onPressed: _markAllRead,
              label: const Text('Tout marquer lu'),
              icon: const Icon(Icons.done_all),
            )
          : null,
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
          border: notification.isRead
              ? null
              : Border.all(color: AppTheme.primary.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title ?? 'Notification', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6, top: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $h:$m';
  }
}
