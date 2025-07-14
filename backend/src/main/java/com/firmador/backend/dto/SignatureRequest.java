package com.firmador.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class SignatureRequest {
    
    @NotBlank(message = "Signer name is required")
    private String signerName;
    
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
    
    // Signature appearance settings (in PDF points)
    private Double signatureX = 100.0;
    private Double signatureY = 100.0;
    private Double signatureWidth = 150.0;
    private Double signatureHeight = 50.0;
    private Integer signaturePage = 1;
    
    // Timestamp settings
    private Boolean enableTimestamp = false;
    private String timestampServerUrl = "http://timestamp.digicert.com";
    
    // Constructors
    public SignatureRequest() {}
    
    public SignatureRequest(String signerName, String signerId, 
                           String location, String reason, byte[] certificateData, 
                           String certificatePassword) {
        this.signerName = signerName;
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
    
    public Double getSignatureX() {
        return signatureX;
    }
    
    public void setSignatureX(Double signatureX) {
        this.signatureX = signatureX;
    }
    
    public Double getSignatureY() {
        return signatureY;
    }
    
    public void setSignatureY(Double signatureY) {
        this.signatureY = signatureY;
    }
    
    public Double getSignatureWidth() {
        return signatureWidth;
    }
    
    public void setSignatureWidth(Double signatureWidth) {
        this.signatureWidth = signatureWidth;
    }
    
    public Double getSignatureHeight() {
        return signatureHeight;
    }
    
    public void setSignatureHeight(Double signatureHeight) {
        this.signatureHeight = signatureHeight;
    }
    
    public Integer getSignaturePage() {
        return signaturePage;
    }
    
    public void setSignaturePage(Integer signaturePage) {
        this.signaturePage = signaturePage;
    }
    
    public Boolean getEnableTimestamp() {
        return enableTimestamp;
    }
    
    public void setEnableTimestamp(Boolean enableTimestamp) {
        this.enableTimestamp = enableTimestamp;
    }
    
    public String getTimestampServerUrl() {
        return timestampServerUrl;
    }
    
    public void setTimestampServerUrl(String timestampServerUrl) {
        this.timestampServerUrl = timestampServerUrl;
    }
} 