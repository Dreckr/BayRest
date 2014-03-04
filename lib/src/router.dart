library bay.rest.router;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:bay/bay.dart';
import 'package:http_server/http_server.dart';
import 'annotations.dart';
import 'requests.dart';
import 'resources.dart';
import 'responses.dart';

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
                  parameterResolver.resolveParameters(resourceMethod, requestBody);
              
              var response = 
                  resourceMirror.invoke(resourceMethod.name, 
                                        parameterResolution.positionalArguments,
                                        parameterResolution.namedArguments).reflectee;
              
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
//
//class Router {
//  List<Resource> resources;
//  Map<UriPattern, Key> filters;
//  
//  Future<HttpRequestBody> handleRequest(HttpRequest request) {
//    var completer = new Completer<HttpRequestBody>();
//    
//    var resourceMethod;
//    try {
//      resourceMethod = _findResourceMethod(httpRequestBody);
//
//      if (resourceMethod == null) {
//        throw new ResourceNotFoundException(httpRequestBody.request.uri.path);
//      }
//    } catch (error, stackTrace) {
//      completer.completeError(error, stackTrace);
//      return completer.future;
//    }
//    
//    _applyFilters(httpRequestBody).then(
//      (httpRequest) {
//        _callResourceMethod(resourceMethod, httpRequest).then(
//          (httpRequest) {
//            completer.complete(httpRequest);
//        }, onError: (error, stackTrace) => 
//                                  completer.completeError(error, stackTrace));
//      }, onError: (error, stackTrace) => 
//                                  completer.completeError(error, stackTrace));
//    
//    return completer.future;
//  }
//  
//  Future<HttpRequestBody> _applyFilters(HttpRequestBody httpRequestBody) {
//    var completer = new Completer<HttpRequestBody>();
//    var matchingFilters = new List<ResourceFilter>();
//    filters.forEach(
//      (pattern, key) {
//        if (pattern.matches(httpRequestBody.request.uri)) {
//          var resourceFilter;
//          
//          try {
//            resourceFilter = bay.injector.getInstanceOfKey(key);
//          } catch (error, stackTrace) {
//            completer.completeError(error, stackTrace);
//          }
//          
//          if (resourceFilter is ResourceFilter) {
//            matchingFilters.add(resourceFilter);
//          }
//        }
//    });
//    
//    if (completer.isCompleted) {
//      return completer.future;
//    }
//    
//    _iterateThroughFilters(matchingFilters.iterator, httpRequestBody).then(
//        (httpRequest) => completer.complete(httpRequest),
//        onError: (error, stackTrace) => 
//            completer.completeError(error, stackTrace)
//        );
//    
//    return completer.future;
//  }
//  
//  // TODO(diego): Should be replaced with a chain of responsability?
//  Future<HttpRequestBody> _iterateThroughFilters(
//                       Iterator<ResourceFilter> resourceFilterIterator, 
//                       HttpRequestBody httpRequestBody,
//                       [Completer completer]) {
//    if (completer == null) {
//      completer = new Completer<HttpRequestBody>();
//    }
//    
//    if (resourceFilterIterator.moveNext()) {
//      try {
//        resourceFilterIterator.current.filter(httpRequestBody).then(
//          (httpRequestBody) {
//              _iterateThroughFilters(resourceFilterIterator, 
//                                   httpRequestBody, 
//                                   completer);
//        }, onError: (error, stackTrace) => 
//            completer.completeError(error, stackTrace));
//      } catch (error, stackTrace) {
//        completer.completeError(error, stackTrace);
//      }
//    } else {
//      completer.complete(httpRequestBody);
//    }
//    
//    return completer.future;
//  }
//  
//  ResourceMethod _findResourceMethod(HttpRequestBody httpRequestBody) {
//    Resource matchingResource;
//    ResourceMethod matchingMethod;
//    HttpRequest request = httpRequestBody.request;
//    
//    resources.forEach(
//        (resource) {
//          if (resource.pathPattern.matches(request.uri)) {
//            if (matchingResource == null) {
//              matchingResource = resource;
//            } else {
//              throw new MultipleMatchingResourcesError(request.uri.path);
//            }
//          }
//          
//          if (matchingResource != null) {
//            matchingResource.methods.forEach(
//              (method) {
//                var match = method.pathPattern.match(request.uri);
//                if (match != null && 
//                    match.rest.path.length == 0 &&
//                    method.method == request.method) {
//                  if (matchingMethod == null) {
//                    matchingMethod = method;
//                  } else {
//                    throw 
//                      new MultipleMatchingResourcesError(request.uri.path);
//                  }
//                }
//              });
//          }
//    });
//    
//    return matchingMethod;
//  }
//  
//  Future<HttpRequestBody> _callResourceMethod(ResourceMethod resourceMethod, 
//      HttpRequestBody httpRequestBody) {
//    var completer = new Completer<HttpRequestBody>();
//    requestHandler
//      .handleRequest(resourceMethod, httpRequestBody)
//      .then(
//        (response) =>
//          responseHandler
//            .handleResponse(resourceMethod, httpRequestBody, response)
//        ,onError: (error, stackTrace) => 
//            completer.completeError(error, stackTrace))
//      .then((_) { 
//        if (!completer.isCompleted)
//          completer.complete(httpRequestBody);
//      },
//            onError: (error, stackTrace) => 
//              completer.completeError(error, stackTrace));
//              
//    
//    return completer.future;
//  }
//  
//}
