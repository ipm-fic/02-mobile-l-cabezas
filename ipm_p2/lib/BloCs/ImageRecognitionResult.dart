

import 'package:startup_namer/BloCs/Result.dart';
import 'package:startup_namer/BloCs/Status.dart';
import 'package:startup_namer/BloCs/Tags.dart';

class ImageRecognitionResult {
  Result result;
  Status status;

  ImageRecognitionResult({this.result, this.status});


  factory ImageRecognitionResult.fromJson(Map<String, dynamic> json) {
    return ImageRecognitionResult(
      result: json['result'] != null ? new Result.fromJson(json['result']) : null,
      status: json['status'] != null ? new Status.fromJson(json['status']) : null,
    );
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






