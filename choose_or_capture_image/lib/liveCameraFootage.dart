import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'main.dart';

class LiveCameraFootage extends StatefulWidget {
  final bool isCustomModel;
  const LiveCameraFootage({super.key, required this.isCustomModel});

  @override
  State<LiveCameraFootage> createState() => _LiveCameraFootageState();
}

class _LiveCameraFootageState extends State<LiveCameraFootage> {
  late CameraController cameraController;
  String results = "The results will be displayed here";
  dynamic imageLabeler;
  CameraImage? img;
  bool isBusy = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.isCustomModel) {
      createLabeler();
    } else {
      final ImageLabelerOptions options =
          ImageLabelerOptions(confidenceThreshold: 0.5);
      imageLabeler = ImageLabeler(options: options);
    }
    cameraController = CameraController(cameras[0], ResolutionPreset.veryHigh);
    cameraController.startImageStream((image) => {
          if (!isBusy)
            {
              isBusy = true,
              img = image,
              ImageLabeling(),
              isBusy = false,
            }
        });
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object error) {
      if (error is CameraException) {
        switch (error.code) {
          case 'CameraAccessDenied':
            print('Camera access denied');
            break;
          default:
            print('Error: ${error.code}\nError Message: ${error.description}');
            break;
        }
      }
    });
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

  createLabeler() async {
    final modelPath = await getModelPath('assets/ml/mobilenet.tflite');
    final options = LocalLabelerOptions(
      // confidenceThreshold: 0.5,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  void ImageLabeling() async {
    results = "";
    InputImage inputImage = getInputImage();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    for (ImageLabel label in labels) {
      final String text = label.label;
      // final int index = label.index;
      final double confidence = label.confidence;
      results += "$text - ${confidence.toStringAsFixed(2)}\n";
    }
    setState(() {
      results = results;
    });
    isBusy = false;
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());
    final camera = cameras[0];
    final InputImageRotation? imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);

    final InputImageFormat? inputImageFormat =
        InputImageFormatValue.fromRawValue(img!.format.raw);
    final inputImageMetaData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation!,
      format: inputImageFormat!,
      bytesPerRow: img!.planes[0].bytesPerRow,
    );
    final inputImageCamera =
        InputImage.fromBytes(bytes: bytes, metadata: inputImageMetaData);
    return inputImageCamera;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Live Camera Footage'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(
            cameraController,
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(20.0),
              alignment: Alignment.bottomLeft,
              child: Text(results),
            ),
          ),
        ],
      ),
    );
  }
}
