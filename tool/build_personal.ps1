param(
    [string]$Flutter = 'flutter',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\build\personal')
)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
$previous = $env:ORG_GRADLE_PROJECT_personalBuild
$previousPersonal = $env:CAMPUS_PERSONAL_BUILD
try {
    $env:ORG_GRADLE_PROJECT_personalBuild = 'true'
    $env:CAMPUS_PERSONAL_BUILD = 'true'
    & $Flutter pub get
    if ($LASTEXITCODE) { throw 'Dependency resolution failed' }
    & $Flutter test test/tumOnlineApi/lecture_recovery_test.dart test/tumOnlineApi/lecture_recovery_widget_test.dart test/tumOnlineApi/calendar_event_computed_test.dart test/tumOnlineApi/public_course_test.dart
    if ($LASTEXITCODE) { throw 'Lecture regression tests failed' }
    & $Flutter build apk --release --dart-define=PERSONAL_BUILD=true
    if ($LASTEXITCODE) { throw 'APK build failed' }
    New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
    Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Destination (Join-Path $OutputDirectory 'campus-personal.apk')
} finally {
    $env:ORG_GRADLE_PROJECT_personalBuild = $previous
    $env:CAMPUS_PERSONAL_BUILD = $previousPersonal
    Pop-Location
}
