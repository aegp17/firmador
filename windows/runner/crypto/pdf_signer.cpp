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
    // Calculate hash of data to sign
    std::vector<BYTE> hash = CalculateHash(dataToSign);
    if (hash.empty()) {
        return {};
    }
    
    HCRYPTPROV cryptProv = certManager.GetPrivateKeyHandle();
    if (!cryptProv) {
        std::cerr << "No private key available" << std::endl;
        return {};
    }
    
    // Create hash object
    HCRYPTHASH hHash;
    if (!CryptCreateHash(cryptProv, CALG_SHA_256, 0, 0, &hHash)) {
        std::cerr << "Failed to create hash object: " << GetLastError() << std::endl;
        return {};
    }
    
    // Set hash value
    if (!CryptSetHashParam(hHash, HP_HASHVAL, hash.data(), 0)) {
        std::cerr << "Failed to set hash value: " << GetLastError() << std::endl;
        CryptDestroyHash(hHash);
        return {};
    }
    
    // Get signature size
    DWORD signatureSize = 0;
    if (!CryptSignHash(hHash, AT_SIGNATURE, nullptr, 0, nullptr, &signatureSize)) {
        std::cerr << "Failed to get signature size: " << GetLastError() << std::endl;
        CryptDestroyHash(hHash);
        return {};
    }
    
    // Create signature
    std::vector<BYTE> signature(signatureSize);
    if (!CryptSignHash(hHash, AT_SIGNATURE, nullptr, 0, signature.data(), &signatureSize)) {
        std::cerr << "Failed to create signature: " << GetLastError() << std::endl;
        CryptDestroyHash(hHash);
        return {};
    }
    
    CryptDestroyHash(hHash);
    signature.resize(signatureSize);
    return signature;
}

std::vector<BYTE> PdfSigner::AddSignatureToPdf(const std::vector<BYTE>& pdfData,
                                              const std::vector<BYTE>& signature,
                                              const SignaturePosition& position,
                                              const std::vector<BYTE>& timestamp) {
    // Simplified PDF signature addition - in a real implementation, 
    // this would properly modify the PDF structure
    
    std::vector<BYTE> signedPdf = pdfData;
    
    // Find the end of the PDF (before %%EOF)
    std::string pdfText(pdfData.begin(), pdfData.end());
    size_t eofPos = pdfText.rfind("%%EOF");
    if (eofPos == std::string::npos) {
        return {}; // Invalid PDF
    }
    
    // Create signature object (simplified)
    std::stringstream sigObj;
    sigObj << "\n\n% Digital Signature Object\n";
    sigObj << "1000 0 obj\n";
    sigObj << "<<\n";
    sigObj << "/Type /Sig\n";
    sigObj << "/Filter /Adobe.PPKLite\n";
    sigObj << "/SubFilter /adbe.pkcs7.detached\n";
    sigObj << "/ByteRange [0 " << eofPos << " " << (eofPos + 1000) << " 1000]\n";
    sigObj << "/Contents <";
    
    // Add signature bytes as hex
    for (BYTE b : signature) {
        sigObj << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
    }
    
    if (!timestamp.empty()) {
        sigObj << ">\n/TimeStamp <";
        for (BYTE b : timestamp) {
            sigObj << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
        }
    }
    
    sigObj << ">\n";
    sigObj << "/M (D:" << GetCurrentTimestamp() << ")\n";
    sigObj << "/Location (Windows)\n";
    sigObj << "/Reason (Digital Signature)\n";
    sigObj << ">>\nendobj\n\n";
    
    // Insert signature object before %%EOF
    std::string sigObjStr = sigObj.str();
    signedPdf.insert(signedPdf.begin() + eofPos, sigObjStr.begin(), sigObjStr.end());
    
    return signedPdf;
}

std::string PdfSigner::GetCurrentTimestamp() {
    std::time_t t = std::time(nullptr);
    std::tm* tm = std::localtime(&t);
    
    std::stringstream ss;
    ss << std::put_time(tm, "%Y%m%d%H%M%S");
    return ss.str();
}

std::vector<BYTE> PdfSigner::CalculateHash(const std::vector<BYTE>& data, const std::string& algorithm) {
    BCRYPT_ALG_HANDLE hAlg = nullptr;
    BCRYPT_HASH_HANDLE hHash = nullptr;
    std::vector<BYTE> hash;
    
    // Open algorithm provider
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_SHA256_ALGORITHM, nullptr, 0);
    if (!BCRYPT_SUCCESS(status)) {
        return {};
    }
    
    // Get hash object size
    DWORD hashObjectSize = 0;
    DWORD dataSize = 0;
    status = BCryptGetProperty(hAlg, BCRYPT_OBJECT_LENGTH, 
                              reinterpret_cast<PUCHAR>(&hashObjectSize), 
                              sizeof(hashObjectSize), &dataSize, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return {};
    }
    
    // Get hash size
    DWORD hashSize = 0;
    status = BCryptGetProperty(hAlg, BCRYPT_HASH_LENGTH, 
                              reinterpret_cast<PUCHAR>(&hashSize), 
                              sizeof(hashSize), &dataSize, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return {};
    }
    
    // Allocate hash object
    std::vector<BYTE> hashObject(hashObjectSize);
    
    // Create hash
    status = BCryptCreateHash(hAlg, &hHash, hashObject.data(), hashObjectSize, nullptr, 0, 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return {};
    }
    
    // Hash data
    status = BCryptHashData(hHash, const_cast<PUCHAR>(data.data()), 
                           static_cast<ULONG>(data.size()), 0);
    if (!BCRYPT_SUCCESS(status)) {
        BCryptDestroyHash(hHash);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return {};
    }
    
    // Finalize hash
    hash.resize(hashSize);
    status = BCryptFinishHash(hHash, hash.data(), hashSize, 0);
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