library bay.rest.core;

import 'dart:async';
import 'dart:io';
import 'package:bay/bay.dart';
import 'requests.dart';
import 'responses.dart';
import 'router.dart';

class BayRestModule extends DeclarativeModule {
  
  BayRestPlugin plugin;
  BayRestRequestHandler requestHandler;
  RestRouter router;
  ParameterResolver parameteResolver;
  ResponseHandler responseHandler;
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
  
  BayRestRequestHandler(this.router);
  
  bool accepts(HttpRequest request) =>
    router.accepts(request);

  Future<HttpRequest> handle(HttpRequest request) =>
    router.route(request);
}