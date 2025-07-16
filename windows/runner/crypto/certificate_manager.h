#ifndef CERTIFICATE_MANAGER_H
#define CERTIFICATE_MANAGER_H

#include <windows.h>
#include <wincrypt.h>
#include <string>
#include <vector>
#include <map>

struct CertificateInfo {
    std::string subject;
    std::string issuer;
    std::string serialNumber;
    std::string validFrom;
    std::string validTo;
    std::vector<std::string> keyUsage;
    std::string thumbprint;
    bool isValid;
};

class CertificateManager {
public:
    CertificateManager();
    ~CertificateManager();

    // Load certificate from Windows Certificate Store
    bool LoadCertificateFromStore(const std::string& thumbprint);
    
    // Load certificate from PKCS#12 file with password
    bool LoadCertificateFromFile(const std::string& filePath, const std::string& password);
    
    // Get certificate information
    CertificateInfo GetCertificateInfo() const;
    
    // Get available certificates from Windows Certificate Store
    std::vector<CertificateInfo> GetAvailableCertificates() const;
    
    // Get private key handle for signing
    HCRYPTPROV GetPrivateKeyHandle() const;
    
    // Get certificate context for signing
    PCCERT_CONTEXT GetCertificateContext() const;
    
    // Validate certificate
    bool ValidateCertificate() const;

private:
    PCCERT_CONTEXT m_certContext;
    HCRYPTPROV m_cryptProv;
    DWORD m_keySpec;
    bool m_freeProvOrNCryptKey;
    
    // Helper methods
    std::string ExtractNameFromCert(PCCERT_CONTEXT certContext, DWORD nameType) const;
    std::string FormatSerialNumber(const CRYPT_INTEGER_BLOB& serialNumber) const;
    std::string FormatDateTime(const FILETIME& fileTime) const;
    std::vector<std::string> ExtractKeyUsage(PCCERT_CONTEXT certContext) const;
    std::string CalculateThumbprint(PCCERT_CONTEXT certContext) const;
    
    void Cleanup();
};

#endif // CERTIFICATE_MANAGER_H 