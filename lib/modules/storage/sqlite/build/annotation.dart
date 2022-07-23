class DBAnnotation {
  final List<DBEdge> edges;
  const DBAnnotation({this.edges = const []});
}

class DBEdge {
  final String relation;
  final String field;
  final String relationField;
  final bool unique;
  final bool belong;
  const DBEdge({
    this.relationField = "id",
    this.field = "id",
    this.belong = false,
    required this.relation,
    this.unique = false,
  });
}

class DBPKAnnotation {
  final bool AutoInsert;
  const DBPKAnnotation({
    this.AutoInsert = false,
  });
}

enum DBFieldType {
  String,
  Int,
  DateTime,
  Bool,
}

Map<DBFieldType, String> DBFieldTypeTransform = {
  DBFieldType.String: "text",
  DBFieldType.Int: "INTEGER",
  DBFieldType.DateTime: "text",
  DBFieldType.Bool: "text",
};

Map<DBFieldType, String> DBFieldTypeDartTransform = {
  DBFieldType.String: "String",
  DBFieldType.Int: "int",
  DBFieldType.DateTime: "DateTime",
  DBFieldType.Bool: "bool",
};

const IDField = "id";

class DBMetaField {
  final String name;
  final DBFieldType type;
  final bool autoIncrement;
  final bool pk;
  final bool required;

  const DBMetaField({
    required this.name,
    this.type = DBFieldType.String,
    this.autoIncrement = false,
    this.pk = false,
    this.required = false,
  });
}

enum DBEdgeType { To, From }

class DBMetaEdge {
  final DBEdgeType type;
  final String table;
  final bool unique;
  final String ref;
  final String field;
  const DBMetaEdge(
      {required this.table,
      required this.type,
      this.unique = false,
      this.field = IDField,
      this.ref = IDField});
}

class DBMetaIndex {}

class DBSchema {
  final List<DBMetaField> fields;
  final List<DBMetaEdge>? edges;
  final List<DBMetaIndex>? indexs;
  final String table;
  const DBSchema({
    required this.fields,
    required this.table,
    this.edges,
    this.indexs,
  });
}
