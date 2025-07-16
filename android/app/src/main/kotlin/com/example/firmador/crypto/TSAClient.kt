package com.example.firmador.crypto

import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.bouncycastle.asn1.ASN1ObjectIdentifier
import org.bouncycastle.asn1.nist.NISTObjectIdentifiers
import org.bouncycastle.tsp.*
import org.json.JSONObject
import java.io.IOException
import java.math.BigInteger
import java.security.MessageDigest
import java.security.SecureRandom
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * TSA Client for Android with fallback support and comprehensive error handling
 */
class TSAClient {
    
    companion object {
        private const val TAG = "TSAClient"
        private const val TIMEOUT_SECONDS = 10L
        private const val MAX_RETRIES = 2
        
        // TSA servers with fallback support (same as backend)
        private val TSA_SERVERS = listOf(
            "https://freetsa.org/tsr",
            "http://timestamp.digicert.com",
            "http://timestamp.apple.com/ts01",
            "http://timestamp.sectigo.com",
            "http://timestamp.entrust.net/TSS/RFC3161sha2TS"
        )
    }
    
    private val httpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .build()
    
    /**
     * Get timestamp token with fallback support
     */
    fun getTimestampToken(
        message: ByteArray, 
        primaryTsaUrl: String? = null
    ): TimestampResult {
        val serversToTry = buildServerList(primaryTsaUrl)
        
        Log.d(TAG, "Attempting to get timestamp from ${serversToTry.size} servers")
        
        for ((index, serverUrl) in serversToTry.withIndex()) {
            val isLastServer = index == serversToTry.size - 1
            
            for (attempt in 1..MAX_RETRIES) {
                try {
                    Log.d(TAG, "Trying server: $serverUrl (attempt $attempt/$MAX_RETRIES)")
                    
                    val result = requestTimestamp(serverUrl, message)
                    
                    Log.i(TAG, "Successfully obtained timestamp from: $serverUrl")
                    return result.copy(serverUsed = serverUrl)
                    
                } catch (e: Exception) {
                    val errorType = categorizeError(e)
                    Log.w(TAG, "Attempt $attempt failed for $serverUrl: $errorType - ${e.message}")
                    
                    // Don't retry for certain types of errors
                    if (errorType in listOf("HTTP_405", "HTTP_400", "AUTHENTICATION_ERROR")) {
                        break
                    }
                    
                    // Add delay between retries (except on last attempt)
                    if (attempt < MAX_RETRIES) {
                        try {
                            Thread.sleep(1000 * attempt) // Progressive delay
                        } catch (ie: InterruptedException) {
                            Thread.currentThread().interrupt()
                            break
                        }
                    }
                }
            }
        }
        
        Log.e(TAG, "All TSA servers failed after ${serversToTry.size * MAX_RETRIES} attempts")
        return TimestampResult(
            success = false,
            error = "All TSA servers failed. Please check your internet connection."
        )
    }
    
    /**
     * Build the list of servers to try, with primary server first
     */
    private fun buildServerList(primaryTsaUrl: String?): List<String> {
        val servers = mutableListOf<String>()
        
        // Add primary server first if provided and not already in list
        primaryTsaUrl?.let { url ->
            if (url.isNotBlank() && !TSA_SERVERS.contains(url)) {
                servers.add(url)
            }
        }
        
        // Add all default servers
        servers.addAll(TSA_SERVERS)
        
        // Remove duplicates while preserving order
        return servers.distinct()
    }
    
    /**
     * Request timestamp from a specific TSA server
     */
    private fun requestTimestamp(tsaUrl: String, message: ByteArray): TimestampResult {
        try {
            // Create TSA request
            val tsaRequest = createTSARequest(message)
            val requestBytes = tsaRequest.encoded
            
            Log.d(TAG, "Creating timestamp request for URL: $tsaUrl")
            
            // Create HTTP request
            val mediaType = "application/timestamp-query".toMediaType()
            val requestBody = requestBytes.toRequestBody(mediaType)
            
            val httpRequest = Request.Builder()
                .url(tsaUrl)
                .post(requestBody)
                .addHeader("Content-Type", "application/timestamp-query")
                .addHeader("Accept", "application/timestamp-reply")
                .addHeader("User-Agent", "Firmador-Android/1.0")
                .build()
            
            // Execute request
            val response = httpClient.newCall(httpRequest).execute()
            
            if (!response.isSuccessful) {
                throw IOException("HTTP ${response.code}: ${response.message}")
            }
            
            val responseBytes = response.body?.bytes()
                ?: throw IOException("Empty response from TSA server")
            
            // Parse TSA response
            val tsaResponse = TimeStampResponse(responseBytes)
            
            if (tsaResponse.status != 0) {
                throw IOException("TSA server returned error status: ${tsaResponse.status}")
            }
            
            val timeStampToken = tsaResponse.timeStampToken
                ?: throw IOException("No timestamp token in response")
            
            // Extract timestamp information
            val timestampInfo = extractTimestampInfo(timeStampToken)
            
            Log.i(TAG, "Successfully obtained timestamp: $timestampInfo")
            
            return TimestampResult(
                success = true,
                token = timeStampToken.encoded,
                timestampInfo = timestampInfo,
                serverUsed = tsaUrl
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting timestamp from $tsaUrl", e)
            throw e
        }
    }
    
    /**
     * Create a TSA request for the given message
     */
    private fun createTSARequest(message: ByteArray): TimeStampRequest {
        // Hash the message
        val digest = MessageDigest.getInstance("SHA-256")
        val hashedMessage = digest.digest(message)
        
        // Create TSA request generator
        val requestGenerator = TimeStampRequestGenerator()
        requestGenerator.setCertReq(true)
        
        // Generate random nonce
        val nonce = BigInteger.valueOf(SecureRandom().nextLong())
        
        return requestGenerator.generate(
            NISTObjectIdentifiers.id_sha256,
            hashedMessage,
            nonce
        )
    }
    
    /**
     * Extract human-readable timestamp information from token
     */
    private fun extractTimestampInfo(timeStampToken: TimeStampToken): String {
        return try {
            val timestampInfo = timeStampToken.timeStampInfo
            val genTime = timestampInfo.genTime
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss 'UTC'", Locale.US)
            dateFormat.timeZone = TimeZone.getTimeZone("UTC")
            
            dateFormat.format(genTime)
        } catch (e: Exception) {
            Log.w(TAG, "Could not extract timestamp info: ${e.message}")
            "Timestamp included (date not available)"
        }
    }
    
    /**
     * Categorize errors for better handling
     */
    private fun categorizeError(error: Exception): String {
        return when {
            error.message?.contains("405") == true -> "HTTP_405"
            error.message?.contains("400") == true -> "HTTP_400"
            error.message?.contains("401") == true || 
            error.message?.contains("403") == true -> "AUTHENTICATION_ERROR"
            error.message?.contains("timeout") == true -> "TIMEOUT"
            error.message?.contains("SSL") == true ||
            error.message?.contains("TLS") == true -> "SSL_ERROR"
            error.message?.contains("UnknownHost") == true ||
            error.message?.contains("Network") == true -> "DNS_ERROR"
            else -> "UNKNOWN_ERROR"
        }
    }
    
    /**
     * Get display name for TSA server
     */
    fun getTsaServerDisplayName(url: String): String {
        return when {
            url.contains("freetsa.org") -> "FreeTSA"
            url.contains("digicert.com") -> "DigiCert"
            url.contains("apple.com") -> "Apple"
            url.contains("sectigo.com") -> "Sectigo"
            url.contains("entrust.net") -> "Entrust"
            else -> "Custom TSA"
        }
    }
}

/**
 * Result class for timestamp operations
 */
data class TimestampResult(
    val success: Boolean,
    val token: ByteArray? = null,
    val timestampInfo: String? = null,
    val serverUsed: String? = null,
    val error: String? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as TimestampResult

        if (success != other.success) return false
        if (token != null) {
            if (other.token == null) return false
            if (!token.contentEquals(other.token)) return false
        } else if (other.token != null) return false
        if (timestampInfo != other.timestampInfo) return false
        if (serverUsed != other.serverUsed) return false
        if (error != other.error) return false

        return true
    }

    override fun hashCode(): Int {
        var result = success.hashCode()
        result = 31 * result + (token?.contentHashCode() ?: 0)
        result = 31 * result + (timestampInfo?.hashCode() ?: 0)
        result = 31 * result + (serverUsed?.hashCode() ?: 0)
        result = 31 * result + (error?.hashCode() ?: 0)
        return result
    }
} 