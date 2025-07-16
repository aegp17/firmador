#ifndef PDF_SIGNER_H
#define PDF_SIGNER_H

#include <windows.h>
#include <string>
#include <vector>
#include "certificate_manager.h"
#include "tsa_client.h"

struct SignaturePosition {
    double x;
    double y;
    int pageNumber;
    double width;
    double height;
};

struct SigningResult {
    bool success;
    std::string errorMessage;
    std::string signedPdfPath;
    std::string timestampServer;
    std::string signingTime;
    size_t originalSize;
    size_t signedSize;
};

class PdfSigner {
public:
    PdfSigner();
    ~PdfSigner();

    // Sign PDF with certificate
    SigningResult SignPdf(const std::string& inputPdfPath,
                         const std::string& outputPdfPath,
                         CertificateManager& certManager,
                         const SignaturePosition& position,
                         bool includeTimestamp = true);
    
    // Sign PDF from memory
    SigningResult SignPdfFromMemory(const std::vector<BYTE>& pdfData,
                                   CertificateManager& certManager,
                                   const SignaturePosition& position,
                                   bool includeTimestamp = true);
    
    // Get PDF page count
    int GetPageCount(const std::string& pdfPath);
    
    // Get PDF page dimensions
    bool GetPageDimensions(const std::string& pdfPath, int pageNumber, 
                          double& width, double& height);
    
    // Validate PDF
    bool ValidatePdf(const std::string& pdfPath);

private:
    TSAClient m_tsaClient;
    
    // Helper methods
    std::vector<BYTE> ReadPdfFile(const std::string& filePath);
    bool WritePdfFile(const std::string& filePath, const std::vector<BYTE>& data);
    std::vector<BYTE> CreateSignature(const std::vector<BYTE>& dataToSign,
                                    CertificateManager& certManager);
    std::vector<BYTE> AddSignatureToPdf(const std::vector<BYTE>& pdfData,
                                      const std::vector<BYTE>& signature,
                                      const SignaturePosition& position,
                                      const std::vector<BYTE>& timestamp = {});
    std::string GetCurrentTimestamp();
    std::vector<BYTE> CalculateHash(const std::vector<BYTE>& data, const std::string& algorithm = "SHA256");
};

#endif // PDF_SIGNER_H 