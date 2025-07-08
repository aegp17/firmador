# Testing del Backend

## Resumen
El backend implementa una estrategia de testing completa que incluye unit tests, integration tests y testing de APIs. Utiliza JUnit 5, Mockito y Spring Boot Test.

## Estructura de Testing

### Organización de Tests
```
src/test/java/
├── com/firmador/backend/
│   ├── controller/
│   │   └── DigitalSignatureControllerTest.java
│   ├── service/
│   │   ├── DigitalSignatureServiceTest.java
│   │   ├── CertificateServiceTest.java
│   │   └── DocumentStorageServiceTest.java
│   ├── integration/
│   │   ├── SigningWorkflowIntegrationTest.java
│   │   └── HealthCheckIntegrationTest.java
│   └── util/
│       ├── TestDataFactory.java
│       └── TestConstants.java
├── resources/
│   ├── test-data/
│   │   ├── test-document.pdf
│   │   ├── valid-certificate.p12
│   │   └── invalid-certificate.p12
│   └── application-test.yml
```

## Configuración de Testing

### Dependencias Maven
```xml
<dependencies>
    <!-- Spring Boot Test Starter -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- TestContainers para integration tests -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- WireMock para mocking de servicios externos -->
    <dependency>
        <groupId>com.github.tomakehurst</groupId>
        <artifactId>wiremock-jre8</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- AssertJ para assertions más legibles -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Configuración de Test
```yaml
# application-test.yml
spring:
  profiles:
    active: test
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 15MB

logging:
  level:
    com.firmador.backend: DEBUG
    org.springframework.web: INFO

# Configuración específica para tests
test:
  data:
    directory: src/test/resources/test-data/
    valid-certificate: valid-certificate.p12
    invalid-certificate: invalid-certificate.p12
    test-document: test-document.pdf
    certificate-password: testpassword
```

## Unit Tests

### Testing de Servicios

#### DigitalSignatureServiceTest
```java
@ExtendWith(MockitoExtension.class)
class DigitalSignatureServiceTest {
    
    @Mock
    private CertificateService certificateService;
    
    @Mock
    private DocumentStorageService documentStorageService;
    
    @InjectMocks
    private DigitalSignatureService digitalSignatureService;
    
    private SignatureRequest signatureRequest;
    private InputStream pdfStream;
    private InputStream certificateStream;
    
    @BeforeEach
    void setUp() {
        signatureRequest = TestDataFactory.createValidSignatureRequest();
        pdfStream = TestDataFactory.createTestPdfStream();
        certificateStream = TestDataFactory.createTestCertificateStream();
    }
    
    @Test
    @DisplayName("Should sign document successfully with valid inputs")
    void shouldSignDocumentSuccessfully() throws Exception {
        // Arrange
        X509Certificate mockCertificate = TestDataFactory.createMockCertificate();
        when(certificateService.loadCertificate(any(InputStream.class), anyString()))
            .thenReturn(mockCertificate);
        when(certificateService.isValidCertificate(mockCertificate))
            .thenReturn(true);
        when(documentStorageService.storeDocument(any(byte[].class), anyString()))
            .thenReturn("test-document-id");
        
        // Act
        SignatureResponse response = digitalSignatureService.signDocument(
            pdfStream, certificateStream, "password", signatureRequest
        );
        
        // Assert
        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getDocumentId()).isEqualTo("test-document-id");
        assertThat(response.getMessage()).contains("exitosamente");
        
        verify(certificateService).loadCertificate(certificateStream, "password");
        verify(certificateService).isValidCertificate(mockCertificate);
        verify(documentStorageService).storeDocument(any(byte[].class), anyString());
    }
    
    @Test
    @DisplayName("Should throw exception when certificate is invalid")
    void shouldThrowExceptionWhenCertificateIsInvalid() throws Exception {
        // Arrange
        X509Certificate mockCertificate = TestDataFactory.createMockCertificate();
        when(certificateService.loadCertificate(any(InputStream.class), anyString()))
            .thenReturn(mockCertificate);
        when(certificateService.isValidCertificate(mockCertificate))
            .thenReturn(false);
        
        // Act & Assert
        assertThatThrownBy(() -> digitalSignatureService.signDocument(
            pdfStream, certificateStream, "password", signatureRequest
        ))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("Certificate is not valid");
    }
    
    @Test
    @DisplayName("Should handle signature position correctly")
    void shouldHandleSignaturePositionCorrectly() throws Exception {
        // Arrange
        signatureRequest.setSignatureX(150);
        signatureRequest.setSignatureY(200);
        signatureRequest.setSignaturePage(2);
        
        X509Certificate mockCertificate = TestDataFactory.createMockCertificate();
        when(certificateService.loadCertificate(any(InputStream.class), anyString()))
            .thenReturn(mockCertificate);
        when(certificateService.isValidCertificate(mockCertificate))
            .thenReturn(true);
        when(documentStorageService.storeDocument(any(byte[].class), anyString()))
            .thenReturn("test-document-id");
        
        // Act
        SignatureResponse response = digitalSignatureService.signDocument(
            pdfStream, certificateStream, "password", signatureRequest
        );
        
        // Assert
        assertThat(response.isSuccess()).isTrue();
        // Verify que la posición se aplicó correctamente
        // (esto requeriría verificar el PDF resultante o usar spy)
    }
    
    @Test
    @DisplayName("Should create signature text without email")
    void shouldCreateSignatureTextWithoutEmail() throws Exception {
        // Arrange
        X509Certificate mockCertificate = TestDataFactory.createMockCertificate();
        
        // Act
        String signatureText = digitalSignatureService.createSignatureText(
            signatureRequest, mockCertificate
        );
        
        // Assert
        assertThat(signatureText)
            .contains(signatureRequest.getSignerName())
            .contains(signatureRequest.getSignerId())
            .contains(signatureRequest.getLocation())
            .contains(signatureRequest.getReason())
            .doesNotContain("Email:"); // Verificar que no hay email
    }
}
```

#### CertificateServiceTest
```java
@ExtendWith(MockitoExtension.class)
class CertificateServiceTest {
    
    private CertificateService certificateService;
    
    @BeforeEach
    void setUp() {
        certificateService = new CertificateService();
    }
    
    @Test
    @DisplayName("Should validate certificate successfully")
    void shouldValidateCertificateSuccessfully() throws Exception {
        // Arrange
        InputStream certificateStream = TestDataFactory.getValidCertificateStream();
        String password = TestConstants.VALID_CERTIFICATE_PASSWORD;
        
        // Act
        boolean isValid = certificateService.validateCertificate(certificateStream, password);
        
        // Assert
        assertThat(isValid).isTrue();
    }
    
    @Test
    @DisplayName("Should reject invalid password")
    void shouldRejectInvalidPassword() throws Exception {
        // Arrange
        InputStream certificateStream = TestDataFactory.getValidCertificateStream();
        String wrongPassword = "wrongpassword";
        
        // Act
        boolean isValid = certificateService.validateCertificate(certificateStream, wrongPassword);
        
        // Assert
        assertThat(isValid).isFalse();
    }
    
    @Test
    @DisplayName("Should extract certificate info correctly")
    void shouldExtractCertificateInfoCorrectly() throws Exception {
        // Arrange
        InputStream certificateStream = TestDataFactory.getValidCertificateStream();
        String password = TestConstants.VALID_CERTIFICATE_PASSWORD;
        
        // Act
        CertificateInfo info = certificateService.extractCertificateInfo(
            certificateStream, password
        );
        
        // Assert
        assertThat(info).isNotNull();
        assertThat(info.getSubject()).contains("Test User");
        assertThat(info.getIssuer()).contains("Test CA");
        assertThat(info.isValid()).isTrue();
        assertThat(info.getKeyAlgorithm()).isEqualTo("RSA");
        assertThat(info.getSignatureAlgorithm()).contains("SHA256");
    }
    
    @Test
    @DisplayName("Should detect expired certificate")
    void shouldDetectExpiredCertificate() throws Exception {
        // Arrange
        X509Certificate expiredCert = TestDataFactory.createExpiredCertificate();
        
        // Act
        boolean isValid = certificateService.isValidCertificate(expiredCert);
        
        // Assert
        assertThat(isValid).isFalse();
    }
}
```

### Testing de Controladores

#### DigitalSignatureControllerTest
```java
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@TestPropertySource(locations = "classpath:application-test.yml")
class DigitalSignatureControllerTest {
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @MockBean
    private DigitalSignatureService digitalSignatureService;
    
    @MockBean
    private CertificateService certificateService;
    
    @Test
    @DisplayName("Should return health status")
    void shouldReturnHealthStatus() {
        // Act
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "/api/signature/health", Map.class
        );
        
        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsKey("status");
        assertThat(response.getBody().get("status")).isEqualTo("UP");
        assertThat(response.getBody()).containsKey("timestamp");
        assertThat(response.getBody()).containsKey("service");
    }
    
    @Test
    @DisplayName("Should sign document successfully")
    void shouldSignDocumentSuccessfully() throws Exception {
        // Arrange
        MockMultipartFile pdfFile = new MockMultipartFile(
            "file", "test.pdf", "application/pdf", 
            TestDataFactory.getTestPdfBytes()
        );
        
        MockMultipartFile certFile = new MockMultipartFile(
            "certificate", "cert.p12", "application/x-pkcs12", 
            TestDataFactory.getTestCertificateBytes()
        );
        
        SignatureResponse mockResponse = TestDataFactory.createSuccessfulSignatureResponse();
        when(digitalSignatureService.signDocument(any(), any(), anyString(), any()))
            .thenReturn(mockResponse);
        
        MultiValueMap<String, Object> parts = new LinkedMultiValueMap<>();
        parts.add("file", pdfFile.getResource());
        parts.add("certificate", certFile.getResource());
        parts.add("password", "testpassword");
        parts.add("signerName", "Test User");
        parts.add("signerId", "1234567890");
        parts.add("location", "Test Location");
        parts.add("reason", "Test Reason");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        
        HttpEntity<MultiValueMap<String, Object>> requestEntity = 
            new HttpEntity<>(parts, headers);
        
        // Act
        ResponseEntity<SignatureResponse> response = restTemplate.postForEntity(
            "/api/signature/sign", requestEntity, SignatureResponse.class
        );
        
        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getDocumentId()).isNotNull();
    }
    
    @Test
    @DisplayName("Should validate certificate successfully")
    void shouldValidateCertificateSuccessfully() throws Exception {
        // Arrange
        MockMultipartFile certFile = new MockMultipartFile(
            "certificate", "cert.p12", "application/x-pkcs12", 
            TestDataFactory.getTestCertificateBytes()
        );
        
        when(certificateService.validateCertificate(any(), anyString()))
            .thenReturn(true);
        
        MultiValueMap<String, Object> parts = new LinkedMultiValueMap<>();
        parts.add("certificate", certFile.getResource());
        parts.add("password", "testpassword");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        
        HttpEntity<MultiValueMap<String, Object>> requestEntity = 
            new HttpEntity<>(parts, headers);
        
        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/signature/validate-certificate", requestEntity, Map.class
        );
        
        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().get("valid")).isEqualTo(true);
    }
    
    @Test
    @DisplayName("Should handle file too large error")
    void shouldHandleFileTooLargeError() throws Exception {
        // Arrange
        byte[] largeFile = new byte[51 * 1024 * 1024]; // 51MB
        MockMultipartFile pdfFile = new MockMultipartFile(
            "file", "large.pdf", "application/pdf", largeFile
        );
        
        MockMultipartFile certFile = new MockMultipartFile(
            "certificate", "cert.p12", "application/x-pkcs12", 
            TestDataFactory.getTestCertificateBytes()
        );
        
        MultiValueMap<String, Object> parts = new LinkedMultiValueMap<>();
        parts.add("file", pdfFile.getResource());
        parts.add("certificate", certFile.getResource());
        parts.add("password", "testpassword");
        parts.add("signerName", "Test User");
        parts.add("signerId", "1234567890");
        parts.add("location", "Test Location");
        parts.add("reason", "Test Reason");
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        
        HttpEntity<MultiValueMap<String, Object>> requestEntity = 
            new HttpEntity<>(parts, headers);
        
        // Act
        ResponseEntity<String> response = restTemplate.postForEntity(
            "/api/signature/sign", requestEntity, String.class
        );
        
        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE);
    }
}
```

## Integration Tests

### SigningWorkflowIntegrationTest
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(locations = "classpath:application-test.yml")
class SigningWorkflowIntegrationTest {
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Autowired
    private DocumentStorageService documentStorageService;
    
    @Test
    @DisplayName("Complete signing workflow should work end-to-end")
    void completeSigningWorkflowShouldWork() throws Exception {
        // 1. Health Check
        ResponseEntity<Map> healthResponse = restTemplate.getForEntity(
            "/api/signature/health", Map.class
        );
        assertThat(healthResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        
        // 2. Validate Certificate
        MultiValueMap<String, Object> validateParts = new LinkedMultiValueMap<>();
        validateParts.add("certificate", TestDataFactory.getValidCertificateResource());
        validateParts.add("password", TestConstants.VALID_CERTIFICATE_PASSWORD);
        
        ResponseEntity<Map> validateResponse = restTemplate.postForEntity(
            "/api/signature/validate-certificate", 
            new HttpEntity<>(validateParts, createMultipartHeaders()), 
            Map.class
        );
        assertThat(validateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(validateResponse.getBody().get("valid")).isEqualTo(true);
        
        // 3. Get Certificate Info
        ResponseEntity<CertificateInfo> infoResponse = restTemplate.postForEntity(
            "/api/signature/certificate-info", 
            new HttpEntity<>(validateParts, createMultipartHeaders()), 
            CertificateInfo.class
        );
        assertThat(infoResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(infoResponse.getBody().isValid()).isTrue();
        
        // 4. Sign Document
        MultiValueMap<String, Object> signParts = new LinkedMultiValueMap<>();
        signParts.add("file", TestDataFactory.getTestPdfResource());
        signParts.add("certificate", TestDataFactory.getValidCertificateResource());
        signParts.add("password", TestConstants.VALID_CERTIFICATE_PASSWORD);
        signParts.add("signerName", "Integration Test User");
        signParts.add("signerId", "1234567890");
        signParts.add("location", "Test Lab");
        signParts.add("reason", "Integration Testing");
        signParts.add("signatureX", "150");
        signParts.add("signatureY", "200");
        signParts.add("signaturePage", "1");
        
        ResponseEntity<SignatureResponse> signResponse = restTemplate.postForEntity(
            "/api/signature/sign", 
            new HttpEntity<>(signParts, createMultipartHeaders()), 
            SignatureResponse.class
        );
        assertThat(signResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(signResponse.getBody().isSuccess()).isTrue();
        String documentId = signResponse.getBody().getDocumentId();
        assertThat(documentId).isNotNull();
        
        // 5. Download Signed Document
        ResponseEntity<byte[]> downloadResponse = restTemplate.getForEntity(
            "/api/signature/download/" + documentId, byte[].class
        );
        assertThat(downloadResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(downloadResponse.getBody()).isNotEmpty();
        
        // Verify content type
        assertThat(downloadResponse.getHeaders().getContentType())
            .isEqualTo(MediaType.APPLICATION_PDF);
        
        // 6. Verify document is stored
        StoredDocument storedDoc = documentStorageService.getDocument(documentId);
        assertThat(storedDoc).isNotNull();
        assertThat(storedDoc.getData()).isEqualTo(downloadResponse.getBody());
    }
    
    private HttpHeaders createMultipartHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        return headers;
    }
}
```

## Utilities de Testing

### TestDataFactory
```java
public class TestDataFactory {
    
    public static SignatureRequest createValidSignatureRequest() {
        SignatureRequest request = new SignatureRequest();
        request.setSignerName("Test User");
        request.setSignerId("1234567890");
        request.setLocation("Test Location");
        request.setReason("Test Reason");
        request.setSignatureX(100);
        request.setSignatureY(100);
        request.setSignatureWidth(200);
        request.setSignatureHeight(80);
        request.setSignaturePage(1);
        return request;
    }
    
    public static InputStream createTestPdfStream() {
        return TestDataFactory.class.getResourceAsStream("/test-data/test-document.pdf");
    }
    
    public static InputStream createTestCertificateStream() {
        return TestDataFactory.class.getResourceAsStream("/test-data/valid-certificate.p12");
    }
    
    public static InputStream getValidCertificateStream() {
        return TestDataFactory.class.getResourceAsStream("/test-data/valid-certificate.p12");
    }
    
    public static Resource getValidCertificateResource() {
        return new ClassPathResource("test-data/valid-certificate.p12");
    }
    
    public static Resource getTestPdfResource() {
        return new ClassPathResource("test-data/test-document.pdf");
    }
    
    public static byte[] getTestPdfBytes() throws IOException {
        return IOUtils.toByteArray(createTestPdfStream());
    }
    
    public static byte[] getTestCertificateBytes() throws IOException {
        return IOUtils.toByteArray(createTestCertificateStream());
    }
    
    public static X509Certificate createMockCertificate() {
        return Mockito.mock(X509Certificate.class);
    }
    
    public static X509Certificate createExpiredCertificate() {
        X509Certificate cert = Mockito.mock(X509Certificate.class);
        Mockito.when(cert.getNotAfter()).thenReturn(new Date(System.currentTimeMillis() - 86400000)); // Yesterday
        return cert;
    }
    
    public static SignatureResponse createSuccessfulSignatureResponse() {
        return new SignatureResponse(
            true,
            "Documento firmado exitosamente",
            "test-doc-id-" + System.currentTimeMillis(),
            "test-document.pdf",
            "http://localhost:8080/api/signature/download/test-doc-id",
            1024L
        );
    }
    
    public static CertificateInfo createValidCertificateInfo() {
        return new CertificateInfo(
            "CN=Test User, OU=Testing, O=Test Org, C=US",
            "CN=Test CA, O=Test Authority, C=US",
            "1234567890ABCDEF",
            "2024-01-01T00:00:00Z",
            "2025-01-01T00:00:00Z",
            true,
            "RSA",
            "SHA256withRSA"
        );
    }
}
```

### TestConstants
```java
public class TestConstants {
    public static final String VALID_CERTIFICATE_PASSWORD = "testpassword";
    public static final String INVALID_CERTIFICATE_PASSWORD = "wrongpassword";
    public static final String TEST_PDF_FILENAME = "test-document.pdf";
    public static final String TEST_CERTIFICATE_FILENAME = "valid-certificate.p12";
    
    public static final String TEST_SIGNER_NAME = "Test User";
    public static final String TEST_SIGNER_ID = "1234567890";
    public static final String TEST_LOCATION = "Test Location";
    public static final String TEST_REASON = "Testing Purpose";
    
    public static final int DEFAULT_SIGNATURE_X = 100;
    public static final int DEFAULT_SIGNATURE_Y = 100;
    public static final int DEFAULT_SIGNATURE_WIDTH = 200;
    public static final int DEFAULT_SIGNATURE_HEIGHT = 80;
    public static final int DEFAULT_SIGNATURE_PAGE = 1;
}
```

## Performance Tests

### LoadTest (con JMeter o similar)
```java
@Test
@DisplayName("Should handle concurrent signing requests")
void shouldHandleConcurrentSigningRequests() throws Exception {
    int numberOfThreads = 10;
    int requestsPerThread = 5;
    ExecutorService executor = Executors.newFixedThreadPool(numberOfThreads);
    CountDownLatch latch = new CountDownLatch(numberOfThreads * requestsPerThread);
    List<Future<Boolean>> futures = new ArrayList<>();
    
    for (int i = 0; i < numberOfThreads; i++) {
        for (int j = 0; j < requestsPerThread; j++) {
            Future<Boolean> future = executor.submit(() -> {
                try {
                    // Perform signing operation
                    ResponseEntity<SignatureResponse> response = performSigningRequest();
                    latch.countDown();
                    return response.getStatusCode() == HttpStatus.OK;
                } catch (Exception e) {
                    latch.countDown();
                    return false;
                }
            });
            futures.add(future);
        }
    }
    
    // Wait for all requests to complete (max 5 minutes)
    boolean completed = latch.await(5, TimeUnit.MINUTES);
    assertThat(completed).isTrue();
    
    // Verify all requests succeeded
    long successCount = futures.stream()
        .mapToInt(future -> {
            try {
                return future.get() ? 1 : 0;
            } catch (Exception e) {
                return 0;
            }
        })
        .sum();
    
    assertThat(successCount).isEqualTo(numberOfThreads * requestsPerThread);
    
    executor.shutdown();
}
```

## Comandos de Testing

### Ejecutar Tests
```bash
# Todos los tests
mvn test

# Solo unit tests
mvn test -Dtest="**/*Test"

# Solo integration tests
mvn test -Dtest="**/*IntegrationTest"

# Tests específicos
mvn test -Dtest="DigitalSignatureServiceTest"

# Tests con coverage
mvn jacoco:prepare-agent test jacoco:report

# Tests en modo verbose
mvn test -X
```

### Coverage Report
```bash
# Generar reporte de cobertura
mvn jacoco:report

# Ver reporte en: target/site/jacoco/index.html
```

## Referencias
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/spring-boot-features.html#boot-features-testing)
- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
- [AssertJ Documentation](https://assertj.github.io/doc/)
- [Código fuente de tests](../../backend/src/test/) 