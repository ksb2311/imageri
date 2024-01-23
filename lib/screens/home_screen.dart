import 'package:flutter/material.dart';
import 'package:imegeri/screens/viewpage_screen.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssetPathEntity> _paths = [];
  List<AssetEntity> _assets = [];

  @override
  void initState() {
    super.initState();
    _requestPermission();
    // getThumb();
  }

  Future<void> _requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (state == PermissionState.authorized && await Permission.manageExternalStorage.request().isGranted) {
      final paths = await PhotoManager.getAssetPathList();
      if (paths.isNotEmpty) {
        final assets = await paths[0].getAssetListPaged(page: 0, size: 80);
        setState(() {
          _paths = paths;
          _assets = assets;
        });
        debugPrint(' paths found');
      } else {
        debugPrint('No paths found');
      }
    } else {
      debugPrint('Permission not granted');
    }
  }

  void updatePathList() async {
    final paths = await PhotoManager.getAssetPathList();
    setState(() {
      _paths = paths;
    });
  }

  void getThumb() async {
    if (_paths.isNotEmpty) {
      final assets = await _paths[0].getAssetListPaged(page: 0, size: 80);
      setState(() {
        _assets = assets;
      });
    }
  }

  Future<AssetEntity?> getFirstAssetFromAlbum(AssetPathEntity album) async {
    List<AssetEntity> assets = await album.getAssetListPaged(page: 0, size: 1);
    return assets.isNotEmpty ? assets.first : null;
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.transparent,
    // ));
    return Scaffold(
        appBar: AppBar(
          title: const Text('Imageri'),
        ),
        body: _paths.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(2.0),
                child: GridView.builder(
                  itemCount: _paths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 30),
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<AssetEntity?>(
                      future: getFirstAssetFromAlbum(_paths[index]),
                      builder: (BuildContext context, AsyncSnapshot<AssetEntity?> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return GestureDetector(
                            onTap: () async {
                              final assets = await _paths[index].getAssetListPaged(page: 0, size: 80);
                              setState(() {
                                _assets = assets;
                              });
                              if (!mounted) return;
                              if (_assets.isNotEmpty) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GalleryView(gotAssets: _assets, pathName: _paths[index].name),
                                    ));
                                // )).then((_) => updatePathList());
                              }
                            },
                            child: Stack(
                              fit: StackFit.passthrough,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  margin: const EdgeInsets.all(2),
                                  child: AssetEntityImage(
                                    snapshot.data!,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize(200, 200),
                                    thumbnailFormat: ThumbnailFormat.jpeg,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 5,
                                  child: Text(
                                    _paths[index].name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    );
                  },
                ))
            : const Center(child: CircularProgressIndicator()));
  }
}

class GalleryView extends StatefulWidget {
  final List<AssetEntity> gotAssets;
  final String pathName;

  const GalleryView({super.key, required this.gotAssets, required this.pathName});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  late List<AssetEntity> allAssetsInFolder = [];
  late var allAssetsDate = [];
  Map<String, List<AssetEntity>> groupedAssets = {};

  // item seletion
  late bool selectionMode = false;
  late List<AssetEntity> selectedAssets = [];

  @override
  void initState() {
    getAssetsList();
    super.initState();
  }

  void getAssetsList() {
    setState(() {
      allAssetsInFolder = widget.gotAssets;
      for (var asset in allAssetsInFolder) {
        String date = DateFormat('dd MMM yyyy').format(asset.modifiedDateTime);
        if (!groupedAssets.containsKey(date)) {
          groupedAssets[date] = [];
        }
        groupedAssets[date]!.add(asset);
        if (!allAssetsDate.contains(date)) {
          allAssetsDate.add(date);
        }
      }
    });
  }

  // Group assets by date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.pathName),
        ),
        // body: ListView.builder(
        //   shrinkWrap: true,
        //   itemCount: groupedAssets.length,
        //   itemBuilder: (BuildContext context, int index) {
        //     List<AssetEntity> flatList = groupedAssets.entries.toList()[index].value;
        //     late String modifiedDate = groupedAssets.entries.toList()[index].key;
        //     // for (var entry in groupedAssets[in].entries) {
        //     //   flatList
        //     //       // ..add(entry.key)
        //     //       // ..addAll(entry.value);
        //     //       .addAll(entry.value);
        //     //   modifiedDate = entry.key;
        //     // }

        //     return Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: Text(
        //             modifiedDate,
        //             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        //           ),
        //         ),
        //         Padding(
        //           padding: const EdgeInsets.all(2.0),
        //           child: GridView.builder(
        //             shrinkWrap: true,
        //             itemCount: flatList.length,
        //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //               crossAxisCount: 4,
        //               crossAxisSpacing: 2,
        //               mainAxisSpacing: 2,
        //             ),
        //             itemBuilder: (context, gindex) {
        //               dynamic item = flatList[gindex];
        //               // This is an asset, so return the asset
        //               return GestureDetector(
        //                 onTap: () async {
        //                   // var fullMediaPath =
        //                   //     await widget._assets[index].file.then((value) => value);
        //                   if (!mounted) return;
        //                   Navigator.push(
        //                       context,
        //                       MaterialPageRoute(
        //                         builder: (context) => ViewerPage(flatList, index),
        //                       ));
        //                   // ).whenComplete(() => getAssetsList());

        //                   // print(await widget._assets[index].file.then((value) => value));
        //                 },
        //                 child: AssetEntityImage(
        //                   item,
        //                   isOriginal: false,
        //                   thumbnailSize: const ThumbnailSize(200, 200),
        //                   thumbnailFormat: ThumbnailFormat.jpeg,
        //                   fit: BoxFit.cover,
        //                 ),
        //               );
        //             },
        //           ),
        //         ),
        //       ],
        //     );
        //     // : const SizedBox();
        //   },
        // ));
        body: ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: allAssetsDate.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(), // Your separator widget here
          itemBuilder: (BuildContext context, int index) {
            List<AssetEntity> assetsForCurrentDate = allAssetsInFolder
                .where((asset) {
                  return DateFormat('dd MMM yyyy').format(asset.modifiedDateTime) == allAssetsDate[index];
                })
                .toList()
                .cast<AssetEntity>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    allAssetsDate[index],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(assetsForCurrentDate.length, (gvIndex) {
                    AssetEntity asset = allAssetsInFolder.firstWhere(
                      (asset) => asset.id == assetsForCurrentDate[gvIndex].id,
                    );
                    bool isSelected = selectedAssets.contains(asset);
                    return GestureDetector(
                      onTap: () async {
                        // var fullMediaPath =
                        //     await widget._assets[index].file.then((value) => value);
                        if (!selectionMode) {
                          if (!mounted) return;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewerPage(allAssetsInFolder, allAssetsInFolder.indexOf(asset)),
                              ));
                        } else {
                          setState(() {
                            if (isSelected) {
                              selectedAssets.remove(asset);
                            } else {
                              selectedAssets.add(asset);
                            }
                          });
                        }
                        // ).whenComplete(() => getAssetsList());

                        // print(await widget._assets[index].file.then((value) => value));
                      },
                      onLongPress: () {
                        setState(() {
                          selectionMode = !selectionMode;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Stack(fit: StackFit.expand, children: [
                          AssetEntityImage(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize(200, 200),
                            thumbnailFormat: ThumbnailFormat.jpeg,
                            fit: BoxFit.cover,
                          ),
                          selectionMode
                              ? isSelected
                                  ? const Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Icon(Icons.check_circle, color: Colors.green),
                                    )
                                  : const Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Icon(Icons.circle_outlined),
                                    )
                              : const SizedBox()
                        ]),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ));
  }

  Future<List<AssetEntity>> getUpdatedAssets() async {
    // Fetch the updated list of assets
    List<AssetPathEntity> pathList = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
    List<AssetEntity> assets = [];
    for (var path in pathList) {
      List<AssetEntity> assetList = await path.getAssetListRange(start: 0, end: await path.assetCountAsync);
      assets.addAll(assetList);
    }
    return assets;
  }
}
