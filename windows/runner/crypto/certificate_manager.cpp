#include "certificate_manager.h"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <fstream> // Added for file operations
#include <windows.h> // Required for Windows API functions
#include <wincrypt.h> // Required for cryptographic functions
#include <ncrypt.h> // Required for NCrypt functions

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
    DWORD keySpec;
    BOOL freeProvOrNCryptKey = FALSE;
    if (!CryptAcquireCertificatePrivateKey(
        m_certContext,
        CRYPT_ACQUIRE_CACHE_FLAG | CRYPT_ACQUIRE_COMPARE_KEY_FLAG,
        nullptr,
        &m_cryptProv,
        &keySpec,
        &freeProvOrNCryptKey)) {
        std::cerr << "Failed to acquire private key: " << GetLastError() << std::endl;
        CertFreeCertificateContext(m_certContext);
        m_certContext = nullptr;
        return false;
    }
    
    m_keySpec = keySpec;
    m_freeProvOrNCryptKey = freeProvOrNCryptKey;
    
    return ValidateCertificate();
}

bool CertificateManager::LoadCertificateFromFile(const std::string& filePath, const std::string& password) {
    Cleanup();
    
    // Convert strings to wide strings
    std::wstring wFilePath(filePath.begin(), filePath.end());
    std::wstring wPassword(password.begin(), password.end());
    
    // Read PKCS#12 file
    std::ifstream file(filePath, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "Failed to open certificate file: " << filePath << std::endl;
        return false;
    }
    
    file.seekg(0, std::ios::end);
    size_t fileSize = file.tellg();
    file.seekg(0, std::ios::beg);
    
    std::vector<BYTE> fileData(fileSize);
    file.read(reinterpret_cast<char*>(fileData.data()), fileSize);
    file.close();
    
    // Create data blob
    CRYPT_DATA_BLOB pfxBlob = {0};
    pfxBlob.cbData = static_cast<DWORD>(fileSize);
    pfxBlob.pbData = fileData.data();
    
    // Import PKCS#12
    HCERTSTORE hTempStore = PFXImportCertStore(&pfxBlob, wPassword.c_str(), CRYPT_EXPORTABLE);
    if (!hTempStore) {
        std::cerr << "Failed to import PKCS#12 file: " << GetLastError() << std::endl;
        return false;
    }
    
    // Find the certificate with private key
    m_certContext = nullptr;
    PCCERT_CONTEXT pCertContext = nullptr;
    
    while ((pCertContext = CertEnumCertificatesInStore(hTempStore, pCertContext)) != nullptr) {
        DWORD keySpec;
        BOOL freeProvOrNCryptKey = FALSE;
        HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hKey;
        
        if (CryptAcquireCertificatePrivateKey(
            pCertContext,
            CRYPT_ACQUIRE_CACHE_FLAG | CRYPT_ACQUIRE_COMPARE_KEY_FLAG,
            nullptr,
            &hKey,
            &keySpec,
            &freeProvOrNCryptKey)) {
            
            // Found certificate with private key
            m_certContext = CertDuplicateCertificateContext(pCertContext);
            m_cryptProv = hKey;
            m_keySpec = keySpec;
            m_freeProvOrNCryptKey = freeProvOrNCryptKey;
            break;
        }
    }
    
    CertCloseStore(hTempStore, 0);
    
    if (!m_certContext) {
        std::cerr << "No certificate with private key found in PKCS#12 file" << std::endl;
        return false;
    }
    
    return ValidateCertificate();
}

CertificateInfo CertificateManager::GetCertificateInfo() const {
    CertificateInfo info = {};
    
    if (!m_certContext) {
        return info;
    }
    
    info.subject = ExtractNameFromCert(m_certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
    info.issuer = ExtractNameFromCert(m_certContext, CERT_NAME_ISSUER_FLAG);
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
    
    // Open the Personal certificate store
    HCERTSTORE hStore = CertOpenSystemStore(0, L"MY");
    if (!hStore) {
        std::cerr << "Failed to open certificate store: " << GetLastError() << std::endl;
        return certificates;
    }
    
    PCCERT_CONTEXT pCertContext = nullptr;
    while ((pCertContext = CertEnumCertificatesInStore(hStore, pCertContext)) != nullptr) {
        // Check if certificate has private key
        DWORD keySpec;
        BOOL freeProvOrNCryptKey = FALSE;
        HCRYPTPROV_OR_NCRYPT_KEY_HANDLE hKey;
        
        if (CryptAcquireCertificatePrivateKey(
            pCertContext,
            CRYPT_ACQUIRE_CACHE_FLAG | CRYPT_ACQUIRE_COMPARE_KEY_FLAG,
            nullptr,
            &hKey,
            &keySpec,
            &freeProvOrNCryptKey)) {
            
            CertificateInfo info = {};
            info.subject = ExtractNameFromCert(pCertContext, CERT_NAME_SIMPLE_DISPLAY_TYPE);
            info.issuer = ExtractNameFromCert(pCertContext, CERT_NAME_ISSUER_FLAG);
            info.serialNumber = FormatSerialNumber(pCertContext->pCertInfo->SerialNumber);
            info.validFrom = FormatDateTime(pCertContext->pCertInfo->NotBefore);
            info.validTo = FormatDateTime(pCertContext->pCertInfo->NotAfter);
            info.keyUsage = ExtractKeyUsage(pCertContext);
            info.thumbprint = CalculateThumbprint(pCertContext);
            info.isValid = true; // Simplified validation
            
            certificates.push_back(info);
            
            if (freeProvOrNCryptKey) {
                if (keySpec == CERT_NCRYPT_KEY_SPEC) {
                    NCryptFreeObject(hKey);
                } else {
                    CryptReleaseContext(hKey, 0);
                }
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
    SYSTEMTIME currentTime;
    GetSystemTime(&currentTime);
    
    FILETIME currentFileTime;
    SystemTimeToFileTime(&currentTime, &currentFileTime);
    
    // Compare with certificate validity period
    if (CompareFileTime(&currentFileTime, &m_certContext->pCertInfo->NotBefore) < 0 ||
        CompareFileTime(&currentFileTime, &m_certContext->pCertInfo->NotAfter) > 0) {
        return false; // Certificate expired or not yet valid
    }
    
    return true;
}

std::string CertificateManager::ExtractNameFromCert(PCCERT_CONTEXT certContext, DWORD nameType) const {
    DWORD nameSize = CertGetNameString(certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE, nameType, nullptr, nullptr, 0);
    if (nameSize <= 1) {
        return "";
    }
    
    std::vector<wchar_t> nameBuffer(nameSize);
    CertGetNameString(certContext, CERT_NAME_SIMPLE_DISPLAY_TYPE, nameType, nullptr, nameBuffer.data(), nameSize);
    
    // Convert to UTF-8
    int utf8Size = WideCharToMultiByte(CP_UTF8, 0, nameBuffer.data(), -1, nullptr, 0, nullptr, nullptr);
    if (utf8Size <= 1) {
        return "";
    }
    
    std::vector<char> utf8Buffer(utf8Size);
    WideCharToMultiByte(CP_UTF8, 0, nameBuffer.data(), -1, utf8Buffer.data(), utf8Size, nullptr, nullptr);
    
    return std::string(utf8Buffer.data());
}

std::string CertificateManager::FormatSerialNumber(const CRYPT_INTEGER_BLOB& serialNumber) const {
    std::stringstream ss;
    for (DWORD i = 0; i < serialNumber.cbData; ++i) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(serialNumber.pbData[serialNumber.cbData - 1 - i]);
    }
    return ss.str();
}

std::string CertificateManager::FormatDateTime(const FILETIME& fileTime) const {
    SYSTEMTIME systemTime;
    FileTimeToSystemTime(&fileTime, &systemTime);
    
    std::stringstream ss;
    ss << std::setfill('0') << std::setw(4) << systemTime.wYear << "-"
       << std::setw(2) << systemTime.wMonth << "-"
       << std::setw(2) << systemTime.wDay << " "
       << std::setw(2) << systemTime.wHour << ":"
       << std::setw(2) << systemTime.wMinute << ":"
       << std::setw(2) << systemTime.wSecond;
    
    return ss.str();
}

std::vector<std::string> CertificateManager::ExtractKeyUsage(PCCERT_CONTEXT certContext) const {
    std::vector<std::string> keyUsage;
    
    PCERT_EXTENSION pExtension = CertFindExtension(szOID_KEY_USAGE, 
                                                  certContext->pCertInfo->cExtension,
                                                  certContext->pCertInfo->rgExtension);
    if (pExtension) {
        CRYPT_BIT_BLOB keyUsageBlob;
        DWORD size = sizeof(keyUsageBlob);
        
        if (CryptDecodeObject(X509_ASN_ENCODING, X509_KEY_USAGE, 
                             pExtension->Value.pbData, pExtension->Value.cbData,
                             0, &keyUsageBlob, &size)) {
            
            if (keyUsageBlob.cbData > 0) {
                BYTE usage = keyUsageBlob.pbData[0];
                if (usage & CERT_DIGITAL_SIGNATURE_KEY_USAGE) keyUsage.push_back("Digital Signature");
                if (usage & CERT_NON_REPUDIATION_KEY_USAGE) keyUsage.push_back("Non Repudiation");
                if (usage & CERT_KEY_ENCIPHERMENT_KEY_USAGE) keyUsage.push_back("Key Encipherment");
                if (usage & CERT_DATA_ENCIPHERMENT_KEY_USAGE) keyUsage.push_back("Data Encipherment");
                if (usage & CERT_KEY_AGREEMENT_KEY_USAGE) keyUsage.push_back("Key Agreement");
                if (usage & CERT_KEY_CERT_SIGN_KEY_USAGE) keyUsage.push_back("Certificate Signing");
                if (usage & CERT_CRL_SIGN_KEY_USAGE) keyUsage.push_back("CRL Signing");
            }
        }
    }
    
    return keyUsage;
}

std::string CertificateManager::CalculateThumbprint(PCCERT_CONTEXT certContext) const {
    BYTE thumbprint[20]; // SHA1 hash
    DWORD thumbprintSize = sizeof(thumbprint);
    
    if (!CertGetCertificateContextProperty(certContext, CERT_SHA1_HASH_PROP_ID, thumbprint, &thumbprintSize)) {
        return "";
    }
    
    std::stringstream ss;
    for (DWORD i = 0; i < thumbprintSize; ++i) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(thumbprint[i]);
    }
    
    return ss.str();
}

void CertificateManager::Cleanup() {
    if (m_certContext) {
        CertFreeCertificateContext(m_certContext);
        m_certContext = nullptr;
    }
    
    if (m_cryptProv && m_freeProvOrNCryptKey) {
        if (m_keySpec == CERT_NCRYPT_KEY_SPEC) {
            NCryptFreeObject(m_cryptProv);
        } else {
            CryptReleaseContext(m_cryptProv, 0);
        }
        m_cryptProv = 0;
    }
    
    m_keySpec = 0;
    m_freeProvOrNCryptKey = false;
} 