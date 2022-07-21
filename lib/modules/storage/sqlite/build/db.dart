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
  generateForAnnotatedElement(
      e.Element element, ConstantReader annotation, BuildStep buildStep) {
    return '''
part of '${Path.basename(buildStep.inputId.path)}';

class ${element.name}JSONHelp {
  static ${element.name} fromJson(Map<String, dynamic> json) => _\$${element.name}FromJson(json);
  static Map<String, dynamic> toJson(${element.name} obj) => _\$${element.name}ToJson(obj);
}

class ${element.name}Client {
  Database db;
  ${element.name}Client(this.db);

  ${analyseElement(element, annotation)}
}
''';
  }

  String analyseElement(e.Element element, ConstantReader annotation) {
    switch (element.kind) {
      case e.ElementKind.CLASS:
        return _analyseElementForClass(element as e.ClassElement, annotation);
      case e.ElementKind.FUNCTION:
      default:
        return "";
    }
  }

  String _analyseElementForClass(
      e.ClassElement classElement, ConstantReader annotation) {
    var edgeFunction = "";
    List<String> edgeField = [];
    List<Map<String, dynamic>> edgeList = [];
    var edgeSchema = [];
    annotation.read("edges").listValue.forEach((field) {
      String relationTable = field.getField("relation")!.toStringValue()!;
      String relationField = field.getField("relationField")!.toStringValue()!;
      String selfField = field.getField("field")!.toStringValue()!;
      bool unique = field.getField("unique")!.toBoolValue()!;
      bool belong = field.getField("belong")!.toBoolValue()!;
      var relationDBTable = "${classElement.name}_$relationTable";
      edgeList.add({
        "relationTable": relationTable,
        "relationDBTable": relationDBTable,
        "relationField": relationField,
        "selfField": selfField,
        "unique": unique,
        "belong": belong,
      });
      if (belong) {
        if (unique) {
          edgeFunction += '''
Future<List<$relationTable>?>get$relationTable(int identity) async {
  var rows = await db.rawQuery("select * from $relationTable where ${classElement.name}_id = ? limit 1", [identity])
  if(rows.isEmpty) {
    return null;
  }
  return $relationTable\JSONHelp.fromJson(rows[0]);
}
''';
        } else {
          edgeFunction += '''
Future<List<$relationTable>?>get$relationTable\s(int identity) async {
  return (await db.rawQuery("select * from $relationTable where ${classElement.name}_id = ?", [identity]))
    .map((e) => $relationTable\JSONHelp.fromJson(e)).toList();
}
''';
        }
      } else {
        if (unique) {
          var selfRelationField = "${relationTable}_id";
          edgeField.add(selfRelationField);
          edgeFunction += '''
Future<int>set$relationTable(int identity, int $relationTable\_identity) async {
  return await db.rawUpdate("update ${classElement.name} set $selfRelationField = ? where $selfField = ?", [$relationTable\_identity, identity]);
}
Future<$relationTable?>get$relationTable(int identity) async {
  var rows = await db.rawQuery("select t1.* from ${classElement.name} as s left join $relationTable as t1 where s.$selfField = ? and t1.$relationField = s.$selfRelationField", [identity]);
  if(rows.isEmpty) {
    return null;
  }

  return ${relationTable}JSONHelp.fromJson(rows[0]);
}
''';
        } else {
          edgeSchema.addAll([
            '''
create table if not exists $relationDBTable (
    ${classElement.name}_id INTEGER,
    ${relationTable}_id INTEGER
  );
''',
            '''
CREATE INDEX ${classElement.name}_index
ON $relationDBTable (${classElement.name}_id);
'''
          ]);
          edgeFunction += '''
Future<void>del$relationTable\s(int identity) async {
  await db.rawDelete("delete from $relationDBTable where ${classElement.name}_id = ?", [identity]);
}
Future<void>set$relationTable\s(int identity, List<int> $relationTable\_identities) async {
  await del$relationTable\s(identity);
  var iterator = $relationTable\_identities.iterator;
  while(iterator.moveNext()) {
    await db.rawInsert("insert into $relationDBTable(${classElement.name}_id, $relationTable\_id) values(?, ?)", [identity, iterator.current]);
  }
}
Future<List<$relationTable>>get$relationTable\s(int identity) async {
  return (await db.rawQuery("select * from $relationTable where $relationField in (select $relationTable\_id from $relationDBTable where ${classElement.name}_id=?)", [identity]))
    .map((e) => $relationTable\JSONHelp.fromJson(e)).toList();
}  
''';
        }
      }
    });

    var fieldStr = '''
  $edgeFunction

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

    edgeField.forEach((element) {
      schema += '''
    $element INTEGER,
''';
    });

    var cfLen = classElement.fields.length - 1;
    for (var i = 0; i <= cfLen; i++) {
      var e = classElement.fields[i];
      var dbFieldName = e.name;
      var dbFieldVarName = "${e.name}\Field";
      if (_coreJSONKeyChecker.hasAnnotationOfExact(e)) {
        dbFieldName = _coreJSONKeyChecker
            .firstAnnotationOfExact(e)!
            .getField("name")!
            .toStringValue()!;
      }

      var isPk = false;
      var autoInsert = false;
      if (!hasPK && _coreDBPKChecker.hasAnnotationOfExact(e)) {
        isPk = true;
        hasPK = true;

        bool? autoInsertValue = _coreDBPKChecker
            .firstAnnotationOfExact(e)!
            .getField("AutoInsert")
            ?.toBoolValue();
        if (autoInsertValue != null && autoInsertValue) {
          autoInsert = true;
        }

        fieldStr += '''
  Future<int>delete(${e.type} ${e.name}) async {
    ${edgeList.map((element) => (element["unique"] as bool) || (element["belong"] as bool) ? "" : '''
  await del${element["relationTable"]}\s(${e.name}!);
''').toList().join("\n")}
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
      var schemaPlus = "";
      if (isPk) {
        schemaPlus = " PRIMARY KEY ${autoInsert ? "AUTOINCREMENT" : ""}";
      }
      schema += '''
  \$$dbFieldVarName ${e.type.isDartCoreString ? "TEXT" : "INTEGER"}$schemaPlus${i == cfLen ? "" : ","}
  ''';
    }

    fieldStr += '''
  static const dbTable = "${classElement.name}";
  static const dbSchema = \'''
  create table if not exists \$dbTable (
  $schema
  );
  ${edgeSchema.join("\n")}
\''';
''';
    return fieldStr;
  }
}
