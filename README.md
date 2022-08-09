# maxilozoz_box

A new Flutter package project.

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

## 测试
```bash
flutter test test/[*].dart
```

## 文档

### 启动
```dart
    import 'package:maxilozoz_box/application.dart';
    final Application app = new Application();
    app.run();
```

### 路由
```dart
    //添加路由
    import 'package:maxilozoz_box/modules/route/route.dart';

    //获取route
    MinRoute route = app.make('route');

    //根路径
    route.add('/', () => DemoPage());

    //带参
    route.add('/page/:id', (Map data) => RegExpDemoPage(id: int.parse(data['id'])));
```

> 如果带参, 函数类型必须带有实参, 不然匹配不到

### 路由中间件

```dart
    import 'package:maxilozoz_box/modules/route/routeMiddleware.dart';
    //新增一个中间件实现
    class TestMiddleware {
        //需实现一个过滤方法
        RouteMiddlewareFilterItem filter(RouteSettings settings){
            //RouteMiddlewareFilterItem
            //    ok 过滤结果 如果为假 则会停止其余中间件
            //    settings 如需要重新定向路由, 需要设置新的name
            RouteMiddlewareFilterItem item = RouteMiddlewareFilterItem(ok: true, settings: settings);
            // auth is false, to auth
            bool auth = false;
            if(!auth) {
                item.settings = settings.copyWith(name: '/auth/login');
                item.ok = false;
            }
            return item;
        }
    }

    //注册
    route.routeMiddleware.add('auth', TestMiddleware());

    //添加一个路径为/path的路由 并设置`auth`中间件
    //访问/path会直接定向到/auth/logi页面 因为`auth`中间件因判断没有登陆修改了路由
    route.add('/path', (){}, middlewares: ['auth']);
```

### 配置参数
```dart
    //尝试获取当前环境下的`http_connect_timeout`配置
    app.config('http_connect_timeout');

    //设置当前环境`http_connect_timeout` 默认设置生产环境
    app.config({
        'http_connect_timeout': 500
    });

    //设置开发环境`http_connect_timeout`
    app.config({
        'http_connect_timeout': 500
    }, dev: true);

    //设置生产环境`http_connect_timeout`
    app.config({
        'http_connect_timeout': 500
    }, dev: false);
```

### Sqlite orm
> gen code 表结构定义
```dart
import "package:maxilozoz_box/modules/storage/sqlite/sqlite.dart";
import 'package:maxilozoz_box/modules/storage/sqlite/build/annotation.dart';
part 'db.db.g.dart';

@DBSchema(
  fields: [
    // 字段定义
    DBMetaField(name: "identity"),
    DBMetaField(name: "apiKey"),
  ],
)
class Ngrok {}

@DBSchema(
  fields: [
    DBMetaField(name: "name"),
    DBMetaField(name: "desc"),
  ],
  edges: [
    DBMetaEdge(table: "Plan", type: DBEdgeType.To),
    DBMetaEdge(table: "Thing", type: DBEdgeType.To, unique: true),
  ],
)
class Award {}

@DBSchema(
  fields: [
    DBMetaField(name: "name"),
    DBMetaField(name: "desc"),
    DBMetaField(name: "createdAt", type: DBFieldType.DateTime),
    DBMetaField(name: "deadLine", type: DBFieldType.DateTime),
    DBMetaField(name: "finishAt", type: DBFieldType.DateTime),
    DBMetaField(name: "joint", type: DBFieldType.Int),
    DBMetaField(name: "jointCount", type: DBFieldType.Int),
  ],
  edges: [
    DBMetaEdge(table: "Award", type: DBEdgeType.From),
    DBMetaEdge(table: "PlanDetail", type: DBEdgeType.To),
  ],
)
class Plan {}

@DBSchema(
  fields: [
    DBMetaField(name: "hit", type: DBFieldType.Int),
    DBMetaField(name: "desc"),
    DBMetaField(name: "createdAt", type: DBFieldType.DateTime),
  ],
  edges: [
    DBMetaEdge(table: "Plan", type: DBEdgeType.From, unique: true),
  ],
)
class PlanDetail {}

@DBSchema(
  fields: [
    DBMetaField(name: "name"),
    DBMetaField(name: "desc"),
  ],
  edges: [
    DBMetaEdge(table: "Award", type: DBEdgeType.From),
  ],
)
class Thing {}
```
```shell
dart run build_runner build
```
```dart
save: (FormData data) async {
    if (!data.valid) {
        tip.TextAlertDesc(context, "请检查!");
        return;
    }

    DBClientSet appDB = await Application.instance!.make("app_db");

    // 丝滑
    await appDB.transaction(() async {
        var item = await (await appDB.Award().firstOrNew(widget.identity)).fill(data.data).save();
        await item.setPlans((data.data[plansField] as List)
            .map((e) => e as int)
            .toList());
        await item.setThing(data.data[thingField]);
    });

    tip.TextAlertDescWithCB(
        context, "一切都好", () => Navigator.pop(context));
}
```
```dart
var rows = await clientSet
    .query()
    .table(Table.from(AwardClient.table))
    .where(In("id", [
        clientSet
            .query()
            .table(Table.from("Award_Plan"))
            .select("Award_ref")
            .where(Eq("Plan_ref", id))
            .limit(1)
    ]))
    .query();
```

### HTTP
> 参考 [Dio 3.0.1](https://pub.dev/packages/dio)
```dart
    import 'package:maxilozoz_box/modules/http/http.dart';
    Http http = app.make('http');
```

### 日志
```dart
    //读取key日志
    List<String> logs = app.log(key: 'key');

    //添加key日志
    app.log(key: 'key', logStr: '...');

    //限制日志存储长度, 会自动剔除老日志
    app.log(key: 'key', logStr: '...', limit: 200);
```

## 其他

### 依赖注入
```dart
    //加入 utils 依赖, 每次获取到的依赖相同
    app.bind('utils', (Application app, dynamic params){
        return (){
            print('utils');
        };
    });

    //关闭分享依赖 每次获取的依赖不同
    app.bind('utils', (Application app, dynamic params){
        return (){
            print('utils');
        };
    }, share: true);

    //获取 utils 依赖
    app.make('utils');

    //对于分享的依赖, 可以设置 force 强制产生新的依赖
    app.make('utils', force: true);

    //获取依赖可以传递参数 对于不分享的依赖每次可以取得不同的特性
    app.make('utils', params: {
        'key': 'value'
    });

    app.bind('utils', (Application app, dynamic params){
        return (){
            //可以获取其他依赖 自动解决依赖关系!
            print('utils' + app.make('other'));
        };
    }, share: true);
```

### 服务提供者
```dart
    import 'package:maxilozoz_box/application.dart';

    class TestServiceProvider {
        //服务名
        String get name {
            return 'test';
        }

        //注册服务
        void register(Application app){
            app.bind('test', (Application app, dynamic params) {
                return "test";
            });
        }

        //暂时无用 留空即可
        void boot(Application app){}
    }
```


