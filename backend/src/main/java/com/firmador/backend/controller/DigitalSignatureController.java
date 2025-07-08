package com.firmador.backend.controller;

import com.firmador.backend.dto.CertificateInfo;
import com.firmador.backend.dto.SignatureRequest;
import com.firmador.backend.dto.SignatureResponse;
import com.firmador.backend.service.DigitalSignatureService;
import com.firmador.backend.service.DocumentStorageService;
import jakarta.validation.Valid;
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

    private final DigitalSignatureService digitalSignatureService;
    private final DocumentStorageService documentStorageService;

    public DigitalSignatureController(DigitalSignatureService digitalSignatureService,
                                    DocumentStorageService documentStorageService) {
        this.digitalSignatureService = digitalSignatureService;
        this.documentStorageService = documentStorageService;
    }

    @PostMapping(value = "/sign", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<SignatureResponse> signDocument(
            @RequestParam("document") MultipartFile document,
            @RequestParam("certificate") MultipartFile certificate,
            @RequestParam("signerName") String signerName,
            @RequestParam("signerEmail") String signerEmail,
            @RequestParam("signerId") String signerId,
            @RequestParam("location") String location,
            @RequestParam("reason") String reason,
            @RequestParam("certificatePassword") String certificatePassword,
            @RequestParam(value = "signatureX", defaultValue = "100") Integer signatureX,
            @RequestParam(value = "signatureY", defaultValue = "100") Integer signatureY,
            @RequestParam(value = "signatureWidth", defaultValue = "200") Integer signatureWidth,
            @RequestParam(value = "signatureHeight", defaultValue = "80") Integer signatureHeight,
            @RequestParam(value = "signaturePage", defaultValue = "1") Integer signaturePage) {

        try {
            // Validate file types
            if (!isPdfFile(document)) {
                return ResponseEntity.badRequest()
                    .body(new SignatureResponse(false, "El archivo debe ser un PDF"));
            }

            if (!isCertificateFile(certificate)) {
                return ResponseEntity.badRequest()
                    .body(new SignatureResponse(false, "El certificado debe ser un archivo .p12 o .pfx"));
            }

            // Create signature request
            SignatureRequest signatureRequest = new SignatureRequest();
            signatureRequest.setSignerName(signerName);
            signatureRequest.setSignerEmail(signerEmail);
            signatureRequest.setSignerId(signerId);
            signatureRequest.setLocation(location);
            signatureRequest.setReason(reason);
            signatureRequest.setCertificateData(certificate.getBytes());
            signatureRequest.setCertificatePassword(certificatePassword);
            signatureRequest.setSignatureX(signatureX);
            signatureRequest.setSignatureY(signatureY);
            signatureRequest.setSignatureWidth(signatureWidth);
            signatureRequest.setSignatureHeight(signatureHeight);
            signatureRequest.setSignaturePage(signaturePage);

            // Sign the document
            SignatureResponse response = digitalSignatureService.signDocument(
                document.getBytes(), signatureRequest);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new SignatureResponse(false, "Error interno del servidor: " + e.getMessage()));
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