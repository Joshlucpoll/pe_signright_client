import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pe_signright_client/settings.dart';
import 'package:pe_signright_client/translation.dart';
import 'package:pull_down_button/pull_down_button.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
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
  int _currentRecordingSeconds = 0;

  String model = "ASL-100";

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

  Future<void> incrementRecordingSeconds() async {
    await Future.delayed(const Duration(seconds: 1));

    if (_isRecording) {
      setState(() {
        _currentRecordingSeconds++;
      });
      incrementRecordingSeconds();
    } else {
      setState(() {
        _currentRecordingSeconds = 0;
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final videoFile = await _controller!.stopVideoRecording();

      print(
          "Video recording stopped: ${videoFile.path}"); // You might want to handle the saved file further

      // Send the video to the API
      showCupertinoDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return TranslationDisplay(
            model: model.split('-')[1],
            videoPath: videoFile.path,
          );
        },
      );
    } else {
      // Start recording
      await _controller!.startVideoRecording();
      print("Video recording started");

      // Start the timer
      incrementRecordingSeconds();
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
          Positioned(
            top: 20,
            right: 20,
            child: CupertinoButton(
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (BuildContext context) {
                    return const SettingsPage();
                  },
                ),
              ),
              child: const Icon(
                CupertinoIcons.gear_alt_fill,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isRecording
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_currentRecordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_currentRecordingSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PullDownButton(
                  position: PullDownMenuPosition.over,
                  buttonAnchor: PullDownMenuAnchor.start,
                  menuOffset: -16,
                  // itemsOrder: PullDownMenuItemsOrder.downwards,
                  itemBuilder: (context) => [
                    PullDownMenuHeader(
                      leading: const Icon(
                        CupertinoIcons.sparkles,
                        color: Colors.black,
                      ),
                      title: 'AI Model',
                      subtitle: 'Model complexity',
                      onTap: () {},
                    ),
                    ...([
                      'ASL-100',
                      'ASL-300',
                      'ASL-1000',
                      'ASL-2000',
                    ]).map((e) {
                      return PullDownMenuItem.selectable(
                        title: e,
                        selected: model == e,
                        onTap: () {
                          setState(() {
                            model = e;
                          });
                        },
                      );
                    }),
                  ],
                  buttonBuilder: (context, showMenu) => SizedBox(
                    width: 80,
                    height: 40,
                    child: CupertinoButton(
                      onPressed: showMenu,
                      color: Colors.black.withAlpha(100),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(100),
                        right: Radius.circular(100),
                      ),
                      padding: EdgeInsets.zero,
                      child: Text(
                        model,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.only(bottom: 4, top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: CupertinoButton(
                      borderRadius: BorderRadius.circular(1000),
                      padding: EdgeInsets.all(20),
                      color: Colors.red,
                      onPressed: _toggleRecording,
                      child: Icon(
                        _isRecording
                            ? CupertinoIcons.stop_circle
                            : CupertinoIcons.video_camera,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  onPressed: _cycleCamera,
                  child: const Icon(
                    CupertinoIcons.switch_camera,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
