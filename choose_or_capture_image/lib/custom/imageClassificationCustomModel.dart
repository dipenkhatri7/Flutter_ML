import 'dart:io';
import 'package:choose_or_capture_image/liveCameraFootage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageClassificationCustomModel extends StatefulWidget {
  const ImageClassificationCustomModel({super.key});

  @override
  State<ImageClassificationCustomModel> createState() =>
      _ImageClassificationCustomModelState();
}

class _ImageClassificationCustomModelState
    extends State<ImageClassificationCustomModel> {
  late ImagePicker _picker;
  File? _image;
  dynamic imageLabeler;
  String results = "The results will be displayed here";
  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    createLabeler();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = File(image!.path);
      imageLabeling();
    });
  }

  void chooseImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(image!.path);
      imageLabeling();
    });
  }

  createLabeler() async {
    final modelPath = await getModelPath('assets/ml/efficientnet.tflite');
    final options = LocalLabelerOptions(
      // confidenceThreshold: 0.5,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  void imageLabeling() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    results = "";
    for (ImageLabel label in labels) {
      final String text = label.label;
      // final int index = label.index;
      final double confidence = label.confidence;
      results += "$text - ${confidence.toStringAsFixed(2)}\n";
    }
    setState(() {
      results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Custom Image Classification'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: _image != null
                      ? Image.file(
                          _image!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.fill,
                        )
                      : Icon(
                          Icons.image,
                          size: 150,
                        ),
                ),
                ElevatedButton(
                  onLongPress: captureImage,
                  onPressed: chooseImage,
                  child: Text('Choose Image'),
                ),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Center(child: Text(results)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveCameraFootage(
                          isCustomModel: true,
                        ),
                      ),
                    );
                  },
                  child: Text('Custom Image In Live Camera Footage'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
