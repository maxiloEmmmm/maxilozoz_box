class DBAnnotation {
  final List<DBEdge> edges;
  const DBAnnotation({
    this.edges = const []
  });
}

class DBEdge {
  final String relation;
  final String field;
  final String relationField;
  final bool unique;
  const DBEdge({
    this.relationField = "id",
    this.field = "id",
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