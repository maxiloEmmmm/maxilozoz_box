import 'package:shared_preferences/shared_preferences.dart';

class Log {
  void set(String key, String log, {int limit: 200}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> oldLog = prefs.getStringList(key) ?? [];
    oldLog.add(log.toString());
    
    int oLen = oldLog.length;
    if(oLen > limit) {
      oldLog = oldLog.getRange(oLen - limit, oLen) as List<String>;
    }

    prefs.setStringList(key, oldLog);
  }

  Future<List<String>> get(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}