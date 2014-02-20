library bay.rest.filters;

import 'dart:async';
import 'dart:mirrors';
import 'package:bay/bay.dart';
import 'package:dado/dado.dart';
import 'package:uri/uri.dart';
import 'package:http_server/http_server.dart';
import 'annotations.dart';

class FilterScanner {
  
  FilterScanner();
  
  Map<UriPattern, Key> scanFilters() {
    var filters = {};
    bay.injector.bindings.forEach(
      (binding) {
        var typeMirror = reflectType(binding.key.type);
        var filterMetadataMirror = typeMirror.metadata.firstWhere(
          (metadata) => metadata.reflectee is Filter
        , orElse: () => null);
        
        if (filterMetadataMirror !=  null) {
          var filterMetadata = filterMetadataMirror.reflectee;
          var uriPattern = new UriParser(new UriTemplate(filterMetadata.path));
          filters[uriPattern] = binding.key;
        }
    });
    
    return filters;
  }
  
}

abstract class ResourceFilter {
  
  Future<HttpRequestBody> filter(HttpRequestBody httpRequestBody);
  
}