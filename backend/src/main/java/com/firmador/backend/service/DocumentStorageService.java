package com.firmador.backend.service;

import org.springframework.stereotype.Service;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

@Service
public class DocumentStorageService {
    
    // Almacenamiento en memoria (para desarrollo - en producción usar S3, etc.)
    private final Map<String, StoredDocument> documentStorage = new ConcurrentHashMap<>();
    
    public void storeDocument(String documentId, byte[] data, String filename, String contentType) {
        StoredDocument storedDoc = new StoredDocument(data, filename, contentType, System.currentTimeMillis());
        documentStorage.put(documentId, storedDoc);
    }
    
    public StoredDocument getDocument(String documentId) {
        return documentStorage.get(documentId);
    }
    
    public boolean documentExists(String documentId) {
        return documentStorage.containsKey(documentId);
    }
    
    public void removeDocument(String documentId) {
        documentStorage.remove(documentId);
    }
    
    public static class StoredDocument {
        private final byte[] data;
        private final String filename;
        private final String contentType;
        private final long timestamp;
        
        public StoredDocument(byte[] data, String filename, String contentType, long timestamp) {
            this.data = data;
            this.filename = filename;
            this.contentType = contentType;
            this.timestamp = timestamp;
        }
        
        public byte[] getData() { return data; }
        public String getFilename() { return filename; }
        public String getContentType() { return contentType; }
        public long getTimestamp() { return timestamp; }
    }
} 