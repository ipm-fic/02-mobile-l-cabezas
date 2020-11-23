import 'dart:async';
import 'package:flutter/material.dart';
import 'package:startup_namer/BloCs/ImageRecognitionResult.dart';
import 'package:startup_namer/BloCs/image_recognition_provider.dart';


class getInfo extends StatelessWidget {
   final String imagePath;
  getInfo({Key key, this.imagePath});

  Future<ImageRecognitionResult> _futureAlbum;

  @override
  Widget build(BuildContext context) {
    _futureAlbum=null;
    _futureAlbum=printear();
    return Scaffold(
        appBar: AppBar(title: const Text('¿Que hay en la foto?')),
        body: Container(
          color: Colors.white,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(5.0),
          child: FutureBuilder<ImageRecognitionResult>(
              future: _futureAlbum,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FittedBox(
                      fit: BoxFit.fill,
                      child:  Text(snapshot.data.providedResults(),
                          style:DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0))
                  );

                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        )
    );
  }

  Future<ImageRecognitionResult> printear(){
    final imP = ImageRecognitionProvider();
    return imP.imageRecognition(imagePath);
  }


}
