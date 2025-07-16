#include "native_crypto_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include "crypto/certificate_manager.h"
#include "crypto/pdf_signer.h"
#include "crypto/tsa_client.h"

#include <memory>
#include <iostream>

namespace {
    class NativeCryptoPluginImpl : public NativeCryptoPlugin {
    public:
        NativeCryptoPluginImpl(flutter::PluginRegistrarWindows* registrar) {
            channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "com.example.firmador/native_crypto",
                &flutter::StandardMethodCodec::GetInstance());

            channel_->SetMethodCallHandler([this](const auto& call, auto result) {
                HandleMethodCall(call, std::move(result));
            });
        }

        virtual ~NativeCryptoPluginImpl() {}

    private:
        std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
    };
}

void NativeCryptoPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto plugin = std::make_unique<NativeCryptoPluginImpl>(registrar);
    registrar->AddPlugin(std::move(plugin));
}

NativeCryptoPlugin::NativeCryptoPlugin() {}

NativeCryptoPlugin::~NativeCryptoPlugin() {}

void NativeCryptoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const std::string& method = method_call.method_name();
    
    try {
        if (method == "getCertificateInfo") {
            GetCertificateInfo(method_call.arguments(), std::move(result));
        } else if (method == "getAvailableCertificates") {
            GetAvailableCertificates(std::move(result));
        } else if (method == "signPdf") {
            SignPdf(method_call.arguments(), std::move(result));
        } else if (method == "testTSAConnectivity") {
            TestTSAConnectivity(std::move(result));
        } else if (method == "validatePdf") {
            ValidatePdf(method_call.arguments(), std::move(result));
        } else {
            result->NotImplemented();
        }
    } catch (const std::exception& e) {
        result->Error("NATIVE_ERROR", e.what());
    }
}

void NativeCryptoPlugin::GetCertificateInfo(
    const flutter::EncodableValue& arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const auto* args = std::get_if<flutter::EncodableMap>(&arguments);
    if (!args) {
        result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
        return;
    }
    
    auto certPath_it = args->find(flutter::EncodableValue("certificatePath"));
    auto password_it = args->find(flutter::EncodableValue("password"));
    auto thumbprint_it = args->find(flutter::EncodableValue("thumbprint"));
    
    CertificateManager certManager;
    bool loaded = false;
    
    if (thumbprint_it != args->end()) {
        // Load from Windows Certificate Store
        const auto* thumbprint = std::get_if<std::string>(&thumbprint_it->second);
        if (thumbprint) {
            loaded = certManager.LoadCertificateFromStore(*thumbprint);
        }
    } else if (certPath_it != args->end() && password_it != args->end()) {
        // Load from PKCS#12 file
        const auto* certPath = std::get_if<std::string>(&certPath_it->second);
        const auto* password = std::get_if<std::string>(&password_it->second);
        if (certPath && password) {
            loaded = certManager.LoadCertificateFromFile(*certPath, *password);
        }
    }
    
    if (!loaded) {
        result->Error("CERTIFICATE_LOAD_FAILED", "Failed to load certificate");
        return;
    }
    
    CertificateInfo info = certManager.GetCertificateInfo();
    
    flutter::EncodableMap response;
    response[flutter::EncodableValue("subject")] = flutter::EncodableValue(info.subject);
    response[flutter::EncodableValue("issuer")] = flutter::EncodableValue(info.issuer);
    response[flutter::EncodableValue("serialNumber")] = flutter::EncodableValue(info.serialNumber);
    response[flutter::EncodableValue("validFrom")] = flutter::EncodableValue(info.validFrom);
    response[flutter::EncodableValue("validTo")] = flutter::EncodableValue(info.validTo);
    response[flutter::EncodableValue("thumbprint")] = flutter::EncodableValue(info.thumbprint);
    response[flutter::EncodableValue("isValid")] = flutter::EncodableValue(info.isValid);
    
    flutter::EncodableList keyUsageList;
    for (const auto& usage : info.keyUsage) {
        keyUsageList.push_back(flutter::EncodableValue(usage));
    }
    response[flutter::EncodableValue("keyUsage")] = flutter::EncodableValue(keyUsageList);
    
    result->Success(flutter::EncodableValue(response));
}

void NativeCryptoPlugin::GetAvailableCertificates(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    CertificateManager certManager;
    std::vector<CertificateInfo> certificates = certManager.GetAvailableCertificates();
    
    flutter::EncodableList certificateList;
    for (const auto& cert : certificates) {
        flutter::EncodableMap certMap;
        certMap[flutter::EncodableValue("subject")] = flutter::EncodableValue(cert.subject);
        certMap[flutter::EncodableValue("issuer")] = flutter::EncodableValue(cert.issuer);
        certMap[flutter::EncodableValue("serialNumber")] = flutter::EncodableValue(cert.serialNumber);
        certMap[flutter::EncodableValue("validFrom")] = flutter::EncodableValue(cert.validFrom);
        certMap[flutter::EncodableValue("validTo")] = flutter::EncodableValue(cert.validTo);
        certMap[flutter::EncodableValue("thumbprint")] = flutter::EncodableValue(cert.thumbprint);
        certMap[flutter::EncodableValue("isValid")] = flutter::EncodableValue(cert.isValid);
        
        flutter::EncodableList keyUsageList;
        for (const auto& usage : cert.keyUsage) {
            keyUsageList.push_back(flutter::EncodableValue(usage));
        }
        certMap[flutter::EncodableValue("keyUsage")] = flutter::EncodableValue(keyUsageList);
        
        certificateList.push_back(flutter::EncodableValue(certMap));
    }
    
    result->Success(flutter::EncodableValue(certificateList));
}

void NativeCryptoPlugin::SignPdf(
    const flutter::EncodableValue& arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const auto* args = std::get_if<flutter::EncodableMap>(&arguments);
    if (!args) {
        result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
        return;
    }
    
    // Extract arguments
    auto pdfPath_it = args->find(flutter::EncodableValue("pdfPath"));
    auto outputPath_it = args->find(flutter::EncodableValue("outputPath"));
    auto certPath_it = args->find(flutter::EncodableValue("certificatePath"));
    auto password_it = args->find(flutter::EncodableValue("password"));
    auto thumbprint_it = args->find(flutter::EncodableValue("thumbprint"));
    auto position_it = args->find(flutter::EncodableValue("position"));
    auto includeTimestamp_it = args->find(flutter::EncodableValue("includeTimestamp"));
    
    if (pdfPath_it == args->end() || outputPath_it == args->end() || position_it == args->end()) {
        result->Error("MISSING_ARGUMENTS", "pdfPath, outputPath, and position are required");
        return;
    }
    
    const auto* pdfPath = std::get_if<std::string>(&pdfPath_it->second);
    const auto* outputPath = std::get_if<std::string>(&outputPath_it->second);
    const auto* positionMap = std::get_if<flutter::EncodableMap>(&position_it->second);
    
    if (!pdfPath || !outputPath || !positionMap) {
        result->Error("INVALID_ARGUMENTS", "Invalid argument types");
        return;
    }
    
    // Parse position
    SignaturePosition position = {};
    auto x_it = positionMap->find(flutter::EncodableValue("x"));
    auto y_it = positionMap->find(flutter::EncodableValue("y"));
    auto page_it = positionMap->find(flutter::EncodableValue("pageNumber"));
    auto width_it = positionMap->find(flutter::EncodableValue("width"));
    auto height_it = positionMap->find(flutter::EncodableValue("height"));
    
    if (x_it != positionMap->end()) {
        if (const auto* x = std::get_if<double>(&x_it->second)) {
            position.x = *x;
        }
    }
    if (y_it != positionMap->end()) {
        if (const auto* y = std::get_if<double>(&y_it->second)) {
            position.y = *y;
        }
    }
    if (page_it != positionMap->end()) {
        if (const auto* page = std::get_if<int>(&page_it->second)) {
            position.pageNumber = *page;
        }
    }
    if (width_it != positionMap->end()) {
        if (const auto* width = std::get_if<double>(&width_it->second)) {
            position.width = *width;
        } else {
            position.width = 200.0; // Default width
        }
    }
    if (height_it != positionMap->end()) {
        if (const auto* height = std::get_if<double>(&height_it->second)) {
            position.height = *height;
        } else {
            position.height = 50.0; // Default height
        }
    }
    
    // Parse includeTimestamp
    bool includeTimestamp = true;
    if (includeTimestamp_it != args->end()) {
        if (const auto* timestamp = std::get_if<bool>(&includeTimestamp_it->second)) {
            includeTimestamp = *timestamp;
        }
    }
    
    // Load certificate
    CertificateManager certManager;
    bool loaded = false;
    
    if (thumbprint_it != args->end()) {
        const auto* thumbprint = std::get_if<std::string>(&thumbprint_it->second);
        if (thumbprint) {
            loaded = certManager.LoadCertificateFromStore(*thumbprint);
        }
    } else if (certPath_it != args->end() && password_it != args->end()) {
        const auto* certPath = std::get_if<std::string>(&certPath_it->second);
        const auto* password = std::get_if<std::string>(&password_it->second);
        if (certPath && password) {
            loaded = certManager.LoadCertificateFromFile(*certPath, *password);
        }
    }
    
    if (!loaded) {
        result->Error("CERTIFICATE_LOAD_FAILED", "Failed to load certificate");
        return;
    }
    
    // Sign PDF
    PdfSigner signer;
    SigningResult signingResult = signer.SignPdf(*pdfPath, *outputPath, certManager, position, includeTimestamp);
    
    if (!signingResult.success) {
        result->Error("SIGNING_FAILED", signingResult.errorMessage);
        return;
    }
    
    // Return success response
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(true);
    response[flutter::EncodableValue("signedPdfPath")] = flutter::EncodableValue(signingResult.signedPdfPath);
    response[flutter::EncodableValue("timestampServer")] = flutter::EncodableValue(signingResult.timestampServer);
    response[flutter::EncodableValue("signingTime")] = flutter::EncodableValue(signingResult.signingTime);
    response[flutter::EncodableValue("originalSize")] = flutter::EncodableValue(static_cast<int64_t>(signingResult.originalSize));
    response[flutter::EncodableValue("signedSize")] = flutter::EncodableValue(static_cast<int64_t>(signingResult.signedSize));
    
    result->Success(flutter::EncodableValue(response));
}

void NativeCryptoPlugin::TestTSAConnectivity(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    TSAClient tsaClient;
    std::vector<TSAServer> servers = tsaClient.GetAvailableTSAServers();
    
    flutter::EncodableList serverList;
    for (const auto& server : servers) {
        flutter::EncodableMap serverMap;
        serverMap[flutter::EncodableValue("name")] = flutter::EncodableValue(server.name);
        serverMap[flutter::EncodableValue("url")] = flutter::EncodableValue(server.url);
        serverMap[flutter::EncodableValue("available")] = flutter::EncodableValue(tsaClient.TestTSAServer(server));
        
        serverList.push_back(flutter::EncodableValue(serverMap));
    }
    
    result->Success(flutter::EncodableValue(serverList));
}

void NativeCryptoPlugin::ValidatePdf(
    const flutter::EncodableValue& arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const auto* args = std::get_if<flutter::EncodableMap>(&arguments);
    if (!args) {
        result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
        return;
    }
    
    auto pdfPath_it = args->find(flutter::EncodableValue("pdfPath"));
    if (pdfPath_it == args->end()) {
        result->Error("MISSING_ARGUMENTS", "pdfPath is required");
        return;
    }
    
    const auto* pdfPath = std::get_if<std::string>(&pdfPath_it->second);
    if (!pdfPath) {
        result->Error("INVALID_ARGUMENTS", "pdfPath must be a string");
        return;
    }
    
    PdfSigner signer;
    bool isValid = signer.ValidatePdf(*pdfPath);
    int pageCount = signer.GetPageCount(*pdfPath);
    
    double width, height;
    bool hasDimensions = signer.GetPageDimensions(*pdfPath, 1, width, height);
    
    flutter::EncodableMap response;
    response[flutter::EncodableValue("isValid")] = flutter::EncodableValue(isValid);
    response[flutter::EncodableValue("pageCount")] = flutter::EncodableValue(pageCount);
    if (hasDimensions) {
        response[flutter::EncodableValue("pageWidth")] = flutter::EncodableValue(width);
        response[flutter::EncodableValue("pageHeight")] = flutter::EncodableValue(height);
    }
    
    result->Success(flutter::EncodableValue(response));
} 