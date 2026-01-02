package com.example.hisabi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hisabi/voice_input"
    private val REQUEST_CODE_SPEECH = 1001
    private var pendingResult: MethodChannel.Result? = null

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
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Say something like \"20 for groceries\"")
        }

        try {
            startActivityForResult(intent, REQUEST_CODE_SPEECH)
        } catch (e: ActivityNotFoundException) {
            pendingResult?.error("NO_SPEECH_APP", "Speech recognition not available", null)
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
                result.error("CANCELLED", "User cancelled voice input", null)
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
