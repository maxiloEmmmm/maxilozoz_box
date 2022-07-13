import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart' as e;
import 'package:build/build.dart';
import 'package:path/path.dart' as Path;
class DBAnnotation {
  const DBAnnotation();
}

class DBPKAnnotation {
  const DBPKAnnotation();
}
const _coreDBPKChecker = const TypeChecker.fromRuntime(DBPKAnnotation);

class DBGenerator extends GeneratorForAnnotation<DBAnnotation> {
  @override
  generateForAnnotatedElement(e.Element element, ConstantReader annotation, BuildStep buildStep) {
    return '''
part of '${Path.basename(buildStep.inputId.path)}';

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
    return (await db.rawQuery("select * from ${classElement.name}"))
      .map((e) => ${classElement.name}.fromJson(e)).toList();
  }

  Future<int>insert(${classElement.name} obj) async {
    return await db.insert("${classElement.name}", obj.toJson());
  }

  Future<int>updateWhere(${classElement.name} obj, String? where, List<Object?>? whereArgs) async {
    return await db.update("${classElement.name}", obj.toJson(), where: where, whereArgs: whereArgs);
  }
''';

    var hasPK = false;
    for (var e in classElement.fields) {
      if (!hasPK && _coreDBPKChecker.hasAnnotationOfExact(e)) {
        hasPK = true;
        // _coreDBPKChecker.firstAnnotationOfExact(e).getField(name)
        fieldStr += '''
  Future<int>delete(${e.type} ${e.name}) async {
    return await db.rawDelete("delete from ${classElement.name} where ${e.name} = ?", [${e.name}]);
  }

  Future<int>update(${e.type} ${e.name}, ${classElement.name} obj) async {
    return await updateWhere(obj, "${e.name} = ?", [${e.name}]);
  }

  Future<${classElement.name}?>first(${e.type} ${e.name}) async {
    //ignore more rows
    var rows = await db.rawQuery("select * from ${classElement.name} where ${e.name} = ? limit 1", [${e.name}]);
    if(rows.isEmpty) {
      return null;
    }

    return ${classElement.name}.fromJson(rows[0]);
  }
''';
      }
      
      fieldStr += '''
  static var ${e.name}Field = "${e.name}";
''';
    }
    var schema = "";
    for (var e in classElement.fields) {
      schema += '''
  ${e.name} ${e.type.isDartCoreString ? "TEXT" : "INTEGER"};
  ''';
    }
    fieldStr += '''
  static var dbTable = "${classElement.name}";
  static var dbSchema = \'''
  create table ${classElement.name} (
  $schema
  );
  \''';
''';
    return fieldStr;
  }
}