import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// Requests whose path starts with [pathPrefix] go to [baseUrl] instead of
/// the Dio's default host (`BASE_URL`) — an app whose endpoints live behind
/// more than one backend declares one route per prefix (Songlet: its product
/// backend by default, `/app/config` on the platform). Matching is per path
/// segment: `/app/config` claims `/app/config` and `/app/config/x`, not
/// `/app/configs`.
@immutable
class EndpointRoute {
  const EndpointRoute(this.pathPrefix, this.baseUrl);

  final String pathPrefix;
  final String baseUrl;

  bool claims(String path) {
    final bare = path.split('?').first;
    return bare == pathPrefix || bare.startsWith('$pathPrefix/');
  }
}

/// First in every Dio chain: points a request at its route's host before it
/// is signed, sent, retried or replayed (they all reuse the same options, so
/// a retry or a re-signed replay stays on that host). Absolute URLs are left
/// alone; unrouted paths keep the default host.
class EndpointRoutingInterceptor extends Interceptor {
  EndpointRoutingInterceptor(this.routes);

  final List<EndpointRoute> routes;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (!path.startsWith('http://') && !path.startsWith('https://')) {
      for (final route in routes) {
        if (route.claims(path)) {
          options.baseUrl = route.baseUrl;
          break;
        }
      }
    }
    handler.next(options);
  }
}
