library bay.rest.test;

import 'package:bay/bay.dart';
import 'package:bay_rest/bay_rest.dart';
import 'package:logging/logging.dart';

void main () {
  Bay.init([new BayRestModule(), new TestModule()], port: 9999);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}.'
          '${rec.error != null ? '${rec.error}\n${rec.stackTrace}' : ''}');
  });

}

class TestModule extends DeclarativeModule {
  @Singleton
  TestResource testResource;
  TestModel testModel;

  String testString = "ImaString";
  int testNumber = 13;
}

@Path("/test")
class TestResource {
  TestModel model;

  TestResource(this.model);

  @PUT
  updateModel(TestModel newModel, @HeaderParam("Content-Type") type) {
    print(type);
    model = newModel;
    return model;
  }

  @GET
  blabla() {
    return model;
  }
}

class TestModel {
  String someString;
  int someNumber;

  TestModel();

  @inject
  TestModel.filled(this.someNumber, this.someString);

}