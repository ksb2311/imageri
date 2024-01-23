import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imegeri/widgets/glassmorphism.dart';
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

  // controllers
  TransformationController controllerT = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;
  late PageController controllerPage;

  late List<String> preloadedImgFilePaths = [];

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
    double s = (sizeBytes / p).roundToDouble();
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
    print(preloadedImgFilePaths);
  }

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
      if (controllerT.value.getMaxScaleOnAxis() != 1.0) {
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
                  child: SizedBox(
                    // margin: const EdgeInsets.all(20),
                    height: 70,
                    width: double.infinity,
                    child: GlassMorphism(
                      blur: 20,
                      opacity: 0.2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              imgFilePath = preloadedImgFilePaths[imgFilePathIndex];
                              try {
                                Share.shareXFiles([XFile(imgFilePath)], text: basename(aFile.path));
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
                              String creDateStr =
                                  '${dateMod!.day.toString()}-${dateMod!.month.toString()}-${dateMod!.year.toString()} ${dateMod!.hour.toString()}:${dateMod!.minute.toString()}';
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
                                              Text('Width: ${assset.width}'),
                                              Text('Height: ${assset.height}'),
                                              Text('Created: $creDateStr'),
                                              Text('Type: ${extension(assset.title!)}'),
                                              Text('Size: ${convertSize(statOfFile.size)}'),
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
                            icon: const Icon(Icons.edit),
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
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert),
                            color: toolBarIconColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
          uiToggleState
              ? Wrap(
                  children: [
                    GlassMorphism(
                      blur: 20,
                      opacity: 0.2,
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        foregroundColor: toolBarIconColor,
                        title: Text(
                          assset.modifiedDateTime.toLocal().toString(),
                          style: TextStyle(fontSize: 20, color: toolBarIconColor),
                        ),
                      ),
                    )
                  ],
                )
              : const SizedBox(),
        ]));
  }
}
