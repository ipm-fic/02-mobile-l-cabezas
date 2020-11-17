import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
//primera pantalla
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

/// Camara interna o externa
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
  }
  throw ArgumentError('Unknown lens direction');
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saca una foto')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);
            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => getInfo(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class getInfo extends StatelessWidget {

  final String imagePath;

   const getInfo({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Display the Picture')
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: printear(imagePath)//Image.file(File(imagePath)),
    );
  }

  Widget printear(String imagePath){
    final imP = ImageRecognitionProvider();
    var imR = ImageRecognitionResult();
    var p = imP.imageRecognition(imagePath);
    //print(imR.providedResults());

    /*if(imR.providedResults() != null) {
      ListView.builder(
          itemCount: imR.providedResults().length,
          itemBuilder: (context, index) {
            return new Text(imR.providedResults());
          });
    }
    else{print('no');}*/

  }


}

class ImageRecognitionProvider {
  getInfo imagePath;
  final successCode = 200;
  final String url = 'https://api.imagga.com/v2/tags';
  Future<ImageRecognitionResult> imageRecognition(String imagePath) async {
    String f = base64Encode(File(imagePath).readAsBytesSync());
    final response = await http.post(
        'https://api.imagga.com/v2/tags',
        headers: {
          HttpHeaders.authorizationHeader: "Basic YWNjX2MwNWFmOGQwNjc5NDg0OTo0NWY0M2Q1ODU3MmUzNzhkYzIxYjZjOTE3ODU1YzlhNQ== "
        },
        body: {'image_base64': f}
    );
    print('response................');
    print(response.statusCode);
  if (response.statusCode == 200){
    print(response.body);
    print('a');
    //jsonDecode(response.body)
    return ImageRecognitionResult.fromJson(jsonDecode(response.body));
  }
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