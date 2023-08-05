import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../main.dart';

class LiveObjectDetection extends StatefulWidget {
  const LiveObjectDetection({super.key});

  @override
  State<LiveObjectDetection> createState() => _LiveObjectDetectionState();
}

class _LiveObjectDetectionState extends State<LiveObjectDetection> {
  CameraController? cameraController;
  ObjectDetector? objectDetector;
  CameraImage? img;
  bool isBusy = false;
  Size? size;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    cameraController!.dispose();
    super.dispose();
  }

  void initializeCamera() async {
    const mode = DetectionMode.stream;
    final options = ObjectDetectorOptions(
        mode: mode, classifyObjects: true, multipleObjects: true);

    objectDetector = ObjectDetector(options: options);
    cameraController = CameraController(cameras[0], ResolutionPreset.veryHigh);
    await cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      cameraController!.startImageStream((image) => {
            if (!isBusy)
              {
                print('here'),
                isBusy = true,
                img = image,
                ProcessObjectDetection(),
                isBusy = false,
              }
          });
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

  List<DetectedObject> objects = [];
  dynamic _scanResults;
  void ProcessObjectDetection() async {
    var frameImg = getInputImage();
    objects = await objectDetector!.processImage(frameImg);
    print('object: ${objects.length}');

    // for (DetectedObject detectedObject in objects) {
    //   print('asdfasfasfasdfas');
    //   final rect = detectedObject.boundingBox;
    //   final trackingId = detectedObject.trackingId;
    //   for (Label label in detectedObject.labels) {
    //     print('sadfasfasfasf');
    //     print('${label.text} : ${label.confidence.toString()}');
    //   }
    // }
    print('here4');
    if (mounted) {
      setState(() {
        _scanResults = objects;
        isBusy = false;
      });
    }
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());

    final imageRotation =
        InputImageRotationValue.fromRawValue(cameras[0].sensorOrientation);
    print('here');
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(img!.format.raw);
    print('here2');
    final inputImageMetaData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation!,
      format: inputImageFormat!,
      bytesPerRow: img!.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageMetaData,
    );
  }

  Widget buildResult() {
    print('scanResults ${_scanResults}');
    if (_scanResults == null ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      print('here5');
      return Text('Loading');
    }
    final Size imageSize = Size(
      cameraController!.value.previewSize!.height,
      cameraController!.value.previewSize!.width,
    );

    CustomPainter painter = ObjectDetectorPainter(
      imageSize,
      _scanResults,
    );
    print('here6');
    return CustomPaint(
      painter: painter,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (cameraController != null) {
      stackChildren.add(
        Positioned(
          top: 0,
          left: 0,
          width: size!.width,
          height: size!.height,
          child: Container(
            child: (!cameraController!.value.isInitialized)
                ? Container()
                : AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
          ),
        ),
      );
      stackChildren.add(Positioned(
        top: 0,
        left: 0,
        width: size!.width,
        height: size!.height,
        child: buildResult(),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Object Detection',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }
}

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(this.absoluteImageSize, this.objects);
  final Size absoluteImageSize;
  final List<DetectedObject> objects;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;
    print('hsss');
    for (DetectedObject detectedObject in objects) {
      canvas.drawRect(
          Rect.fromLTRB(
              detectedObject.boundingBox.left * scaleX,
              detectedObject.boundingBox.top * scaleY,
              detectedObject.boundingBox.right * scaleX,
              detectedObject.boundingBox.bottom * scaleY),
          paint);

      for (Label label in detectedObject.labels) {
        TextSpan span = TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 20.0),
          text: "${label.text} ${(label.confidence * 100).toStringAsFixed(0)}%",
        );
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(
            canvas,
            Offset(detectedObject.boundingBox.left * scaleX,
                detectedObject.boundingBox.top * scaleY));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(ObjectDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.objects != objects;
  }
}
