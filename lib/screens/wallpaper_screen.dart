import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:imegeri/widgets/glassmorphism.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class WallpaperView extends StatefulWidget {
  final AssetEntity asset;
  final String fullpath;
  const WallpaperView({super.key, required this.asset, required this.fullpath});

  @override
  State<WallpaperView> createState() => _WallpaperViewState();
}

class _WallpaperViewState extends State<WallpaperView> {
  final GlobalKey _globalKey = GlobalKey();

  void setWallpaperAs(choice) async {
    // Get the app's documents directory
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create a file in the app's documents directory
    File tempFile = File('${appDocDir.path}/temp_image.png');

    // Step 1: Capture the cropped view
    if (!mounted) return;
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Step 2: Save the captured image
    File imgFile = tempFile;
    await imgFile.writeAsBytes(pngBytes);

    // Step 3: Set the saved image as wallpaper
    String result = await WallpaperManager.setWallpaperFromFile(
      imgFile.path,
      choice == 1
          ? WallpaperManager.HOME_SCREEN
          : choice == 2
              ? WallpaperManager.LOCK_SCREEN
              : WallpaperManager.BOTH_SCREEN,
    )
        ? 'Wallpaper set'
        : 'Failed to set wallpaper.';

    debugPrint('result $result');
  }

  @override
  Widget build(BuildContext context) {
    double offsetX = 0;
    double offsetY = 0;
    return Stack(fit: StackFit.expand, children: [
      GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            offsetX += details.delta.dx;
            offsetY += details.delta.dy;
          });
        },
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: RepaintBoundary(
            key: _globalKey,
            child: AssetEntityImage(
              widget.asset,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      Positioned(
          bottom: 150,
          left: 100,
          right: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: GlassMorphism(
              blur: 20,
              opacity: 50,
              child: TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      elevation: 0,
                      context: context,
                      builder: (context) {
                        return GlassMorphism(
                          blur: 20,
                          opacity: 50,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              const SizedBox(height: 10),
                              ListTile(
                                title: const Text('Home Screen'),
                                onTap: () => setWallpaperAs(1),
                              ),
                              ListTile(
                                title: const Text('Lock Screen'),
                                onTap: () => setWallpaperAs(2),
                              ),
                              ListTile(
                                title: const Text('Both'),
                                onTap: () => setWallpaperAs(3),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text(
                    'Set as Wallpaper',
                    style: TextStyle(color: Colors.white),
                  )),
            ),
          ))
    ]);
  }
}
