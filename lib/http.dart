import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'http_exceptions.dart';

Future<String> extractJSON(http.Response response) async {
  return response.body;
}

Future<http.Response> get(String baseAddress, String endpoint,
    {Map<String, String> queryParameters}) async {
  try {
    var uri;
    if (queryParameters != null) {
      uri = Uri.https(baseAddress, '$API_VERSION$endpoint', queryParameters);
    } else {
      uri = Uri.https(baseAddress, '$API_VERSION$endpoint');
    }
    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    return returnResponseOrThrowException(response);
  } on IOException catch (e) {
    print(e.toString());
    //throw NetworkException();
  }
}

Future<http.Response> post(String baseAddress, String endpoint,
    {Map<String, dynamic> body}) async {
  try {
    var uri;
    uri = Uri.https(baseAddress, '$API_VERSION$endpoint');
    final response = await http.post(
      uri,
      body: json.encode(body),
      headers: {
        HttpHeaders.acceptHeader: '*/*',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    return returnResponseOrThrowException(response);
  } on IOException {
    throw NetworkException();
  } catch (e) {
    print(e);
  }
}

/*Future<http.Response> _put(dynamic task) async {
  try {
    final response = await http.put(
      '$_baseAddress/todos/${task.id}',
      body: json.encode(task.toJson()),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    return returnResponseOrThrowException(response);
  } on IOException {
    throw NetworkException();
  }
}

Future<http.Response> _delete(String id) async {
  try {
    final response = await http.delete(
      '$_baseAddress/todos/$id',
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    return returnResponseOrThrowException(response);
  } on IOException {
    throw NetworkException();
  }
}*/

http.Response returnResponseOrThrowException(http.Response response) {
  if (response.statusCode == 404) {
    // Not found
    throw ItemNotFoundException(response.body);
  } else if (response.statusCode == 500) {
    throw InternalServerErrorException(response.body);
  } else if (response.statusCode == 400) {
    String responseBody = '';
    if (response.bodyBytes != null) {
      responseBody = response.body;
    }
    throw BadRequestException(responseBody);
  } else if (response.statusCode > 400) {
    throw UnknownApiException(response.statusCode);
  } else {
    return response;
  }
}
