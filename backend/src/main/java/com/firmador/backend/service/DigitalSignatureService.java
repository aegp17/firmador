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

@Service
public class DigitalSignatureService {
    
    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    private static final Logger logger = LoggerFactory.getLogger(DigitalSignatureService.class);

    private final CertificateService certificateService;

    public DigitalSignatureService(CertificateService certificateService) {
        this.certificateService = certificateService;
    }

    /**
     * Creates a TSA client for timestamping
     */
    private ITSAClient createTSAClient(String timestampUrl) {
        if (timestampUrl == null || timestampUrl.trim().isEmpty()) {
            return null;
        }
        
        try {
            logger.info("Creating TSA client for URL: {}", timestampUrl);
            return new TSAClientBouncyCastle(timestampUrl);
        } catch (Exception e) {
            logger.error("Failed to create TSA client for URL: {}", timestampUrl, e);
            return null;
        }
    }

    /**
     * Configure signature appearance
     */
    private void configureSignatureAppearance(PdfSigner signer, SignatureRequest request) {
        // Configure signature appearance based on request parameters
        PdfSignatureAppearance appearance = signer.getSignatureAppearance();
        
        // Set signature text
        appearance.setLayer2Text(String.format(
            "Firmado por: %s\nFecha: %s\nUbicación: %s\nRazón: %s",
            request.getSignerName(),
            LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
            request.getLocation(),
            request.getReason()
        ));
        
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

    public byte[] signPdf(byte[] pdfBytes, SignatureRequest request) {
        try {
            logger.info("Starting PDF signing process for signer: {}", request.getSignerName());
            
            // Load the PDF document
            PdfReader reader = new PdfReader(new ByteArrayInputStream(pdfBytes));
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            
            // Create signed PDF with external container
            PdfSigner signer = new PdfSigner(reader, outputStream, new StampingProperties());
            
            // Configure signature appearance
            configureSignatureAppearance(signer, request);
            
            // Load certificate and private key
            KeyStore keystore = loadKeyStore(request.getCertificateData(), request.getCertificatePassword());
            String alias = keystore.aliases().nextElement();
            PrivateKey privateKey = (PrivateKey) keystore.getKey(alias, request.getCertificatePassword().toCharArray());
            Certificate[] certificateChain = keystore.getCertificateChain(alias);
            
            logger.info("Certificate loaded successfully for alias: {}", alias);
            
            // Create external signature container
            IExternalSignature externalSignature = new PrivateKeySignature(privateKey, DigestAlgorithms.SHA256, "BC");
            
            // Create TSA client if timestamping is enabled
            ITSAClient tsaClient = null;
            if (Boolean.TRUE.equals(request.getEnableTimestamp())) {
                tsaClient = createTSAClient(request.getTimestampServerUrl());
                if (tsaClient != null) {
                    logger.info("Timestamping enabled with server: {}", request.getTimestampServerUrl());
                } else {
                    logger.warn("Failed to create TSA client, signing without timestamp");
                }
            } else {
                logger.info("Timestamping disabled");
            }
            
            // Sign the document with proper parameters
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
            
            logger.info("PDF signed successfully. Timestamping: {}", 
                       tsaClient != null ? "enabled" : "disabled");
            
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