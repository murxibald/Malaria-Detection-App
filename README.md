App zur Diagnose von Malaria anhand von Blutproben

## Voraussetzungen

Für die Arbeit an diesem Projekt werden die Programmiersprachen Dart und [Python](https://www.python.org/downloads/), die Frameworks [Flutter](https://docs.flutter.dev/get-started/install) und [TensorFlow](https://www.tensorflow.org/install) sowie die Entwicklungsumgebungen [Android Studio](https://developer.android.com/studio) und [Jupyter Notebook](https://jupyter.org/install#jupyter-notebook) benötigt.

## Arbeit

* Der Branch `main` kann nur über Merge-Operationen verändert werden.
* Die Entwicklung der App findet im Ordner `lib` statt. Hierfür eignet sich Android Studio mit installiertem Flutter PlugIn. Pakete können über den Befehl  `flutter pub add <name des pakets>` installiert werden. Die Verwendung der Programmiersprache Dart ist generell [hier](https://dart.dev/language) und Flutter-spezifisch [hier](https://docs.flutter.dev/ui) dokumentiert. Das offizielle [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter) ist nötig, um den in TensorFlow entwickelten Algorithmus in der App zu implementieren.
* Die Entwicklung des Algorithmus findet im Ordner `cell_classification` statt. Hierfür eignet sich Jupyter Notebook. Pakete können über den Befehl `pip install <name des pakets>` installiert werden. Die Verwendung der Programmiersprache Python ist generell [hier](https://www.w3schools.com/python) und TensorFlow-spezifisch [hier](https://www.tensorflow.org/tutorials) dokumentiert.

## Ausführung

Die App kann über den Befehl `flutter run` ausgeführt werden. Sie kann eintweder in einem Emulator in Android Studio oder auf einem Android Smartphone, das per USB-Kabel an den Rechner angeschlossen ist, ausgeführt werden. Das Smartphone muss dafür im Entwicklermodus sein. Um sicherzustellen, dass alle Abhängigkeiten erfüllt sind, kann der Befehl `pub get` ausgeführt werden.