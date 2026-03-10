package com.cvc.avas_eto

import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.cvc.avas_eto/open_file"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "openFile") {
				val path = call.argument<String>("path")
				openFile(path, result)
			} else {
				result.notImplemented()
			}
		}
	}

	private fun openFile(path: String?, result: MethodChannel.Result) {
		if (path == null) {
			result.error("NO_PATH", "Path is null", null)
			return
		}

		try {
			val file = File(path)
			val authority = applicationContext.packageName + ".fileprovider"
			val uri: Uri = FileProvider.getUriForFile(this, authority, file)

			val ext = file.extension
			val mime = if (ext.isNotEmpty()) MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) else "*/*"

			val intent = Intent(Intent.ACTION_VIEW)
			intent.setDataAndType(uri, mime ?: "*/*")
			intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

			val chooser = Intent.createChooser(intent, "Abrir con")
			startActivity(chooser)
			result.success(true)
		} catch (e: Exception) {
			result.error("OPEN_ERROR", e.message, null)
		}
	}
}
