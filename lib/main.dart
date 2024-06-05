import 'dart:io';
import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          highlightColor: const Color(0xFFD0996F),
          canvasColor: const Color(0xFFFDF5EC),
          textTheme: TextTheme(
            headlineSmall: ThemeData
                .light()
                .textTheme
                .headlineSmall!
                .copyWith(color: const Color(0xFFBC764A)),
          ),
          iconTheme: IconThemeData(
            color: Colors.grey[600],
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFBC764A),
            centerTitle: false,
            foregroundColor: Colors.white,
            actionsIconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith(
                      (states) => const Color(0xFFBC764A)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: MaterialStateColor.resolveWith(
                    (states) => const Color(0xFFBC764A),
              ),
              side: MaterialStateBorderSide.resolveWith(
                      (states) => const BorderSide(color: Color(0xFFBC764A))),
            ),
          ), colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(background: const Color(0xFFFDF5EC))),
      home: const HomePage(title: 'Malaria Detection'),
    );
}

class ImageController {}

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;

  String _result = "";
  late Interpreter _interpreter;
  late Interpreter _segmentationInterpreter;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('Initializing the interpreter...');
    }
    loadModel().then((Interpreter interpreter) => setState(() => _interpreter = interpreter));
    /*if (kDebugMode) {
      print('Interpreter initialized.\nInitializing the segmentation interpreter...');
    }
    loadSegmentationModel().then((Interpreter segmentationInterpreter) => setState(() => _segmentationInterpreter = segmentationInterpreter));
    if (kDebugMode) {
      print('Segmentation interpreter initialized.');
    }*/
  }

  Future<Interpreter> loadModel() async => await Interpreter.fromAsset('assets/classification.tflite');
  //Future<Interpreter> loadSegmentationModel() async => Interpreter.fromAsset('assets/segmentation.tflite');

  // Start the image prediction.
  Future<void> classifyImage(File imageFile) async {
      if (kDebugMode) {
        print('Start prediction...');
      }
      List<int> inputShape = _interpreter.getInputTensor(0).shape;
      if (kDebugMode) {
        print('Input shape: $inputShape');
      }
      img.Image? image = await img.decodeImageFile(imageFile.path);
      if (kDebugMode) {
        print('Got image.');
      }
      img.Image imageInput = img.copyResize(
        image!,
        width: inputShape[1],
        height: inputShape[2]
      );
      if (kDebugMode) {
        print('Resized image.');
      }
      List<List<List<List<double>>>> input = [List.generate(imageInput.height, (int y) => List.generate(
        imageInput.width, (int x) {
          img.Pixel pixel = imageInput.getPixel(x, y);
          return [
            (pixel.r) / 255,
            (pixel.g) / 255,
            (pixel.b) / 255
          ];
        }
      ))];
      if (kDebugMode) {
        print('Got input list.');
      }
      List output = [[0, 0, 0, 0]];
      _interpreter.run(input, output);
      String result = '';
      if (output[0][0] > output[0][1] && output[0][0] > output[0][2] && output[0][0] > output[0][3]) {
        result = 'Plasmodium falciparum';
      } else if (output[0][1] > output[0][2] && output[0][1] > output[0][3]) {
        result = 'Plasmodium malariae';
      } else if (output[0][2] > output[0][3]) {
        result = 'Plasmodium ovale';
      } else {
        result = 'Plasmodium vivax';
      }
      setState(() => _result = result);
  }

  @override
  void dispose() {
    _interpreter.close();
    if (kDebugMode) {
      print('Interpreter closed.');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: !kIsWeb ? AppBar(title: Text(widget.title)) : null,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
              child: Text(
                widget.title,
                style: Theme
                    .of(context)
                    .textTheme
                    .displayMedium!
                    .copyWith(color: Theme
                    .of(context)
                    .highlightColor),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );

  Widget _body() => _croppedFile == null && _pickedFile == null ? _uploaderCard() : _imageCard();

  Widget _imageCard() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: kIsWeb ? 24.0 : 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                child: _image(),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _menu(),
        ],
      ),
    );

  Widget _image() {
    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    if (_croppedFile != null) {
      final String path = _croppedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else if (_pickedFile != null) {
      final String path = _pickedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() => Column(
        children:[
        Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => _clear(),
            backgroundColor: Colors.redAccent,
            tooltip: 'Delete',
            child: const Icon(Icons.delete),
          ),
          //if (_croppedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () => _cropImage(),
              backgroundColor: const Color(0xFFBC764A),
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
          ),
          /*Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () => _autocropImage(File(_croppedFile!.path)),
              backgroundColor: const Color(0xFFB8BC4A),
              tooltip: 'Autocrop',
              child: const Icon(Icons.transform),
            ),
          ),*/
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () => classifyImage(File(_croppedFile!.path)),
              backgroundColor: const Color(0xFF009256),
              tooltip: 'Classify',
              child: const Icon(Icons.science),
            ),
          ),

        ]),
        Container(
          margin: const EdgeInsets.all(30.0),
          child: const Text('Result:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        ),
        Text(_result.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23))
    ]);

  Widget _uploaderCard() => Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: SizedBox(
          width: kIsWeb ? 380.0 : 320.0,
          height: 300.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DottedBorder(
                    radius: const Radius.circular(12.0),
                    borderType: BorderType.RRect,
                    dashPattern: const [8, 4],
                    color: Theme
                        .of(context)
                        .highlightColor
                        .withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Theme
                                .of(context)
                                .highlightColor,
                            size: 80.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Upload an image to start',
                            style: kIsWeb
                                ? Theme
                                .of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                color: Theme
                                    .of(context)
                                    .highlightColor)
                                : Theme
                                .of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                color:
                                Theme
                                    .of(context)
                                    .highlightColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton(
                  onPressed: () => _uploadImage(),
                  child: const Text('Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Future<void> _cropImage() async {
    setState(() => _result = "");
    if (_pickedFile != null) {
      if (kDebugMode) {
        print('Cropping image...');
      }
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
            const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: false,
            showZoomer: false,
          ),
        ],
      );
      if (kDebugMode) {
        print('Image cropped.');
      }
      if (croppedFile != null) {
        setState(() => _croppedFile = croppedFile);
        if (kDebugMode) {
          print('Updated _croppedFile.');
        }
      }
    }
  }

  /*Future<void> _autocropImage(File imageFile) async {
    setState(() => _result = '');
    if (kDebugMode) {
      print('Start segmentation...');
    }
    List<int> inputShape = _segmentationInterpreter.getInputTensor(0).shape;
    List<int> outputShape = _segmentationInterpreter.getOutputTensor(0).shape;
    if (kDebugMode) {
      print('Input shape: $inputShape\nOutput shape: $outputShape');
    }
    img.Image? image = await img.decodeImageFile(imageFile.path);
    if (kDebugMode) {
      print('Got image.');
    }
    img.Image imageInput = img.copyResize(
        image!,
        width: 224,
        height: 224
    );
    if (kDebugMode) {
      print('Resized image.');
    }
    List<List<List<List<double>>>> input = [List.generate(imageInput.height, (int y) => List.generate(
        imageInput.width, (int x) {
      img.Pixel pixel = imageInput.getPixel(x, y);
      return [
        (pixel.r) / 255,
        (pixel.g) / 255,
        (pixel.b) / 255
      ];
    }
    ))];
    if (kDebugMode) {
      print('Got input list.');
    }
    List output = List.filled(224 * 224, 0).reshape([1, 224, 224, 1]);
    _segmentationInterpreter.run(input, output);
    List<int> minY = List.filled(224, 223);
    List<int> maxLenY = List.filled(224, 0);
    List<int> minX = List.filled(224, 223);
    List<int> maxLenX = List.filled(224, 0);
    // Sucht in jeder Reihe und jeder Spalte die laengste Pixelfolge
    for (int x = 0; x < 224; x++) {
      int curLenY = 0;
      int curMinY = 223;
      int curLenX = 0;
      int curMinX = 223;
      for (int y = 0; y < 224; y++) {
        if (output[0][x][y][0] > 0.5) {
          curMinY = min(curMinY, y);
          curLenY++;
        } else {
          if (curLenY > maxLenY[x]) {
            maxLenY[x] = curLenY;
            minY[x] = curMinY;
          }
          curLenY = 0;
          curMinY = 223;
        }
        if (output[0][y][x][0] > 0.5) {
          curMinX = min(curMinX, x);
          curLenX++;
        } else {
          if (curLenX > maxLenX[x]) {
            maxLenX[x] = curLenX;
            minX[x] = curMinX;
          }
          curLenX = 0;
          curMinX = 223;
        }
      }
    }
    int absX = 223;
    int absY = 223;
    int absLen = 0;
    int absVol = 0;
    // Schaut fuer jede Spalte, ob sie sich mit einer Reihe ueberschneidet und sucht nach dem größten Produkt aus Reihen- und Spaltenlänge
    for (int x = 0; x < 224; x++) {
      for (int y = 0; y < 224; y++) {
        if (minX[y] <= x && minY[x] <= y && x < minX[y] + maxLenX[y] && y < minY[x] + maxLenY[x] && absVol < maxLenX[y] * maxLenY[x]) {
          absVol = maxLenX[y] * maxLenY[x];
          absLen = max(maxLenX[y], maxLenY[x]);
          absX = minX[y];
          absY = minY[x];
        }
      }
    }
    // Rauszoomen
    if (absLen > 1 && absLen < 215) {
      int xLeft = absX - 5;
      int xRight = absX + absLen + 4;
      int yTop = absY - 5;
      int yBottom = absY + absLen + 4;
      if (xLeft < 0) {
        xLeft = 0;
      } else if (xRight > 223) {
        xLeft -= xRight - 223;
      }
      if (yTop < 0) {
        yTop = 0;
      } else if (yBottom > 223) {
        yTop -= yBottom - 223;
      }
      int imgLen = min(image!.width, image!.height);
      img.Image quadImg = img.copyResize(image!, width: imgLen, height: imgLen);
      int ratio = imgLen ~/ 224;
      img.Image croppedImg = img.copyCrop(quadImg, x: xLeft * ratio, y: yTop * ratio, width: (absLen + 10) * ratio, height: (absLen + 10) * ratio);
      img.encodeJpgFile('croppedFile.jpg', croppedImg);
      setState(() => _croppedFile = CroppedFile('croppedFile.jpg'));
    } else if (absLen < 1){
      setState(() => _result = 'No parasites detected.');
    }
  }*/

  Future<void> _uploadImage() async {
    if (kDebugMode) {
      print('Uploading an image...');
    }
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (kDebugMode) {
      print('Image uploaded.');
    }
    if (pickedFile != null) {
      setState(() => _pickedFile = pickedFile);
      if (kDebugMode) {
        print('Updated _pickedFile.');
      }
      setState(() => _croppedFile = CroppedFile(pickedFile.path));
      if (kDebugMode) {
        print('Updated _croppedFile');
      }
    }
  }

  void _clear() => setState(() {
      _pickedFile = null;
      _croppedFile = null;
      _result = "";
    });
}
