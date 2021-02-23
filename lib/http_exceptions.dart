class UnknownApiException implements Exception {
  int httpCode;

  UnknownApiException(this.httpCode);
}

class ItemNotFoundException implements Exception {
  String message;

  ItemNotFoundException(this.message);
}

class InternalServerErrorException implements Exception {
  String message;

  InternalServerErrorException(this.message);
}

class NetworkException implements Exception {}
