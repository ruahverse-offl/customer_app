package com.newbalan.medical.delivery

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannelName = "com.newbalan.medical/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val filename = call.argument<String>("filename")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (bytes == null || filename.isNullOrBlank()) {
                            result.error("ARGS", "bytes and filename are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveBytesToDownloads(bytes, filename, mimeType)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Writes [bytes] to the device's public Downloads folder as [filename].
     *
     * Android 10+ (Q, API 29): uses MediaStore.Downloads — no storage permission
     * required, and the file shows up in the Files app's Downloads section like
     * any browser-downloaded file.
     *
     * Android 9 and earlier: falls back to writing directly to the legacy
     * Downloads path. Relies on WRITE_EXTERNAL_STORAGE which we cap at
     * maxSdkVersion=29 in the manifest.
     *
     * Returns a human-readable location (e.g. "Downloads/invoice_ABC.pdf")
     * that the Flutter side can show in a success message.
     */
    private fun saveBytesToDownloads(bytes: ByteArray, filename: String, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("Could not create file in Downloads")
            resolver.openOutputStream(uri)?.use { out -> out.write(bytes) }
                ?: throw IllegalStateException("Could not open output stream for $uri")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Downloads/$filename"
        }

        // Legacy path for Android 9 and below.
        @Suppress("DEPRECATION")
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) downloadsDir.mkdirs()
        val file = File(downloadsDir, filename)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
