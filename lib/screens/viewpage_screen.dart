import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imegeri/screens/wallpaper_screen.dart';
import 'package:imegeri/widgets/glassmorphism.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';

class ViewerPage extends StatefulWidget {
  // final String filePath;
  final List<AssetEntity> _pathsList;
  final int _assetIndex;

  const ViewerPage(this._pathsList, this._assetIndex, {Key? key}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> with TickerProviderStateMixin {
  bool uiToggleState = false;
  ScrollPhysics pageScrollToggleState = const PageScrollPhysics();
  Completer<ImageInfo> completer = Completer<ImageInfo>();
  String imgFilePath = '';
  int imgFilePathIndex = 0;
  late AssetEntity assset;
  late String assetPath;
  late List<AssetEntity> pathListLocal;

  bool isBlur = false;
  Color toolBarIconColor = Colors.white;
  bool expandToolBar = false;

  bool swipeLock = false;

  // controllers
  TransformationController controllerT = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;
  late PageController controllerPage;

  late List<String> preloadedImgFilePaths = [];
  // final platform = const MethodChannel('com.example.wallpaper');

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _animation = Matrix4Tween(begin: controllerT.value, end: Matrix4.identity()).animate(_animationController);
    _animationController.addListener(() {
      controllerT.value = _animation.value;
    });
    controllerPage = PageController(initialPage: widget._assetIndex);
    assset = widget._pathsList[imgFilePathIndex];
    assetPath = '';
    preloadFilePaths();
    // getFilePath();
    // getPathList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    controllerT.dispose();
    controllerPage.dispose();
    super.dispose();
  }

  void uiToggle() {
    setState(() {
      uiToggleState = !uiToggleState;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  String convertSize(int sizeBytes) {
    if (sizeBytes == 0) {
      return "0B";
    }
    List<String> sizeName = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    int i = (log(sizeBytes) / log(1024)).floor();
    num p = pow(1024, i);
    double s = (sizeBytes / p);
    return "${s.toStringAsFixed(2)} ${sizeName[i]}";
  }

  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        file.deleteSync();
      } else {
        debugPrint("The file does not exist.");
      }
    } catch (e) {
      // Error in getting access to the file.
      debugPrint(e.toString());
    }
  }

  bool isImage(String path) {
    final mimeType = lookupMimeType(path);
    return mimeType != null && mimeType.startsWith('image/');
  }

  void getPathFromFile(index) async {
    File? imgfile = await widget._pathsList[index].file;
    setState(() {
      imgFilePath = imgfile!.path;
    });
  }

  Future<void> preloadFilePaths() async {
    List<String> paths = [];
    for (var asset in widget._pathsList) {
      final file = await asset.file;
      if (file != null) {
        paths.add(file.path);
      }
    }
    setState(() {
      preloadedImgFilePaths = paths;
      imgFilePath = preloadedImgFilePaths[widget._assetIndex];
    });
  }

  // Future<void> setWallpaper(String imagePath) async {
  //   try {
  //     await platform.invokeMethod('setWallpaper', {'imagePath': imagePath});
  //   } on PlatformException catch (e) {
  //     debugPrint('$e');
  //     // Handle error
  //   }
  // }

  // void getPathList() async {
  // List<AssetEntity> alist = widget._pathsList;
  // print(alist.first.file.then((value) => value!.path));
  // setState(() {
  //   pathListLocal = alist;
  // });
  // }

  @override
  Widget build(BuildContext context) {
    FileStat statOfFile = FileStat.statSync(imgFilePath);
    DateTime? dateMod = statOfFile.modified;
    File aFile = File(imgFilePath);
    // print(isImage(aFile.path));
    // bool isImage = false;
    // String fileExtension = imgFilePath.split('.').last.toLowerCase();

    // if (fileExtension == 'jpg' ||
    //     fileExtension == 'jpeg' ||
    //     fileExtension == 'png' ||
    //     fileExtension == 'gif' ||
    //     fileExtension == 'bmp') {
    //   isImage = true;
    // }

    // PhotoProvider imgprovider = PhotoProvider(mediumId: widget.medium.id);

    controllerT.addListener(() {
      if (controllerT.value.getMaxScaleOnAxis() != 1.0 || swipeLock) {
        setState(() {
          pageScrollToggleState = const NeverScrollableScrollPhysics();
        });
      } else {
        setState(() {
          pageScrollToggleState = const PageScrollPhysics();
        });
      }
    });

    controllerPage.addListener(() {
      setState(() {
        imgFilePathIndex = controllerPage.page!.round();
        assset = widget._pathsList[imgFilePathIndex];
        // assetPath = preloadedImgFilePaths[imgFilePathIndex];
        // statOfFile = FileStat.statSync(assetPath);
        dateMod = assset.modifiedDateTime;
      });
    });

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(
              // allowImplicitScrolling: true,
              controller: controllerPage,
              // physics: controllerT.value.getMaxScaleOnAxis() == 1.0
              //     ? null
              //     : const NeverScrollableScrollPhysics(),
              physics: pageScrollToggleState,
              itemCount: widget._pathsList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                    onDoubleTapDown: (details) {
                      _handleDoubleTapDown(details);
                    },
                    onDoubleTap: () {
                      if (controllerT.value.getMaxScaleOnAxis() <= 1.0) {
                        _animation = Matrix4Tween(
                          begin: controllerT.value,
                          end: Matrix4.identity()
                            ..translate(-_doubleTapDetails!.localPosition.dx * 2, -_doubleTapDetails!.localPosition.dy * 2)
                            ..scale(3.0),
                        ).animate(_animationController);
                        _animationController.forward(from: 0.0);
                      } else {
                        _animation = Matrix4Tween(
                          begin: controllerT.value,
                          end: Matrix4.identity(),
                        ).animate(_animationController);
                        _animationController.forward(from: 0.0);
                      }
                    },
                    onTap: () {
                      uiToggle();
                      if (uiToggleState) {
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
                      } else {
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
                      }
                      expandToolBar = false;
                    },
                    child: InteractiveViewer(
                        // boundaryMargin: const EdgeInsets.all(1.0),
                        // clipBehavior: Clip.none,
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 1.0,
                        maxScale: 5.0,
                        constrained: true,
                        transformationController: controllerT,
                        child: AssetEntityImage(widget._pathsList[index])));
              }),
          uiToggleState
              ? Positioned(
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                  left: 0,
                  right: 0,
                  child: GlassMorphism(
                    blur: 20,
                    opacity: 50,
                    child: Column(
                      children: [
                        expandToolBar
                            ? ListView(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.all(5),
                                children: [
                                  // const ListTile(
                                  //   textColor: Colors.white,
                                  //   title: Text('Add to album'),
                                  //   trailing: Icon(Icons.photo_album),
                                  //   iconColor: Colors.white,
                                  // ),
                                  ListTile(
                                    textColor: Colors.white,
                                    title: const Text('Set As Wallpaper'),
                                    trailing: const Icon(Icons.wallpaper),
                                    iconColor: Colors.white,
                                    onTap: () async {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WallpaperView(asset: assset, fullpath: imgFilePath),
                                          ));

//                                       String result;
// // Platform messages may fail, so we use a try/catch PlatformException.
//                                       try {
//                                         result = await AsyncWallpaper.setWallpaperFromFile(
//                                           filePath: imgFilePath,
//                                           wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
//                                           // goToHome: goToHome,
//                                           toastDetails: ToastDetails.success(),
//                                           errorToastDetails: ToastDetails.error(),
//                                         )
//                                             ? 'Wallpaper set'
//                                             : 'Failed to get wallpaper.';
//                                       } on PlatformException {
//                                         result = 'Failed to get wallpaper.';
//                                         debugPrint(result);
//                                       }
                                    },
                                  ),
                                  ListTile(
                                    textColor: Colors.white,
                                    iconColor: swipeLock ? Colors.redAccent : Colors.greenAccent,
                                    title: const Text('Lock Swipe'),
                                    trailing: const Icon(Icons.swipe),
                                    onTap: () {
                                      setState(() {
                                        swipeLock = !swipeLock;
                                      });
                                      if (swipeLock) {
                                        setState(() {
                                          pageScrollToggleState = const NeverScrollableScrollPhysics();
                                        });
                                      } else {
                                        setState(() {
                                          pageScrollToggleState = const PageScrollPhysics();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: 70,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {
                                  imgFilePath = preloadedImgFilePaths[imgFilePathIndex];
                                  try {
                                    Share.shareXFiles([XFile(imgFilePath)], text: basename(aFile.path));
                                    print(imgFilePath);
                                  } catch (e) {
                                    debugPrint('Error sharing file: $e');
                                    // Handle the error or show a message to the user
                                  }
                                },
                                icon: const Icon(Icons.share),
                                color: toolBarIconColor,
                              ),
                              IconButton(
                                onPressed: () async {
                                  assetPath = preloadedImgFilePaths[imgFilePathIndex];
                                  statOfFile = FileStat.statSync(assetPath);
                                  if (!mounted) return;

                                  showDialog<void>(
                                      context: context,
                                      barrierDismissible: false, // user must tap button!
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(basename(aFile.path)),
                                          content: Wrap(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ListTile(
                                                    dense: true,
                                                    leading: const Icon(Icons.access_time),
                                                    title: Text('Created: ${DateFormat('dd-MMM-yyyy hh:mm a').format(assset.createDateTime)}'),
                                                    subtitle: Text('Modified: ${DateFormat('dd-MMM-yyyy hh:mm a').format(assset.modifiedDateTime)}'),
                                                  ),
                                                  ListTile(
                                                    dense: true,
                                                    leading: const Icon(Icons.image),
                                                    title: Text(
                                                        '${convertSize(statOfFile.size)} ${extension(assset.title!).replaceFirst(RegExp(r'.'), '')}'),
                                                    subtitle: Text(
                                                        '${((assset.width * assset.width) / 1000000).toStringAsFixed(1)}MP (${assset.width} x ${assset.height})'),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Ok'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                icon: const Icon(Icons.info),
                                color: toolBarIconColor,
                              ),
                              IconButton(
                                onPressed: () {
                                  // print(imgFilePath);
                                  OpenFile.open(imgFilePath);
                                },
                                icon: const Icon(Icons.open_in_new),
                                color: toolBarIconColor,
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog<void>(
                                      context: context,
                                      barrierDismissible: false, // user must tap button!
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete'),
                                          content: const Wrap(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Are you sure?'),
                                                ],
                                              )
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: const ButtonStyle(foregroundColor: MaterialStatePropertyAll(Colors.red)),
                                              onPressed: () async {
                                                // Navigator.of(context).pop();
                                                deleteFile(aFile);
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Ok'),
                                            ),
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                icon: const Icon(Icons.delete),
                                color: toolBarIconColor,
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    expandToolBar = !expandToolBar;
                                  });
                                },
                                icon: const Icon(Icons.more_vert),
                                color: toolBarIconColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
          uiToggleState
              ? Wrap(
                  children: [
                    GlassMorphism(
                      blur: 20,
                      opacity: 50,
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        foregroundColor: toolBarIconColor,
                        title: Column(
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(assset.modifiedDateTime),
                              style: TextStyle(fontSize: 20, color: toolBarIconColor),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(assset.modifiedDateTime),
                              style: TextStyle(fontSize: 15, color: toolBarIconColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              : const SizedBox(),
        ]));
  }
}
