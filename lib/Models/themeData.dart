import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserThemeData extends ChangeNotifier {
  SharedPreferences? _prefs;

  UserThemeData() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      notifyListeners();
    });
  }

  bool get updatedValue{
    try{
      return _prefs?.getBool('darkMode') ?? false;
    }catch (e){return false;}
  }

  Future<void> updateTheme(bool newValue) async {
    await _prefs?.setBool('darkMode', newValue);
    notifyListeners();
  }
}

