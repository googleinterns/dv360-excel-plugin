import 'dart:async';

import 'package:http/http.dart';

import '../data_model/create_user_request.pb.dart';
import '../data_model/get_rules_response.pb.dart';
import '../data_model/get_run_history.pb.dart';
import '../data_model/rule.pb.dart';

/// A class to interact with the Rules Builder server.
class RuleService {
  /// The base URL of the Rules Builder server.
  static const serverUrl =
      'https://rules-server-dot-spreadsheet-dv360-plugin.uc.r.appspot.com';

  /// The endpoint for operations on users.
  static const usersEndpoint = '$serverUrl/users';

  /// The endpoint for operations on rules.
  static const rulesEndpoint = '$serverUrl/rules';

  /// The endpoint for run history.
  static const runHistoryEndpoint = '$serverUrl/run_history';

  /// Creates a user using the user's ID token and refresh token.
  Future<void> createUser(String idToken, String refreshToken) async {
    final headers = {
      'Content-Type': 'application/x-protobuf',
      'Authorization': 'Bearer $idToken'
    };
    final createUserRequest = CreateUserRequest()..refreshToken = refreshToken;
    await post(usersEndpoint,
        body: createUserRequest.writeToBuffer(), headers: headers);
  }

  /// Creates a rule using the user's ID token and rule proto.
  ///
  /// Returns the status code of the response.
  Future<int> createRule(String idToken, Rule rule) async {
    final headers = {
      'Content-Type': 'application/x-protobuf',
      'Authorization': 'Bearer $idToken'
    };
    final response =
        await post(rulesEndpoint, body: rule.writeToBuffer(), headers: headers);
    return response.statusCode;
  }

  /// Gets the rules of a user given their [idToken].
  Future<List<Rule>> getRules(String idToken) async {
    final headers = {
      'Content-Type': 'application/x-protobuf',
      'Authorization': 'Bearer $idToken'
    };
    final response = await get(rulesEndpoint, headers: headers);
    return GetRulesResponse.fromBuffer(response.bodyBytes).rules;
  }

  Future<GetRunHistoryResponse> getRunHistory(
      String idToken, String ruleId) async {
    final headers = {
      'Content-Type': 'application/x-protobuf',
      'Authorization': 'Bearer $idToken'
    };
    final url = Uri.parse(runHistoryEndpoint)
        .replace(queryParameters: {'ruleId': ruleId});
    final response = await get(url.toString(), headers: headers);
    return GetRunHistoryResponse.fromBuffer(response.bodyBytes);
  }
}
