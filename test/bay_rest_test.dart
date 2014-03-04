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
  TestResource testResource;
  TestModel testModel;
  
  String testString = "ImaString";
  int testNumber = 13;
}

@Path("/test")
class TestResource {
  TestModel model;
    
  TestResource(this.model);
  
  @GET
  TestModel blabla() {
    return model;
  }
}

class TestModel {
  String someString;
  int someNumber;
  
  TestModel(this.someNumber, this.someString);
  
}