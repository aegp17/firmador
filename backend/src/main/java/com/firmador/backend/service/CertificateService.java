package com.firmador.backend.service;

import com.firmador.backend.dto.CertificateInfo;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x500.style.BCStyle;
import org.bouncycastle.cert.jcajce.JcaX509CertificateHolder;
import org.springframework.stereotype.Service;

import javax.security.auth.x500.X500Principal;
import java.security.cert.X509Certificate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Service
public class CertificateService {

    public CertificateInfo extractCertificateInfo(X509Certificate certificate) {
        try {
            // Extract subject information
            String subject = certificate.getSubjectDN().getName();
            String commonName = extractCommonName(new X500Principal(certificate.getSubjectDN().getName()));
            
            // Extract issuer information
            String issuer = certificate.getIssuerDN().getName();
            
            // Extract validity dates
            LocalDateTime validFrom = certificate.getNotBefore().toInstant()
                .atZone(ZoneId.systemDefault()).toLocalDateTime();
            LocalDateTime validTo = certificate.getNotAfter().toInstant()
                .atZone(ZoneId.systemDefault()).toLocalDateTime();
            
            // Extract serial number
            String serialNumber = certificate.getSerialNumber().toString(16).toUpperCase();
            
            // Extract key usage information
            List<String> keyUsages = extractKeyUsages(certificate);
            
            // Extract algorithm information
            String algorithm = certificate.getSigAlgName();
            String version = "v" + certificate.getVersion();
            
            // Determine if certificate is trusted (basic validation)
            boolean isTrusted = isCertificateTrusted(certificate);
            
            return new CertificateInfo(
                subject,
                issuer,
                validFrom,
                validTo,
                serialNumber,
                commonName,
                keyUsages,
                isTrusted,
                algorithm,
                version
            );
            
        } catch (Exception e) {
            throw new RuntimeException("Error al extraer información del certificado: " + e.getMessage(), e);
        }
    }

    private String extractCommonName(X500Principal principal) {
        try {
            String dn = principal.getName();
            
            // Parse the distinguished name to extract CN
            String[] parts = dn.split(",");
            for (String part : parts) {
                String trimmed = part.trim();
                if (trimmed.startsWith("CN=")) {
                    return trimmed.substring(3);
                }
            }
            
            // If no CN found, try to use the entire subject
            return dn;
            
        } catch (Exception e) {
            return "N/A";
        }
    }

    private List<String> extractKeyUsages(X509Certificate certificate) {
        List<String> keyUsages = new ArrayList<>();
        
        try {
            // Get key usage extension
            boolean[] keyUsageArray = certificate.getKeyUsage();
            if (keyUsageArray != null) {
                String[] keyUsageNames = {
                    "Digital Signature",
                    "Non-Repudiation",
                    "Key Encipherment",
                    "Data Encipherment",
                    "Key Agreement",
                    "Key Certificate Signing",
                    "CRL Signing",
                    "Encipher Only",
                    "Decipher Only"
                };
                
                for (int i = 0; i < keyUsageArray.length && i < keyUsageNames.length; i++) {
                    if (keyUsageArray[i]) {
                        keyUsages.add(keyUsageNames[i]);
                    }
                }
            }
            
            // Get extended key usage
            try {
                List<String> extendedKeyUsage = certificate.getExtendedKeyUsage();
                if (extendedKeyUsage != null) {
                    for (String usage : extendedKeyUsage) {
                        keyUsages.add(mapExtendedKeyUsage(usage));
                    }
                }
            } catch (Exception e) {
                // Extended key usage not available
            }
            
        } catch (Exception e) {
            // Key usage extension not available
        }
        
        // If no key usages found, add default ones
        if (keyUsages.isEmpty()) {
            keyUsages.add("Digital Signature");
            keyUsages.add("Non-Repudiation");
        }
        
        return keyUsages;
    }

    private String mapExtendedKeyUsage(String oid) {
        switch (oid) {
            case "1.3.6.1.5.5.7.3.1":
                return "Server Authentication";
            case "1.3.6.1.5.5.7.3.2":
                return "Client Authentication";
            case "1.3.6.1.5.5.7.3.3":
                return "Code Signing";
            case "1.3.6.1.5.5.7.3.4":
                return "Email Protection";
            case "1.3.6.1.5.5.7.3.8":
                return "Time Stamping";
            case "1.3.6.1.5.5.7.3.9":
                return "OCSP Signing";
            default:
                return "Unknown Usage (" + oid + ")";
        }
    }

    private boolean isCertificateTrusted(X509Certificate certificate) {
        try {
            // Basic validation - check if certificate is currently valid
            certificate.checkValidity();
            
            // Additional checks could be added here:
            // - Check against a trusted CA list
            // - Check revocation status
            // - Check certificate chain
            
            return true;
            
        } catch (Exception e) {
            return false;
        }
    }

    public String formatIssuerName(String issuerDN) {
        try {
            // Parse and format the issuer DN for better readability
            String[] parts = issuerDN.split(",");
            StringBuilder formatted = new StringBuilder();
            
            for (String part : parts) {
                String trimmed = part.trim();
                if (trimmed.startsWith("CN=")) {
                    formatted.append("CN=").append(trimmed.substring(3));
                } else if (trimmed.startsWith("O=")) {
                    formatted.append(", O=").append(trimmed.substring(2));
                } else if (trimmed.startsWith("C=")) {
                    formatted.append(", C=").append(trimmed.substring(2));
                } else if (trimmed.startsWith("L=")) {
                    formatted.append(", L=").append(trimmed.substring(2));
                } else if (trimmed.startsWith("ST=")) {
                    formatted.append(", ST=").append(trimmed.substring(3));
                } else if (trimmed.startsWith("OU=")) {
                    formatted.append(", OU=").append(trimmed.substring(3));
                }
            }
            
            return formatted.toString();
            
        } catch (Exception e) {
            return issuerDN;
        }
    }
} 