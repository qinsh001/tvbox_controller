import 'dart:convert';
import 'dart:io';

enum HttpRequestReturnType { JSON, STRING, FULLRESPONSE }
///
/// Helper class for http requests
///
class XHttpUtils {
  static HttpClient client = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  ///
  /// Sends a HTTP GET request to the given [url] with the given [queryParameters] and [headers].
  ///
  static Future<dynamic> _get(String url,
      {Map<String, dynamic>? queryParameters,
      Map<String, String>? headers,
      HttpRequestReturnType returnType = HttpRequestReturnType.JSON}) async {
    var finalUrl = _getUriUrl(url, queryParameters);

    var response = await client.getUrl(finalUrl);
    headers?.keys.forEach((key) {
      response.headers.set(key, "${headers[key]}");
    });
    final res = await response.close();
    return _handleResponse(res, returnType);
  }

  ///
  /// Sends a HTTP GET request to the given [url] with the given [queryParameters] and [headers].
  /// Returns the full [Response] object.
  ///
  static Future<HttpClientResponse> getForFullResponse(String url,
      {Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) async {
    return await _get(url,
        queryParameters: queryParameters,
        headers: headers,
        returnType: HttpRequestReturnType.FULLRESPONSE) as HttpClientResponse;
  }

  ///
  /// Sends a HTTP GET request to the given [url] with the given [queryParameters] and [headers].
  /// Returns the response as a map using json.decode.
  ///
  static Future<Map<String, dynamic>> getForJson(String url,
      {Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) async {
    return await _get(url,
        queryParameters: queryParameters,
        headers: headers,
        returnType: HttpRequestReturnType.JSON) as Map<String, dynamic>;
  }

  ///
  /// Sends a HTTP GET request to the given [url] with the given [queryParameters] and [headers].
  /// Returns the response as a string.
  ///
  static Future<String> getForString(String url,
      {Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) async {
    return await _get(url,
        queryParameters: queryParameters,
        headers: headers,
        returnType: HttpRequestReturnType.STRING) as String;
  }

  ///
  /// Basic function which handle response and decode JSON. Throws [HttpClientException] if status code not 200-290
  ///
  static dynamic _handleResponse(
      HttpClientResponse response, HttpRequestReturnType returnType) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      switch (returnType) {
        case HttpRequestReturnType.JSON:
          return json.decode(response.toString());
        case HttpRequestReturnType.STRING:
          return response.toString();
        case HttpRequestReturnType.FULLRESPONSE:
          return response;
      }
    } else {}
  }

  ///
  /// Add the given [queryParameters] to the given [url]. If the key for a parameter already exists then it is overwritten.
  ///
  static String addQueryParameterToUrl(
      String url, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return url;

    final existingQueryParameters = getQueryParameterFromUrl(url);

    if (existingQueryParameters != null) {
      queryParameters.addAll(existingQueryParameters);
    }

    return Uri.parse(url).replace(queryParameters: queryParameters).toString();
  }

  static Uri _getUriUrl(String url, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(url);
    }
    return Uri.parse(url).replace(queryParameters: queryParameters);
  }

  ///
  /// Fetches the query parameter from the given [url]. Returns null if none exist.
  ///
  static Map<String, dynamic>? getQueryParameterFromUrl(String url) {
    var queryParameters = <String, dynamic>{};
    var splitted = url.split('?');
    if (splitted.length != 2) {
      return null;
    }
    var query = splitted.elementAt(1);

    var splittedQuery = query.split('&');
    splittedQuery.forEach((String q) {
      var pair = q.split('=');
      var key = Uri.decodeFull(pair[0]);
      var value = '';
      if (pair.length > 1) {
        value = Uri.decodeFull(pair[1]);
      }

      if (key.contains('[]')) {
        if (queryParameters.containsKey(key)) {
          List<dynamic> values = queryParameters[key];
          values.add(value);
        } else {
          var values = [];
          values.add(value);
          queryParameters.putIfAbsent(key, () => values);
        }
      } else {
        if (queryParameters.containsKey(key)) {
          queryParameters.update(key, (value) => value);
        } else {
          queryParameters.putIfAbsent(key, () => value);
        }
      }
    });
    if (queryParameters.isEmpty) {
      return null;
    } else {
      return queryParameters;
    }
  }
}
