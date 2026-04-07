// ignore_for_file: experimental_member_api
import 'package:isar/isar.dart';

part 'user_data.g.dart';

@collection
class UserData {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  late String name;
  late String email;
  String? avatarUrl;
  
  bool darkMode = false;
  bool hasSeenOnboarding = false;
  bool rememberMe = false;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.darkMode = false,
    this.hasSeenOnboarding = false,
    this.rememberMe = false,
  });
}
