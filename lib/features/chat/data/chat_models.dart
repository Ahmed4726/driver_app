class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isFromMe,
    this.readAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int? ?? 0,
      senderId: json['sender_id'] as int? ?? 0,
      text: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      isFromMe: json['is_from_me'] == true,
      readAt: json['read_at']?.toString(),
    );
  }

  final int id;
  final int senderId;
  final String text;
  final String createdAt;
  final bool isFromMe;
  final String? readAt;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.bookingId,
    required this.driverTripId,
    required this.driverId,
    required this.driverName,
    required this.passengerId,
    required this.passengerName,
    required this.messages,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => ChatMessageModel.fromJson(Map<String, dynamic>.from(entry)))
        .toList();

    return ChatConversation(
      id: json['id'] as int? ?? 0,
      bookingId: json['booking_id'] as int? ?? 0,
      driverTripId: json['driver_trip_id'] as int? ?? 0,
      driverId: (json['driver'] as Map?)?['id'] as int? ?? 0,
      driverName: (json['driver'] as Map?)?['name']?.toString() ?? 'Driver',
      passengerId: (json['passenger'] as Map?)?['id'] as int? ?? 0,
      passengerName: (json['passenger'] as Map?)?['name']?.toString() ?? 'Passenger',
      messages: messages,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final int id;
  final int bookingId;
  final int driverTripId;
  final int driverId;
  final String driverName;
  final int passengerId;
  final String passengerName;
  final List<ChatMessageModel> messages;
  final int unreadCount;
}
