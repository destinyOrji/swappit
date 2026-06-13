import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _api = ApiService();
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final res = await _api.getChats();
      setState(() {
        _chats = res['chats'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Messages',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _chats.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadChats,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _chats.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) => _ChatTile(chat: _chats[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Accept a trade and start chatting\nwith your swap partner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final photo = chat['other_user_photo'];
    final name = chat['other_user_name'] ?? 'User';
    final message = chat['message'] ?? '';
    final unread = chat['unread_count'] ?? 0;
    final createdAt = DateTime.tryParse(chat['created_at'] ?? '') ?? DateTime.now();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: photo != null
            ? CachedNetworkImage(
                imageUrl: photo,
                width: 52,
                height: 52,
                fit: BoxFit.cover)
            : Container(
                width: 52,
                height: 52,
                color: AppColors.primarySurface,
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 26)),
      ),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary)),
      subtitle: Text(message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeago.format(createdAt),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('$unread',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      onTap: () {},
    );
  }
}
