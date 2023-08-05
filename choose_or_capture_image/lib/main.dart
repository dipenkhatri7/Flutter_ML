import 'dart:io';

import 'package:camera/camera.dart';
import 'package:choose_or_capture_image/custom/ImageClassificationCustomModel.dart';
import 'package:choose_or_capture_image/liveCameraFootage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Choose Images'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ImagePicker _picker;
  File? _image;
  dynamic imageLabeler;
  String results = "The results will be displayed here";
  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.5);
    imageLabeler = ImageLabeler(options: options);
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
        title: Text(widget.title),
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
                    )),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveCameraFootage(
                          isCustomModel: false,
                        ),
                      ),
                    );
                  },
                  child: Text('Classify Image In Live Camera Footage'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ImageClassificationCustomModel()));
                  },
                  child: Text('Custom Models Image Classification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
