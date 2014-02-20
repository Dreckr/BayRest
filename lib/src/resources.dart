library bay.resources;

import 'dart:mirrors';
import 'package:bay/bay.dart';
import 'package:logging/logging.dart';
import 'package:uri/uri.dart';
import 'annotations.dart';
import 'dart:async';
import 'dart:io';

final _resourcesLogger = new Logger("bay.resources");

class Resource {
  String path;
  UriPattern pathPattern;
  BayBinding binding;
  List<ResourceMethod> methods = new List();
  final ClassMirror classMirror;
  
  Resource(BayBinding binding) :
    binding = binding,
    classMirror = reflectClass(binding.key.type) {
    
    path = _findPath(binding);
    pathPattern = new UriParser(new UriTemplate(path));
    
    _mapMethods();
  }
  
  Future<HttpRequest> handle(HttpRequest request) {
    
  }
  
  void _mapMethods() {
    classMirror.declarations.forEach(
      (name, declaration) {
        if (declaration is MethodMirror) {
          var pathMetadataMirror = declaration.metadata.firstWhere(
              (metadata) => metadata.reflectee is Path
              , orElse: () => null);
          
          var methodMetadataMirror = declaration.metadata.firstWhere(
              (metadata) => metadata.reflectee is Method
              , orElse: () => null);
          
          if (pathMetadataMirror == null && methodMetadataMirror == null)
            return;
          
          var method;
          if (methodMetadataMirror != null) {
            method = methodMetadataMirror.reflectee.method;
          } else {
            method = "GET";
          }
          
          var path = "";
          if (pathMetadataMirror != null) {
            path += normalizePath(pathMetadataMirror.reflectee.path);
          }
          
          methods.add(new ResourceMethod(this, name, path, method));
        }
    });
  }
  
  String _findPath(BayBinding binding) {
    var pathMetadata =  reflectClass(binding.key.type).metadata.firstWhere(
        (metadata) => metadata.reflectee is Path, 
        orElse: () => null);
    
    return pathMetadata != null ? pathMetadata.reflectee.path : null;
  }
  
}

class ResourceMethod {
  final Resource owner;
  final Symbol name;
  final String path;
  final UriPattern pathPattern;
  final String method;
  final MethodMirror methodMirror;
  
  ResourceMethod(Resource owner, 
                 Symbol name,
                 String path,
                 String this.method) :
                   owner = owner,
                   path = path,
                   pathPattern = 
                   new UriParser(new UriTemplate(owner.path + path)),
                   name = name,
                   methodMirror = 
                   owner.classMirror.declarations[name];

}

String normalizePath(String path) {
  if (!path.startsWith("/")) {
    path = "/" + path;
  }
  
  if (path.endsWith("/")) {
    path = path.substring(0, path.length - 1);
  }
  
  return path;
}