package com.cvc.avas_eto

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.cvc.avas_eto/open_file"
	private val REQUEST_TAKE_PHOTO = 9421
	private var pendingPhotoResult: MethodChannel.Result? = null
	private var currentPhotoPath: String? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"openFile" -> {
					val path = call.argument<String>("path")
					openFile(path, result)
				}
				"takePhoto" -> takePhoto(result)
				else -> result.notImplemented()
			}
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)

		if (requestCode != REQUEST_TAKE_PHOTO) return

		val callback = pendingPhotoResult
		pendingPhotoResult = null

		if (callback == null) return

		if (resultCode == Activity.RESULT_OK && !currentPhotoPath.isNullOrEmpty()) {
			callback.success(currentPhotoPath)
		} else {
			currentPhotoPath?.let { path ->
				try {
					File(path).delete()
				} catch (_: Exception) {
				}
			}
			callback.success(null)
		}

		currentPhotoPath = null
	}

	private fun takePhoto(result: MethodChannel.Result) {
		if (pendingPhotoResult != null) {
			result.error("CAMERA_BUSY", "Ya hay una captura de foto en curso", null)
			return
		}

		try {
			val photoFile = File.createTempFile(
				"task_photo_${System.currentTimeMillis()}_",
				".jpg",
				cacheDir
			)
			currentPhotoPath = photoFile.absolutePath

			val authority = applicationContext.packageName + ".fileprovider"
			val photoUri: Uri = FileProvider.getUriForFile(this, authority, photoFile)

			val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
				putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
				addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
				addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
			}

			val activity = intent.resolveActivity(packageManager)
			if (activity == null) {
				result.error("NO_CAMERA_APP", "No hay app de camara disponible", null)
				return
			}

			pendingPhotoResult = result
			startActivityForResult(intent, REQUEST_TAKE_PHOTO)
		} catch (e: Exception) {
			pendingPhotoResult = null
			currentPhotoPath = null
			result.error("TAKE_PHOTO_ERROR", e.message, null)
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
			intent.setDataAndType(uri, mime)
			intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

			val chooser = Intent.createChooser(intent, "Abrir con")
			startActivity(chooser)
			result.success(true)
		} catch (e: Exception) {
			result.error("OPEN_ERROR", e.message, null)
		}
	}
}
