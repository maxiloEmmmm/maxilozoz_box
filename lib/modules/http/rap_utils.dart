import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
class RapUtils {
  int functionNums = 0;
  List apis = [];
  void loadJsonFile() async {
    String jsonStr = await rootBundle.loadString('lib/rap.json');
    Map<String, dynamic> rapInfo = jsonDecode(jsonStr);
    rapInfo['data']['modules'].forEach((element) {
      String groupName = element['name'];
      element['interfaces'].forEach((api) {
        bool isReg = api['url'].startsWith('reg:');
        apis.add({
          'groupName': groupName,
          'apiName': api['name'],
          'reg': isReg,
          'url': isReg ? api['url'].substring(4) : api['url'],
          'method': api['method'],
          'properties': api['properties'],
          'id': api['id'],
          'parentId': api['parentId'],
          'isFunction': false
        });
      });
    });
  }

  dynamic tryProxy(path, method){
    Map api = apis.firstWhere((element) {
      if(element['reg']) {
        RegExp reg = new RegExp('^'+element['url']+'\$');
        return reg.hasMatch(path);
      }else if(path == element['url'] && method.toLowerCase() == element['method'].toLowerCase()) {
        return true;
      }else {
        return false;
      }
    }, orElse: (){});

    if(api != null){
      if(api['isFunction']) {
        //TODO: input params inject.
        return api['handle']({});
      }
      return makeData(api['properties'].where((element) => element['scope'] == 'response').toList());
    }else {
      return false;
    }
  }

  dynamic makeData(List properties, {int parentId = -1}){
    Map data = {};
    List propertiesCopy = List.from(properties);
    int len = properties.length;
    int removeCount = 0;
    for(int i = 0; i < len; i++) {
      Map v = properties[i];

      if(v['parentId'] == parentId) {
        propertiesCopy.removeAt(i - removeCount);
        removeCount++;
        String type = v['type'];
        String rule = v['rule'] == null || v['rule'] == '' ? '0' : v['rule'];
        dynamic index = v['name'];
        switch(type) {
          case 'Boolean': {
            data[index] = Random().nextInt(1) > 0;
          }break;
          case 'Number': {
            if(rule.contains('-')) {
              List ranges = rule.split('-');
              int min = int.parse(ranges[0]);
              int max = int.parse(ranges[1]);
              data[index] = min + Random().nextInt(max - min >= 1 ? max - min : 1);
            }else {
              int iRule = int.parse(rule);
              data[index] = iRule >= 1 ? Random().nextInt(iRule) : iRule;
            }
          }break;
          case 'String': {
            List set = ['a', 'b', 'c', 'd', 'e', 'f', 
              'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
              'o', 'p', 'p', 'q', 'r', 't', 'u', 'v',
              'w', 'x', 'y', 'z', '0', '1', '2', '3',
              '4', '5', '6', '7', '8', '9'];
            int nums;
            if(rule.contains('-')) {
              List ranges = rule.split('-');
              int min = int.parse(ranges[0]);
              int max = int.parse(ranges[1]);
              nums = min + Random().nextInt(max - min >= 1 ? max - min : 1);
            }else {
              int iRule = int.parse(rule);
              nums = iRule >= 1 ? Random().nextInt(iRule) : iRule;
            }
            data[index] = List.generate(nums, (index){
              return set[Random().nextInt(35)];
            }).join();
          }break;
          case 'Array': {
            int nums;
            if(rule.contains('-')) {
              List ranges = rule.split('-');
              int min = int.parse(ranges[0]);
              int max = int.parse(ranges[1]);
              nums = min + Random().nextInt(max - min >= 1 ? max - min : 1);
            }else {
              int iRule = int.parse(rule);
              nums = iRule >= 1 ? Random().nextInt(iRule) : iRule;
            }

            List items = [];
            for(int aIndex = 0; aIndex < nums; aIndex++) {
              items.add(makeData(propertiesCopy, parentId: v['id']));
            }
            data[index] = items;
          }break;
          case 'Object': {
            data[index] = makeData(propertiesCopy, parentId: v['id']);
          }break;
        }
      }
    }
    return data;
  }

  void proxyFunction(path, method, name, dynamic Function(Map params) func){
    functionNums++;
    bool isReg = path.startsWith('reg:');
    apis.add({
      'groupName': '自定义rap函数配置',
      'apiName': name,
      'reg': isReg,
      'url': isReg ? path.substring(4) : path,
      'method': method,
      'id': 999999999 + functionNums,
      'parentId': -1,
      'isFunction': true,
      'handle': func
    });
  }
}