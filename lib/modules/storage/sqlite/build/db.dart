import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:maxilozoz_box/modules/storage/sqlite/build/annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/output_helpers.dart';
import 'package:analyzer/dart/element/element.dart' as e;
import 'package:build/build.dart';
import 'package:path/path.dart' as Path;

const _coreDBPKChecker = const TypeChecker.fromRuntime(DBPKAnnotation);
const _coreJSONKeyChecker = const TypeChecker.fromRuntime(JsonKey);

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
      rets.add(DBMetaField(
        name: name,
        type: DBFieldType.values[iterator.current
            .getField("type")!
            .getField("index")!
            .toIntValue()!],
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

  parseTable doParseTable(ConstantReader ann) {
    var p = parseTable();
    p.table = ann.read("table").stringValue;
    p.fields = doParseField(ann);
    p.edges = doParseEdge(ann);
    parseCheck();
    // todo support index
    return p;
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      pp.tables.add(doParseTable(annotatedElement.annotation));
    }

    if (pp.tables.isEmpty) {
      return "";
    }

    String output = "";
    pp.tables.forEach((element) {
      output += render(buildStep, element);
    });
    pp.tables = [];

    return normalizeGeneratorOutput(output).join("");
  }

  String renderUtil() {
    return '''
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

  String render(BuildStep bs, parseTable pt) {
    List<String> rets = [
      renderPart(bs),
      renderClient(pt),
      renderType(pt),
      renderUtil()
    ];

    return rets.join("\n");
  }

  String renderType(parseTable pt) {
    var ptt = formatType(pt.table);
    return '''
class $ptt {
  ${pt.fields.map((field) => '''${DBFieldTypeDartTransform[field.type]}? ${field.name};''').toList().join("\n")}

  $ptt({
     ${pt.fields.map((field) => "this.${field.name}").toList().join(",\n")}
  });

  // idea from JsonSerializableGenerator
  $ptt.fromMap(Map data) {
    ${pt.fields.map((field) {
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

  // idea from JsonSerializableGenerator
  Map<String, Object?> toMap() {
    final val = <String, Object?>{};

    void writeNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    ${pt.fields.map((field) {
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
}
''';
  }

  String renderPart(BuildStep bs) {
    return "part of '${Path.basename(bs.inputId.path)}';";
  }

  String renderClient(parseTable pt) {
    return '''
class ${pt.table}Client {
  Database db;
  ${pt.table}Client(this.db);

  ${renderClientSchema(pt)}
}
''';
  }

  List<DBMetaField> loadTableEdgeFields(parseTable pt) {
    List<DBMetaField> ret = [];
    pt.edges.forEach((element) {
      if (!element.unique || element.type == DBEdgeType.To) {
        return;
      }

      ret.add(DBMetaField(
        name: formatEdgeField(element.table),
        type: DBFieldType.Int,
        required: true,
      ));
    });
    return ret;
  }

  String formatType(String prefix) {
    return "$prefix\Type";
  }

  String formatEdgeField(String prefix) {
    return "$prefix\_ref";
  }

  String formatEdgeTable(String main, edge) {
    return "$main\_$edge";
  }

  String renderClientEdgeSchema(parseTable pt) {
    List<String> ret = [];
    pt.edges.forEach((element) {
      if (element.unique || element.type != DBEdgeType.To) {
        return;
      }

      // M2M
      if (pp.table(element.table)!.edgeMap[pt.table]!.unique) {
        return;
      }

      ret.add('''
create table if not exists ${formatEdgeTable(pt.table, element.table)} (
${formatEdgeField(pt.table)} INTEGER not null,
${formatEdgeField(element.table)} INTEGER not null
);
''');
    });
    return ret.join("\n");
  }

  String renderClientFunc(parseTable pt) {
    return '''
  Future<List<${formatType(pt.table)}>>all() async {
    return (await db.rawQuery("select * from \$table"))
      .map((e) => ${formatType(pt.table)}.fromMap(e)).toList();
  }

  Future<List<${formatType(pt.table)}>>query(String sub, [List<Object?>? arguments]) async {
    return (await db.rawQuery("select * from \$table \$sub", arguments))
      .map((e) => ${formatType(pt.table)}.fromMap(e)).toList();
  }

  Future<int>insert(${formatType(pt.table)} obj) async {
    return await db.insert(table, obj.toMap());
  }

  Future<int>updateWhere(${formatType(pt.table)} obj, String? where, List<Object?>? whereArgs) async {
    return await db.update(table, obj.toMap(), where: where, whereArgs: whereArgs);
  }
''';
  }

  String renderClientSchema(parseTable pt) {
    List<DBMetaField> efs = loadTableEdgeFields(pt);
    String fields = [
      ...pt.fields,
      ...efs,
    ]
        .map((field) =>
            "${field.name} ${DBFieldTypeTransform[field.type]} ${field.pk ? "PRIMARY KEY" : ""} ${field.autoIncrement ? "AUTOINCREMENT" : ""} ${field.required ? "not null" : ""}")
        .toList()
        .join("\n");

    return '''
${renderClientFunc(pt)}
${pt.fields.map((e) => '''
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
