import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class NotFoundRoute extends StatelessWidget {
  const NotFoundRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: Text("404 Not Found."));
  }
}
