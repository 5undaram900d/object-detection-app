
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection_app/main.dart';
import 'package:tflite_v2/tflite_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isWorking = false;
  String result = '';
  late CameraController cameraController;
  CameraImage? imgCamera;

  loadModel() async{
    await Tflite.loadModel(model: "assets/data/objectData.tflite", labels: "assets/data/objectData.txt",);
  }
  
  initCamera(){
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value){
      if(!mounted){
        return;
      }
      setState(() {
        cameraController.startImageStream((imageFromStream){
          if(!isWorking){
            isWorking = true;
            imgCamera = imageFromStream;
            runModelOnStreamFrames();
          }
        });
      });
    });
  }

  runModelOnStreamFrames() async{
    if(imgCamera != null){
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      result = "";
      recognitions?.forEach((response) {
        result += response["label"] + " " + (response["confidence"] as double).toStringAsFixed(2) + "\n\n";
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() async{
    super.dispose();
    await Tflite.close();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/jarvis.jpg",),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.black,
                        height: MediaQuery.of(context).size.height*0.4,
                        child: Image.asset("assets/images/camera.jpg", fit: BoxFit.fill,),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: ()=> initCamera(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height*0.39,
                          width: double.infinity,
                          child: imgCamera==null
                              ? const SizedBox(height: 270, width: 270, child: Icon(Icons.photo_camera_front, color: Colors.teal, size: 40,),)
                              : AspectRatio(aspectRatio: cameraController.value.aspectRatio, child: CameraPreview(cameraController),),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 55),
                    child: SingleChildScrollView(
                      child: Text(result, style: const TextStyle(backgroundColor: Colors.black87, fontSize: 30, color: Colors.white,), textAlign: TextAlign.center,),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
