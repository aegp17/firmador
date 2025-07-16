#include "tsa_client.h"
#include <iostream>
#include <sstream>
#include <random>

TSAClient::TSAClient() : m_hInternet(nullptr) {
    // Initialize WinINet
    m_hInternet = InternetOpen(L"Firmador TSA Client", 
                              INTERNET_OPEN_TYPE_PRECONFIG, 
                              nullptr, nullptr, 0);
    
    if (!m_hInternet) {
        std::cerr << "Failed to initialize WinINet: " << GetLastError() << std::endl;
    }
    
    InitializeDefaultTSAServers();
}

TSAClient::~TSAClient() {
    if (m_hInternet) {
        InternetCloseHandle(m_hInternet);
    }
}

TSAResponse TSAClient::GetTimestamp(const std::vector<BYTE>& messageHash, 
                                  const std::string& hashAlgorithm) {
    if (!m_hInternet) {
        TSAResponse response = {};
        response.success = false;
        response.errorMessage = "WinINet not initialized";
        return response;
    }
    
    // Create TSA request
    std::vector<BYTE> tsaRequest = CreateTSARequest(messageHash, hashAlgorithm);
    if (tsaRequest.empty()) {
        TSAResponse response = {};
        response.success = false;
        response.errorMessage = "Failed to create TSA request";
        return response;
    }
    
    // Try each TSA server in order
    for (const auto& server : m_tsaServers) {
        std::cout << "Trying TSA server: " << server.name << std::endl;
        
        TSAResponse response = RequestTimestampFromServer(server, tsaRequest);
        if (response.success) {
            response.serverUsed = server.name;
            std::cout << "Successfully obtained timestamp from: " << server.name << std::endl;
            return response;
        } else {
            std::cout << "Failed to get timestamp from " << server.name << ": " << response.errorMessage << std::endl;
        }
    }
    
    // All servers failed
    TSAResponse response = {};
    response.success = false;
    response.errorMessage = "All TSA servers failed";
    return response;
}

void TSAClient::SetTSAServers(const std::vector<TSAServer>& servers) {
    m_tsaServers = servers;
}

std::vector<TSAServer> TSAClient::GetAvailableTSAServers() const {
    return m_tsaServers;
}

bool TSAClient::TestTSAServer(const TSAServer& server) const {
    if (!m_hInternet) {
        return false;
    }
    
    // Parse URL
    std::wstring wUrl(server.url.begin(), server.url.end());
    
    URL_COMPONENTS urlComponents = {0};
    urlComponents.dwStructSize = sizeof(urlComponents);
    
    // Set buffer sizes
    wchar_t hostname[256];
    wchar_t urlPath[256];
    urlComponents.lpszHostName = hostname;
    urlComponents.dwHostNameLength = sizeof(hostname) / sizeof(wchar_t);
    urlComponents.lpszUrlPath = urlPath;
    urlComponents.dwUrlPathLength = sizeof(urlPath) / sizeof(wchar_t);
    
    if (!InternetCrackUrl(wUrl.c_str(), 0, 0, &urlComponents)) {
        return false;
    }
    
    // Connect to server
    HINTERNET hConnect = InternetConnect(
        m_hInternet,
        hostname,
        urlComponents.nPort,
        nullptr, nullptr,
        INTERNET_SERVICE_HTTP,
        0, 0
    );
    
    if (!hConnect) {
        return false;
    }
    
    // Test connection with HEAD request
    HINTERNET hRequest = HttpOpenRequest(
        hConnect,
        L"HEAD",
        urlPath,
        nullptr, nullptr, nullptr,
        urlComponents.nScheme == INTERNET_SCHEME_HTTPS ? INTERNET_FLAG_SECURE : 0,
        0
    );
    
    bool result = false;
    if (hRequest) {
        if (HttpSendRequest(hRequest, nullptr, 0, nullptr, 0)) {
            DWORD statusCode;
            DWORD statusCodeSize = sizeof(statusCode);
            
            if (HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
                             &statusCode, &statusCodeSize, nullptr)) {
                // Accept various status codes as "alive"
                result = (statusCode == 200 || statusCode == 405 || statusCode == 400);
            }
        }
        InternetCloseHandle(hRequest);
    }
    
    InternetCloseHandle(hConnect);
    return result;
}

TSAResponse TSAClient::RequestTimestampFromServer(const TSAServer& server, 
                                                const std::vector<BYTE>& tsaRequest) {
    TSAResponse response = {};
    response.success = false;
    
    // Make HTTP POST request
    std::vector<BYTE> responseData = HttpPostRequest(server.url, tsaRequest, response.httpStatusCode);
    
    if (responseData.empty()) {
        response.errorMessage = "Failed to send TSA request to " + server.name;
        return response;
    }
    
    if (response.httpStatusCode != 200) {
        response.errorMessage = "TSA server returned HTTP " + std::to_string(response.httpStatusCode);
        return response;
    }
    
    response.success = true;
    response.timestampData = responseData;
    response.serverUsed = server.name;
    
    return response;
}

std::vector<BYTE> TSAClient::CreateTSARequest(const std::vector<BYTE>& messageHash, 
                                            const std::string& hashAlgorithm) {
    // Simplified TSA request creation
    // In a full implementation, this would create a proper RFC 3161 TSA request
    
    std::vector<BYTE> tsaRequest;
    
    // TSA Request structure (simplified)
    // This is a minimal implementation - a full version would use ASN.1 encoding
    
    // Add TSA request header (simplified)
    std::string requestHeader = "TSA_REQUEST_V1\n";
    tsaRequest.insert(tsaRequest.end(), requestHeader.begin(), requestHeader.end());
    
    // Add hash algorithm
    std::string algLine = "ALGORITHM:" + hashAlgorithm + "\n";
    tsaRequest.insert(tsaRequest.end(), algLine.begin(), algLine.end());
    
    // Add message hash (hex encoded)
    std::string hashLine = "HASH:";
    tsaRequest.insert(tsaRequest.end(), hashLine.begin(), hashLine.end());
    
    // Convert hash to hex
    for (BYTE b : messageHash) {
        char hex[3];
        sprintf_s(hex, "%02x", b);
        tsaRequest.push_back(hex[0]);
        tsaRequest.push_back(hex[1]);
    }
    
    tsaRequest.push_back('\n');
    
    // Add random nonce
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);
    
    std::string nonceLine = "NONCE:";
    tsaRequest.insert(tsaRequest.end(), nonceLine.begin(), nonceLine.end());
    
    for (int i = 0; i < 8; ++i) {
        char hex[3];
        sprintf_s(hex, "%02x", dis(gen));
        tsaRequest.push_back(hex[0]);
        tsaRequest.push_back(hex[1]);
    }
    
    tsaRequest.push_back('\n');
    
    return tsaRequest;
}

std::vector<BYTE> TSAClient::HttpPostRequest(const std::string& url, 
                                           const std::vector<BYTE>& postData,
                                           int& httpStatusCode) {
    std::vector<BYTE> response;
    httpStatusCode = 0;
    
    if (!m_hInternet) {
        return response;
    }
    
    // Convert URL to wide string
    std::wstring wUrl(url.begin(), url.end());
    
    // Parse URL
    URL_COMPONENTS urlComponents = {0};
    urlComponents.dwStructSize = sizeof(urlComponents);
    
    wchar_t hostname[256];
    wchar_t urlPath[256];
    urlComponents.lpszHostName = hostname;
    urlComponents.dwHostNameLength = sizeof(hostname) / sizeof(wchar_t);
    urlComponents.lpszUrlPath = urlPath;
    urlComponents.dwUrlPathLength = sizeof(urlPath) / sizeof(wchar_t);
    
    if (!InternetCrackUrl(wUrl.c_str(), 0, 0, &urlComponents)) {
        return response;
    }
    
    // Connect to server
    HINTERNET hConnect = InternetConnect(
        m_hInternet,
        hostname,
        urlComponents.nPort,
        nullptr, nullptr,
        INTERNET_SERVICE_HTTP,
        0, 0
    );
    
    if (!hConnect) {
        return response;
    }
    
    // Open HTTP request
    DWORD flags = urlComponents.nScheme == INTERNET_SCHEME_HTTPS ? 
                  INTERNET_FLAG_SECURE : 0;
    
    HINTERNET hRequest = HttpOpenRequest(
        hConnect,
        L"POST",
        urlPath,
        nullptr, nullptr, nullptr,
        flags,
        0
    );
    
    if (!hRequest) {
        InternetCloseHandle(hConnect);
        return response;
    }
    
    // Set headers
    std::wstring headers = L"Content-Type: application/timestamp-query\r\n";
    
    // Send request
    BOOL requestSent = HttpSendRequest(
        hRequest,
        headers.c_str(),
        static_cast<DWORD>(headers.length()),
        const_cast<BYTE*>(postData.data()),
        static_cast<DWORD>(postData.size())
    );
    
    if (requestSent) {
        // Get status code
        DWORD statusCode;
        DWORD statusCodeSize = sizeof(statusCode);
        
        if (HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
                         &statusCode, &statusCodeSize, nullptr)) {
            httpStatusCode = static_cast<int>(statusCode);
        }
        
        if (httpStatusCode == 200) {
            // Read response
            BYTE buffer[4096];
            DWORD bytesRead;
            
            while (InternetReadFile(hRequest, buffer, sizeof(buffer), &bytesRead) && bytesRead > 0) {
                response.insert(response.end(), buffer, buffer + bytesRead);
            }
        }
    }
    
    InternetCloseHandle(hRequest);
    InternetCloseHandle(hConnect);
    
    return response;
}

void TSAClient::InitializeDefaultTSAServers() {
    m_tsaServers.clear();
    
    // Add default TSA servers with fallback support
    TSAServer server1 = {};
    server1.url = "https://freetsa.org/tsr";
    server1.name = "FreeTSA";
    server1.requiresAuth = false;
    m_tsaServers.push_back(server1);
    
    TSAServer server2 = {};
    server2.url = "http://timestamp.digicert.com";
    server2.name = "DigiCert";
    server2.requiresAuth = false;
    m_tsaServers.push_back(server2);
    
    TSAServer server3 = {};
    server3.url = "http://timestamp.sectigo.com";
    server3.name = "Sectigo";
    server3.requiresAuth = false;
    m_tsaServers.push_back(server3);
    
    TSAServer server4 = {};
    server4.url = "http://timestamp.apple.com/ts01";
    server4.name = "Apple";
    server4.requiresAuth = false;
    m_tsaServers.push_back(server4);
    
    TSAServer server5 = {};
    server5.url = "http://time.certum.pl";
    server5.name = "Certum";
    server5.requiresAuth = false;
    m_tsaServers.push_back(server5);
}

std::string TSAClient::GetLastWinInetError() const {
    DWORD error = GetLastError();
    
    LPWSTR errorMsg = nullptr;
    DWORD length = FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
        nullptr,
        error,
        0,
        reinterpret_cast<LPWSTR>(&errorMsg),
        0,
        nullptr
    );
    
    std::string result;
    if (length > 0 && errorMsg) {
        // Convert to UTF-8
        int utf8Length = WideCharToMultiByte(CP_UTF8, 0, errorMsg, length, nullptr, 0, nullptr, nullptr);
        if (utf8Length > 0) {
            std::vector<char> utf8Buffer(utf8Length);
            WideCharToMultiByte(CP_UTF8, 0, errorMsg, length, utf8Buffer.data(), utf8Length, nullptr, nullptr);
            result = std::string(utf8Buffer.data(), utf8Length);
        }
        LocalFree(errorMsg);
    }
    
    if (result.empty()) {
        result = "Unknown WinINet error: " + std::to_string(error);
    }
    
    return result;
} 