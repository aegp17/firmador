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
        }
        
        std::cout << "Failed to get timestamp from " << server.name 
                  << ": " << response.errorMessage << std::endl;
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
    
    // Convert URL to wide string
    std::wstring wUrl(server.url.begin(), server.url.end());
    
    HINTERNET hConnect = InternetOpenUrl(m_hInternet, wUrl.c_str(), 
                                        nullptr, 0, 
                                        INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE,
                                        0);
    
    if (!hConnect) {
        return false;
    }
    
    // Check HTTP status
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(statusCode);
    
    bool success = HttpQueryInfo(hConnect, 
                                HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
                                &statusCode, &statusCodeSize, nullptr) != FALSE;
    
    InternetCloseHandle(hConnect);
    
    return success && (statusCode == 200 || statusCode == 405); // 405 is expected for GET on TSA endpoint
}

TSAResponse TSAClient::RequestTimestampFromServer(const TSAServer& server, 
                                                const std::vector<BYTE>& tsaRequest) {
    TSAResponse response = {};
    
    try {
        std::vector<BYTE> responseData = HttpPostRequest(server.url, tsaRequest, 
                                                       response.httpStatusCode);
        
        if (response.httpStatusCode == 200 && !responseData.empty()) {
            response.success = true;
            response.timestampData = responseData;
            response.serverUsed = server.name;
        } else {
            response.success = false;
            response.errorMessage = "HTTP " + std::to_string(response.httpStatusCode);
        }
    } catch (const std::exception& e) {
        response.success = false;
        response.errorMessage = e.what();
    }
    
    return response;
}

std::vector<BYTE> TSAClient::CreateTSARequest(const std::vector<BYTE>& messageHash, 
                                            const std::string& hashAlgorithm) {
    // Simplified TSA request creation
    // In a full implementation, this would create a proper ASN.1 TSRequest structure
    
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);
    
    std::vector<BYTE> tsaRequest;
    
    // Add a simple header (this is a placeholder - real implementation needs proper ASN.1)
    tsaRequest.push_back(0x30); // SEQUENCE
    tsaRequest.push_back(0x82); // Length (long form)
    
    // Add version
    tsaRequest.push_back(0x02); // INTEGER
    tsaRequest.push_back(0x01); // Length
    tsaRequest.push_back(0x01); // Version 1
    
    // Add message imprint
    tsaRequest.push_back(0x30); // SEQUENCE
    tsaRequest.push_back(static_cast<BYTE>(messageHash.size() + 10)); // Length estimate
    
    // Add hash algorithm (simplified)
    tsaRequest.push_back(0x30); // SEQUENCE
    tsaRequest.push_back(0x07); // Length
    tsaRequest.push_back(0x06); // OID
    tsaRequest.push_back(0x05); // Length
    // SHA256 OID simplified
    tsaRequest.insert(tsaRequest.end(), {0x2B, 0x0E, 0x03, 0x02, 0x1A});
    
    // Add hash value
    tsaRequest.push_back(0x04); // OCTET STRING
    tsaRequest.push_back(static_cast<BYTE>(messageHash.size())); // Length
    tsaRequest.insert(tsaRequest.end(), messageHash.begin(), messageHash.end());
    
    // Add nonce (random)
    tsaRequest.push_back(0x02); // INTEGER
    tsaRequest.push_back(0x08); // Length (8 bytes)
    for (int i = 0; i < 8; ++i) {
        tsaRequest.push_back(static_cast<BYTE>(dis(gen)));
    }
    
    // Update length field
    size_t totalLength = tsaRequest.size() - 3;
    tsaRequest[2] = static_cast<BYTE>((totalLength >> 8) & 0xFF);
    tsaRequest.insert(tsaRequest.begin() + 3, static_cast<BYTE>(totalLength & 0xFF));
    
    return tsaRequest;
}

std::vector<BYTE> TSAClient::HttpPostRequest(const std::string& url, 
                                           const std::vector<BYTE>& postData,
                                           int& httpStatusCode) {
    std::vector<BYTE> responseData;
    httpStatusCode = 0;
    
    // Parse URL
    std::string scheme, host, path;
    INTERNET_PORT port = INTERNET_DEFAULT_HTTPS_PORT;
    
    if (url.find("https://") == 0) {
        size_t hostStart = 8;
        size_t pathStart = url.find('/', hostStart);
        host = url.substr(hostStart, pathStart - hostStart);
        path = url.substr(pathStart);
        port = INTERNET_DEFAULT_HTTPS_PORT;
    } else if (url.find("http://") == 0) {
        size_t hostStart = 7;
        size_t pathStart = url.find('/', hostStart);
        host = url.substr(hostStart, pathStart - hostStart);
        path = url.substr(pathStart);
        port = INTERNET_DEFAULT_HTTP_PORT;
    } else {
        throw std::runtime_error("Unsupported URL scheme");
    }
    
    // Convert to wide strings
    std::wstring wHost(host.begin(), host.end());
    std::wstring wPath(path.begin(), path.end());
    
    // Connect to server
    HINTERNET hConnect = InternetConnect(m_hInternet, wHost.c_str(), port,
                                        nullptr, nullptr, INTERNET_SERVICE_HTTP, 0, 0);
    if (!hConnect) {
        throw std::runtime_error("Failed to connect to server: " + GetLastWinInetError());
    }
    
    // Create request
    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE;
    if (port == INTERNET_DEFAULT_HTTPS_PORT) {
        flags |= INTERNET_FLAG_SECURE;
    }
    
    HINTERNET hRequest = HttpOpenRequest(hConnect, L"POST", wPath.c_str(),
                                        nullptr, nullptr, nullptr, flags, 0);
    if (!hRequest) {
        InternetCloseHandle(hConnect);
        throw std::runtime_error("Failed to create HTTP request: " + GetLastWinInetError());
    }
    
    // Set headers
    std::wstring headers = L"Content-Type: application/timestamp-query\r\n";
    if (!HttpAddRequestHeaders(hRequest, headers.c_str(), -1, 
                              HTTP_ADDREQ_FLAG_ADD | HTTP_ADDREQ_FLAG_REPLACE)) {
        InternetCloseHandle(hRequest);
        InternetCloseHandle(hConnect);
        throw std::runtime_error("Failed to add headers: " + GetLastWinInetError());
    }
    
    // Send request
    BOOL success = HttpSendRequest(hRequest, nullptr, 0, 
                                  const_cast<BYTE*>(postData.data()), 
                                  static_cast<DWORD>(postData.size()));
    if (!success) {
        InternetCloseHandle(hRequest);
        InternetCloseHandle(hConnect);
        throw std::runtime_error("Failed to send request: " + GetLastWinInetError());
    }
    
    // Get status code
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(statusCode);
    HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
                 &statusCode, &statusCodeSize, nullptr);
    httpStatusCode = static_cast<int>(statusCode);
    
    // Read response
    DWORD bytesAvailable = 0;
    while (InternetQueryDataAvailable(hRequest, &bytesAvailable, 0, 0) && bytesAvailable > 0) {
        std::vector<BYTE> buffer(bytesAvailable);
        DWORD bytesRead = 0;
        
        if (InternetReadFile(hRequest, buffer.data(), bytesAvailable, &bytesRead)) {
            responseData.insert(responseData.end(), buffer.begin(), 
                              buffer.begin() + bytesRead);
        } else {
            break;
        }
    }
    
    InternetCloseHandle(hRequest);
    InternetCloseHandle(hConnect);
    
    return responseData;
}

void TSAClient::InitializeDefaultTSAServers() {
    m_tsaServers.clear();
    
    // FreeTSA (Free)
    TSAServer freeTsa = {};
    freeTsa.url = "https://freetsa.org/tsr";
    freeTsa.name = "FreeTSA";
    freeTsa.requiresAuth = false;
    m_tsaServers.push_back(freeTsa);
    
    // DigiCert TSA
    TSAServer digicert = {};
    digicert.url = "http://timestamp.digicert.com";
    digicert.name = "DigiCert";
    digicert.requiresAuth = false;
    m_tsaServers.push_back(digicert);
    
    // Sectigo TSA
    TSAServer sectigo = {};
    sectigo.url = "http://timestamp.sectigo.com";
    sectigo.name = "Sectigo";
    sectigo.requiresAuth = false;
    m_tsaServers.push_back(sectigo);
    
    // GlobalSign TSA
    TSAServer globalsign = {};
    globalsign.url = "http://timestamp.globalsign.com/scripts/timstamp.dll";
    globalsign.name = "GlobalSign";
    globalsign.requiresAuth = false;
    m_tsaServers.push_back(globalsign);
    
    // Entrust TSA
    TSAServer entrust = {};
    entrust.url = "http://timestamp.entrust.net/TSS/RFC3161sha2TS";
    entrust.name = "Entrust";
    entrust.requiresAuth = false;
    m_tsaServers.push_back(entrust);
}

std::string TSAClient::GetLastWinInetError() const {
    DWORD error = GetLastError();
    std::stringstream ss;
    ss << "Error " << error;
    
    if (error == ERROR_INTERNET_TIMEOUT) {
        ss << " (Timeout)";
    } else if (error == ERROR_INTERNET_NAME_NOT_RESOLVED) {
        ss << " (Name not resolved)";
    } else if (error == ERROR_INTERNET_CANNOT_CONNECT) {
        ss << " (Cannot connect)";
    }
    
    return ss.str();
} 