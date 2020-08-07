import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import '../proto/rule.pb.dart';
import '../utils.dart';

/// A class that wraps around Cloud Firestore.
class FirestoreClient {
  /// The name of collection of users in Firestore.
  static const usersCollectionName = 'users';

  /// The name of the collection of rules in Firestore.
  static const rulesCollectionName = 'rules';

  /// The name of the encrypted refresh token field in Firestore.
  static const encryptedRefreshTokenFieldName = 'encryptedRefreshToken';

  /// The Firestore API.
  final FirestoreApi _api;

  /// The Google Cloud project ID.
  final String projectId;

  /// The Cloud Firestore database ID.
  final String databaseId;

  /// Creates an instance of [FirestoreClient].
  FirestoreClient(
      Client client, this.projectId, this.databaseId, String baseUrl)
      : _api = FirestoreApi(client, rootUrl: baseUrl);

  /// Adds a rule to the Firestore database.
  ///
  /// The [rule] is an instance of [Rule], a protobuf generated class.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<String> createRule(String userId, Rule rule) async {
    final document = rule.toDocument();

    return await _addDocument(
      '/$usersCollectionName/$userId',
      rulesCollectionName,
      document,
    );
  }

  /// Adds a user to the Firestore database along with the encrypted refresh
  /// token.
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
      usersCollectionName,
      document,
      documentId: userId,
    );
  }

  /// Gets the user's encrypted refresh token given the [userId].
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<String> getEncryptedUserRefreshToken(String userId) async {
    final document = await _getDocument('/$usersCollectionName/$userId');

    final encryptedRefreshToken =
        document.fields[encryptedRefreshTokenFieldName].stringValue;

    return encryptedRefreshToken;
  }

  /// Get a [Document] located at [path] from Firestore.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  Future<Document> _getDocument(String path) async {
    final document = await _api.projects.databases.documents
        .get('projects/$projectId/databases/$databaseId/documents$path');

    return document;
  }

  /// Adds a document to the Firestore database.
  ///
  /// The [parent] is the parent resource. This can be
  /// `projects/$projectId/databases/$databaseId/documents` or any sub-document.
  ///
  /// The [collection] is the name of the collection relative to [parent] where
  /// the new document will be added.
  ///
  /// The [documentId] optionally allows a custom name for the document.
  ///
  /// Throws an [ApiRequestError] if Firestore API returns an error.
  /// Returns the name of the new document.
  Future<String> _addDocument(
      String parent, String collection, Document document,
      {String documentId}) async {
    final newDocument = await _api.projects.databases.documents.createDocument(
        document,
        'projects/$projectId/databases/$databaseId/documents$parent',
        collection,
        documentId: documentId);

    // [Document.name] is the resource name.
    // For example: projects/$projectId/databases/$databaseId/documents$path
    // To get the name of the document, we have to split it by '/' and get the
    // last string.
    final documentName = newDocument.name.split('/').last;

    return documentName;
  }
}
