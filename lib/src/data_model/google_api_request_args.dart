library google_api_request_args;

import 'package:built_value/built_value.dart';

part 'google_api_request_args.g.dart';

abstract class GoogleApiRequestArgs
    implements Built<GoogleApiRequestArgs, GoogleApiRequestArgsBuilder> {
  String get path;
  String get method;

  @nullable
  String get body;

  GoogleApiRequestArgs._();
  factory GoogleApiRequestArgs(
          [Function(GoogleApiRequestArgsBuilder b) updates]) =
      _$GoogleApiRequestArgs;
}
