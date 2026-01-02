class UserModel {
  final int id;
  final String email;
  final String name;
  final String? pictureUrl;

  UserModel({required this.id, required this.email, required this.name, this.pictureUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      pictureUrl: json['pictureUrl'] as String?,
    );
  }
}