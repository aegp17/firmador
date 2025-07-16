package com.example.firmador

import android.os.Bundle
import android.util.Log
import com.example.firmador.crypto.CertificateHelper
import com.example.firmador.signature.PdfSignatureService
import com.example.firmador.signature.SignatureRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.firmador/crypto"
        private const val TAG = "MainActivity"
    }
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var pdfSignatureService: PdfSignatureService
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize services
        pdfSignatureService = PdfSignatureService(this)
        
        // Setup method channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getCertificateInfo" -> handleGetCertificateInfo(call, result)
                "signPdf" -> handleSignPdf(call, result)
                else -> result.notImplemented()
            }
        }
        
        Log.d(TAG, "Flutter engine configured with native Android crypto support")
    }
    
    /**
     * Handle certificate information extraction
     */
    private fun handleGetCertificateInfo(call: MethodCall, result: MethodChannel.Result) {
        val p12Path = call.argument<String>("p12Path")
        val password = call.argument<String>("password")
        
        if (p12Path == null || password == null) {
            result.error("INVALID_ARGUMENTS", "Missing p12Path or password", null)
            return
        }
        
        // Run in background thread to avoid blocking UI
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "Extracting certificate info from: $p12Path")
                
                val certificateInfo = CertificateHelper.loadCertificateInfo(p12Path, password)
                
                withContext(Dispatchers.Main) {
                    Log.d(TAG, "Certificate info extracted successfully")
                    result.success(certificateInfo)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting certificate info", e)
                
                withContext(Dispatchers.Main) {
                    val errorMessage = when {
                        e.message?.contains("password") == true -> "Incorrect certificate password"
                        e.message?.contains("file") == true -> "Certificate file not found or corrupted"
                        else -> "Error reading certificate: ${e.message}"
                    }
                    result.error("CERTIFICATE_ERROR", errorMessage, e.message)
                }
            }
        }
    }
    
    /**
     * Handle PDF signing with digital certificate
     */
    private fun handleSignPdf(call: MethodCall, result: MethodChannel.Result) {
        // Extract parameters
        val pdfPath = call.argument<String>("pdfPath")
        val p12Path = call.argument<String>("p12Path")
        val password = call.argument<String>("password")
        val page = call.argument<Int>("page") ?: 1
        val x = call.argument<Double>("x") ?: 100.0
        val y = call.argument<Double>("y") ?: 100.0
        val width = call.argument<Double>("width") ?: 150.0
        val height = call.argument<Double>("height") ?: 50.0
        
        // Optional signature details
        val signerName = call.argument<String>("signerName") ?: "Unknown Signer"
        val location = call.argument<String>("location") ?: "Ecuador"
        val reason = call.argument<String>("reason") ?: "Digital Signature"
        val enableTimestamp = call.argument<Boolean>("enableTimestamp") ?: false
        val timestampServerUrl = call.argument<String>("timestampServerUrl")
        
        // Validate required parameters
        if (pdfPath == null || p12Path == null || password == null) {
            result.error("INVALID_ARGUMENTS", "Missing required parameters: pdfPath, p12Path, or password", null)
            return
        }
        
        // Run signing in background thread
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "Starting PDF signing process")
                Log.d(TAG, "PDF: $pdfPath")
                Log.d(TAG, "Certificate: $p12Path")
                Log.d(TAG, "Position: ($x, $y) on page $page")
                Log.d(TAG, "Timestamp: $enableTimestamp")
                
                // Create signature request
                val signatureRequest = SignatureRequest(
                    pdfPath = pdfPath,
                    certificatePath = p12Path,
                    certificatePassword = password,
                    signerName = signerName,
                    location = location,
                    reason = reason,
                    signatureX = x,
                    signatureY = y,
                    signatureWidth = width,
                    signatureHeight = height,
                    signaturePage = page,
                    enableTimestamp = enableTimestamp,
                    timestampServerUrl = timestampServerUrl
                )
                
                // Sign the PDF
                val signatureResult = pdfSignatureService.signPdf(signatureRequest)
                
                withContext(Dispatchers.Main) {
                    if (signatureResult.success) {
                        Log.i(TAG, "PDF signed successfully: ${signatureResult.signedFilePath}")
                        
                        // Prepare result data
                        val resultData = mapOf(
                            "success" to true,
                            "message" to signatureResult.message,
                            "signedFilePath" to signatureResult.signedFilePath,
                            "timestampUsed" to signatureResult.timestampUsed,
                            "timestampInfo" to signatureResult.timestampInfo,
                            "tsaServerUsed" to signatureResult.tsaServerUsed,
                            "warning" to signatureResult.warning
                        )
                        
                        result.success(resultData)
                    } else {
                        Log.e(TAG, "PDF signing failed: ${signatureResult.message}")
                        result.error("SIGNING_ERROR", signatureResult.message, signatureResult.error?.message)
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error during PDF signing", e)
                
                withContext(Dispatchers.Main) {
                    val errorMessage = when {
                        e.message?.contains("password") == true -> "Incorrect certificate password"
                        e.message?.contains("PDF") == true -> "Invalid or corrupted PDF file"
                        e.message?.contains("Certificate") == true -> "Certificate file error"
                        else -> "Signing failed: ${e.message}"
                    }
                    result.error("SIGNING_ERROR", errorMessage, e.message)
                }
            }
        }
    }
}
