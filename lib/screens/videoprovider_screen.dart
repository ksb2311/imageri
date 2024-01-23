import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProvider extends StatefulWidget {
  final String filePath;

  const VideoProvider({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  State<VideoProvider> createState() => _VideoProviderState();
}

class _VideoProviderState extends State<VideoProvider> {
  VideoPlayerController? _controller;
  File? _file;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initAsync();
    });
    // getPermsiiion();
    super.initState();
  }

  // void getPermsiiion() async {
  //   var status = await Permission.manageExternalStorage.request();
  //   if (status.isGranted) {
  //     print('Permission Granted');
  //   } else if (status.isPermanentlyDenied) {
  //     openAppSettings();
  //   }
  // }

  Future<void> initAsync() async {
    try {
      _file = File(widget.filePath);
      _controller = VideoPlayerController.file(_file!);
      _controller?.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    } catch (e) {
      debugPrint("Failed : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null || !_controller!.value.isInitialized
        ? const SizedBox()
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          );
  }
}
