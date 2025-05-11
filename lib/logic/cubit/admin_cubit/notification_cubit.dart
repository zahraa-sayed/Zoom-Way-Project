import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zoom_way/data/api/admin_api_service.dart';

class Notification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  Notification({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      type: json['type'],
      data: json['data'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
    );
  }
}

class NotificationState {
  final List<Notification> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });
}

class NotificationCubit extends Cubit<NotificationState> {
  final AdminApiService _apiService = AdminApiService();

  NotificationCubit() : super(NotificationState());

  Future<void> loadNotifications() async {
    emit(NotificationState(isLoading: true));
    try {
      final response = await _apiService.getNotifications();

      if (response['success'] == true && response['data'] != null) {
        final List<Notification> notifications = (response['data'] as List)
            .map((notification) => Notification.fromJson(notification))
            .toList();

        emit(NotificationState(notifications: notifications));
        debugPrint('Notifications loaded successfully: $notifications');
      } else {
        emit(NotificationState(error: 'Failed to load notifications'));
        debugPrint('Failed to load notifications: $response');
      }
    } catch (e) {
      print('Error loading notifications: $e');
      emit(NotificationState(error: 'Failed to load notifications'));
    }
  }
}
