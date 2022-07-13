import 'package:json_annotation/json_annotation.dart';
import 'package:maxilozoz_box/modules/storage/sqlite/build/annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart' as e;
import 'package:build/build.dart';
import 'package:path/path.dart' as Path;
const _coreDBPKChecker = const TypeChecker.fromRuntime(DBPKAnnotation);
const _coreJSONKeyChecker = const TypeChecker.fromRuntime(JsonKey);
class DBGenerator extends GeneratorForAnnotation<DBAnnotation> {
  @override
  generateForAnnotatedElement(e.Element element, ConstantReader annotation, BuildStep buildStep) {
    return '''
part of '${Path.basename(buildStep.inputId.path)}';

class ${element.name}JSONHelp {
  static ${element.name} fromJson(Map<String, dynamic> json) => _\$${element.name}FromJson(json);
  static Map<String, dynamic> toJson(${element.name} obj) => _\$${element.name}ToJson(obj);
}

class ${element.name}Client {
  Database db;
  ${element.name}Client(this.db);

  ${analyseElement(element)}
}
''';
  }

  String analyseElement(e.Element element) {
    switch (element.kind) {
      case e.ElementKind.CLASS:
        return _analyseElementForClass(element as e.ClassElement);
      case e.ElementKind.FUNCTION:
      default:
        return "";
    }
  }

  String _analyseElementForClass(e.ClassElement classElement) {
    var fieldStr = '''

  Future<List<${classElement.name}>>all() async {
    return (await db.rawQuery("select * from \$dbTable"))
      .map((e) => ${classElement.name}JSONHelp.fromJson(e)).toList();
  }

  Future<int>insert(${classElement.name} obj) async {
    return await db.insert(dbTable, ${classElement.name}JSONHelp.toJson(obj));
  }

  Future<int>updateWhere(${classElement.name} obj, String? where, List<Object?>? whereArgs) async {
    return await db.update(dbTable, ${classElement.name}JSONHelp.toJson(obj), where: where, whereArgs: whereArgs);
  }
''';

    var hasPK = false;
    var schema = "";
    for (var e in classElement.fields) {
      var dbFieldName = e.name;
      var dbFieldVarName = "${e.name}\Field";
      if (_coreJSONKeyChecker.hasAnnotationOfExact(e)) {
        dbFieldName = _coreJSONKeyChecker.firstAnnotationOfExact(e)!.getField("name")!.toStringValue()!;
      }

      if (!hasPK && _coreDBPKChecker.hasAnnotationOfExact(e)) {
        hasPK = true;
        fieldStr += '''
  Future<int>delete(${e.type} ${e.name}) async {
    return await db.rawDelete("delete from \$dbTable where \$$dbFieldVarName = ?", [${e.name}]);
  }

  Future<int>update(${e.type} ${e.name}, ${classElement.name} obj) async {
    return await updateWhere(obj, "\$$dbFieldVarName = ?", [${e.name}]);
  }

  Future<${classElement.name}?>first(${e.type} ${e.name}) async {
    //ignore more rows
    var rows = await db.rawQuery("select * from \$dbTable where \$$dbFieldVarName = ? limit 1", [${e.name}]);
    if(rows.isEmpty) {
      return null;
    }

    return ${classElement.name}JSONHelp.fromJson(rows[0]);
  }
''';
      }
      
      fieldStr += '''
  static const $dbFieldVarName = "$dbFieldName";
''';
      schema += '''
  \$$dbFieldVarName ${e.type.isDartCoreString ? "TEXT" : "INTEGER"};
  ''';
    }

    fieldStr += '''
  static const dbTable = "${classElement.name}";
  static const dbSchema = \'''
  create table \$dbTable (
  $schema
  );
  \''';
''';
    return fieldStr;
  }
}