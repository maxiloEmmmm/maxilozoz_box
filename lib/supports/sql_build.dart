void main() {
  print((QueryBuild()
        ..table(Table.from("t1"))
        ..where(Eq(s1: "a", s2: 1)))
      .toString()
      .compareTo("select * from `t1` where `a` = 1"));
  var t1Table = Table.from("q1");
  var t2Table = Table.from("q2");

  print((QueryBuild()
        ..table(t1Table)
        ..select("${t1Table.f("a")}, ${t2Table.f("c")}")
        ..join(LeftJoin(table: t2Table)
          ..on(Eq(s1: t1Table.f("a"), s2: t2Table.f("b"))))
        ..where(Gt(s1: t1Table.f("a"), s2: 5)))
      .toString()
      .compareTo(
          '''select `q1`.`a`, `q2`.`c` from `q1` left join `q2` on `q1`.`a` = `q2`.`b` where `q1`.`a` > 5'''));

  print((QueryBuild()
        ..table(t1Table)
        ..select("a")
        ..where(Or(
          s1: And(
            s1: Eq(s1: "a", s2: 1),
            s2: In(s1: "b", s2: ["1", "ab"]),
          ),
          s2: And(
            s1: Eq(s1: "c", s2: "2"),
            s2: In(s1: "d", s2: [1, 2, 3]),
          ),
        )))
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

class QueryBuild extends Query {
  Query? _table;
  List<Query> _where = [];
  List<Query> _join = [];
  Query? _limit;
  Query? _orderBy;
  String? _select;

  QueryBuild();

  void table(Query t) {
    _table = t;
  }

  void select(dynamic t) {
    _select = t is Query ? t.toString() : ident(t);
  }

  void where(Query q) {
    _where.add(q);
  }

  void join(Query q) {
    _join.add(q);
  }

  void limit(Query q) {
    _limit = q;
  }

  void orderBy(Query q) {
    _orderBy = q;
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
      build += " " + _limit.toString();
    }

    return build;
  }
}

abstract class Query {
  String toString();
}

class And extends Query {
  Query s1, s2;

  And({required this.s1, required this.s2});

  String toString() {
    return "(${s1.toString()}) and (${s2.toString()})";
  }
}

class Or extends Query {
  Query s1, s2;

  Or({required this.s1, required this.s2});

  String toString() {
    return "(${s1.toString()}) or (${s2.toString()})";
  }
}

class In extends Query {
  String s1;
  List<dynamic>? s2;

  In({required this.s1, this.s2});

  String toString() {
    return "${ident(s1.toString())} in (${s2?.map((e) => wrapValue(e)).toList().join(",")})";
  }
}

class Eq extends Query {
  String s1;
  dynamic s2;

  Eq({required this.s1, required this.s2});

  String toString() {
    return "${ident(s1.toString())} = ${wrapValue(s2)}";
  }
}

class NEq extends Query {
  Query s1;
  dynamic s2;

  NEq({required this.s1, required this.s2});

  String toString() {
    return "${ident(s1.toString())} != ${wrapValue(s2)}";
  }
}

class Gt extends Query {
  String s1;
  dynamic s2;

  Gt({required this.s1, required this.s2});

  String toString() {
    return "${ident(s1.toString())} > ${wrapValue(s2)}";
  }
}

class GtE extends Query {
  Query s1;
  dynamic s2;

  GtE({required this.s1, required this.s2});

  String toString() {
    return "${ident(s1.toString())} >= ${wrapValue(s2)}";
  }
}

class Lt extends Query {
  Query s1;
  dynamic s2;

  Lt({required this.s1, required this.s2});

  String toString() {
    return "${ident(s1.toString())} < ${wrapValue(s2)}";
  }
}

class LtE extends Query {
  Query s1;
  dynamic s2;

  LtE({required this.s1, required this.s2});

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
