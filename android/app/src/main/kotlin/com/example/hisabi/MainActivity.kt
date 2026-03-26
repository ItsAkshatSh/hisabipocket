package com.example.hisabipocket

import android.app.Activity
import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hisabi/voice_input"
    private val REQUEST_CODE_SPEECH = 1001
    private val REQUEST_CODE_RECORD_AUDIO = 2002
    private var pendingResult: MethodChannel.Result? = null
    private var pendingStartAfterPermission: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "startVoiceInput") {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "Voice input already in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    startVoiceRecognition()
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun startVoiceRecognition() {
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            pendingStartAfterPermission = true
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQUEST_CODE_RECORD_AUDIO
            )
            return
        }

        startVoiceRecognitionInternal()
    }

    private fun startVoiceRecognitionInternal() {
        val languageTag = Locale.getDefault().toLanguageTag()

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageTag)
            // Prefer online recognition when possible; forcing offline can yield empty results.
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            // Avoid streaming partial hypotheses; we only need the final transcript.
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Say something like \"20 for groceries\"")
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
        }

        try {
            // If there is no speech recognizer activity, the Google popup can say
            // "Voice search is not available". We pre-detect and return a clear error.
            if (intent.resolveActivity(packageManager) == null) {
                pendingResult?.error(
                    "VOICE_SEARCH_UNAVAILABLE",
                    "Voice search is not available on this device. Install/enable Google speech services and try again.",
                    null
                )
                pendingResult = null
                return
            }

            startActivityForResult(intent, REQUEST_CODE_SPEECH)
        } catch (e: ActivityNotFoundException) {
            pendingResult?.error(
                "VOICE_SEARCH_UNAVAILABLE",
                "Voice search is not available on this device. Install/enable Google speech services and try again.",
                null
            )
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_SPEECH) {
            val result = pendingResult ?: return
            pendingResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull() ?: ""
                result.success(text)
            } else {
                // Many devices show a Google dialog like "Voice search is not available"
                // and return RESULT_CANCELED. Surface that to the UI.
                result.error(
                    "VOICE_SEARCH_UNAVAILABLE",
                    "Voice search is not available on this device. Install/enable Google speech services and try again.",
                    null
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_CODE_RECORD_AUDIO) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (pendingStartAfterPermission) {
                    pendingStartAfterPermission = false
                    startVoiceRecognitionInternal()
                }
            } else {
                pendingStartAfterPermission = false
                pendingResult?.error(
                    "PERMISSION_DENIED",
                    "Microphone permission was denied",
                    null
                )
                pendingResult = null
            }
        }
    }

    override fun getInitialRoute(): String? {
        intent?.data?.let { uri ->
            if (uri.scheme == "homewidget") {
                return when (uri.host) {
                    "quick_voice_add" -> "/voice-add"
                    "open_dashboard" -> "/dashboard"
                    else -> super.getInitialRoute()
                }
            }
        }
        return super.getInitialRoute()
    }
}
