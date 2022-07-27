import 'dart:async';

import 'package:maxilozoz_box/modules/storage/sqlite/build/annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/output_helpers.dart';
import 'package:analyzer/dart/element/element.dart' as e;
import 'package:build/build.dart';
import 'package:path/path.dart' as Path;

String formatType(String prefix) {
  return "$prefix\Type";
}

String formatClient(String prefix) {
  return "$prefix\Client";
}

String formatEdgeField(String prefix) {
  return "$prefix\_ref";
}

String formatEdgeTable(String main, edge) {
  return "$main\_$edge";
}

class parseTable {
  List<DBMetaField> fields = [];
  List<DBMetaEdge> edges = [];
  List<DBMetaIndex> indexs = [];
  String table = "";

  Map<String, DBMetaEdge> get edgeMap {
    Map<String, DBMetaEdge> ret = {};
    edges.forEach((element) {
      ret[element.table] = element;
    });
    return ret;
  }

  List<DBMetaField> get typeFields {
    return [
      ...fields,
      ...edges
          .where((element) => element.type == DBEdgeType.From && element.unique)
          .map((e) {
        return DBMetaField(
            name: formatEdgeField(e.table),
            type: DBFieldType.Int,
            required: e.required);
      }).toList()
    ];
  }
}

class parse {
  List<parseTable> tables = [];

  Map<String, parseTable> tableMap() {
    Map<String, parseTable> ret = {};
    tables.forEach((element) {
      ret[element.table] = element;
    });
    return ret;
  }

  parseTable? table(String name) {
    return tableMap()[name];
  }
}

class DBGenerator extends Generator {
  TypeChecker get typeChecker => TypeChecker.fromRuntime(DBSchema);
  var pp = parse();

  List<DBMetaField> doParseField(ConstantReader ann) {
    var iterator = ann.read("fields").listValue.iterator;

    List<DBMetaField> rets = [
      DBMetaField(
        name: IDField,
        pk: true,
        autoIncrement: true,
        type: DBFieldType.Int,
      )
    ];
    while (iterator.moveNext()) {
      String name = iterator.current.getField("name")!.toStringValue()!;
      if (name.compareTo(IDField) == 0) {
        print("not support custom id field");
        continue;
      }

      var defaultDefine = iterator.current.getField("default");

      rets.add(DBMetaField(
        name: name,
        type: DBFieldType.values[iterator.current
            .getField("type")!
            .getField("index")!
            .toIntValue()!],
        defaultDefine: defaultDefine == null ? "" : defaultDefine.toString()
      ));
    }

    return rets;
  }

  List<DBMetaEdge> doParseEdge(ConstantReader ann) {
    var edgesField = ann.read("edges");
    if (edgesField.isNull) {
      return [];
    }
    var iterator = edgesField.listValue.iterator;
    List<DBMetaEdge> rets = [];
    while (iterator.moveNext()) {
      rets.add(DBMetaEdge(
        table: iterator.current.getField("table")!.toStringValue()!,
        type: DBEdgeType.values[iterator.current
            .getField("type")!
            .getField("index")!
            .toIntValue()!],
        unique: iterator.current.getField("unique")!.toBoolValue()!,
      ));
    }
    return rets;
  }

  void parseCheck() {
    pp.tables.forEach((pt) {
      pt.edges.forEach((edge) {
        parseTable? et = pp.table(edge.table);
        if (et == null) {
          throw "${edge.table} table schema not define on ${pt.table} table edge check";
        }

        DBMetaEdge? dbme = et.edgeMap[pt.table];
        if (dbme == null) {
          throw "${edge.table} table schema not define ${pt.table} edge on ${pt.table} table edge check";
        }

        if (edge.type == dbme.type) {
          throw "edge type equal on ${pt.table} & ${edge.table}";
        }
      });
    });
  }

  parseTable doParseTable(String table, ConstantReader ann) {
    var p = parseTable();
    p.table = table;
    p.fields = doParseField(ann);
    p.edges = doParseEdge(ann);
    // todo support index
    return p;
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    pp.tables = [];
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      if (!(annotatedElement.element is e.ClassElement)) {
        throw 'db annotation must on class';
      }
      pp.tables.add(doParseTable(
          (annotatedElement.element as e.ClassElement).name,
          annotatedElement.annotation));
    }

    if (pp.tables.isEmpty) {
      return "";
    }

    parseCheck();

    String output = [renderPart(buildStep), renderUtil(), "\n"].join("\n");
    pp.tables.forEach((element) {
      output += render(element);
    });

    return normalizeGeneratorOutput(output).join("");
  }

  static const DBClientSetClass = "DBClientSet";
  String renderUtil() {
    return '''
  class $DBClientSetClass {
    ${pp.tables.map((table) {
              return '''
  ${formatClient(table.table)} ${table.table}(){
    return ${formatClient(table.table)}(this);       
  }''';
            }).toList().join("\n")}

    DatabaseExec db;
    static const schema = \'''
${pp.tables.map((e) => "\${${formatClient(e.table)}.schema}").toList().join("\n")}
\''';
    $DBClientSetClass(this.db);

    Future<void> transaction(Future<void> Function() cb) async {
      var _db = db;
      try {
        await (db as Database).transaction((txn) async {
          db = txn;
          await cb();
        });
      }catch(e) {
        db = _db;
        throw e.toString();
      }
      db = _db;
    }
  }

  String dateTime2String(DateTime data) {
    return data.toIso8601String();
  }
  DateTime string2DateTime(String data) {
    return DateTime.parse(data);
  }

  int bool2Int(bool data) {
    return data ? 0 : 1;
  }
  bool int2Bool(int data) {
    return data == 0;
  }
''';
  }

  String render(parseTable pt) {
    List<String> rets = [renderClient(pt), renderType(pt)];

    return rets.join("\n");
  }

  String renderTypeEdgeFunc(parseTable pt) {
    List<String> rets = [];
    pt.edges.forEach((element) {
      DBMetaEdge edge = pp.table(element.table)!.edgeMap[pt.table]!;
      switch (element.type) {
        case DBEdgeType.To:
          if (edge.unique) {
            // 举例 用户和卡片
            // 这里处理一个用户有一张或多张卡
            // 一张卡只对应一个用户的情况
            // 只需要在卡表加用户id即可
            rets.add('''
  Future<${element.unique ? "" : "List<"}${formatType(element.table)}${element.unique ? (element.required ? "" : "?") : ">"}>query${element.table}${element.unique ? "" : "s"}() async {
    var rows = clientSet.${element.table}().query("select * from \${${formatClient(element.table)}.table} where ${formatEdgeField(pt.table)} = ? ${element.unique ? "limit 1" : ""}", [$IDField]);
    ${element.unique ? '''
    if(rows.isEmpty) {
      return null;
    }
    return rows[0];
''' : '''
    return rows;
'''}
  }
''');
          } else {
            // 这里处理一个用户有一或多张卡
            // 一张卡对应一个或多个用户的情况
            // 应在中间表进行查询
            rets.add('''
  Future<${element.unique ? "" : "List<"}${formatType(element.table)}${element.unique ? (element.required ? "" : "?") : ">"}>query${element.table}${element.unique ? "" : "s"}() async {
    var rows = await clientSet.db.rawQuery("select * from \${${formatClient(element.table)}.table} where id in (select ${formatEdgeField(element.table)} from ${formatEdgeTable(pt.table, element.table)} where ${formatEdgeField(pt.table)} = ? ${element.unique ? "limit 1" : ""})", [$IDField]);
    ${element.unique ? '''
    if(rows.isEmpty) {
      return null;
    }
    return clientSet.${element.table}().newTypeByRow(rows[0]);
''' : '''
    return rows.map((row) => clientSet.${element.table}().newTypeByRow(row)).toList();
'''}
  }

  Future<void>set${element.table}${element.unique ? "" : "s"}(${!element.unique ? "List<int> ids" : "int idx"}) async {
    var it = ${element.unique ? "[idx]" : "ids"}.iterator;
    while(it.moveNext()) {
      await clientSet.db.rawInsert("insert into ${formatEdgeTable(pt.table, element.table)}(${formatEdgeField(pt.table)}, ${formatEdgeField(element.table)}) values(?, ?)", [$IDField, it.current]);
    }
  }
''');
          }
          break;
        case DBEdgeType.From:
          if (element.unique) {
            // 一个卡只有一个用户持有
            rets.add('''
  Future<${formatType(element.table)}?>query${element.table}() async {
    var rows = await clientSet.${element.table}().query("select * from \${${formatClient(element.table)}.table} where $IDField = ? limit 1", [${formatEdgeField(element.table)}]);
    if(rows.isEmpty) {
      return null;
    }
    return rows[0];
  }

  ${formatType(pt.table)} set${element.table}(int idx) {
    ${formatEdgeField(element.table)} = idx;
    return this;
  }
''');
          } else {
            // 一个卡多个用户持有
            rets.add('''
  Future<List<${formatType(element.table)}>>query${element.table}() async {
    var rows = await clientSet.db.rawQuery("select * from \${${formatClient(element.table)}.table} where id in (select ${formatEdgeField(element.table)} from ${formatEdgeTable(element.table, pt.table)} where ${formatEdgeField(pt.table)} = ? limit 1)", [$IDField]);
    return rows.map((row) => clientSet.${element.table}().newTypeByRow(row)).toList();
  }
  Future<void>set${element.table}s(List<int> ids) async {
    await clientSet.db.rawDelete("delete from ${formatEdgeTable(element.table, pt.table)} where ${formatEdgeField(pt.table)} = ?", [$IDField]);
    var it = ids.iterator;
    while(it.moveNext()) {
      await clientSet.db.rawInsert("insert into ${formatEdgeTable(element.table, pt.table)}(${formatEdgeField(pt.table)}, ${formatEdgeField(element.table)}) values(?, ?)", [$IDField, it.current]);
    }
    return;
  }
''');
          }
      }
    });
    return rets.toList().join("\n");
  }

  String renderTypeFunc(parseTable pt) {
    return '''
  Future<${formatType(pt.table)}>save() async {
    if($IDField == null) {
      ${pt.fields.where((field) => field.defaultDefine.isNotEmpty).map((field) {
        return '''
      if(${field.name} == null) {
        ${field.name} = ${field.defaultDefine};
      }
''';
      }).toList().join("\n")}
      $IDField = await clientSet.${pt.table}().insert(this);
    }else {
      await clientSet.${pt.table}().update(this);
    }

    return (await clientSet.${pt.table}().first($IDField!))!;
  }

  Future<int>destory() async {
    if($IDField == null) {
      throw "current type not allow this opeart";
    }
    ${pt.edges.where((element) => !element.unique && element.type == DBEdgeType.From).map((element) {
              return '''await clientSet.db.rawDelete("delete from ${formatEdgeTable(element.table, pt.table)} where ${formatEdgeField(pt.table)} = ?", [$IDField]);''';
            }).toList().join("\n")}
    return await clientSet.${pt.table}().delete($IDField!);
  }

  ${renderTypeEdgeFunc(pt)}
''';
  }

  String renderType(parseTable pt) {
    var ptt = formatType(pt.table);
    // DB and toDB idea from JsonSerializableGenerator
    // fill idea from laravel php framework
    return '''
class $ptt {
  late $DBClientSetClass clientSet;

  ${pt.typeFields.map((field) => '''${DBFieldTypeDartTransform[field.type]}? ${field.name};''').toList().join("\n")}

  $ptt({
     ${pt.typeFields.map((field) => "this.${field.name}").toList().join(",\n")}
  });

  $ptt fill(Map data) {
    ${pt.typeFields.map((field) {
              return '''
if(data["${field.name}"] != null) {
  ${field.name} = data["${field.name}"] as ${DBFieldTypeDartTransform[field.type]};
}
''';
            }).toList().join("\n")}
    return this;
  }

  $ptt fillByType($ptt obj) {
    ${pt.typeFields.map((field) {
              return '''
if(obj.${field.name} != null) {
  ${field.name} = obj.${field.name};
}
''';
            }).toList().join("\n")}
    return this;
  }

  $ptt.DB(Map data) {
    ${pt.typeFields.map((field) {
              String getData =
                  '''data["${field.name}"] as ${DBFieldTypeDartTransform[field.type]}?''';
              switch (field.type) {
                case DBFieldType.DateTime:
                  getData =
                      '''data["${field.name}"] == null ? null : string2DateTime(data["${field.name}"] as String)''';
                  break;
                case DBFieldType.Bool:
                  getData =
                      '''data["${field.name}"] == null ? null : int2Bool(data["${field.name}"] as int)''';
                  break;
                default:
              }
              return '''${field.name} = $getData;''';
            }).toList().join("\n")}
  }

  Map<String, Object?> toDB() {
    final val = <String, Object?>{};

    void writeNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    ${pt.typeFields.map((field) {
              String getData = field.name;
              switch (field.type) {
                case DBFieldType.DateTime:
                  getData =
                      '''${field.name} == null ? null : dateTime2String(${field.name}!)''';
                  break;
                case DBFieldType.Bool:
                  getData =
                      '''${field.name} == null ? null : bool2Int(${field.name}!)''';
                  break;
                default:
              }
              return '''writeNotNull('${field.name}', $getData);''';
            }).toList().join("\n")}

    return val;
  }

  ${renderTypeFunc(pt)}
}
''';
  }

  String renderPart(BuildStep bs) {
    return "part of '${Path.basename(bs.inputId.path)}';";
  }

  String renderClient(parseTable pt) {
    return '''
class ${formatClient(pt.table)} {
  $DBClientSetClass clientSet;
  ${pt.table}Client(this.clientSet);

  ${renderClientSchema(pt)}
}
''';
  }

  String renderClientEdgeSchema(parseTable pt) {
    List<String> ret = [];
    pt.edges.forEach((element) {
      if (element.unique || element.type != DBEdgeType.From) {
        return;
      }

      ret.add('''
create table if not exists ${formatEdgeTable(element.table, pt.table)} (
${formatEdgeField(pt.table)} INTEGER not null,
${formatEdgeField(element.table)} INTEGER not null
);
''');
    });
    return ret.join("\n");
  }

  String renderClientFunc(parseTable pt) {
    return '''
  Future<int>delete(int id) async {
    return await clientSet.db.rawDelete("delete from \$table where $IDField = ?", [id]);
  }

  Future<${formatType(pt.table)}?>first(int id) async {
    var rows = await query("select * from \$table where $IDField = ?", [id]);
    if(rows.isEmpty) {
      return null;
    }
    
    return rows[0];
  } 

  Future<${formatType(pt.table)}>firstOrNew(int id) async {
    var rows = await query("select * from \$table where $IDField = ?", [id]);
    if(rows.isEmpty) {
      var item =${formatType(pt.table)}();
      if(id > 0) {
        item.id = id;
      }
      return wrapType(item);
    }
    
    return rows[0];
  }

  ${formatType(pt.table)} wrapType(${formatType(pt.table)} typ) {
    typ.clientSet = clientSet;
    return typ;
  } 

  Future<List<${formatType(pt.table)}>>all() async {
    return await query("select * from \$table", []);
  }
  
  Future<List<${formatType(pt.table)}>>query(String query, [List<Object?>? arguments]) async {
    return (await clientSet.db.rawQuery(query, arguments))
      .map((e) => newTypeByRow(e)).toList();
  }

  Future<int>insert(${formatType(pt.table)} obj) async {
    return await clientSet.db.insert(table, obj.toDB());
  }

  Future<int>update(${formatType(pt.table)} obj) async {
    return await clientSet.db.update(table, obj.toDB(), where: "$IDField = ?", whereArgs: [obj.$IDField!]);
  }

  ${formatType(pt.table)} newType() {
    return wrapType(${formatType(pt.table)}());
  }

  ${formatType(pt.table)} newTypeByRow(Map row) {
    return wrapType(${formatType(pt.table)}.DB(row));
  }
''';
  }

  String renderClientSchema(parseTable pt) {
    String fields = pt.typeFields
        .map((field) =>
            "${field.name} ${DBFieldTypeTransform[field.type]} ${field.pk ? "PRIMARY KEY" : ""} ${field.autoIncrement ? "AUTOINCREMENT" : ""} ${field.required ? "not null" : ""}")
        .toList()
        .join(",\n");

    return '''
${renderClientFunc(pt)}
${pt.typeFields.map((e) => '''
  static const ${e.name}Field="${e.name}";''').toList().join("\n")}
static const table = "${pt.table}";
static const schema = \'''
create table if not exists ${pt.table} (
  $fields
);
${renderClientEdgeSchema(pt)}
\''';
''';
  }
}
