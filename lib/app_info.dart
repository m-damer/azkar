/// Shown on the About screen. Keep in step with pubspec.yaml.
const String appVersion = '1.0';

/// CI passes the run number (also the Android versionCode). 0 in local builds.
const int buildNumber = int.fromEnvironment('BUILD_NUMBER', defaultValue: 0);

/// GitHub release tag the app checks for new APKs.
const String updateTag = String.fromEnvironment('UPDATE_TAG', defaultValue: 'dev');
