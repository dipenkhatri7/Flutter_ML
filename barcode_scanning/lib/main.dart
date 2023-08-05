import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(BarCode());
}

class BarCode extends StatefulWidget {
  const BarCode({super.key});

  @override
  State<BarCode> createState() => _BarCodeState();
}

class _BarCodeState extends State<BarCode> {
  File? _image;
  late ImagePicker _picker;
  String result = 'Results will be shown here';
  dynamic barcodeScanner;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _picker = ImagePicker();
    final List<BarcodeFormat> format = [BarcodeFormat.all];
    barcodeScanner = BarcodeScanner(formats: format);
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
      barCodeScan();
    });
  }

  void chooseImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(image!.path);
      barCodeScan();
    });
  }

  void barCodeScan() async {
    InputImage inputImage = InputImage.fromFile(_image!);

    final List<Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);

    for (Barcode barCode in barcodes) {
      final BarcodeType type = barCode.type;
      final Rect boundingBox = barCode.boundingBox;
      final String? rawValue = barCode.rawValue;
      final String? displayValue = barCode.displayValue;

      switch (type) {
        case BarcodeType.wifi:
          BarcodeWifi? wifi = barCode.value as BarcodeWifi?;
          final String? ssid = wifi!.ssid;
          result = "Wifi SSID: $ssid \nWifi Password: ${wifi.password}";
          // final String? ssid = barCode.wifi!.ssid;
          // final String? password = barCode.wifi!.password;
          // final BarcodeWiFiEncryptionType encryptionType =
          //     barCode.wifi!.encryptionType;
          break;
        case BarcodeType.url:
          BarcodeUrl? url = barCode.value as BarcodeUrl?;
          final String? title = url!.title;
          result = "URL: ${url.title} ${url.url}";
          break;
        default:
          result = rawValue!;
      }
      setState(() {
        result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'images/frame.png',
                            fit: BoxFit.cover,
                          ),
                          GestureDetector(
                            onLongPress: captureImage,
                            onTap: chooseImage,
                            child: Center(
                              child: _image == null
                                  ? Icon(
                                      Icons.camera_alt,
                                      size: 50,
                                    )
                                  : Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // ElevatedButton(
                    //   onLongPress: captureImage,
                    //   onPressed: chooseImage,
                    //   child: Text('Choose / Capture'),
                    // ),
                    SizedBox(height: 20),
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
