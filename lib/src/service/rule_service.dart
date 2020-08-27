import 'dart:async';

import 'package:angular/angular.dart';
import 'package:http/http.dart';

import '../data_model/create_user_request.pb.dart';
import '../data_model/rule.pb.dart';

/// A class to interact with the Rules Builder server.
@Injectable()
class RuleService {
  /// The base URL of the Rules Builder server.
  static const serverUrl =
      'https://rules-server-dot-spreadsheet-dv360-plugin.uc.r.appspot.com';

  /// The endpoint for operations on users.
  static const usersEndpoint = '$serverUrl/users';

  /// The endpoint for operations on rules.
  static const rulesEndpoint = '$serverUrl/rules';

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
  Future<void> createRule(String idToken, Rule rule) async {
    final headers = {
      'Content-Type': 'application/x-protobuf',
      'Authorization': 'Bearer $idToken'
    };
    await post(rulesEndpoint, body: rule.writeToBuffer(), headers: headers);
  }
}
