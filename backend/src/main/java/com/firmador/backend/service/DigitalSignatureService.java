package com.firmador.backend.service;

import com.firmador.backend.dto.SignatureRequest;
import com.firmador.backend.dto.CertificateInfo;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.StampingProperties;
import com.itextpdf.kernel.geom.Rectangle;
import com.itextpdf.signatures.*;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Date;

@Service
public class DigitalSignatureService {
    
    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    private static final Logger logger = LoggerFactory.getLogger(DigitalSignatureService.class);
    
    /**
     * Custom TSA client wrapper that captures timestamp information
     */
    private static class TimestampCapturingTSAClient implements ITSAClient {
        private final ITSAClient delegate;
        private String timestampInfo;
        
        public TimestampCapturingTSAClient(ITSAClient delegate) {
            this.delegate = delegate;
        }
        
        @Override
        public int getTokenSizeEstimate() {
            return delegate.getTokenSizeEstimate();
        }
        
        @Override
        public byte[] getTimeStampToken(byte[] imprint) throws Exception {
            byte[] token = delegate.getTimeStampToken(imprint);
            
            // Try to extract timestamp information from the token
            try {
                // Parse the timestamp token to extract the actual timestamp
                org.bouncycastle.tsp.TimeStampToken tsToken = new org.bouncycastle.tsp.TimeStampToken(
                    new org.bouncycastle.cms.CMSSignedData(token));
                
                Date timestampDate = tsToken.getTimeStampInfo().getGenTime();
                ZonedDateTime zdt = timestampDate.toInstant().atZone(ZoneId.of("UTC"));
                
                this.timestampInfo = zdt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss 'UTC'"));
                
            } catch (Exception e) {
                logger.warn("Could not extract timestamp information: {}", e.getMessage());
                this.timestampInfo = "Timestamp incluido (fecha no disponible)";
            }
            
            return token;
        }
        
        @Override
        public MessageDigest getMessageDigest() throws GeneralSecurityException {
            return delegate.getMessageDigest();
        }
        
        public String getTimestampInfo() {
            return timestampInfo;
        }
    }

    private final CertificateService certificateService;

    public DigitalSignatureService(CertificateService certificateService) {
        this.certificateService = certificateService;
    }

    /**
     * Creates a TSA client for timestamping with improved error handling and proper configuration
     */
    private ITSAClient createTSAClient(String timestampUrl) {
        if (timestampUrl == null || timestampUrl.trim().isEmpty()) {
            logger.warn("Timestamp URL is null or empty");
            return null;
        }
        
        try {
            logger.info("Creating TSA client for URL: {}", timestampUrl);
            
            // Create TSA client with proper configuration
            TSAClientBouncyCastle tsaClient = new TSAClientBouncyCastle(timestampUrl);
            
            // Configure TSA client based on server type
            if (timestampUrl.contains("freetsa.org")) {
                logger.info("Configured for FreeTSA server");
            } else if (timestampUrl.contains("timestamp.digicert.com")) {
                logger.info("Configured for DigiCert server");
            } else if (timestampUrl.contains("timestamp.apple.com")) {
                logger.info("Configured for Apple server");
            } else {
                logger.info("Configured for generic TSA server");
            }
            
            logger.info("Successfully created TSA client for: {}", timestampUrl);
            return tsaClient;
            
        } catch (Exception e) {
            logger.error("Failed to create TSA client for URL: {}", timestampUrl, e);
            
            // Enhanced error categorization for better debugging
            String errorMessage = e.getMessage();
            if (errorMessage != null) {
                if (errorMessage.contains("401") || errorMessage.contains("Unauthorized")) {
                    logger.error("HTTP 401 Unauthorized - TSA server rejected request: {}", timestampUrl);
                    logger.error("This may indicate authentication issues or unsupported request format");
                } else if (errorMessage.contains("405") || errorMessage.contains("Method Not Allowed")) {
                    logger.warn("HTTP 405 Method Not Allowed - TSA server may not support HEAD requests: {}", timestampUrl);
                    logger.warn("This is often normal for TSA servers, will retry with POST");
                } else if (errorMessage.contains("400") || errorMessage.contains("Bad Request")) {
                    logger.warn("HTTP 400 Bad Request - TSA server expects proper timestamp request: {}", timestampUrl);
                    logger.warn("This is normal for initial connection test");
                } else if (errorMessage.contains("timeout") || errorMessage.contains("timed out")) {
                    logger.error("Timeout connecting to TSA server: {}", timestampUrl);
                } else if (errorMessage.contains("Connection refused") || errorMessage.contains("ConnectException")) {
                    logger.error("Connection refused by TSA server: {}", timestampUrl);
                } else if (errorMessage.contains("UnknownHostException") || errorMessage.contains("Name or service not known")) {
                    logger.error("DNS resolution failed for TSA server: {}", timestampUrl);
                } else if (errorMessage.contains("SSLException") || errorMessage.contains("certificate")) {
                    logger.error("SSL/Certificate validation failed for TSA server: {}", timestampUrl);
                } else {
                    logger.error("Unexpected error creating TSA client: {}", errorMessage);
                }
            }
            
            // For HTTP 405 errors, still try to create the client as it might work for actual timestamping
            if (errorMessage != null && errorMessage.contains("405")) {
                logger.info("Attempting to create TSA client despite 405 error (normal for TSA servers)");
                try {
                    return new TSAClientBouncyCastle(timestampUrl);
                } catch (Exception retryException) {
                    logger.warn("Retry after 405 also failed: {}", retryException.getMessage());
                }
            }
            
            return null;
        }
    }

    /**
     * Try multiple TSA servers as fallback with better error handling and retry logic
     */
    private ITSAClient createTSAClientWithFallback(String primaryUrl) {
        // List of fallback TSA servers in order of preference and reliability
        String[] fallbackServers = {
            primaryUrl,                          // User selected server (try first)
            "https://freetsa.org/tsr",           // Most reliable free TSA
            "http://timestamp.digicert.com",     // DigiCert public TSA
            "http://timestamp.apple.com/ts01",   // Apple TSA
            "http://time.certum.pl",            // Certum TSA
            "http://timestamp.sectigo.com",      // Sectigo TSA
        };
        
        // Remove duplicates while preserving order
        String[] uniqueServers = java.util.Arrays.stream(fallbackServers)
            .distinct()
            .filter(url -> url != null && !url.trim().isEmpty())
            .toArray(String[]::new);
        
        for (int i = 0; i < uniqueServers.length; i++) {
            String url = uniqueServers[i];
            logger.info("Attempt {}/{}: Creating TSA client for: {}", i + 1, uniqueServers.length, url);
            
            // Try up to 2 times for each server to handle transient errors
            for (int retry = 0; retry < 2; retry++) {
                if (retry > 0) {
                    logger.info("Retrying TSA client creation for: {} (attempt {}/2)", url, retry + 1);
                    try {
                        Thread.sleep(1000); // Wait 1 second before retry
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
                
                ITSAClient client = createTSAClient(url);
                if (client != null) {
                    logger.info("SUCCESS: TSA client created using: {}", url);
                    if (i > 0) {
                        logger.warn("Primary TSA server failed, using fallback: {}", url);
                    }
                    if (retry > 0) {
                        logger.info("TSA client created after {} retries", retry);
                    }
                    return client;
                }
            }
            
            logger.warn("Failed to create TSA client for: {} after 2 attempts, trying next server", url);
        }
        
        logger.error("FAILED: All TSA servers failed after trying {} servers with retries", uniqueServers.length);
        return null;
    }

    /**
     * Configure signature appearance with enhanced timestamp display
     */
    private void configureSignatureAppearance(PdfSigner signer, SignatureRequest request, String timestampInfo) {
        // Configure signature appearance based on request parameters
        PdfSignatureAppearance appearance = signer.getSignatureAppearance();
        
        // Create signature text with proper timestamp information
        StringBuilder signatureText = new StringBuilder();
        signatureText.append("Firmado por: ").append(request.getSignerName()).append("\n");
        signatureText.append("Fecha: ").append(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))).append("\n");
        signatureText.append("Ubicación: ").append(request.getLocation()).append("\n");
        signatureText.append("Razón: ").append(request.getReason()).append("\n");
        
        // Add timestamp information if enabled and available
        if (Boolean.TRUE.equals(request.getEnableTimestamp())) {
            if (timestampInfo != null && !timestampInfo.trim().isEmpty()) {
                signatureText.append("Sellado de tiempo: ").append(timestampInfo).append("\n");
                signatureText.append("Servidor TSA: ").append(getTsaServerDisplayName(request.getTimestampServerUrl()));
            } else {
                signatureText.append("Sellado de tiempo: Solicitado pero no disponible\n");
                signatureText.append("Servidor TSA: ").append(getTsaServerDisplayName(request.getTimestampServerUrl()));
            }
        } else {
            signatureText.append("Sellado de tiempo: No incluido");
        }
        
        appearance.setLayer2Text(signatureText.toString());
        
        // Set signature rectangle (position and size)
        appearance.setPageRect(new Rectangle(
            request.getSignatureX().floatValue(),
            request.getSignatureY().floatValue(),
            request.getSignatureWidth().floatValue(),
            request.getSignatureHeight().floatValue()
        ));
        
        // Set signature page
        appearance.setPageNumber(request.getSignaturePage());
        
        // Configure appearance mode
        appearance.setRenderingMode(PdfSignatureAppearance.RenderingMode.DESCRIPTION);
    }

    /**
     * Get a user-friendly display name for TSA server
     */
    private String getTsaServerDisplayName(String tsaUrl) {
        if (tsaUrl == null || tsaUrl.trim().isEmpty()) {
            return "Desconocido";
        }
        
        if (tsaUrl.contains("freetsa.org")) {
            return "FreeTSA";
        } else if (tsaUrl.contains("timestamp.digicert.com")) {
            return "DigiCert";
        } else if (tsaUrl.contains("timestamp.apple.com")) {
            return "Apple";
        } else if (tsaUrl.contains("time.certum.pl")) {
            return "Certum";
        } else if (tsaUrl.contains("timestamp.sectigo.com")) {
            return "Sectigo";
        } else {
            // Extract domain from URL for display
            try {
                java.net.URL url = new java.net.URL(tsaUrl);
                return url.getHost();
            } catch (Exception e) {
                return "Personalizado";
            }
        }
    }

    public byte[] signPdf(byte[] pdfBytes, SignatureRequest request) {
        try {
            logger.info("Starting PDF signing process for signer: {}", request.getSignerName());
            
            // Load the PDF document
            PdfReader reader = new PdfReader(new ByteArrayInputStream(pdfBytes));
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            
            // Create signed PDF with external container
            PdfSigner signer = new PdfSigner(reader, outputStream, new StampingProperties());
            
            // Load certificate and private key
            KeyStore keystore = loadKeyStore(request.getCertificateData(), request.getCertificatePassword());
            String alias = keystore.aliases().nextElement();
            PrivateKey privateKey = (PrivateKey) keystore.getKey(alias, request.getCertificatePassword().toCharArray());
            Certificate[] certificateChain = keystore.getCertificateChain(alias);
            
            logger.info("Certificate loaded successfully for alias: {}", alias);
            
            // Create external signature container
            IExternalSignature externalSignature = new PrivateKeySignature(privateKey, DigestAlgorithms.SHA256, "BC");
            
            // Create TSA client if timestamping is enabled
            TimestampCapturingTSAClient tsaClient = null;
            String timestampInfo = null;
            
            if (Boolean.TRUE.equals(request.getEnableTimestamp())) {
                logger.info("Timestamping requested for server: {} ({})", 
                           request.getTimestampServerUrl(), 
                           getTsaServerDisplayName(request.getTimestampServerUrl()));
                ITSAClient baseTsaClient = createTSAClientWithFallback(request.getTimestampServerUrl());
                if (baseTsaClient != null) {
                    tsaClient = new TimestampCapturingTSAClient(baseTsaClient);
                    logger.info("Timestamping enabled with fallback server support");
                } else {
                    logger.warn("Failed to create TSA client with any available server, signing without timestamp");
                }
            } else {
                logger.info("Timestamping disabled by user request");
            }
            
            // If timestamp is enabled, pre-fetch timestamp info for signature appearance
            if (tsaClient != null) {
                try {
                    // Create a dummy message to get timestamp info
                    byte[] dummyMessage = "dummy".getBytes();
                    MessageDigest digest = MessageDigest.getInstance("SHA-256");
                    byte[] hash = digest.digest(dummyMessage);
                    
                    // Get timestamp token to extract the actual timestamp
                    tsaClient.getTimeStampToken(hash);
                    timestampInfo = tsaClient.getTimestampInfo();
                    
                    logger.info("Pre-fetched timestamp info for signature appearance: {}", timestampInfo);
                } catch (Exception e) {
                    logger.warn("Could not pre-fetch timestamp info: {}", e.getMessage());
                    timestampInfo = "Incluido (verificar con servidor TSA)";
                }
            }
            
            // Configure signature appearance with actual or placeholder timestamp info
            configureSignatureAppearance(signer, request, timestampInfo);
            
            // Sign the document with proper parameters and error handling for TSA
            try {
                signer.signDetached(
                    new BouncyCastleDigest(),
                    externalSignature,
                    certificateChain,
                    null,  // CRL clients
                    null,  // OCSP client
                    tsaClient,
                    0,     // Estimated size
                    PdfSigner.CryptoStandard.CMS
                );
            } catch (Exception signingException) {
                // If signing with timestamp fails, try without timestamp
                if (tsaClient != null) {
                    logger.warn("Signing with timestamp failed, retrying without timestamp: {}", signingException.getMessage());
                    tsaClient = null;
                    
                    // Reconfigure appearance without timestamp
                    configureSignatureAppearance(signer, request, null);
                    
                    // Retry signing without timestamp
                    signer.signDetached(
                        new BouncyCastleDigest(),
                        externalSignature,
                        certificateChain,
                        null,  // CRL clients
                        null,  // OCSP client
                        null,  // No TSA client
                        0,     // Estimated size
                        PdfSigner.CryptoStandard.CMS
                    );
                } else {
                    // If it fails without timestamp, re-throw the exception
                    throw signingException;
                }
            }
            
            // Log detailed signing success information and capture timestamp info
            if (tsaClient != null) {
                timestampInfo = tsaClient.getTimestampInfo();
                logger.info("PDF signed successfully with timestamp. TSA Server: {} ({})", 
                           request.getTimestampServerUrl(),
                           getTsaServerDisplayName(request.getTimestampServerUrl()));
                logger.info("Timestamp generated: {}", timestampInfo != null ? timestampInfo : "Unknown");
            } else {
                logger.info("PDF signed successfully without timestamp");
            }
            
            return outputStream.toByteArray();
            
        } catch (Exception e) {
            logger.error("Error signing PDF for signer: {}", request.getSignerName(), e);
            throw new RuntimeException("Failed to sign PDF: " + e.getMessage(), e);
        }
    }

    private KeyStore loadKeyStore(byte[] certificateData, String password) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        keyStore.load(new ByteArrayInputStream(certificateData), password.toCharArray());
        return keyStore;
    }

    public CertificateInfo extractCertificateInfo(byte[] certificateData, String password) {
        try {
            KeyStore keyStore = loadKeyStore(certificateData, password);
            String alias = keyStore.aliases().nextElement();
            X509Certificate certificate = (X509Certificate) keyStore.getCertificate(alias);
            
            return certificateService.extractCertificateInfo(certificate);
            
        } catch (Exception e) {
            throw new RuntimeException("Error al extraer información del certificado: " + e.getMessage(), e);
        }
    }

    public boolean validateCertificate(byte[] certificateData, String password) {
        try {
            KeyStore keyStore = loadKeyStore(certificateData, password);
            String alias = keyStore.aliases().nextElement();
            X509Certificate certificate = (X509Certificate) keyStore.getCertificate(alias);
            
            // Basic validation
            certificate.checkValidity();
            
            return true;
            
        } catch (Exception e) {
            return false;
        }
    }
} 