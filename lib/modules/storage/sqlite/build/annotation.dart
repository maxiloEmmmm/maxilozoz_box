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
