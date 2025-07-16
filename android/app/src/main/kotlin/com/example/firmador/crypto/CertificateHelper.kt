package com.example.firmador.crypto

import org.bouncycastle.asn1.x500.X500Name
import org.bouncycastle.cert.jcajce.JcaX509CertificateHolder
import java.io.FileInputStream
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.*

/**
 * Helper class for certificate operations including PKCS12 loading and information extraction
 */
class CertificateHelper {
    
    companion object {
        private const val TAG = "CertificateHelper"
        private const val PKCS12_TYPE = "PKCS12"
        
        /**
         * Load a PKCS12 certificate file and extract information
         */
        fun loadCertificateInfo(p12Path: String, password: String): Map<String, Any> {
            try {
                // Load the PKCS12 keystore
                val keyStore = loadKeyStore(p12Path, password)
                val alias = keyStore.aliases().nextElement()
                val certificate = keyStore.getCertificate(alias) as X509Certificate
                
                return extractCertificateInfo(certificate)
            } catch (e: Exception) {
                throw RuntimeException("Error loading certificate: ${e.message}", e)
            }
        }
        
        /**
         * Load PKCS12 keystore from file
         */
        fun loadKeyStore(p12Path: String, password: String): KeyStore {
            val keyStore = KeyStore.getInstance(PKCS12_TYPE)
            FileInputStream(p12Path).use { fis ->
                keyStore.load(fis, password.toCharArray())
            }
            return keyStore
        }
        
        /**
         * Get private key from keystore
         */
        fun getPrivateKey(keyStore: KeyStore, password: String): PrivateKey {
            val alias = keyStore.aliases().nextElement()
            return keyStore.getKey(alias, password.toCharArray()) as PrivateKey
        }
        
        /**
         * Get certificate chain from keystore
         */
        fun getCertificateChain(keyStore: KeyStore): Array<java.security.cert.Certificate> {
            val alias = keyStore.aliases().nextElement()
            return keyStore.getCertificateChain(alias)
        }
        
        /**
         * Extract detailed information from X.509 certificate
         */
        fun extractCertificateInfo(certificate: X509Certificate): Map<String, Any> {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            dateFormat.timeZone = TimeZone.getTimeZone("UTC")
            
            // Parse subject DN
            val subjectDN = certificate.subjectDN.name
            val issuerDN = certificate.issuerDN.name
            
            // Extract common name from subject
            val commonName = extractCommonName(subjectDN)
            
            // Get key usage information
            val keyUsages = mutableListOf<String>()
            certificate.keyUsage?.let { usage ->
                if (usage[0]) keyUsages.add("Digital Signature")
                if (usage[1]) keyUsages.add("Non Repudiation")
                if (usage[2]) keyUsages.add("Key Encipherment")
                if (usage[3]) keyUsages.add("Data Encipherment")
                if (usage[4]) keyUsages.add("Key Agreement")
                if (usage[5]) keyUsages.add("Certificate Sign")
                if (usage[6]) keyUsages.add("CRL Sign")
                if (usage[7]) keyUsages.add("Encipher Only")
                if (usage[8]) keyUsages.add("Decipher Only")
            }
            
            // Check if certificate is currently valid
            val now = Date()
            val isValid = try {
                certificate.checkValidity(now)
                true
            } catch (e: Exception) {
                false
            }
            
            return mapOf(
                "subject" to subjectDN,
                "issuer" to issuerDN,
                "validFrom" to dateFormat.format(certificate.notBefore),
                "validTo" to dateFormat.format(certificate.notAfter),
                "serialNumber" to certificate.serialNumber.toString(16).uppercase(),
                "commonName" to commonName,
                "keyUsages" to keyUsages,
                "trusted" to isValid,
                "algorithm" to certificate.sigAlgName,
                "version" to certificate.version,
                "publicKeyAlgorithm" to certificate.publicKey.algorithm
            )
        }
        
        /**
         * Extract common name from Distinguished Name
         */
        private fun extractCommonName(distinguishedName: String): String {
            try {
                // Parse using BouncyCastle for more reliable parsing
                val x500Name = X500Name(distinguishedName)
                val rdns = x500Name.getRDNs()
                
                for (rdn in rdns) {
                    for (atv in rdn.typesAndValues) {
                        if (atv.type.toString() == "2.5.4.3") { // CN OID
                            return atv.value.toString()
                        }
                    }
                }
                
                // Fallback to simple parsing
                val cnPattern = Regex("CN=([^,]+)")
                val match = cnPattern.find(distinguishedName)
                return match?.groupValues?.get(1)?.trim() ?: "Unknown"
                
            } catch (e: Exception) {
                // Final fallback
                return distinguishedName.substringAfter("CN=").substringBefore(",").trim()
            }
        }
        
        /**
         * Validate certificate password
         */
        fun validateCertificate(p12Path: String, password: String): Boolean {
            return try {
                loadKeyStore(p12Path, password)
                true
            } catch (e: Exception) {
                false
            }
        }
        
        /**
         * Check if certificate is currently valid (not expired)
         */
        fun isCertificateValid(certificate: X509Certificate): Boolean {
            return try {
                certificate.checkValidity()
                true
            } catch (e: Exception) {
                false
            }
        }
    }
} 