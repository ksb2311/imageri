package com.example.imegeri

// import android.app.WallpaperManager
// import android.net.Uri
import io.flutter.embedding.android.FlutterActivity

// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodChannel
// import java.io.File
// import java.io.IOException

class MainActivity : FlutterActivity() {
    // private val CHANNEL = "com.example.wallpaper"

    // override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    //     MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    //         .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
    //             if (call.method == "setWallpaper") {
    //                 val imagePath = call.argument<String>("imagePath")
    //                 val imageFile = imagePath?.let { File(it) }
    //                 val imageUri = Uri.fromFile(imageFile)
    //                 val wallpaperManager =
    //                     WallpaperManager.getInstance(applicationContext)
    //                 try {
    //                     wallpaperManager.setStream(contentResolver.openInputStream(imageUri))
    //                     result.success(null)
    //                 } catch (e: IOException) {
    //                     result.error("ERROR", "Failed to set wallpaper", null)
    //                 }
    //             } else {
    //                 result.notImplemented()
    //             }
    //         }
    // }
}
