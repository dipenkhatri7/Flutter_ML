import 'dart:io';

import 'package:ar_treasure_hunt/objDetection/liveObjDetection.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

class ObjectDetection extends StatefulWidget {
  const ObjectDetection({super.key});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  ImagePicker? imagePicker;
  File? _image;
  var image;

  String results = 'Your results will appear here';
  ObjectDetector? objectDetector;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imagePicker = ImagePicker();

    final mode = DetectionMode.single;

    final options = ObjectDetectorOptions(
        mode: mode, classifyObjects: true, multipleObjects: true);

    objectDetector = ObjectDetector(options: options);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  chooseImage() async {
    XFile? imageFile =
        await imagePicker!.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        _image = File(imageFile.path);
      });
      ProcessObjectDetection();
    }
  }

  cameraImage() async {
    XFile? imageFile = await imagePicker!.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      setState(() {
        _image = File(imageFile.path);
      });
      ProcessObjectDetection();
    }
  }

  List<DetectedObject>? objects;
  ProcessObjectDetection() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    objects = await objectDetector!.processImage(inputImage);
    String updatedResults = '';
    for (DetectedObject detectedObject in objects!) {
      final rect = detectedObject.boundingBox;
      final trackingId = detectedObject.trackingId;
      for (Label label in detectedObject.labels) {
        print('${label.text} : ${label.confidence.toString()}');
        updatedResults +=
            '${label.text} : ${(label.confidence * 100).toStringAsFixed(2)}%\n';
      }
    }

    setState(() {
      results =
          updatedResults.isNotEmpty ? updatedResults : 'No objects detected';
      _image;
    });

    drawRectangleAroundObjects();
  }

  drawRectangleAroundObjects() async {
    image = await _image!.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image = image;
      objects = objects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'AR Treasure Hunt',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            if (_image != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _image = null;
                    image = null;
                    objects = null;
                  });
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.black.withOpacity(0.458),
          // decoration: const BoxDecoration(
          //   image: DecorationImage(
          //       image: AssetImage('images/bg.jpg'), fit: BoxFit.cover),
          // ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: <Widget>[
                    Center(
                      child: ElevatedButton(
                        onPressed: chooseImage,
                        onLongPress: cameraImage,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.38,
                          child: image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: image.width != null &&
                                          image.height != null
                                      ? FittedBox(
                                          child: SizedBox(
                                            width: image.width.toDouble(),
                                            height: image.height.toDouble(),
                                            child: CustomPaint(
                                              painter: ObjectPainter(
                                                  objectList: objects!,
                                                  imageFile: image),
                                            ),
                                          ),
                                        )
                                      : Container())
                              : Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                  ),
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.38,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            results,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.deepPurple,
                      onPrimary: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveObjectDetection(),
                        ),
                      );
                    },
                    child: const Text('Live Object Detection'),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

class ObjectPainter extends CustomPainter {
  List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;

    for (DetectedObject rectangle in objectList) {
      canvas.drawRect(rectangle.boundingBox, p);

      for (Label label in rectangle.labels) {
        TextSpan span = new TextSpan(
          style: new TextStyle(color: Colors.red, fontSize: 20.0),
          text: label.text +
              " " +
              (label.confidence * 100).toStringAsFixed(0) +
              "%",
        );

        TextPainter tp = new TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
            canvas,
            new Offset(
                rectangle.boundingBox.left, rectangle.boundingBox.top - 20));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
