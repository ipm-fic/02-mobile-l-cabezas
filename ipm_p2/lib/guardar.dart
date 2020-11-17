

import 'dart:convert';
import 'dart:io' as Io;

import 'package:camera/camera.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:requests/requests.dart';


// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';




List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}


class CameraApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FirstScreen(),
        routes:<String,WidgetBuilder>{
          '/FirstScree' : (BuildContext context) => new FirstScreen(),
          '/SecondScreen': (BuildContext context) => new SecondScreen()
        }
    );
  }
}

//primera pantalla
class FirstScreen extends StatefulWidget {

  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

/// Camara interna o externa
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<FirstScreen>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  //String videoPath;
  //bool enableAudio = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Saca una foto'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          //_toggleAudioWidget(),*/
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _cameraTogglesRowWidget(),
                new ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/SecondScreen');
                    },
                    child: const Text('Datos'))

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }




  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null &&
              controller.value.isInitialized &&
              !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }


  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      //enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  //Future<ImageRecognitionResult>
  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) async {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          //videoController?.dispose();
          //videoController = null;
        });
        if (filePath != null) {showInSnackBar('Picture saved to $filePath');}

      }
    });
  }


  Future<String> takePicture() async {
    ImageRecognitionProvider i = ImageRecognitionProvider();
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final extDir = await getApplicationDocumentsDirectory();
    print(extDir);
    final String dirPath = '${extDir.path}/Pictures/p2';
    print(dirPath);
    await Io.Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    print(i.imageRecognition(filePath));
    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

//subir info al api
class ImageRecognitionProvider {
  Future<ImageRecognitionResult> result;
  ImageRecognitionProvider({this.result});

  final successCode = 200;
  final String url = 'https://api.imagga.com/v2/tags';

  Future<http.Response> imageRecognition(String  image) async {

    String f = base64Encode(Io.File(image).readAsBytesSync());

    final response = await http.post(
        'https://api.imagga.com/v2/tags',
        headers:{Io.HttpHeaders.authorizationHeader:"Basic YWNjX2MwNWFmOGQwNjc5NDg0OTo0NWY0M2Q1ODU3MmUzNzhkYzIxYjZjOTE3ODU1YzlhNQ== " },
        body:{'image_base64': base64Decode(f)}
    );
    print('response................');
    print(response.statusCode);

    /*List<int> bytes = utf8.encode('acc_c05af8d06794849'+':'+'45f43d58572e378dc21b6c917855c9a5');
    String auth = base64Encode(bytes);

    auth = "Basic YWNjX2MwNWFmOGQwNjc5NDg0OTo0NWY0M2Q1ODU3MmUzNzhkYzIxYjZjOTE3ODU1YzlhNQ== " ;

    debugPrint(auth);

    final mimeTypeData = lookupMimeType(image, headerBytes: [0xFF, 0xD8]);

    final imageUploadRequest = http.MultipartRequest('POST', Uri.parse(url));
    final file = await http.MultipartFile.fromPath('image', image, contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    imageUploadRequest.files.add(file);
    imageUploadRequest.headers['Authorization'] = auth;
    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await  http.Response.fromStream(streamedResponse);

      debugPrint(response.statusCode.toString()); //todo if != from 200, do something else
      debugPrint(response.body);
      ImageRecognitionResult result = ImageRecognitionResult.fromJson(jsonDecode(response.body));
      return result;
    } catch (e) {
      debugPrint(e);
      return null;
    }*/
  }

}


//que hacer con la info que cogimos
class ImageRecognitionResult {
  Result result;
  Status status;

  ImageRecognitionResult({this.result, this.status});


  ImageRecognitionResult.fromJson(Map<String, dynamic> json) {
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
    status =
    json['status'] != null ? new Status.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result.toJson();
    }
    if (this.status != null) {
      data['status'] = this.status.toJson();
    }
    return data;
  }

  String providedResults(){
    String res = "";
    int count = 1;
    for (Tags tag in result.tags){
      res += tag.tag.en;
      if (count>2)
        break;
      res+=', ';
      count++;
    }
    print(res);
    return res;
  }
}

class SecondScreen extends StatelessWidget {
  final ImageRecognitionResult result;

  const SecondScreen({this.result}) ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos obtenidos'),
      ),
      body: Center(
          child: ListView.builder(
              itemBuilder: (context, index) {
                return new Text('result.()');
              }
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}



class Result {
  List<Tags> tags;

  Result({this.tags});

  Result.fromJson(Map<String, dynamic> json) {
    if (json['tags'] != null) {
      tags = new List<Tags>();
      json['tags'].forEach((v) {
        tags.add(new Tags.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.tags != null) {
      data['tags'] = this.tags.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Tags {
  double confidence;
  Tag tag;

  Tags({this.confidence, this.tag});

  Tags.fromJson(Map<String, dynamic> json) {
    confidence = json['confidence'];
    tag = json['tag'] != null ? new Tag.fromJson(json['tag']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['confidence'] = this.confidence;
    if (this.tag != null) {
      data['tag'] = this.tag.toJson();
    }
    return data;
  }
}

class Tag {
  String en;

  Tag({this.en});

  Tag.fromJson(Map<String, dynamic> json) {
    en = json['en'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['en'] = this.en;
    return data;
  }
}

class Status {
  String text;
  String type;

  Status({this.text, this.type});

  Status.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text'] = this.text;
    data['type'] = this.type;
    return data;
  }
}







