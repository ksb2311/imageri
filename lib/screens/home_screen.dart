import 'package:flutter/material.dart';
import 'package:imegeri/screens/galleryview_screen.dart';
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
  List<int> _assetsCount = [];

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
        final List<int> countlist = [];
        for (var count in paths) {
          countlist.add((await count.getAssetListPaged(page: 0, size: 80)).length);
        }
        setState(() {
          _paths = paths;
          _assets = assets;
          _assetsCount = countlist;
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Imageri'),
        ),
        body: _paths.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(2.0),
                child: GridView.builder(
                  itemCount: _paths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.7),
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
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 120,
                                    padding: const EdgeInsets.all(2.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: AssetEntityImage(
                                        snapshot.data!,
                                        isOriginal: false,
                                        thumbnailSize: const ThumbnailSize(200, 200),
                                        thumbnailFormat: ThumbnailFormat.jpeg,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _paths[index].name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_assetsCount[index]}',
                                  )
                                ],
                              ),
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
