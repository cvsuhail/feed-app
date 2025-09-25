class FeedModel {
  final String id;
  final String thumbnail;
  final String video;
  final String description;
  final UserDetails userDetails;
  final String createdAt;
  final int likes;
  final int comments;
  final List<String> categories;

  const FeedModel({
    required this.id,
    required this.thumbnail,
    required this.video,
    required this.description,
    required this.userDetails,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.categories,
  });

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    // Handle likes as array of user IDs - count the length
    int likesCount = 0;
    if (json['likes'] is List) {
      likesCount = (json['likes'] as List).length;
    } else if (json['likes'] is int) {
      likesCount = json['likes'] as int;
    }

    return FeedModel(
      id: json['id']?.toString() ?? '',
      thumbnail: json['image']?.toString() ?? json['thumbnail']?.toString() ?? '',
      video: json['video']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      userDetails: UserDetails.fromJson(json['user'] ?? json['user_details'] ?? {}),
      createdAt: json['created_at']?.toString() ?? '',
      likes: likesCount,
      comments: 0, // API doesn't provide comments count, setting to 0
      categories: [], // API doesn't provide categories for individual feeds
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thumbnail': thumbnail,
      'video': video,
      'description': description,
      'user': userDetails.toJson(),
      'created_at': createdAt,
      'likes': likes,
      'comments': comments,
      'categories': categories,
    };
  }

  FeedModel copyWith({
    String? id,
    String? thumbnail,
    String? video,
    String? description,
    UserDetails? userDetails,
    String? createdAt,
    int? likes,
    int? comments,
    List<String>? categories,
  }) {
    return FeedModel(
      id: id ?? this.id,
      thumbnail: thumbnail ?? this.thumbnail,
      video: video ?? this.video,
      description: description ?? this.description,
      userDetails: userDetails ?? this.userDetails,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      categories: categories ?? this.categories,
    );
  }

  @override
  String toString() {
    return 'FeedModel(id: $id, thumbnail: $thumbnail, video: $video, description: $description, userDetails: $userDetails, createdAt: $createdAt, likes: $likes, comments: $comments, categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedModel &&
        other.id == id &&
        other.thumbnail == thumbnail &&
        other.video == video &&
        other.description == description &&
        other.userDetails == userDetails &&
        other.createdAt == createdAt &&
        other.likes == likes &&
        other.comments == comments &&
        other.categories == categories;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        thumbnail.hashCode ^
        video.hashCode ^
        description.hashCode ^
        userDetails.hashCode ^
        createdAt.hashCode ^
        likes.hashCode ^
        comments.hashCode ^
        categories.hashCode;
  }
}

class UserDetails {
  final String id;
  final String name;
  final String avatar;
  final String username;

  const UserDetails({
    required this.id,
    required this.name,
    required this.avatar,
    required this.username,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    // Handle null/empty profile images with default avatar
    String avatar = json['image']?.toString() ?? json['avatar']?.toString() ?? '';
    if (avatar.isEmpty || avatar == 'null') {
      avatar = 'assets/images/avatar.png'; // Default avatar
    }
    
    return UserDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      avatar: avatar,
      username: json['username']?.toString() ?? json['name']?.toString() ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'username': username,
    };
  }

  UserDetails copyWith({
    String? id,
    String? name,
    String? avatar,
    String? username,
  }) {
    return UserDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
    );
  }

  @override
  String toString() {
    return 'UserDetails(id: $id, name: $name, avatar: $avatar, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDetails &&
        other.id == id &&
        other.name == name &&
        other.avatar == avatar &&
        other.username == username;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ avatar.hashCode ^ username.hashCode;
  }
}
