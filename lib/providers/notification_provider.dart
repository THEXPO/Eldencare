import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/notification_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    _init();
  }

  List<AppNotification> _notifications = [];
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  NotificationPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved preferences
      final savedPrefs = prefs.getString('eldencare_notification_prefs');
      if (savedPrefs != null) {
        _preferences = NotificationPreferences.fromJson(
          jsonDecode(savedPrefs) as Map<String, dynamic>,
        );
      }

      // Load saved notifications
      final savedNotifs = prefs.getString('eldencare_notifications_cache');
      if (savedNotifs != null) {
        final list = (jsonDecode(savedNotifs) as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _notifications = list;
      } else {
        // Seed initial notifications for demo
        _notifications = [
          AppNotification(
            id: 'notif-1',
            title: 'Morning Medication Due',
            body: 'It is time for your scheduled morning medication (Amlodipine 5 mg).',
            notificationType: 'medication',
            createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
          AppNotification(
            id: 'notif-2',
            title: 'Diet Reminder: Breakfast',
            body: 'Your scheduled meal (Oatmeal with berries) is coming up.',
            notificationType: 'diet',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            readAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          AppNotification(
            id: 'notif-3',
            title: 'Upcoming Clinic Appointment',
            body: 'Appointment with Dr. Sarah Nguyen tomorrow at 10:00 AM.',
            notificationType: 'appointment',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
        await _saveNotifications();
      }
    } catch (e) {
      debugPrint('NotificationProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences(NotificationPreferences next) async {
    _preferences = next;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'eldencare_notification_prefs',
        jsonEncode(next.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  Future<void> addNotification(AppNotification item) async {
    _notifications.insert(0, item);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(readAt: DateTime.now());
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    _notifications = _notifications.map((n) {
      if (!n.isRead) return n.copyWith(readAt: now);
      return n;
    }).toList();
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString('eldencare_notifications_cache', raw);
    } catch (e) {
      debugPrint('Error saving notifications cache: $e');
    }
  }

  void resetForLogout() {
    _notifications = [];
    notifyListeners();
  }
}
