import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart';

import 'proto/rule.pb.dart';

/// An extension on the [Rule] protobuf generated class.
extension DocumentConversion on Rule {
  /// Extends the [Rule] protobuf generated class to be able to convert to a
  /// Firestore [Document].
  ///
  /// This is necessary because [Document.fields] is a map with [Value] values.
  /// [Value] is a union type. See:
  /// https://pub.dev/documentation/googleapis/latest/googleapis.firestore.v1/Value-class.html
  ///
  /// We will first convert [Rule] to a JSON format before converting to
  /// [Document]. In this way, we can minimize coupling between the proto schema
  /// and how we construct the document (and vice versa).
  Document toDocument() {
    // First, transform the [Rule] into a standard JSON string.
    // [toProto3Json()] is used to convert to the proto3 JSON format instead of
    // [writeToJson()] because the representation is much more readable.
    final jsonString = jsonEncode(toProto3Json());

    // Next, decode the JSON string into a JSON object.
    // We pass in a reviver function [packValue()] that is called for every
    // object that is parsed while decoding. This allows us to transform it
    // into a valid [Document] structure.
    final transformedJsonObject =
        jsonDecode(jsonString, reviver: packValue)['mapValue'];

    return Document.fromJson(transformedJsonObject as Map<dynamic, dynamic>);
  }
}

/// An extension on the Firestore [Document] class.
extension ProtoConversion on Document {
  /// Extends the [Document] class to be able to convert to a protobuf
  /// generated [Rule].
  ///
  /// This is necessary because [Document.fields] is a map with [Value] values.
  /// [Value] is a union type. See:
  /// https://pub.dev/documentation/googleapis/latest/googleapis.firestore.v1/Value-class.html
  ///
  /// We will first convert the [Document] to a JSON format before converting
  /// to [Rule]. In this way, we can minimize coupling between the proto schema
  /// and the document.
  Rule toProto() {
    // First, create a [Value] with a mapValue set to the fields in the
    // [Document].
    final documentJsonFormat = Value()
      ..mapValue = (MapValue()..fields = fields);

    // Next, convert unpack each [Value] recursively into a valid JSON
    // protobuf format.
    final protoJsonFormat = unpackValue(documentJsonFormat);

    // Finally, create and return the [Rule] from the JSON object.
    return Rule()..mergeFromProto3Json(protoJsonFormat);
  }
}

/// Converts an object with type T to a [Value] structured object depending
/// on type T.
///
/// Can be used as a reviver function when parsing a JSON string with
/// [jsonDecode()].
Object packValue(Object key, Object value) {
  if (value is bool) return {'booleanValue': value};
  if (value is double) return {'doubleValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is Int64) return {'integerValue': value};
  if (value is String) return {'stringValue': value};
  if (value is DateTime) return {'timestampValue': value.toIso8601String()};
  if (value is List) {
    return {
      'arrayValue': {'values': value}
    };
  }
  if (value is Map) {
    return {
      'mapValue': {'fields': value}
    };
  }

  return '';
}

/// Unpacks a [Value] object recursively depending on its underlying type.
///
/// See:
/// https://pub.dev/documentation/googleapis/latest/googleapis.firestore.v1/Value-class.html
Object unpackValue(Value packedValue) {
  Object unpacked;

  // Only one of [packedValue]'s .*Value fields will be set.
  // The others will be null.
  unpacked ??= packedValue.booleanValue;
  unpacked ??= packedValue.doubleValue;
  unpacked ??= packedValue.integerValue;
  unpacked ??= packedValue.stringValue;
  unpacked ??= packedValue.timestampValue;
  unpacked ??= packedValue.arrayValue?.values?.map(unpackValue)?.toList();
  if (unpacked != null) return unpacked;

  // If the value is a map value, recurse and create a new map.
  final newMap = {};
  packedValue.mapValue?.fields?.forEach((key, value) {
    newMap[key] = unpackValue(value);
  });

  return newMap;
}

/// Encrypts the [unencrypted] string using the AES key.
///
/// To generate a random key:
/// ```
/// pub global activate encrypt
/// secure-random
/// ```
///
/// See here:
/// https://pub.dev/packages/encrypt
String encryptRefreshToken(String unencrypted, String aesKey) {
  final key = Key.fromBase64(aesKey);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  return encrypter.encrypt(unencrypted, iv: iv).base64;
}

/// Decrypts the [encrypted] string using the AES key.
///
/// See here:
/// https://pub.dev/packages/encrypt
String decryptRefreshToken(String encrypted, String aesKey) {
  final key = Key.fromBase64(aesKey);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  return encrypter.decrypt(Encrypted.fromBase64(encrypted), iv: iv);
}
