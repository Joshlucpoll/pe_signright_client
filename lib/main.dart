import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CameraFeed(),
    );
  }
}

class CameraFeed extends StatefulWidget {
  @override
  _CameraFeedState createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isRecording = false; // Added to track recording state

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller =
          CameraController(_cameras[_selectedCameraIdx], ResolutionPreset.high);
      _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _cycleCamera() {
    if (_cameras.length > 1) {
      _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
      _initCamera();
    }
  }

  Future<void> _sendVideoToApi(String videoFilePath) async {
    // Create a multipart request
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.0.114:3000/translate'));

    // Attach the video file to the request
    var videoFile = File(videoFilePath);
    var videoStream = http.ByteStream(videoFile.openRead());
    var videoLength = await videoFile.length();
    var videoMultipartFile = http.MultipartFile(
      'video',
      videoStream,
      videoLength,
      filename: videoFile.path,
    );
    request.files.add(videoMultipartFile);

    // Send the request
    var response = await request.send();

    // Check the response status
    if (response.statusCode == 200) {
      print('Video sent successfully');
    } else {
      print('Failed to send video. Error: ${response.reasonPhrase}');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final videoFile = await _controller!.stopVideoRecording();

      print(
          "Video recording stopped: ${videoFile.path}"); // You might want to handle the saved file further

      // Send the video to the API
      await _sendVideoToApi(videoFile.path);
    } else {
      // Start recording
      await _controller!.startVideoRecording();
      print("Video recording started");
    }
    setState(() {
      _isRecording = !_isRecording; // Toggle recording state
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    final xScale = MediaQuery.of(context).orientation == Orientation.landscape
        ? _controller!.value.aspectRatio / deviceRatio
        : 1.0;
    final yScale = MediaQuery.of(context).orientation == Orientation.landscape
        ? _controller!.value.aspectRatio / deviceRatio
        : 1.0;

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          AspectRatio(
            aspectRatio: deviceRatio,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(xScale, yScale, 1),
              child: CameraPreview(_controller!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  child: CupertinoButton(
                    onPressed: () {},
                    child: const Icon(CupertinoIcons.photo_camera),
                  ),
                  opacity: 0,
                ),
                CupertinoButton(
                  borderRadius: BorderRadius.circular(10),
                  padding: EdgeInsets.all(20),
                  color: Colors.red,
                  onPressed: _toggleRecording,
                  child: Icon(
                    _isRecording
                        ? CupertinoIcons.stop_circle
                        : CupertinoIcons.video_camera,
                  ),
                ),
                CupertinoButton(
                  onPressed: _cycleCamera,
                  child: const Icon(CupertinoIcons.switch_camera),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
