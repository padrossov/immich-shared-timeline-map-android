#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd "${1:?Pass the patched Immich checkout}" && pwd)
patch_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
phase=${2:-all}
case "$phase" in all|prepare|check|apk) ;; *) echo "Unknown build phase: $phase" >&2; exit 2;; esac
if [[ "$phase" == all || "$phase" == prepare ]]; then
  cd "$source_dir/open-api"
  bash bin/generate-dart-sdk.sh
  cd "$source_dir/mobile"
  flutter pub get --enforce-lockfile
  dart run drift_dev make-migrations
  dart run build_runner build
  while IFS= read -r pigeon_file; do
    dart run pigeon --input "$pigeon_file"
  done < <(find pigeon -maxdepth 1 -name '*.dart' -print | sort)
  dart run easy_localization:generate -S ../i18n
  dart run bin/generate_keys.dart
fi
cd "$source_dir/mobile"
if [[ "$phase" == all || "$phase" == check ]]; then
  python3 "$patch_dir/verify_sql.py" "$source_dir"
  flutter analyze --no-pub --fatal-infos
  flutter test --no-pub test/medium/repositories/shared_album_queries_test.dart test/medium/repositories/timeline_repository_test.dart test/unit/shared_album_preferences_test.dart
fi
if [[ "$phase" == all || "$phase" == apk ]]; then
  # Bound memory use on the small GitHub-hosted runner. This changes only
  # the disposable build checkout, not the feature patch or the server.
  if [[ "${CI:-}" == true ]]; then
    cat >> android/gradle.properties <<'GRADLE'

org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=768m
org.gradle.workers.max=2
org.gradle.parallel=false
kotlin.compiler.execution.strategy=in-process
GRADLE
  fi
  # Use an explicit development keystore location on CI. A caller-provided
  # release keystore takes precedence. No private key is committed/uploaded.
  if [[ "${CI:-}" == true && ! -s android/key.jks ]]; then
    development_keystore="$HOME/.android/debug.keystore"
    if [[ ! -s "$development_keystore" ]]; then
      echo "Existing signing key required; configure ANDROID_KEYSTORE_BASE64 in the fork workflow." >&2
      exit 1
    fi
    install -m 600 "$development_keystore" android/key.jks
    export ALIAS=androiddebugkey ANDROID_KEY_PASSWORD=android ANDROID_STORE_PASSWORD=android
  fi
  # This release-mode client coexists with the official application.
  IMMICH_SHARED_ALBUMS_BUILD=1 flutter build apk --release --target-platform android-arm64
fi
