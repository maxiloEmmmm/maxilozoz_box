import 'package:shared_preferences/shared_preferences.dart';

class StoreHelp {
  SharedPreferences? prefs;

  void load() async{
    prefs = await SharedPreferences.getInstance();
  }
}