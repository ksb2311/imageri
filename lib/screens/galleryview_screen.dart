import 'package:flutter/material.dart';
import 'package:imegeri/screens/viewpage_screen.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:system_theme/system_theme.dart';

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
  late List<AssetEntity> selectedAssetsByDate = [];

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

  Future<List<XFile>> getFilePaths(List<AssetEntity> entities) async {
    List<XFile> filePaths = [];
    for (var entity in entities) {
      var file = await entity.file;
      filePaths.add(XFile(file!.path));
    }
    return filePaths;
  }

  // Group assets by date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: selectionMode ? Text('${selectedAssets.length} Selected') : Text(widget.pathName),
        ),
        body: Column(children: [
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: allAssetsDate.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10), // Your separator widget here
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
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            allAssetsDate[index],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          GestureDetector(
                              onTap: () {
                                Set<AssetEntity> assetUnique = {};
                                assetUnique.addAll(assetsForCurrentDate);
                                setState(() {
                                  selectionMode = true;
                                  if (!assetsForCurrentDate.every((element) => selectedAssets.contains(element))) {
                                    selectedAssets.removeWhere((element) => assetsForCurrentDate.contains(element));
                                    selectedAssets.addAll(assetUnique);
                                  } else {
                                    selectedAssets.removeWhere((element) => assetsForCurrentDate.contains(element));
                                  }
                                });
                              },
                              child: const Icon(Icons.check_circle_outline))
                        ],
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
                              selectedAssets.add(asset);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Stack(fit: StackFit.expand, children: [
                              !asset.title.toString().toLowerCase().endsWith('.avif')
                                  ? AssetEntityImage(
                                      asset,
                                      isOriginal: false,
                                      thumbnailSize: const ThumbnailSize(200, 200),
                                      thumbnailFormat: ThumbnailFormat.jpeg,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(),
                              // isSelected
                              //     ? Container(
                              //         decoration: BoxDecoration(border: Border.all(color: SystemTheme.accentColor.accent, width: 5)),
                              //       )
                              //     : const SizedBox(),
                              selectionMode
                                  ? isSelected
                                      ? Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            decoration: BoxDecoration(color: SystemTheme.accentColor.accent, borderRadius: BorderRadius.circular(30)),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Theme.of(context).cardColor,
                                            ),
                                          ),
                                        )
                                      : Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                              decoration:
                                                  BoxDecoration(color: SystemTheme.accentColor.accent, borderRadius: BorderRadius.circular(30)),
                                              child: const Icon(Icons.circle, color: Colors.black)),
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
            ),
          ),
          selectionMode
              ? BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                          onPressed: () async {
                            try {
                              if (selectedAssets.isNotEmpty) {
                                List<XFile> xFiles = await getFilePaths(selectedAssets);
                                await Share.shareXFiles(xFiles, text: 'Multiple Files');
                              }
                            } catch (e) {
                              debugPrint('Error sharing file: $e');
                            }
                          },
                          icon: const Icon(Icons.share)),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              if (selectedAssets.length < allAssetsInFolder.length) {
                                Set<AssetEntity> uniqueList = {};
                                for (var element in allAssetsInFolder) {
                                  uniqueList.add(element);
                                }
                                selectedAssets.clear();
                                selectedAssets.addAll(uniqueList.toList());
                              } else {
                                selectedAssets.clear();
                              }
                            });
                          },
                          icon: Icon(selectedAssets.length == allAssetsInFolder.length ? Icons.grid_off : Icons.grid_on)),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              selectedAssets.clear();
                              selectionMode = false;
                            });
                          },
                          icon: const Icon(Icons.cancel_outlined)),
                    ],
                  ),
                )
              : const SizedBox()
        ]));
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
