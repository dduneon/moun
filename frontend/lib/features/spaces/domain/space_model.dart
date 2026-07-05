import 'package:flutter/foundation.dart';

@immutable
class SpaceModel {
  const SpaceModel({
    required this.id,
    required this.name,
    required this.baseDay,
    required this.createdByUserId,
    required this.memberCount,
  });

  final int id;
  final String name;
  final int baseDay;
  final int createdByUserId;
  final int memberCount;

  factory SpaceModel.fromJson(Map<String, dynamic> json) => SpaceModel(
        id: json['id'] as int,
        name: json['name'] as String,
        baseDay: json['base_day'] as int,
        createdByUserId: json['created_by_user_id'] as int,
        memberCount: json['member_count'] as int,
      );
}

@immutable
class SpaceInviteModel {
  const SpaceInviteModel({
    required this.token,
    required this.url,
    required this.expiresAt,
  });

  final String token;
  final String url;
  final DateTime expiresAt;

  factory SpaceInviteModel.fromJson(Map<String, dynamic> json) => SpaceInviteModel(
        token: json['token'] as String,
        url: json['url'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

@immutable
class SpaceInvitePreviewModel {
  const SpaceInvitePreviewModel({
    required this.spaceId,
    required this.spaceName,
    required this.memberCount,
    required this.valid,
  });

  final int spaceId;
  final String spaceName;
  final int memberCount;
  final bool valid;

  factory SpaceInvitePreviewModel.fromJson(Map<String, dynamic> json) => SpaceInvitePreviewModel(
        spaceId: json['space_id'] as int,
        spaceName: json['space_name'] as String,
        memberCount: json['member_count'] as int,
        valid: json['valid'] as bool,
      );
}

@immutable
class SpaceMemberModel {
  const SpaceMemberModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.joinedAt,
    required this.isOwner,
  });

  final int userId;
  final String name;
  final String? email;
  final DateTime joinedAt;
  final bool isOwner;

  factory SpaceMemberModel.fromJson(Map<String, dynamic> json) => SpaceMemberModel(
        userId: json['user_id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        isOwner: json['is_owner'] as bool,
      );
}

/// 현재 사용자가 보고 있는 컨텍스트 — 개인 공간 또는 특정 Space.
@immutable
sealed class SpaceContext {
  const SpaceContext();
}

class PersonalContext extends SpaceContext {
  const PersonalContext();
}

class SpaceSelected extends SpaceContext {
  const SpaceSelected(this.space);
  final SpaceModel space;
}
