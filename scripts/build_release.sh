#!/usr/bin/env sh

set -eu

flutter pub get
dart analyze
flutter test
flutter build web --release
