import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProvider extends StatefulWidget {
  final File filePath;

  const VideoProvider({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  State<VideoProvider> createState() => _VideoProviderState();
}

class _VideoProviderState extends State<VideoProvider> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.filePath)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    // Add a listener to update the UI when the video player's position changes.
    _videoPlayerController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.removeListener(() {});
    _videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _videoPlayerController.value.isInitialized
          ? Stack(children: [
              AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                      onPressed: () {
                        setState(() {
                          _videoPlayerController.value.isPlaying ? _videoPlayerController.pause() : _videoPlayerController.play();
                        });
                      },
                      icon: _videoPlayerController.value.isPlaying ? const Icon(Icons.pause_rounded) : const Icon(Icons.play_arrow_rounded),
                      iconSize: 100),
                ),
              ),
              Positioned(
                  bottom: 20,
                  left: 10,
                  right: 10,
                  child: Text('${_videoPlayerController.value.duration.inMinutes}:${_videoPlayerController.value.duration.inSeconds}')),
              Positioned(
                  bottom: 20,
                  // left: 10,
                  right: 10,
                  child: Text('${_videoPlayerController.value.position.inMinutes}:${_videoPlayerController.value.position.inSeconds}')),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: VideoProgressIndicator(_videoPlayerController,
                      allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white)),
                ),
              ),
            ])
          : const SizedBox(),
    );
  }
}
