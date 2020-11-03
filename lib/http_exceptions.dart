class UnknownApiException implements Exception{
  int httpCode;

  UnknownApiException(this.httpCode);
}

class ItemNotFoundException implements Exception{}
class InternalServerErrorException implements Exception{}
class NetworkException implements Exception{}
