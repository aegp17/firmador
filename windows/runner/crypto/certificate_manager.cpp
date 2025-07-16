#include "certificate_manager.h"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <algorithm>

CertificateManager::CertificateManager() 
    : m_certContext(nullptr), m_cryptProv(0), m_keySpec(0), m_freeProvOrNCryptKey(false) {
}

CertificateManager::~CertificateManager() {
    Cleanup();
}

bool CertificateManager::LoadCertificateFromStore(const std::string& thumbprint) {
    Cleanup();
    
    // Open the Personal certificate store
    HCERTSTORE hStore = CertOpenSystemStore(0, L"MY");
    if (!hStore) {
        std::cerr << "Failed to open certificate store: " << GetLastError() << std::endl;
        return false;
    }
    
    // Convert thumbprint to bytes
    std::vector<BYTE> thumbprintBytes;
    for (size_t i = 0; i < thumbprint.length(); i += 2) {
        std::string byteStr = thumbprint.substr(i, 2);
        BYTE byte = static_cast<BYTE>(std::stoul(byteStr, nullptr, 16));
        thumbprintBytes.push_back(byte);
    }
    
    CRYPT_HASH_BLOB hashBlob = {0};
    hashBlob.cbData = static_cast<DWORD>(thumbprintBytes.size());
    hashBlob.pbData = thumbprintBytes.data();
    
    // Find certificate by thumbprint
    m_certContext = CertFindCertificateInStore(
        hStore,
        X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
        0,
        CERT_FIND_SHA1_HASH,
        &hashBlob,
        nullptr
    );
    
    CertCloseStore(hStore, 0);
    
    if (!m_certContext) {
        std::cerr << "Certificate not found in store" << std::endl;
        return false;
    }
    
    // Get private key handle
    BOOL callerFreeProvOrNCryptKey = FALSE;
    if (!CryptAcquireCertificatePrivateKey(
        m_certContext,
        CRYPT_ACQUIRE_CACHE_FLAG,
        nullptr,
        &m_cryptProv,
        &m_keySpec,
        &callerFreeProvOrNCryptKey)) {
        std::cerr << "Failed to acquire private key: " << GetLastError() << std::endl;
        return false;
    }
    
    m_freeProvOrNCryptKey = callerFreeProvOrNCryptKey != FALSE;
    return true;
}

bool CertificateManager::LoadCertificateFromFile(const std::string& filePath, const std::string& password) {
    Cleanup();
    
    // Convert file path to wide string
    std::wstring wFilePath(filePath.begin(), filePath.end());
    
    // Convert password to wide string
    std::wstring wPassword(password.begin(), password.end());
    
    // Open PKCS#12 file
    HCERTSTORE hStore = PFXImportCertStore(
        nullptr, // Use file path instead
        const_cast<LPCWSTR>(wPassword.c_str()),
        CRYPT_EXPORTABLE | CRYPT_USER_KEYSET
    );
    
    if (!hStore) {
        std::cerr << "Failed to import PKCS#12 file: " << GetLastError() << std::endl;
        return false;
    }
    
    // Find the first certificate with a private key
    m_certContext = CertEnumCertificatesInStore(hStore, nullptr);
    if (!m_certContext) {
        std::cerr << "No certificates found in PKCS#12 file" << std::endl;
        CertCloseStore(hStore, 0);
        return false;
    }
    
    // Duplicate the certificate context so it persists after store closure
    m_certContext = CertDuplicateCertificateContext(m_certContext);
    CertCloseStore(hStore, 0);
    
    // Get private key handle
    BOOL callerFreeProvOrNCryptKey = FALSE;
    if (!CryptAcquireCertificatePrivateKey(
        m_certContext,
        CRYPT_ACQUIRE_CACHE_FLAG,
        nullptr,
        &m_cryptProv,
        &m_keySpec,
        &callerFreeProvOrNCryptKey)) {
        std::cerr << "Failed to acquire private key from PKCS#12: " << GetLastError() << std::endl;
        return false;
    }
    
    m_freeProvOrNCryptKey = callerFreeProvOrNCryptKey != FALSE;
    return true;
}

CertificateInfo CertificateManager::GetCertificateInfo() const {
    CertificateInfo info = {};
    
    if (!m_certContext) {
        info.isValid = false;
        return info;
    }
    
    info.subject = ExtractNameFromCert(m_certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
    info.issuer = ExtractNameFromCert(m_certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
    info.serialNumber = FormatSerialNumber(m_certContext->pCertInfo->SerialNumber);
    info.validFrom = FormatDateTime(m_certContext->pCertInfo->NotBefore);
    info.validTo = FormatDateTime(m_certContext->pCertInfo->NotAfter);
    info.keyUsage = ExtractKeyUsage(m_certContext);
    info.thumbprint = CalculateThumbprint(m_certContext);
    info.isValid = ValidateCertificate();
    
    return info;
}

std::vector<CertificateInfo> CertificateManager::GetAvailableCertificates() const {
    std::vector<CertificateInfo> certificates;
    
    HCERTSTORE hStore = CertOpenSystemStore(0, L"MY");
    if (!hStore) {
        return certificates;
    }
    
    PCCERT_CONTEXT certContext = nullptr;
    while ((certContext = CertEnumCertificatesInStore(hStore, certContext)) != nullptr) {
        // Check if certificate has a private key
        HCRYPTPROV cryptProv;
        DWORD keySpec;
        BOOL freeProvOrNCryptKey;
        
        if (CryptAcquireCertificatePrivateKey(
            certContext,
            CRYPT_ACQUIRE_CACHE_FLAG | CRYPT_ACQUIRE_SILENT_FLAG,
            nullptr,
            &cryptProv,
            &keySpec,
            &freeProvOrNCryptKey)) {
            
            CertificateInfo info = {};
            info.subject = ExtractNameFromCert(certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
            info.issuer = ExtractNameFromCert(certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
            info.serialNumber = FormatSerialNumber(certContext->pCertInfo->SerialNumber);
            info.validFrom = FormatDateTime(certContext->pCertInfo->NotBefore);
            info.validTo = FormatDateTime(certContext->pCertInfo->NotAfter);
            info.keyUsage = ExtractKeyUsage(certContext);
            info.thumbprint = CalculateThumbprint(certContext);
            info.isValid = true; // Simplified validation
            
            certificates.push_back(info);
            
            if (freeProvOrNCryptKey) {
                CryptReleaseContext(cryptProv, 0);
            }
        }
    }
    
    CertCloseStore(hStore, 0);
    return certificates;
}

HCRYPTPROV CertificateManager::GetPrivateKeyHandle() const {
    return m_cryptProv;
}

PCCERT_CONTEXT CertificateManager::GetCertificateContext() const {
    return m_certContext;
}

bool CertificateManager::ValidateCertificate() const {
    if (!m_certContext) {
        return false;
    }
    
    // Check if certificate is within validity period
    FILETIME currentTime;
    GetSystemTimeAsFileTime(&currentTime);
    
    if (CompareFileTime(&currentTime, &m_certContext->pCertInfo->NotBefore) < 0 ||
        CompareFileTime(&currentTime, &m_certContext->pCertInfo->NotAfter) > 0) {
        return false;
    }
    
    // Additional validation could be added here (revocation checking, etc.)
    return true;
}

std::string CertificateManager::ExtractNameFromCert(PCCERT_CONTEXT certContext, DWORD nameType) const {
    DWORD size = CertGetNameString(certContext, nameType, 0, nullptr, nullptr, 0);
    if (size == 0) {
        return "";
    }
    
    std::vector<wchar_t> name(size);
    CertGetNameString(certContext, nameType, 0, nullptr, name.data(), size);
    
    // Convert wide string to regular string
    std::wstring wName(name.data());
    return std::string(wName.begin(), wName.end());
}

std::string CertificateManager::FormatSerialNumber(const CRYPT_INTEGER_BLOB& serialNumber) const {
    std::stringstream ss;
    for (DWORD i = serialNumber.cbData; i > 0; --i) {
        ss << std::hex << std::setw(2) << std::setfill('0') 
           << static_cast<int>(serialNumber.pbData[i - 1]);
    }
    return ss.str();
}

std::string CertificateManager::FormatDateTime(const FILETIME& fileTime) const {
    SYSTEMTIME systemTime;
    if (!FileTimeToSystemTime(&fileTime, &systemTime)) {
        return "";
    }
    
    std::stringstream ss;
    ss << systemTime.wYear << "-"
       << std::setw(2) << std::setfill('0') << systemTime.wMonth << "-"
       << std::setw(2) << std::setfill('0') << systemTime.wDay;
    
    return ss.str();
}

std::vector<std::string> CertificateManager::ExtractKeyUsage(PCCERT_CONTEXT certContext) const {
    std::vector<std::string> keyUsages;
    
    PCERT_EXTENSION keyUsageExt = CertFindExtension(
        szOID_KEY_USAGE,
        certContext->pCertInfo->cExtension,
        certContext->pCertInfo->rgExtension
    );
    
    if (keyUsageExt) {
        CRYPT_BIT_BLOB keyUsageBlob;
        DWORD size = sizeof(keyUsageBlob);
        
        if (CryptDecodeObjectEx(
            X509_ASN_ENCODING,
            X509_KEY_USAGE,
            keyUsageExt->Value.pbData,
            keyUsageExt->Value.cbData,
            0,
            nullptr,
            &keyUsageBlob,
            &size)) {
            
            if (keyUsageBlob.cbData > 0) {
                BYTE keyUsageByte = keyUsageBlob.pbData[0];
                
                if (keyUsageByte & CERT_DIGITAL_SIGNATURE_KEY_USAGE) {
                    keyUsages.push_back("Digital Signature");
                }
                if (keyUsageByte & CERT_NON_REPUDIATION_KEY_USAGE) {
                    keyUsages.push_back("Non Repudiation");
                }
                if (keyUsageByte & CERT_KEY_ENCIPHERMENT_KEY_USAGE) {
                    keyUsages.push_back("Key Encipherment");
                }
                if (keyUsageByte & CERT_DATA_ENCIPHERMENT_KEY_USAGE) {
                    keyUsages.push_back("Data Encipherment");
                }
            }
        }
    }
    
    return keyUsages;
}

std::string CertificateManager::CalculateThumbprint(PCCERT_CONTEXT certContext) const {
    BYTE thumbprint[20]; // SHA-1 hash is 20 bytes
    DWORD size = sizeof(thumbprint);
    
    if (!CertGetCertificateContextProperty(
        certContext,
        CERT_SHA1_HASH_PROP_ID,
        thumbprint,
        &size)) {
        return "";
    }
    
    std::stringstream ss;
    for (DWORD i = 0; i < size; ++i) {
        ss << std::hex << std::setw(2) << std::setfill('0') 
           << static_cast<int>(thumbprint[i]);
    }
    
    return ss.str();
}

void CertificateManager::Cleanup() {
    if (m_certContext) {
        CertFreeCertificateContext(m_certContext);
        m_certContext = nullptr;
    }
    
    if (m_cryptProv && m_freeProvOrNCryptKey) {
        CryptReleaseContext(m_cryptProv, 0);
        m_cryptProv = 0;
    }
    
    m_keySpec = 0;
    m_freeProvOrNCryptKey = false;
} 