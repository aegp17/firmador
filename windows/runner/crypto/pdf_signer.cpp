#include "pdf_signer.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <ctime>
#include <bcrypt.h>

PdfSigner::PdfSigner() {
}

PdfSigner::~PdfSigner() {
}

SigningResult PdfSigner::SignPdf(const std::string& inputPdfPath,
                                const std::string& outputPdfPath,
                                CertificateManager& certManager,
                                const SignaturePosition& position,
                                bool includeTimestamp) {
    SigningResult result = {};
    
    try {
        // Read PDF file
        std::vector<BYTE> pdfData = ReadPdfFile(inputPdfPath);
        if (pdfData.empty()) {
            result.success = false;
            result.errorMessage = "Failed to read PDF file";
            return result;
        }
        
        result.originalSize = pdfData.size();
        
        // Validate PDF
        if (!ValidatePdf(inputPdfPath)) {
            result.success = false;
            result.errorMessage = "Invalid PDF file";
            return result;
        }
        
        // Create signature data
        std::vector<BYTE> dataToSign = pdfData; // Simplified - in real implementation, hash specific parts
        std::vector<BYTE> signature = CreateSignature(dataToSign, certManager);
        if (signature.empty()) {
            result.success = false;
            result.errorMessage = "Failed to create digital signature";
            return result;
        }
        
        // Get timestamp if requested
        std::vector<BYTE> timestamp;
        if (includeTimestamp) {
            std::vector<BYTE> signatureHash = CalculateHash(signature);
            TSAResponse tsaResponse = m_tsaClient.GetTimestamp(signatureHash);
            if (tsaResponse.success) {
                timestamp = tsaResponse.timestampData;
                result.timestampServer = tsaResponse.serverUsed;
            } else {
                std::cout << "Warning: Failed to get timestamp: " << tsaResponse.errorMessage << std::endl;
                // Continue without timestamp
            }
        }
        
        // Add signature to PDF
        std::vector<BYTE> signedPdf = AddSignatureToPdf(pdfData, signature, position, timestamp);
        if (signedPdf.empty()) {
            result.success = false;
            result.errorMessage = "Failed to add signature to PDF";
            return result;
        }
        
        // Write signed PDF
        if (!WritePdfFile(outputPdfPath, signedPdf)) {
            result.success = false;
            result.errorMessage = "Failed to write signed PDF file";
            return result;
        }
        
        result.success = true;
        result.signedPdfPath = outputPdfPath;
        result.signingTime = GetCurrentTimestamp();
        result.signedSize = signedPdf.size();
        
    } catch (const std::exception& e) {
        result.success = false;
        result.errorMessage = std::string("Exception: ") + e.what();
    }
    
    return result;
}

SigningResult PdfSigner::SignPdfFromMemory(const std::vector<BYTE>& pdfData,
                                          CertificateManager& certManager,
                                          const SignaturePosition& position,
                                          bool includeTimestamp) {
    SigningResult result = {};
    
    try {
        result.originalSize = pdfData.size();
        
        // Create signature data
        std::vector<BYTE> dataToSign = pdfData; // Simplified
        std::vector<BYTE> signature = CreateSignature(dataToSign, certManager);
        if (signature.empty()) {
            result.success = false;
            result.errorMessage = "Failed to create digital signature";
            return result;
        }
        
        // Get timestamp if requested
        std::vector<BYTE> timestamp;
        if (includeTimestamp) {
            std::vector<BYTE> signatureHash = CalculateHash(signature);
            TSAResponse tsaResponse = m_tsaClient.GetTimestamp(signatureHash);
            if (tsaResponse.success) {
                timestamp = tsaResponse.timestampData;
                result.timestampServer = tsaResponse.serverUsed;
            }
        }
        
        // Add signature to PDF
        std::vector<BYTE> signedPdf = AddSignatureToPdf(pdfData, signature, position, timestamp);
        if (signedPdf.empty()) {
            result.success = false;
            result.errorMessage = "Failed to add signature to PDF";
            return result;
        }
        
        result.success = true;
        result.signingTime = GetCurrentTimestamp();
        result.signedSize = signedPdf.size();
        
    } catch (const std::exception& e) {
        result.success = false;
        result.errorMessage = std::string("Exception: ") + e.what();
    }
    
    return result;
}

int PdfSigner::GetPageCount(const std::string& pdfPath) {
    // Simplified PDF page counting - read PDF and look for page objects
    std::vector<BYTE> pdfData = ReadPdfFile(pdfPath);
    if (pdfData.empty()) {
        return 0;
    }
    
    std::string pdfText(pdfData.begin(), pdfData.end());
    
    // Look for "/Type /Page" entries
    size_t pos = 0;
    int pageCount = 0;
    while ((pos = pdfText.find("/Type /Page", pos)) != std::string::npos) {
        // Make sure it's not "/Type /Pages" (which is the parent)
        if (pos + 11 < pdfText.length() && pdfText[pos + 11] != 's') {
            pageCount++;
        }
        pos += 11;
    }
    
    return pageCount > 0 ? pageCount : 1; // Default to 1 page if detection fails
}

bool PdfSigner::GetPageDimensions(const std::string& pdfPath, int pageNumber, 
                                 double& width, double& height) {
    // Simplified - return standard A4 dimensions
    // In a real implementation, this would parse PDF page objects
    width = 612.0;  // A4 width in points
    height = 792.0; // A4 height in points
    return true;
}

bool PdfSigner::ValidatePdf(const std::string& pdfPath) {
    std::vector<BYTE> pdfData = ReadPdfFile(pdfPath);
    if (pdfData.size() < 8) {
        return false;
    }
    
    // Check PDF header
    std::string header(pdfData.begin(), pdfData.begin() + 8);
    return header.find("%PDF-") == 0;
}

std::vector<BYTE> PdfSigner::ReadPdfFile(const std::string& filePath) {
    std::ifstream file(filePath, std::ios::binary | std::ios::ate);
    if (!file.is_open()) {
        return {};
    }
    
    std::streamsize size = file.tellg();
    file.seekg(0, std::ios::beg);
    
    std::vector<BYTE> buffer(size);
    if (!file.read(reinterpret_cast<char*>(buffer.data()), size)) {
        return {};
    }
    
    return buffer;
}

bool PdfSigner::WritePdfFile(const std::string& filePath, const std::vector<BYTE>& data) {
    std::ofstream file(filePath, std::ios::binary);
    if (!file.is_open()) {
        return false;
    }
    
    file.write(reinterpret_cast<const char*>(data.data()), data.size());
    return file.good();
}

std::vector<BYTE> PdfSigner::CreateSignature(const std::vector<BYTE>& dataToSign,
                                            CertificateManager& certManager) {
    HCRYPTPROV hProv = certManager.GetPrivateKeyHandle();
    if (!hProv) {
        std::cerr << "No private key available" << std::endl;
        return {};
    }
    
    // Calculate hash of data
    std::vector<BYTE> hash = CalculateHash(dataToSign);
    if (hash.empty()) {
        std::cerr << "Failed to calculate hash" << std::endl;
        return {};
    }
    
    // Sign the hash
    DWORD signatureLength = 0;
    if (!CryptSignHash(reinterpret_cast<HCRYPTHASH>(hash.data()), AT_SIGNATURE, 
                      nullptr, 0, nullptr, &signatureLength)) {
        std::cerr << "Failed to get signature length: " << GetLastError() << std::endl;
        return {};
    }
    
    std::vector<BYTE> signature(signatureLength);
    if (!CryptSignHash(reinterpret_cast<HCRYPTHASH>(hash.data()), AT_SIGNATURE, 
                      nullptr, 0, signature.data(), &signatureLength)) {
        std::cerr << "Failed to create signature: " << GetLastError() << std::endl;
        return {};
    }
    
    signature.resize(signatureLength);
    return signature;
}

std::vector<BYTE> PdfSigner::AddSignatureToPdf(const std::vector<BYTE>& pdfData,
                                             const std::vector<BYTE>& signature,
                                             const SignaturePosition& position,
                                             const std::vector<BYTE>& timestamp) {
    // Simplified PDF signature embedding
    // In a real implementation, this would properly parse and modify the PDF structure
    
    std::vector<BYTE> signedPdf = pdfData;
    
    // Find insertion point (before %%EOF)
    std::string pdfString(signedPdf.begin(), signedPdf.end());
    size_t eofPos = pdfString.rfind("%%EOF");
    if (eofPos == std::string::npos) {
        std::cerr << "Invalid PDF: no %%EOF found" << std::endl;
        return {};
    }
    
    // Create signature dictionary (simplified)
    std::stringstream sigDict;
    sigDict << "\n";
    sigDict << "1 0 obj\n";
    sigDict << "<<\n";
    sigDict << "/Type /Sig\n";
    sigDict << "/Filter /Adobe.PPKLite\n";
    sigDict << "/SubFilter /adbe.pkcs7.detached\n";
    sigDict << "/Contents <";
    
    // Add signature as hex
    for (BYTE b : signature) {
        sigDict << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
    }
    
    // Add timestamp if available
    if (!timestamp.empty()) {
        sigDict << ">";
        sigDict << "/M (D:" << GetCurrentTimestamp() << ")";
        sigDict << "/Location (Windows Certificate Store)";
        sigDict << "/Reason (Digital Signature)";
        sigDict << "/ContactInfo (Firmador Windows)";
        sigDict << "/Contents <";
        for (BYTE b : timestamp) {
            sigDict << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
        }
    }
    
    sigDict << ">\n";
    sigDict << ">>\n";
    sigDict << "endobj\n";
    
    // Insert signature dictionary before %%EOF
    std::string sigDictStr = sigDict.str();
    signedPdf.insert(signedPdf.begin() + eofPos, sigDictStr.begin(), sigDictStr.end());
    
    return signedPdf;
}

std::string PdfSigner::GetCurrentTimestamp() {
    SYSTEMTIME st;
    GetSystemTime(&st);
    
    std::stringstream ss;
    ss << std::setfill('0')
       << std::setw(4) << st.wYear
       << std::setw(2) << st.wMonth
       << std::setw(2) << st.wDay
       << std::setw(2) << st.wHour
       << std::setw(2) << st.wMinute
       << std::setw(2) << st.wSecond
       << "Z";
    
    return ss.str();
}

std::vector<BYTE> PdfSigner::CalculateHash(const std::vector<BYTE>& data) {
    BCRYPT_ALG_HANDLE hAlg = nullptr;
    BCRYPT_HASH_HANDLE hHash = nullptr;
    std::vector<BYTE> hash;
    
    // Open SHA256 algorithm provider
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_SHA256_ALGORITHM, nullptr, 0);
    if (!BCRYPT_SUCCESS(status)) {
        std::cerr << "Failed to open algorithm provider: " << status << std::endl;
        return hash;
    }
    
    // Get hash object length
    DWORD hashObjectLength = 0;
    DWORD resultLength = 0;
    status = BCryptGetProperty(hAlg, BCRYPT_OBJECT_LENGTH, 
                              reinterpret_cast<PUCHAR>(&hashObjectLength), 
                              sizeof(hashObjectLength), &resultLength, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return hash;
    }
    
    // Get hash length
    DWORD hashLength = 0;
    status = BCryptGetProperty(hAlg, BCRYPT_HASH_LENGTH, 
                              reinterpret_cast<PUCHAR>(&hashLength), 
                              sizeof(hashLength), &resultLength, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return hash;
    }
    
    // Create hash object
    std::vector<BYTE> hashObject(hashObjectLength);
    status = BCryptCreateHash(hAlg, &hHash, hashObject.data(), hashObjectLength, 
                             nullptr, 0, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return hash;
    }
    
    // Hash the data
    status = BCryptHashData(hHash, const_cast<PUCHAR>(data.data()), 
                           static_cast<ULONG>(data.size()), 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptDestroyHash(hHash);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return hash;
    }
    
    // Get the hash result
    hash.resize(hashLength);
    status = BCryptFinishHash(hHash, hash.data(), hashLength, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptDestroyHash(hHash);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return {};
    }
    
    // Cleanup
    BCryptDestroyHash(hHash);
    BCryptCloseAlgorithmProvider(hAlg, 0);
    
    return hash;
} 