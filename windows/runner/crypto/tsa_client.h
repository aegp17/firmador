#ifndef TSA_CLIENT_H
#define TSA_CLIENT_H

#include <windows.h>
#include <wininet.h>
#include <string>
#include <vector>

struct TSAServer {
    std::string url;
    std::string name;
    bool requiresAuth;
    std::string username;
    std::string password;
};

struct TSAResponse {
    bool success;
    std::vector<BYTE> timestampData;
    std::string errorMessage;
    std::string serverUsed;
    int httpStatusCode;
};

class TSAClient {
public:
    TSAClient();
    ~TSAClient();

    // Get timestamp token for given hash
    TSAResponse GetTimestamp(const std::vector<BYTE>& messageHash, 
                           const std::string& hashAlgorithm = "SHA256");
    
    // Configure TSA servers (uses default list if not called)
    void SetTSAServers(const std::vector<TSAServer>& servers);
    
    // Get available TSA servers
    std::vector<TSAServer> GetAvailableTSAServers() const;
    
    // Test TSA server connectivity
    bool TestTSAServer(const TSAServer& server) const;

private:
    std::vector<TSAServer> m_tsaServers;
    HINTERNET m_hInternet;
    
    // Helper methods
    TSAResponse RequestTimestampFromServer(const TSAServer& server, 
                                         const std::vector<BYTE>& tsaRequest);
    std::vector<BYTE> CreateTSARequest(const std::vector<BYTE>& messageHash, 
                                     const std::string& hashAlgorithm);
    std::vector<BYTE> HttpPostRequest(const std::string& url, 
                                    const std::vector<BYTE>& postData,
                                    int& httpStatusCode);
    void InitializeDefaultTSAServers();
    std::string GetLastWinInetError() const;
};

#endif // TSA_CLIENT_H 