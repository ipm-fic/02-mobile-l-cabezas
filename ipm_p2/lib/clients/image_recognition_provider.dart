import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:startup_namer/widgets/ImageRecognitionResult.dart';
import 'package:startup_namer/widgets/get_Info.dart';

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
      return ImageRecognitionResult.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
