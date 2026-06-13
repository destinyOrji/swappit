class TradeModel {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String? fromName;
  final String? fromPhoto;
  final String? toName;
  final String? toPhoto;
  final String offeredSkill;
  final String requestedSkill;
  final String status;
  final DateTime createdAt;

  TradeModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.fromName,
    this.fromPhoto,
    this.toName,
    this.toPhoto,
    required this.offeredSkill,
    required this.requestedSkill,
    required this.status,
    required this.createdAt,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      fromName: json['from_name'],
      fromPhoto: json['from_photo'],
      toName: json['to_name'],
      toPhoto: json['to_photo'],
      offeredSkill: json['offered_skill'] ?? '',
      requestedSkill: json['requested_skill'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
}

class MessageModel {
  final int id;
  final int? tradeId;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.tradeId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      tradeId: json['trade_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
