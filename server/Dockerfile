FROM google/dart-runtime-base

WORKDIR /server/app

ADD pkg/proto/pubspec.yaml /server/pkg/proto/

ADD app/pubspec.* /server/app/
RUN pub get
ADD . /server
RUN pub get --offline