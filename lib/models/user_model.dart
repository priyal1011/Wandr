class UserModel {
  final String id;
  String name;
  String email;
  final String password;
  String? photoUrl;
  String? fluttermojiCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.photoUrl,
    this.fluttermojiCode,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? photoUrl,
    String? fluttermojiCode,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    photoUrl: photoUrl ?? this.photoUrl,
    fluttermojiCode: fluttermojiCode ?? this.fluttermojiCode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'photoUrl': photoUrl,
    'fluttermojiCode': fluttermojiCode,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Explorer',
    email: json['email'] ?? '',
    password: json['password'] ?? '',
    photoUrl: json['photoUrl'],
    fluttermojiCode: json['fluttermojiCode'],
  );
}
