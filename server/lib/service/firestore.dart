import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../proto/rule.pb.dart';
import '../utils.dart';

/// A class that wraps around Cloud Firestore.
class FirestoreClient {
  /// The name of collection of users in Firestore.
  static const usersName = 'users';

  /// The name of the collection of rules in Firestore.
  static const rulesName = 'rules';

  /// The name of the collection of the run history in Firestore.
  static const runHistoryName = 'runHistory';

  /// The name of the encrypted refresh token field in Firestore.
  static const encryptedRefreshTokenFieldName = 'encryptedRefreshToken';

  /// The Firestore API.
  final FirestoreApi _api;

  /// The Google Cloud project ID.
  final String _projectId;

  /// The Cloud Firestore database ID.
  final String _databaseId;

  /// Creates an instance of [FirestoreClient].
  FirestoreClient(
      Client client, this._projectId, this._databaseId, String baseUrl)
      : _api = FirestoreApi(client, rootUrl: baseUrl);

  /// Adds a protobuf generated [Rule] to the Firestore database.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<String> createRule(String userId, Rule rule) async {
    final document = rule.toDocument();

    return await _addDocument(
      '/$usersName/$userId',
      rulesName,
      document,
    );
  }

  /// Adds a user to the Firestore database with the encrypted refresh token.
  ///
  /// The [userId] is the `sub` claim of the user's Google ID token.
  /// See: https://developers.google.com/identity/protocols/oauth2/openid-connect#an-id-tokens-payload
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<void> createUser(String userId, String encryptedRefreshToken) async {
    final document = Document()
      ..fields = {
        encryptedRefreshTokenFieldName: Value()
          ..stringValue = encryptedRefreshToken
      };

    await _addDocument(
      '',
      usersName,
      document,
      documentId: userId,
    );
  }

  /// Logs [isSuccess] and optional [message] of a performed rule with [ruleId].
  ///
  /// The [userId] is the `sub` claim of the user's Google ID token.
  /// See: https://developers.google.com/identity/protocols/oauth2/openid-connect#an-id-tokens-payload
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<void> logRunHistory(String userId, String ruleId, bool isSuccess,
      {String message = ''}) async {
    final document = Document()
      ..fields = {
        'timestamp': Value()
          ..timestampValue = DateTime.now().toUtc().toIso8601String(),
        'success': Value()..booleanValue = isSuccess,
        'message': Value()..stringValue = message
      };

    await _addDocument(
      '/$usersName/$userId/$rulesName/$ruleId',
      runHistoryName,
      document,
    );
  }

  /// Gets the user's encrypted refresh token given the [userId].
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<String> getEncryptedUserRefreshToken(String userId) async {
    final document = await _getDocument('/$usersName/$userId');

    final encryptedRefreshToken =
        document.fields[encryptedRefreshTokenFieldName].stringValue;

    return encryptedRefreshToken;
  }

  /// Gets the [Rule] uniquely identified by its [userId] and [ruleId].
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<Rule> getRule(String userId, String ruleId) async {
    final ruleDocument = await _getDocument('/users/$userId/rules/$ruleId');
    return ruleDocument.toProto();
  }

  /// Gets a [Document] located at [path] from Firestore.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<Document> _getDocument(String path) async {
    final document = await _api.projects.databases.documents
        .get('projects/$_projectId/databases/$_databaseId/documents$path');

    return document;
  }

  /// Adds a document to the Firestore database.
  ///
  /// The [parent] is the parent resource. This can be
  /// `projects/$projectId/databases/$databaseId/documents` or any sub-document.
  ///
  /// The [collectionName] is the name of the collection relative to [parent]
  /// where the new document will be added.
  ///
  /// The [documentId] optionally allows a custom name for the document.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  /// Returns the name of the new document.
  Future<String> _addDocument(
      String parent, String collectionName, Document document,
      {String documentId}) async {
    final newDocument = await _api.projects.databases.documents.createDocument(
        document,
        'projects/$_projectId/databases/$_databaseId/documents$parent',
        collectionName,
        documentId: documentId);

    // [Document.name] is the resource name.
    // For example: projects/$projectId/databases/$databaseId/documents$path
    // To get the name of the document, we have to split it by '/' and get the
    // last string.
    final documentName = newDocument.name.split('/').last;

    return documentName;
  }
}
