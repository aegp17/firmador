package com.example.firmador

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.firmador/native_crypto"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCertificateInfo" -> {
                        // Placeholder implementation
                        result.success(mapOf(
                            "subject" to "CN=Test Certificate",
                            "issuer" to "CN=Test CA",
                            "serialNumber" to "123456789",
                            "validFrom" to "2024-01-01",
                            "validTo" to "2025-01-01",
                            "keyUsage" to listOf("Digital Signature", "Non Repudiation")
                        ))
                    }
                    "signPdf" -> {
                        // Placeholder implementation
                        result.success(mapOf(
                            "success" to true,
                            "message" to "PDF signed successfully (placeholder)",
                            "signedFilePath" to "/path/to/signed.pdf"
                        ))
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
