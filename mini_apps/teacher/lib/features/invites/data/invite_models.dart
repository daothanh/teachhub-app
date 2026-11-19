import 'package:equatable/equatable.dart';

/// Lời mời vừa tạo hoặc gửi lại (schema `InviteCreated`). `url` và `shortCode`
/// chỉ có trong phản hồi này, server không trả lại lần sau.
class InviteLink extends Equatable {
  const InviteLink({
    required this.id,
    required this.guardianId,
    required this.url,
    required this.shortCode,
    required this.expiresAt,
    required this.shortCodeExpiresAt,
  });

  factory InviteLink.fromJson(Map<String, dynamic> json) => InviteLink(
    id: json['id'] as String,
    guardianId: json['guardianId'] as String,
    url: json['url'] as String,
    shortCode: json['shortCode'] as String,
    expiresAt: json['expiresAt'] as String,
    shortCodeExpiresAt: json['shortCodeExpiresAt'] as String,
  );

  final String id;
  final String guardianId;

  /// `https://dayhoc.app/i#t=<token>`; mã QR sinh từ chính chuỗi này.
  final String url;

  /// 8 ký tự Crockford base32, sống 48 giờ.
  final String shortCode;
  final String expiresAt;
  final String shortCodeExpiresAt;

  @override
  List<Object?> get props => [
    id, guardianId, url, shortCode, expiresAt, shortCodeExpiresAt, //
  ];
}
