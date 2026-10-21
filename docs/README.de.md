# Campus Personal V5

[English](../README.md) | [简体中文](README.zh-CN.md) | **Deutsch**

Ein persönlicher Android-Fork von [TUM-Dev/campus_flutter](https://github.com/TUM-Dev/campus_flutter). Er stellt den Aufruf von Lehrveranstaltungsdetails aus dem Kalender über den öffentlich lesbaren Endpunkt der TUMonline-Kurswebseite wieder her.

Version **5.3.1+5** · **Android 10+** · Paket `de.tum.in.tumcampus.personal` · App-Name **Campus Personal**.

## Änderungen

- Tatsächliche Kurstitel, Semester, Lehrteam, Inhalte, Lernziele und weitere vorhandene Angaben aus TUMonline lesen.
- Kalenderlinks im Format `lv.detail?cLvNr=...` erkennen, die frühere persönliche Versionen nicht unterstützten.
- Laden, Erfolg und Fehler getrennt anzeigen. Bei Fehlern erscheinen nur die Fehlermeldung und eine Wiederholen-Schaltfläche; fehlende Angaben werden ausgelassen.
- Räume anhand ihrer vollständigen Raumkennung mit der NavigaTUM-Suche verknüpfen.
- Das bereitgestellte blaue App-Symbol und einen eigenen Android-Paketnamen verwenden.

## Fehleranalyse: Sprache wählen

[English](lecture-data.en.md) · [简体中文](lecture-data.zh-CN.md) · [Deutsch](lecture-data.de.md)

Die Analyse unterscheidet den Ausfall der alten API der ursprünglichen App vom cLvNr-Parsingfehler früherer persönlicher Versionen. Sie erläutert Datenabruf, XML-Feldzuordnung, Darstellung und Prüfumfang.

## Bauen

Für V5 wurden Flutter **3.47.7**, Dart **3.13.5**, JDK **21**, Android SDK **36**, Build-Tools **35.0.0** und NDK **28.2.13676358** verwendet.

```powershell
flutter pub get
flutter test
$env:CAMPUS_PERSONAL_BUILD='true'
flutter build apk --release --target lib/main.dart --dart-define=PERSONAL_BUILD=true
```

Beide Schalter für den persönlichen Build müssen gesetzt sein. Die APK liegt anschließend unter `build/app/outputs/flutter-apk/app-release.apk`. Ohne konfigurierten Release-Schlüssel wird der lokale Android-Debug-Schlüssel verwendet. Für kompatible Updates muss derselbe Signaturschlüssel erhalten bleiben. Der private Schlüssel der zuvor ausgelieferten APK ist hier nicht enthalten.

Vollständige Build- und Android-Testbefehle stehen in [README_PERSONAL.md](../README_PERSONAL.md). Der [persönliche Android-Build-Workflow](../.github/workflows/build_personal.yml) wird manuell gestartet; dieser Upload führt ihn nicht aus.

## V5-Prüfergebnisse

Am **20.10.2026** bestanden 141 Flutter-Tests sowie die relevante statische Analyse. Zwei Kursfälle wurden auf einem Android-15-Emulator über echte Netzwerkzugriffe geladen; ihre Lehrinhalte konnten durch Scrollen angezeigt werden. Signatur, Installation als Update und Kaltstart der Release-APK wurden ebenfalls geprüft. Dies sind dokumentierte V5-Ergebnisse, keine erneute Prüfung des Serverzustands am Uploadtag.

[Android-Bilder](images/) · [Prüfprotokolle](validation/) · [Prüfumfang](lecture-data.de.md#prüfung-und-grenzen)

Die persönliche Belegungsliste verwendet weiterhin einen separaten alten Dienst. Dessen Warnung in der Berechtigungsansicht kann bestehen bleiben, obwohl die öffentlichen Kursdetails aus dem Kalender funktionieren.

## Herkunft und Lizenz

App-Quellcode, Assets, Tests und Build-Skripte stammen aus dem ausgelieferten V5-Quellstand auf Basis des Upstream-Commits `9b10141dc53b9552945245a9a978a0b8405a7153`. Die [GPL-3.0-Lizenz](../LICENSE) und die [ursprüngliche README](upstream-README.md) bleiben erhalten. Dies ist ein inoffizieller persönlicher Fork.

Dokumentation und Sprachauswahl wurden am **21.10.2026** ergänzt. [Herkunftsnachweis](source-provenance.md) enthält Prüfsummen und die Änderungen für die Veröffentlichung. APKs, SDKs, Caches und Signaturschlüssel werden nicht in Git gespeichert.
