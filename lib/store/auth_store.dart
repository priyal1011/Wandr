import 'package:flutter/material.dart';
import '../models/user_model.dart';

mixin AuthStore on ChangeNotifier {
  UserModel? currentUser;
  
  void setUser(UserModel? user) {
    currentUser = user;
    notifyListeners();
  }
}
