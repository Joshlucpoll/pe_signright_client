import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

const double angle = 30;

class TranslationDisplay extends StatefulWidget {
  final String videoPath;
  final String model;

  const TranslationDisplay({
    super.key,
    required this.videoPath,
    required this.model,
  });

  @override
  State<TranslationDisplay> createState() => _TranslationDisplayState();
}

class _TranslationDisplayState extends State<TranslationDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late Animation<double> _scalePageAnimation;
  late Animation<Offset> _positionPageAnimation;

  late AnimationController _sunController;
  late Animation<Offset> _positionSunAnimation;
  late Animation<Offset> _positionEarthAnimation;
  late Animation<Offset> _positionCloud1Animation;
  late Animation<Offset> _positionCloud2Animation;
  late Animation<Offset> _positionCloud3Animation;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  late AnimationController _bearSlideController;
  late Animation<Offset> _bearSlideAnimation;

  double _bearWalkRotation = angle / 360;
  late Timer timer;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;

  List<String> framePredictions = [];

  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  int _currentCaptionIndex = 0;

  @override
  void initState() {
    super.initState();

    File videoFile = File(widget.videoPath);
    if (!videoFile.existsSync()) {
      print("Video file does not exist: ${widget.videoPath}");
      return;
    }

    _controller = VideoPlayerController.file(videoFile);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Check if the controller is properly initialized
      if (_controller.value.isInitialized) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
          _controller.setVolume(0.0); // Mute the video
        });

        print("Video initialized successfully.");
      } else {
        // Handle the case where the video did not initialize properly
        print("Failed to initialize video.");
      }
    }).catchError((error) {
      // Handle any errors during initialization
      print("Error initializing video: $error");
    });

    _controller.addListener(_updateCaptionIndex);

    timer = Timer.periodic(
      const Duration(milliseconds: 400),
      (Timer t) {
        setState(() {
          // Flip-flop between the start and end values
          _bearWalkRotation =
              _bearWalkRotation == angle / 360 ? -angle / 360 : angle / 360;
        });
      },
    );

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _bearSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scalePageAnimation = Tween<double>(
      begin: 1,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.ease,
      ),
    );
    _positionPageAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.ease,
      ),
    );

    _positionSunAnimation = Tween<Offset>(
      begin: const Offset(1.5, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _sunController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _positionEarthAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _sunController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _positionCloud1Animation = Tween<Offset>(
      begin: const Offset(-3, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _sunController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _positionCloud2Animation = Tween<Offset>(
      begin: const Offset(-4.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _sunController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _positionCloud3Animation = Tween<Offset>(
      begin: const Offset(3.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _sunController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 12.5664,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    _bearSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _bearSlideController,
        curve: Curves.ease,
      ),
    );

    _bubbleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: Curves.ease,
      ),
    );

    runAnimation();
  }

  void runAnimation() async {
    Future<dynamic> futureFrames = _sendVideoToApi(widget.videoPath);

    _rotationController.forward();

    _rotationAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rotationController.repeat();
      }
    });

    await _pageController.forward();
    _sunController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    await _bearSlideController.forward();

    await futureFrames.then((value) {
      setState(() {
        framePredictions = value;
      });
    });

    await _bubbleController.forward();
  }

  Future<List<String>> _sendVideoToApi(String videoFilePath) async {
    // Create a multipart request
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://192.168.0.244/translate',
        ));

    // Attach the video file to the request
    var videoFile = File(videoFilePath);
    var videoStream = http.ByteStream(videoFile.openRead());
    var videoLength = await videoFile.length();
    var videoMultipartFile = http.MultipartFile(
      'video',
      videoStream,
      videoLength,
      filename: videoFile.path.split('/').last,
    );
    request.files.add(videoMultipartFile);

    request.fields['model'] = widget.model;

    // Send the request
    var response = await request.send();

    // Convert the StreamedResponse to a Response
    var responseString = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      // if (true) {
      // Decode the JSON response
      var jsonResponse = json.decode(responseString.body);

      // Extract the array from the JSON response
      List<String> framePredictions =
          (jsonResponse['frame_predictions'] as List)
              .map((item) => item as String)
              .toList();

      print(framePredictions); // or do whatever you need with the array

      // );
      return framePredictions;
    } else {
      print('Failed to send video. Error: ${response.reasonPhrase}');

      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to translate video. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      return [];
    }
  }

  void _updateCaptionIndex() {
    if (!_controller.value.isInitialized || framePredictions.isEmpty) {
      print("Video controller is not initialized or captions are empty.");
      return;
    }

    // Assuming the frame rate of the video (frames per second)
    const double frameRate = 30.0; // You need to know or estimate this value
    final int currentPosition = _controller.value.position.inMilliseconds;
    final double seconds = currentPosition / 1000.0;

    // Calculate current frame based on the elapsed time and frame rate
    int currentFrame = (seconds * frameRate).floor();

    // Ensure the frame index does not exceed the number of captions available
    if (currentFrame >= framePredictions.length) {
      currentFrame = framePredictions.length - 1; // Keep it within bounds
    }

    if (currentFrame < 0) {
      currentFrame = 0; // Keep it within bounds
    }

    // Update the caption index if it has changed
    if (currentFrame != _currentCaptionIndex) {
      setState(() {
        _currentCaptionIndex = currentFrame;
      });
    }
  }

  @override
  dispose() {
    timer.cancel();
    _pageController.dispose();
    _sunController.dispose();
    _rotationController.dispose();
    _bearSlideController.dispose();
    _bubbleController.dispose();
    _controller.removeListener(_updateCaptionIndex);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: SlideTransition(
            position: _positionPageAnimation,
            child: ScaleTransition(
              scale: _scalePageAnimation,
              child: Container(
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      Color.fromARGB(240, 186, 215, 240),
                      Color.fromARGB(240, 19, 117, 240),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                child: OrientationBuilder(builder: (context, orientation) {
                  return Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Positioned(
                        bottom: -1800,
                        child: SlideTransition(
                          position: _positionEarthAnimation,
                          child: Container(
                            width: 2000,
                            height: 2000,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 3, 131, 57),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SlideTransition(
                          position: _positionSunAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) => Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: Image.asset('assets/pe-sun.png'),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 80,
                        left: 70,
                        child: SlideTransition(
                          position: _bearSlideAnimation,
                          child: Transform.rotate(
                            angle: _bearWalkRotation,
                            child: Image.asset('assets/bear.png', width: 200),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 260,
                        left: 230,
                        child: FadeTransition(
                          opacity: _bubbleAnimation,
                          child: Container(
                            width: 250,
                            height: 130,
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(250, 130),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Text(
                                      framePredictions.isNotEmpty
                                          ? framePredictions[
                                              _currentCaptionIndex]
                                          : "",
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 24),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 30,
                                  left: 40,
                                  child: RotationTransition(
                                    turns: const AlwaysStoppedAnimation(
                                      -45 / 360,
                                    ),
                                    child: CustomPaint(
                                      painter: _BubbleArrow(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 450,
                        top: 130,
                        child: SlideTransition(
                          position: _positionCloud1Animation,
                          child: Image.asset('assets/cloud_1.png'),
                        ),
                      ),
                      Positioned(
                        right: 200,
                        top: 40,
                        child: SlideTransition(
                          position: _positionCloud2Animation,
                          child: Image.asset('assets/cloud_2.png'),
                        ),
                      ),
                      Positioned(
                        right: 50,
                        top: 210,
                        child: SlideTransition(
                          position: _positionCloud3Animation,
                          child: Image.asset('assets/cloud_3.png'),
                        ),
                      ),
                      Positioned(
                        left: orientation == Orientation.portrait ? 210 : 550,
                        top: orientation == Orientation.portrait ? 100 : 200,
                        child: FadeTransition(
                          opacity: _bubbleAnimation,
                          child: SizedBox(
                            width:
                                orientation == Orientation.portrait ? 300 : 450,
                            child: FutureBuilder(
                              future: _initializeVideoPlayerFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return SafeArea(
                                    child: AspectRatio(
                                      aspectRatio: _controller.value
                                          .aspectRatio, // Use the video's aspect ratio
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: VideoPlayer(_controller),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 30,
                        child: FadeTransition(
                          opacity: _bubbleAnimation,
                          child: CupertinoButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: Colors.red,
                              size: 64,
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleArrow extends CustomPainter {
  final Color color;

  _BubbleArrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    Path path = Path();
    path.moveTo(0, 0); // Start
    path.lineTo(-40, -12.5); // Arrow tip
    path.lineTo(0, -25); // Bottom
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
