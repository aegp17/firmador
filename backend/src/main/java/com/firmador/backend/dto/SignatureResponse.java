package com.firmador.backend.dto;

import java.time.LocalDateTime;

public class SignatureResponse {
    
    private boolean success;
    private String message;
    private String documentId;
    private String filename;
    private LocalDateTime signedAt;
    private String signerName;
    private String location;
    private String reason;
    private long fileSize;
    private String downloadUrl;
    
    // Constructors
    public SignatureResponse() {}
    
    public SignatureResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }
    
    public SignatureResponse(boolean success, String message, String documentId, 
                           String filename, LocalDateTime signedAt, String signerName, 
                           String location, String reason, long fileSize, String downloadUrl) {
        this.success = success;
        this.message = message;
        this.documentId = documentId;
        this.filename = filename;
        this.signedAt = signedAt;
        this.signerName = signerName;
        this.location = location;
        this.reason = reason;
        this.fileSize = fileSize;
        this.downloadUrl = downloadUrl;
    }
    
    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public String getDocumentId() {
        return documentId;
    }
    
    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }
    
    public String getFilename() {
        return filename;
    }
    
    public void setFilename(String filename) {
        this.filename = filename;
    }
    
    public LocalDateTime getSignedAt() {
        return signedAt;
    }
    
    public void setSignedAt(LocalDateTime signedAt) {
        this.signedAt = signedAt;
    }
    
    public String getSignerName() {
        return signerName;
    }
    
    public void setSignerName(String signerName) {
        this.signerName = signerName;
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
    
    public long getFileSize() {
        return fileSize;
    }
    
    public void setFileSize(long fileSize) {
        this.fileSize = fileSize;
    }
    
    public String getDownloadUrl() {
        return downloadUrl;
    }
    
    public void setDownloadUrl(String downloadUrl) {
        this.downloadUrl = downloadUrl;
    }
} 