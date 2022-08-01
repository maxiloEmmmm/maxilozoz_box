void main() {
  print((QueryBuild()
        ..table(Table.from("t1"))
        ..where(Eq("a", 1)))
      .toString()
      .compareTo("select * from `t1` where `a` = 1"));
  var t1Table = Table.from("q1");
  var t2Table = Table.from("q2");

  print((QueryBuild()
        ..table(t1Table)
        ..select("${t1Table.f("a")}, ${t2Table.f("c")}")
        ..join(LeftJoin(table: t2Table)..on(Eq(t1Table.f("a"), t2Table.f("b"))))
        ..where(Gt(t1Table.f("a"), 5)))
      .toString()
      .compareTo(
          '''select `q1`.`a`, `q2`.`c` from `q1` left join `q2` on `q1`.`a` = `q2`.`b` where `q1`.`a` > 5'''));

  print((QueryBuild()
        ..table(t1Table)
        ..select("a")
        ..where(Or([
          And([
            Eq("a", 1),
            In("b", ["1", "ab"]),
          ]),
          And([
            Eq("c", "2"),
            In("d", [1, 2, 3]),
          ])
        ])))
      .toString()
      .compareTo(
          '''select `a` from `q1` where ((`a` = 1) and (`b` in ("1","ab"))) or ((`c` = "2") and (`d` in (1,2,3)))'''));
}

String wrapValue(dynamic s) {
  if (s is String) {
    if (s.startsWith("`") || s == "*") {
      return s;
    }

    return '''"$s"''';
  }

  return "$s";
}

String ident(String s) {
  if (s.startsWith("`")) {
    return s;
  }
  return "`$s`";
}

class QueryBuild<T> extends Query {
  Query? _table;
  List<Query> _where = [];
  List<Query> _join = [];
  int? _limit;
  int? _offset;
  Query? _orderBy;
  String? _select;

  Future<List<T>> Function(String)? queryFunc;

  QueryBuild();

  Future<List<T>> query() async {
    return await queryFunc!(toString());
  }

  QueryBuild<T> table(Query t) {
    _table = t;
    return this;
  }

  QueryBuild<T> select(dynamic t) {
    _select = t is Query ? t.toString() : ident(t);
    return this;
  }

  QueryBuild<T> where(Query q) {
    _where.add(q);
    return this;
  }

  QueryBuild<T> join(Query q) {
    _join.add(q);
    return this;
  }

  QueryBuild<T> limit(int size, [int offset = 0]) {
    _limit = size;
    _offset = offset;
    return this;
  }

  QueryBuild<T> orderBy(Query q) {
    _orderBy = q;
    return this;
  }

  String toString() {
    var build = "select";
    if (_select == null) {
      build += " *";
    } else {
      build += " " + _select.toString();
    }

    build += " from " + _table.toString();
    if (_join.isNotEmpty) {
      build += " " + _join.map((j) => j.toString()).toList().join(" ");
    }

    if (_where.isNotEmpty) {
      build += " where " + _where.map((j) => j.toString()).toList().join(" ");
    }

    if (_orderBy != null) {
      build += " " + _orderBy.toString();
    }

    if (_limit != null) {
      build += " limit $_limit, $_offset";
    }

    return build;
  }
}

abstract class Query {
  String toString();
}

class And extends Query {
  List<Query> s1 = [];

  And(this.s1);

  String toString() {
    return s1.map((e) => "(${e.toString()})").join(" and ");
  }
}

class Or extends Query {
  List<Query> s1 = [];

  Or(this.s1);

  String toString() {
    return s1.map((e) => "(${e.toString()})").join(" or ");
  }
}

class In extends Query {
  String s1;
  List<dynamic>? s2;

  In(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} in (${s2?.map((e) => e is Query ? e.toString() : (e)).toList().join(",")})";
  }
}

class Eq extends Query {
  String s1;
  dynamic s2;

  Eq(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} = ${wrapValue(s2)}";
  }
}

class NEq extends Query {
  Query s1;
  dynamic s2;

  NEq(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} != ${wrapValue(s2)}";
  }
}

class Gt extends Query {
  String s1;
  dynamic s2;

  Gt(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} > ${wrapValue(s2)}";
  }
}

class GtE extends Query {
  String s1;
  dynamic s2;

  GtE(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} >= ${wrapValue(s2)}";
  }
}

class Lt extends Query {
  String s1;
  dynamic s2;

  Lt(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} < ${wrapValue(s2)}";
  }
}

class LtE extends Query {
  String s1;
  dynamic s2;

  LtE(this.s1, this.s2);

  String toString() {
    return "${ident(s1.toString())} <= ${wrapValue(s2)}";
  }
}

class Join extends Query {
  Query table;
  String op;
  List<Query> ons = [];

  Join({required this.table, required this.op});

  void on(Query on) {
    ons.add(on);
  }

  String toString() {
    var base = "";
    if (op.isNotEmpty) {
      base += op + " ";
    }
    base += "join ${ident(table.toString())}";
    if (ons.isNotEmpty) {
      base += " on " + ons.map((e) => e.toString()).toList().join("");
    }
    return base;
  }
}

class LeftJoin extends Join {
  LeftJoin({required table}) : super(table: table, op: "left");
}

class RightJoin extends Join {
  RightJoin({required table}) : super(table: table, op: "right");
}

class Table extends Query {
  late String _alias = "";
  Query table;
  bool sample = false;

  Table(this.table);

  void as(String a) {
    _alias = a;
  }

  String f(String a) {
    return "${ident(_alias.isEmpty ? table.toString() : _alias)}.${ident(a)}";
  }

  Table.from(String a)
      : table = StringQuery(a),
        sample = true;

  String toString() {
    if (sample) {
      return ident(table.toString());
    }

    return "(${table.toString()}) as ${ident(_alias)}";
  }
}

class StringQuery extends Query {
  String t = "";
  StringQuery(this.t);

  String toString() {
    return t;
  }
}
