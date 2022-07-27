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
  final String defaultDefine;

  const DBMetaField({
    required this.name,
    this.type = DBFieldType.String,
    this.autoIncrement = false,
    this.pk = false,
    this.required = false,
    this.defaultDefine = "",
  });
}

enum DBEdgeType { To, From }

class DBMetaEdge {
  final DBEdgeType type;
  final String table;
  final bool unique;
  final String ref;
  final String field;
  final bool required;
  const DBMetaEdge({
    required this.table,
    required this.type,
    this.unique = false,
    this.field = IDField,
    this.ref = IDField,
    this.required = false,
  });
}

class DBMetaIndex {}

class DBSchema {
  final List<DBMetaField> fields;
  final List<DBMetaEdge>? edges;
  final List<DBMetaIndex>? indexs;
  const DBSchema({
    required this.fields,
    this.edges,
    this.indexs,
  });
}
