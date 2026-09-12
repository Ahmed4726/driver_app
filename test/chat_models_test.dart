import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/features/chat/data/chat_models.dart';

void main() {
  test('driver chat conversation parses backend payload into in-app message model', () {
    final conversation = ChatConversation.fromJson({
      'id': 9,
      'booking_id': 88,
      'driver_trip_id': 12,
      'driver': {'id': 5, 'name': 'Ali Driver'},
      'passenger': {'id': 3, 'name': 'Hira'},
      'messages': [
        {
          'id': 201,
          'sender_id': 3,
          'message': 'Please wait at stop 2.',
          'read_at': null,
          'created_at': '2026-09-11T09:35:00Z',
          'is_from_me': false,
        },
      ],
      'unread_count': 1,
    });

    expect(conversation.id, 9);
    expect(conversation.messages.length, 1);
    expect(conversation.messages.first.text, 'Please wait at stop 2.');
    expect(conversation.messages.first.isFromMe, isFalse);
    expect(conversation.unreadCount, 1);
  });
}
