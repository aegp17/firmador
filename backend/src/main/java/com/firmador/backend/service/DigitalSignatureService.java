package com.firmador.backend.service;

import com.firmador.backend.dto.CertificateInfo;
import com.firmador.backend.dto.SignatureRequest;
import com.firmador.backend.dto.SignatureResponse;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.kernel.pdf.StampingProperties;
import com.itextpdf.signatures.*;
import com.itextpdf.kernel.geom.Rectangle;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.Security;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DigitalSignatureService {

    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    private final CertificateService certificateService;
    private final DocumentStorageService documentStorageService;

    public DigitalSignatureService(CertificateService certificateService, 
                                  DocumentStorageService documentStorageService) {
        this.certificateService = certificateService;
        this.documentStorageService = documentStorageService;
    }

    public SignatureResponse signDocument(byte[] documentData, SignatureRequest signatureRequest) {
        try {
            // Load certificate and private key
            KeyStore keyStore = loadKeyStore(signatureRequest.getCertificateData(), 
                                           signatureRequest.getCertificatePassword());
            
            String alias = keyStore.aliases().nextElement();
            PrivateKey privateKey = (PrivateKey) keyStore.getKey(alias, 
                                                                signatureRequest.getCertificatePassword().toCharArray());
            Certificate[] chain = keyStore.getCertificateChain(alias);
            X509Certificate certificate = (X509Certificate) chain[0];

            // Create signed PDF
            byte[] signedPdfData = createSignedPdf(documentData, privateKey, chain, signatureRequest, certificate);

            // Generate response
            String documentId = UUID.randomUUID().toString();
            String filename = "signed_document_" + System.currentTimeMillis() + ".pdf";
            
            // Store signed document
            documentStorageService.storeDocument(documentId, signedPdfData, filename, "application/pdf");
            
            SignatureResponse response = new SignatureResponse(
                true, 
                "Documento firmado exitosamente",
                documentId,
                filename,
                LocalDateTime.now(),
                signatureRequest.getSignerName(),
                signatureRequest.getLocation(),
                signatureRequest.getReason(),
                signedPdfData.length,
                "/api/signature/download/" + documentId
            );

            return response;

        } catch (Exception e) {
            return new SignatureResponse(false, "Error al firmar el documento: " + e.getMessage());
        }
    }

    private byte[] createSignedPdf(byte[] documentData, PrivateKey privateKey, Certificate[] chain, 
                                  SignatureRequest signatureRequest, X509Certificate certificate) throws Exception {
        
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        PdfReader reader = new PdfReader(new ByteArrayInputStream(documentData));
        StampingProperties properties = new StampingProperties().useAppendMode();
        
        // Create PDF signer - this will handle the PdfDocument internally
        PdfSigner signer = new PdfSigner(reader, outputStream, properties);
        
        // Get signature appearance
        PdfSignatureAppearance appearance = signer.getSignatureAppearance();
        
        // Configure signature appearance
        appearance.setReason(signatureRequest.getReason());
        appearance.setLocation(signatureRequest.getLocation());
        appearance.setSignatureCreator("Firmador App");
        
        // Set signature rectangle
        Rectangle signatureRect = new Rectangle(
            signatureRequest.getSignatureX(), 
            signatureRequest.getSignatureY(), 
            signatureRequest.getSignatureWidth(), 
            signatureRequest.getSignatureHeight()
        );
        appearance.setPageRect(signatureRect).setPageNumber(signatureRequest.getSignaturePage());
        
        // Create signature text
        String signatureText = createSignatureText(signatureRequest, certificate);
        appearance.setLayer2Text(signatureText);
        
        // Create external signature container
        IExternalSignature pks = new PrivateKeySignature(privateKey, DigestAlgorithms.SHA256, 
                                                        BouncyCastleProvider.PROVIDER_NAME);
        IExternalDigest digest = new BouncyCastleDigest();
        
        // Sign the document
        signer.signDetached(digest, pks, chain, null, null, null, 0, 
                           PdfSigner.CryptoStandard.CMS);
        
        return outputStream.toByteArray();
    }

    private String createSignatureText(SignatureRequest signatureRequest, X509Certificate certificate) {
        StringBuilder sb = new StringBuilder();
        sb.append("Firmado digitalmente por:\n");
        sb.append(signatureRequest.getSignerName()).append("\n");
        sb.append("ID: ").append(signatureRequest.getSignerId()).append("\n");
        sb.append("Fecha: ").append(new Date()).append("\n");
        sb.append("Ubicación: ").append(signatureRequest.getLocation()).append("\n");
        sb.append("Razón: ").append(signatureRequest.getReason()).append("\n");
        sb.append("Certificado: ").append(certificate.getSubjectDN().getName());
        return sb.toString();
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