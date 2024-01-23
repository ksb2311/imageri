import 'package:flutter/material.dart';
import 'package:imegeri/screens/viewpage_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class GalleryView extends StatefulWidget {
  final List<AssetEntity> gotAssets;
  final String pathName;

  const GalleryView({super.key, required this.gotAssets, required this.pathName});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  late var allAssetsInFolder = [];

  @override
  void initState() {
    getAssetsList();
    super.initState();
  }

  void getAssetsList() {
    setState(() {
      allAssetsInFolder = widget.gotAssets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathName),
      ),
      body: GridView.builder(
        itemCount: allAssetsInFolder.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              // var fullMediaPath =
              //     await widget._assets[index].file.then((value) => value);
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewerPage(widget.gotAssets, index),
                ),
              ).whenComplete(() => getAssetsList());

              // print(await widget._assets[index].file.then((value) => value));
            },
            child: AssetEntityImage(
              widget.gotAssets[index],
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(200, 200),
              thumbnailFormat: ThumbnailFormat.jpeg,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
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
