package com.firmador.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

public class CertificateInfo {
    
    private String subject;
    private String issuer;
    private LocalDateTime validFrom;
    private LocalDateTime validTo;
    private String serialNumber;
    private String commonName;
    private List<String> keyUsages;
    private boolean isTrusted;
    private String algorithm;
    private String version;
    
    // Constructors
    public CertificateInfo() {}
    
    public CertificateInfo(String subject, String issuer, LocalDateTime validFrom, 
                          LocalDateTime validTo, String serialNumber, String commonName,
                          List<String> keyUsages, boolean isTrusted, String algorithm, String version) {
        this.subject = subject;
        this.issuer = issuer;
        this.validFrom = validFrom;
        this.validTo = validTo;
        this.serialNumber = serialNumber;
        this.commonName = commonName;
        this.keyUsages = keyUsages;
        this.isTrusted = isTrusted;
        this.algorithm = algorithm;
        this.version = version;
    }
    
    // Getters and Setters
    public String getSubject() {
        return subject;
    }
    
    public void setSubject(String subject) {
        this.subject = subject;
    }
    
    public String getIssuer() {
        return issuer;
    }
    
    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }
    
    public LocalDateTime getValidFrom() {
        return validFrom;
    }
    
    public void setValidFrom(LocalDateTime validFrom) {
        this.validFrom = validFrom;
    }
    
    public LocalDateTime getValidTo() {
        return validTo;
    }
    
    public void setValidTo(LocalDateTime validTo) {
        this.validTo = validTo;
    }
    
    public String getSerialNumber() {
        return serialNumber;
    }
    
    public void setSerialNumber(String serialNumber) {
        this.serialNumber = serialNumber;
    }
    
    public String getCommonName() {
        return commonName;
    }
    
    public void setCommonName(String commonName) {
        this.commonName = commonName;
    }
    
    public List<String> getKeyUsages() {
        return keyUsages;
    }
    
    public void setKeyUsages(List<String> keyUsages) {
        this.keyUsages = keyUsages;
    }
    
    public boolean isTrusted() {
        return isTrusted;
    }
    
    public void setTrusted(boolean trusted) {
        isTrusted = trusted;
    }
    
    public String getAlgorithm() {
        return algorithm;
    }
    
    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }
    
    public String getVersion() {
        return version;
    }
    
    public void setVersion(String version) {
        this.version = version;
    }
} 