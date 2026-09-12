import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../bookings/data/driver_booking.dart';
import '../../data/chat_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.booking, required this.tripId});

  final DriverBooking booking;
  final int tripId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatConversation? _conversation;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _loadConversation(silent: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversation({bool silent = false}) async {
    try {
      final response = await DioClient.dio.get('/driver-trips/${widget.tripId}/bookings/${widget.booking.id}/chat');
      final data = response.data is Map ? response.data['data'] : null;
      if (!mounted) return;
      if (data is Map) {
        setState(() {
          _conversation = ChatConversation.fromJson(Map<String, dynamic>.from(data));
          _loading = false;
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
        await _markRead();
      }
    } on DioException catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = error.response?.data['message']?.toString() ?? 'Unable to load chat.';
        });
      }
    }
  }

  Future<void> _markRead() async {
    try {
      await DioClient.dio.post('/driver-trips/${widget.tripId}/bookings/${widget.booking.id}/chat/read');
    } on DioException {
      // ignore read marker errors; conversation still renders.
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await DioClient.dio.post(
        '/driver-trips/${widget.tripId}/bookings/${widget.booking.id}/chat/messages',
        data: {'message': text},
      );
      _controller.clear();
      await _loadConversation();
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.response?.data['message']?.toString() ?? 'Unable to send message.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final messages = conversation?.messages ?? const <ChatMessageModel>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.passengerName ?? 'Passenger chat'),
      ),
      body: _loading && conversation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body.copyWith(color: AppColors.danger),
                    ),
                  ),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('No messages yet. Start the conversation.'),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final message = messages[index];
                            final isMine = message.isFromMe;

                            return Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isMine ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.text,
                                      style: AppTextStyles.body.copyWith(
                                        color: isMine ? AppColors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(message.createdAt),
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 11,
                                        color: isMine ? AppColors.white.withOpacity(0.85) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _sending ? null : _sendMessage,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(56, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(String value) {
    if (value.isEmpty) return 'now';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final formatter = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return formatter;
  }
}
