library bay.rest.core;

import 'dart:async';
import 'dart:io';
import 'package:bay/bay.dart';
import 'router.dart';

class BayRestModule extends DeclarativeModule {
  
  BayRestPlugin plugin;
  BayRestRequestHandler requestHandler;
}

class BayRestPlugin implements BayPlugin {
  InjectorBindings injectorBindings;
  
  BayRestPlugin(this.injectorBindings);
  
  Future<BayRestPlugin> init() {
    
    return new Future.value(this);
  }
}

class BayRestRequestHandler extends RequestHandler {
  RestRouter router;
  
  bool accepts(HttpRequest request) =>
    router.accepts(request);

  Future<HttpRequest> handle(HttpRequest request) =>
      router.route(request);
}