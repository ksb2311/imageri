import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imegeri/widgets/glassmorphism.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class WallpaperView extends StatelessWidget {
  final AssetEntity asset;
  final String fullpath;
  const WallpaperView({super.key, required this.asset, required this.fullpath});

  void setWallpaperAs(choice) async {
    String result;
    try {
      result = await AsyncWallpaper.setWallpaperFromFile(
        filePath: fullpath,
        wallpaperLocation: choice == 1
            ? AsyncWallpaper.HOME_SCREEN
            : choice == 2
                ? AsyncWallpaper.LOCK_SCREEN
                : AsyncWallpaper.BOTH_SCREENS,
        // goToHome: goToHome,
        toastDetails: ToastDetails.success(),
        errorToastDetails: ToastDetails.error(),
      )
          ? 'Wallpaper set'
          : 'Failed to get wallpaper.';
    } on PlatformException {
      result = 'Failed to get wallpaper.';
      debugPrint(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      AssetEntityImage(asset, fit: BoxFit.fitHeight),
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
