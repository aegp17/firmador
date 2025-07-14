package com.firmador.backend.controller;

import com.firmador.backend.dto.CertificateInfo;
import com.firmador.backend.dto.SignatureRequest;
import com.firmador.backend.dto.SignatureResponse;
import com.firmador.backend.service.DigitalSignatureService;
import com.firmador.backend.service.DocumentStorageService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/signature")
@CrossOrigin(origins = "*")
public class DigitalSignatureController {

    private static final Logger logger = LoggerFactory.getLogger(DigitalSignatureController.class);

    @Autowired
    private DigitalSignatureService digitalSignatureService;
    private final DocumentStorageService documentStorageService;

    public DigitalSignatureController(DigitalSignatureService digitalSignatureService,
                                    DocumentStorageService documentStorageService) {
        this.digitalSignatureService = digitalSignatureService;
        this.documentStorageService = documentStorageService;
    }

    @PostMapping("/sign")
    public ResponseEntity<?> signDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam("signerName") String signerName,
            @RequestParam("signerId") String signerId,
            @RequestParam("location") String location,
            @RequestParam("reason") String reason,
            @RequestParam("certificate") MultipartFile certificate,
            @RequestParam("certificatePassword") String certificatePassword,
            @RequestParam(value = "signatureX", defaultValue = "100.0") Double signatureX,
            @RequestParam(value = "signatureY", defaultValue = "100.0") Double signatureY,
            @RequestParam(value = "signatureWidth", defaultValue = "150.0") Double signatureWidth,
            @RequestParam(value = "signatureHeight", defaultValue = "50.0") Double signatureHeight,
            @RequestParam(value = "signaturePage", defaultValue = "1") Integer signaturePage,
            @RequestParam(value = "enableTimestamp", defaultValue = "false") Boolean enableTimestamp,
            @RequestParam(value = "timestampServerUrl", defaultValue = "https://freetsa.org/tsr") String timestampServerUrl) {
        
        try {
            // Validation
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File is required"));
            }
            
            if (certificate.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Certificate file is required"));
            }
            
            // Create signature request
            SignatureRequest request = new SignatureRequest();
            request.setSignerName(signerName);
            request.setSignerId(signerId);
            request.setLocation(location);
            request.setReason(reason);
            request.setCertificateData(certificate.getBytes());
            request.setCertificatePassword(certificatePassword);
            request.setSignatureX(signatureX);
            request.setSignatureY(signatureY);
            request.setSignatureWidth(signatureWidth);
            request.setSignatureHeight(signatureHeight);
            request.setSignaturePage(signaturePage);
            request.setEnableTimestamp(enableTimestamp);
            request.setTimestampServerUrl(timestampServerUrl);
            
            // Sign the document
            byte[] signedPdf = digitalSignatureService.signPdf(file.getBytes(), request);
            
            // Generate response filename
            String originalFilename = file.getOriginalFilename();
            String signedFilename = originalFilename != null ? 
                originalFilename.replaceFirst("(\\.[^.]*)?$", "_signed$1") :
                "signed_document.pdf";
            
            // Return signed PDF
            return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + signedFilename + "\"")
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                .body(signedPdf);
            
        } catch (Exception e) {
            logger.error("Error during document signing", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to sign document: " + e.getMessage()));
        }
    }

    @PostMapping(value = "/validate-certificate", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> validateCertificate(
            @RequestParam("certificate") MultipartFile certificate,
            @RequestParam("password") String password) {

        Map<String, Object> response = new HashMap<>();

        try {
            if (!isCertificateFile(certificate)) {
                response.put("valid", false);
                response.put("message", "El archivo debe ser un certificado .p12 o .pfx");
                return ResponseEntity.badRequest().body(response);
            }

            boolean isValid = digitalSignatureService.validateCertificate(
                certificate.getBytes(), password);

            response.put("valid", isValid);
            response.put("message", isValid ? "Certificado válido" : "Certificado inválido o contraseña incorrecta");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("valid", false);
            response.put("message", "Error al validar el certificado: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping(value = "/certificate-info", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> getCertificateInfo(
            @RequestParam("certificate") MultipartFile certificate,
            @RequestParam("password") String password) {

        Map<String, Object> response = new HashMap<>();

        try {
            if (!isCertificateFile(certificate)) {
                response.put("success", false);
                response.put("message", "El archivo debe ser un certificado .p12 o .pfx");
                return ResponseEntity.badRequest().body(response);
            }

            CertificateInfo certInfo = digitalSignatureService.extractCertificateInfo(
                certificate.getBytes(), password);

            response.put("success", true);
            response.put("certificateInfo", certInfo);
            response.put("message", "Información del certificado extraída exitosamente");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error al extraer información del certificado: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Firmador Backend is running");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/download/{documentId}")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable String documentId) {
        try {
            DocumentStorageService.StoredDocument document = documentStorageService.getDocument(documentId);
            
            if (document == null) {
                return ResponseEntity.notFound().build();
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", document.getFilename());
            headers.setContentLength(document.getData().length);

            return ResponseEntity.ok()
                .headers(headers)
                .body(document.getData());

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    private boolean isPdfFile(MultipartFile file) {
        String contentType = file.getContentType();
        String filename = file.getOriginalFilename();
        
        return (contentType != null && contentType.equals("application/pdf")) ||
               (filename != null && filename.toLowerCase().endsWith(".pdf"));
    }

    private boolean isCertificateFile(MultipartFile file) {
        String filename = file.getOriginalFilename();
        
        if (filename == null) {
            return false;
        }
        
        String lowercaseFilename = filename.toLowerCase();
        return lowercaseFilename.endsWith(".p12") || 
               lowercaseFilename.endsWith(".pfx") ||
               lowercaseFilename.endsWith(".pkcs12");
    }
} 