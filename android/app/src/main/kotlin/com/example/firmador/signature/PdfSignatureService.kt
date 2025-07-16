package com.example.firmador.signature

import android.content.Context
import android.util.Log
import com.example.firmador.crypto.CertificateHelper
import com.example.firmador.crypto.TSAClient
import com.example.firmador.crypto.TimestampResult
import com.itextpdf.kernel.geom.Rectangle
import com.itextpdf.kernel.pdf.PdfReader
import com.itextpdf.kernel.pdf.StampingProperties
import com.itextpdf.signatures.*
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Security
import java.security.cert.Certificate
import java.text.SimpleDateFormat
import java.util.*

/**
 * PDF Digital Signature Service for Android using iText7
 */
class PdfSignatureService(private val context: Context) {
    
    companion object {
        private const val TAG = "PdfSignatureService"
        
        init {
            // Add BouncyCastle security provider
            if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
                Security.addProvider(BouncyCastleProvider())
            }
        }
    }
    
    private val tsaClient = TSAClient()
    
    /**
     * Sign a PDF document with digital certificate and optional timestamp
     */
    fun signPdf(request: SignatureRequest): SignatureResult {
        return try {
            Log.i(TAG, "Starting PDF signing process for: ${request.signerName}")
            
            // Validate inputs
            validateRequest(request)
            
            // Load certificate and private key
            val keyStore = CertificateHelper.loadKeyStore(request.certificatePath, request.certificatePassword)
            val privateKey = CertificateHelper.getPrivateKey(keyStore, request.certificatePassword)
            val certificateChain = CertificateHelper.getCertificateChain(keyStore)
            
            Log.d(TAG, "Certificate loaded successfully")
            
            // Setup PDF reader and signer
            val pdfReader = PdfReader(request.pdfPath)
            val outputFile = generateOutputPath(request.pdfPath)
            val pdfSigner = com.itextpdf.signatures.PdfSigner(
                pdfReader, 
                FileOutputStream(outputFile), 
                StampingProperties()
            )
            
            // Create external signature
            val externalSignature: IExternalSignature = PrivateKeySignature(
                privateKey, 
                DigestAlgorithms.SHA256, 
                BouncyCastleProvider.PROVIDER_NAME
            )
            
            // Handle timestamp if enabled
            var tsaClientForSigning: ITSAClient? = null
            var timestampInfo: String? = null
            
            if (request.enableTimestamp) {
                Log.d(TAG, "Timestamp requested for server: ${request.timestampServerUrl}")
                
                val timestampResult = obtainTimestamp(request.timestampServerUrl)
                if (timestampResult.success) {
                    tsaClientForSigning = createITextTSAClient(timestampResult)
                    timestampInfo = timestampResult.timestampInfo
                    Log.i(TAG, "Timestamp obtained: $timestampInfo")
                } else {
                    Log.w(TAG, "Timestamp failed: ${timestampResult.error}")
                }
            }
            
            // Configure signature appearance
            configureSignatureAppearance(pdfSigner, request, timestampInfo)
            
            // Sign the document
            try {
                pdfSigner.signDetached(
                    BouncyCastleDigest(),
                    externalSignature,
                    certificateChain,
                    null, // CRL clients
                    null, // OCSP client
                    tsaClientForSigning,
                    0, // Estimated size
                    PdfSigner.CryptoStandard.CMS
                )
                
                Log.i(TAG, "PDF signed successfully: $outputFile")
                
                return SignatureResult(
                    success = true,
                    message = "Document signed successfully",
                    signedFilePath = outputFile,
                    timestampUsed = timestampInfo != null,
                    timestampInfo = timestampInfo,
                    tsaServerUsed = if (timestampInfo != null) request.timestampServerUrl else null
                )
                
            } catch (e: Exception) {
                // If signing with timestamp fails, try without timestamp
                if (tsaClientForSigning != null) {
                    Log.w(TAG, "Signing with timestamp failed, retrying without: ${e.message}")
                    
                    // Reset signer and try again without timestamp
                    val retryReader = PdfReader(request.pdfPath)
                    val retrySigner = com.itextpdf.signatures.PdfSigner(
                        retryReader,
                        FileOutputStream(outputFile),
                        StampingProperties()
                    )
                    
                    configureSignatureAppearance(retrySigner, request, null)
                    
                    retrySigner.signDetached(
                        BouncyCastleDigest(),
                        externalSignature,
                        certificateChain,
                        null, null, null, 0,
                        PdfSigner.CryptoStandard.CMS
                    )
                    
                    Log.i(TAG, "PDF signed successfully without timestamp: $outputFile")
                    
                    return SignatureResult(
                        success = true,
                        message = "Document signed successfully (without timestamp)",
                        signedFilePath = outputFile,
                        timestampUsed = false,
                        timestampInfo = null,
                        warning = "Timestamp was requested but failed, document signed without timestamp"
                    )
                } else {
                    throw e
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error signing PDF", e)
            
            SignatureResult(
                success = false,
                message = "Failed to sign PDF: ${e.message}",
                error = e
            )
        }
    }
    
    /**
     * Validate signature request parameters
     */
    private fun validateRequest(request: SignatureRequest) {
        require(File(request.pdfPath).exists()) { "PDF file not found: ${request.pdfPath}" }
        require(File(request.certificatePath).exists()) { "Certificate file not found: ${request.certificatePath}" }
        require(request.certificatePassword.isNotBlank()) { "Certificate password is required" }
        require(request.signerName.isNotBlank()) { "Signer name is required" }
    }
    
    /**
     * Generate output file path for signed PDF
     */
    private fun generateOutputPath(originalPath: String): String {
        val file = File(originalPath)
        val parent = file.parent ?: ""
        val nameWithoutExt = file.nameWithoutExtension
        val extension = file.extension
        
        return "$parent/${nameWithoutExt}_signed_android.$extension"
    }
    
    /**
     * Obtain timestamp token from TSA servers
     */
    private fun obtainTimestamp(primaryTsaUrl: String?): TimestampResult {
        return try {
            // Create dummy message for pre-fetching timestamp info
            val dummyMessage = "dummy_for_timestamp".toByteArray()
            tsaClient.getTimestampToken(dummyMessage, primaryTsaUrl)
        } catch (e: Exception) {
            Log.e(TAG, "Error obtaining timestamp", e)
            TimestampResult(
                success = false,
                error = e.message ?: "Unknown timestamp error"
            )
        }
    }
    
    /**
     * Create iText TSA client from our timestamp result
     */
    private fun createITextTSAClient(timestampResult: TimestampResult): ITSAClient {
        return object : ITSAClient {
            override fun getTimeStampToken(imprint: ByteArray?): ByteArray? {
                return if (imprint != null) {
                    val result = tsaClient.getTimestampToken(imprint, timestampResult.serverUsed)
                    result.token
                } else {
                    null
                }
            }
            
            override fun getTokenSizeEstimate(): Int = 4096
            
            override fun getMessageDigest(): java.security.MessageDigest {
                return java.security.MessageDigest.getInstance("SHA-256")
            }
        }
    }
    
    /**
     * Configure signature appearance on PDF
     */
    private fun configureSignatureAppearance(
        pdfSigner: com.itextpdf.signatures.PdfSigner,
        request: SignatureRequest,
        timestampInfo: String?
    ) {
        val appearance = pdfSigner.signatureAppearance
        
        // Create signature text
        val signatureText = buildString {
            append("Signed by: ${request.signerName}\n")
            append("Date: ${getCurrentDateString()}\n")
            append("Location: ${request.location}\n")
            append("Reason: ${request.reason}\n")
            
            if (request.enableTimestamp) {
                if (timestampInfo != null) {
                    append("Timestamp: $timestampInfo\n")
                    append("TSA Server: ${tsaClient.getTsaServerDisplayName(request.timestampServerUrl ?: "")}")
                } else {
                    append("Timestamp: Requested but not available\n")
                    append("TSA Server: ${tsaClient.getTsaServerDisplayName(request.timestampServerUrl ?: "")}")
                }
            } else {
                append("Timestamp: Not included")
            }
        }
        
        appearance.layer2Text = signatureText
        
        // Set signature position and size
        appearance.pageRect = Rectangle(
            request.signatureX.toFloat(),
            request.signatureY.toFloat(),
            request.signatureWidth.toFloat(),
            request.signatureHeight.toFloat()
        )
        
        appearance.pageNumber = request.signaturePage
        
        Log.d(TAG, "Signature appearance configured at (${request.signatureX}, ${request.signatureY})")
    }
    
    /**
     * Get current date as formatted string
     */
    private fun getCurrentDateString(): String {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        return dateFormat.format(Date())
    }
}

/**
 * Request data for PDF signing operation
 */
data class SignatureRequest(
    val pdfPath: String,
    val certificatePath: String,
    val certificatePassword: String,
    val signerName: String,
    val location: String,
    val reason: String,
    val signatureX: Double = 100.0,
    val signatureY: Double = 100.0,
    val signatureWidth: Double = 150.0,
    val signatureHeight: Double = 50.0,
    val signaturePage: Int = 1,
    val enableTimestamp: Boolean = false,
    val timestampServerUrl: String? = null
)

/**
 * Result of PDF signing operation
 */
data class SignatureResult(
    val success: Boolean,
    val message: String,
    val signedFilePath: String? = null,
    val timestampUsed: Boolean = false,
    val timestampInfo: String? = null,
    val tsaServerUsed: String? = null,
    val warning: String? = null,
    val error: Throwable? = null
) 