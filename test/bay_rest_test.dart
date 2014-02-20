library bay.rest.test;

import 'dart:async';
import 'package:bay/bay.dart';
import 'package:bay_rest/bay_rest.dart';
import 'package:logging/logging.dart';

void main () {
  Bay.init([new BayRestModule()], port: 9999);
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}.'
          '${rec.error != null ? '${rec.error}\n${rec.stackTrace}' : ''}');
  });
  
}
