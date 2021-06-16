import 'exit.dart';
import 'pagination.dart';

class ExitsResponse {
  final List<Exit>? exits;
  final Pagination? pagination;

  ExitsResponse({this.exits, this.pagination});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [ExitsResponse]
  factory ExitsResponse.fromJson(Map<String, dynamic> json) {
    List<Exit>? exits =
        (json['exits'] as List?)?.map((item) => Exit.fromJson(item)).toList();
    return ExitsResponse(exits: exits, pagination: json['pagination']);
  }

  Map<String, dynamic> toJson() => {'exits': exits, 'pagination': pagination};
}
