library bay.rest.router;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:bay/bay.dart';
import 'package:http_server/http_server.dart';
import 'annotations.dart';
import 'parameter_resolution.dart';
import 'resources.dart';
import 'response_processing.dart';

class RouterModule extends BaseModule {

  @override
  configure() {
    install(new ParameterResolutionModule());
    install(new ResponseProcessingModule());
    bind(RestRouter);
  }
}

class RestRouter {
  List<Resource> resources;
  InjectorBindings injectorBindings;
  ParameterResolver parameterResolver;
  ResponseHandler responseHandler;

  RestRouter(this.injectorBindings,
             this.parameterResolver,
             this.responseHandler) {
    _mapResources();
  }

  bool accepts(HttpRequest request) => findResource(request) != null;

  Future<HttpRequest> route(HttpRequest request) {
    var resource = findResource(request);

    if (resource == null) {
      throw new StateError("No suitable resource found.");
    }

    var resourceMethod = resource.findMethod(request);

    return handle(resourceMethod, request);
  }

  Future<HttpRequest> handle(ResourceMethod resourceMethod,
                              HttpRequest request) {
    var requestBody;

    return HttpBodyHandler.processRequest(request)
            .then((httpRequestBody) {
              requestBody = httpRequestBody;
              var request = requestBody.request;

              var resourceObject = resourceMethod.owner.binding.getInstance();

              var resourceMirror = reflect(resourceObject);
              var parameterResolution =
                  parameterResolver.resolveParameters(resourceMethod,
                                                      requestBody);

              var response = resourceMirror.invoke(
                                    resourceMethod.name,
                                    parameterResolution.positionalArguments,
                                    parameterResolution.namedArguments)
                                      .reflectee;

                return response;
            })
            .then((response) =>
              responseHandler
                .handleResponse(resourceMethod, requestBody, response)
                .then((_) => request)
            );
  }

  Resource findResource(HttpRequest request) =>
      resources.firstWhere(
          (resource) => resource.accepts(request),
          orElse: () => null);

  _mapResources() {
    resources = injectorBindings
      .classAnnotatedWithType(Path)
      .map((binding) => new Resource(binding))
      .toList(growable: false);
  }

}
