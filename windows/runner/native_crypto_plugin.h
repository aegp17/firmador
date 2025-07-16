#ifndef NATIVE_CRYPTO_PLUGIN_H
#define NATIVE_CRYPTO_PLUGIN_H

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class NativeCryptoPlugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

    NativeCryptoPlugin();
    virtual ~NativeCryptoPlugin();

    // Disallow copy and assign.
    NativeCryptoPlugin(const NativeCryptoPlugin&) = delete;
    NativeCryptoPlugin& operator=(const NativeCryptoPlugin&) = delete;

private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    // Method implementations
    void GetCertificateInfo(
        const flutter::EncodableValue& arguments,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    void GetAvailableCertificates(
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    void SignPdf(
        const flutter::EncodableValue& arguments,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    void TestTSAConnectivity(
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
        
    void ValidatePdf(
        const flutter::EncodableValue& arguments,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

#endif // NATIVE_CRYPTO_PLUGIN_H 