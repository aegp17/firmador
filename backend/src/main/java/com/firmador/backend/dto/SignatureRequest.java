package com.firmador.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class SignatureRequest {
    
    @NotBlank(message = "Signer name is required")
    private String signerName;
    
    @NotBlank(message = "Signer email is required")
    private String signerEmail;
    
    @NotBlank(message = "Signer ID is required")
    private String signerId;
    
    @NotBlank(message = "Location is required")
    private String location;
    
    @NotBlank(message = "Reason is required")
    private String reason;
    
    @NotNull(message = "Certificate data is required")
    private byte[] certificateData;
    
    @NotBlank(message = "Certificate password is required")
    private String certificatePassword;
    
    // Signature appearance settings
    private Integer signatureX = 100;
    private Integer signatureY = 100;
    private Integer signatureWidth = 200;
    private Integer signatureHeight = 80;
    private Integer signaturePage = 1;
    
    // Constructors
    public SignatureRequest() {}
    
    public SignatureRequest(String signerName, String signerEmail, String signerId, 
                           String location, String reason, byte[] certificateData, 
                           String certificatePassword) {
        this.signerName = signerName;
        this.signerEmail = signerEmail;
        this.signerId = signerId;
        this.location = location;
        this.reason = reason;
        this.certificateData = certificateData;
        this.certificatePassword = certificatePassword;
    }
    
    // Getters and Setters
    public String getSignerName() {
        return signerName;
    }
    
    public void setSignerName(String signerName) {
        this.signerName = signerName;
    }
    
    public String getSignerEmail() {
        return signerEmail;
    }
    
    public void setSignerEmail(String signerEmail) {
        this.signerEmail = signerEmail;
    }
    
    public String getSignerId() {
        return signerId;
    }
    
    public void setSignerId(String signerId) {
        this.signerId = signerId;
    }
    
    public String getLocation() {
        return location;
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public byte[] getCertificateData() {
        return certificateData;
    }
    
    public void setCertificateData(byte[] certificateData) {
        this.certificateData = certificateData;
    }
    
    public String getCertificatePassword() {
        return certificatePassword;
    }
    
    public void setCertificatePassword(String certificatePassword) {
        this.certificatePassword = certificatePassword;
    }
    
    public Integer getSignatureX() {
        return signatureX;
    }
    
    public void setSignatureX(Integer signatureX) {
        this.signatureX = signatureX;
    }
    
    public Integer getSignatureY() {
        return signatureY;
    }
    
    public void setSignatureY(Integer signatureY) {
        this.signatureY = signatureY;
    }
    
    public Integer getSignatureWidth() {
        return signatureWidth;
    }
    
    public void setSignatureWidth(Integer signatureWidth) {
        this.signatureWidth = signatureWidth;
    }
    
    public Integer getSignatureHeight() {
        return signatureHeight;
    }
    
    public void setSignatureHeight(Integer signatureHeight) {
        this.signatureHeight = signatureHeight;
    }
    
    public Integer getSignaturePage() {
        return signaturePage;
    }
    
    public void setSignaturePage(Integer signaturePage) {
        this.signaturePage = signaturePage;
    }
} 