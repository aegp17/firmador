import UIKit
import Flutter
import Security
import Foundation
import PDFKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let cryptoChannel = FlutterMethodChannel(name: "com.firmador/crypto",
                                              binaryMessenger: controller.binaryMessenger)
    
    cryptoChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getCertificateInfo" {
        self.handleGetCertificateInfo(call: call, result: result)
      } else if call.method == "signPdf" {
        self.handleSignPdf(call: call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleGetCertificateInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let p12Path = args["p12Path"] as? String,
          let password = args["password"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Argumentos 'p12Path' y 'password' son requeridos.", details: nil))
      return
    }

    // LOGS DE DEPURACIÓN
    print("DEBUG: p12Path: \(p12Path)")
    print("DEBUG: password empty: \(password.isEmpty)")
    print("DEBUG: password as Data: \(Array(password.utf8))")
    let fileExists = FileManager.default.fileExists(atPath: p12Path)
    print("DEBUG: file exists: \(fileExists)")
    if fileExists {
        let attr = try? FileManager.default.attributesOfItem(atPath: p12Path)
        print("DEBUG: file size: \(attr?[.size] ?? 0)")
    }

    do {
      let p12Data = try Data(contentsOf: URL(fileURLWithPath: p12Path))
      
      let options: [String: Any] = [kSecImportExportPassphrase as String: password]
      
      var items: CFArray?
      let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
      print("DEBUG: SecPKCS12Import status: \(status)")
      
      guard status == errSecSuccess else {
        if status == errSecAuthFailed {
          result(FlutterError(code: "AUTH_FAILED", message: "Contraseña incorrecta.", details: nil))
        } else {
          result(FlutterError(code: "PKCS12_IMPORT_FAILED", message: "No se pudo leer el archivo del certificado. Código de error: \(status)", details: nil))
        }
        return
      }
      
      guard let importedItems = items as? [[String: Any]],
            let identityDict = importedItems.first else {
        result(FlutterError(code: "IDENTITY_NOT_FOUND", message: "No se encontró una identidad en el archivo P12.", details: nil))
        return
      }
      let identity = identityDict[kSecImportItemIdentity as String] as! SecIdentity
      
      var certificate: SecCertificate?
      SecIdentityCopyCertificate(identity, &certificate)
      
      guard let finalCert = certificate else {
        result(FlutterError(code: "CERT_NOT_FOUND", message: "No se pudo extraer el certificado de la identidad.", details: nil))
        return
      }

      // --- Validación de cadena de confianza ---
      // CA y subCA como PEM
      let caPem = """
-----BEGIN CERTIFICATE-----
MIIGVzCCBD+gAwIBAgIRAKysQ/WAVQpFyoJS0Z+8nKYwDQYJKoZIhvcNAQELBQAw
gcQxCzAJBgNVBAYTAkVDMRswGQYDVQQKDBJGSVJNQVNFR1VSQSBTLkEuUy4xMDAu
BgNVBAsMJ0VOVElEQUQgREUgQ0VSVElGSUNBQ0lPTiBERSBJTkZPUk1BQ0lPTjET
MBEGA1UECAwKVFVOR1VSQUhVQTFAMD4GA1UEAww3QVVUT1JJREFEIERFIENFUlRJ
RklDQUNJT04gUkFJWiBDQS0xIEZJUk1BU0VHVVJBIFMuQS5TLjEPMA0GA1UEBwwG
QU1CQVRPMB4XDTIzMTIyNzE4MzYyM1oXDTQzMTIyNzE5MzU1M1owgcQxCzAJBgNV
BAYTAkVDMRswGQYDVQQKDBJGSVJNQVNFR1VSQSBTLkEuUy4xMDAuBgNVBAsMJ0VO
VElEQUQgREUgQ0VSVElGSUNBQ0lPTiBERSBJTkZPUk1BQ0lPTjETMBEGA1UECAwK
VFVOR1VSQUhVQTFAMD4GA1UEAww3QVVUT1JJREFEIERFIENFUlRJRklDQUNJT04g
UkFJWiBDQS0xIEZJUk1BU0VHVVJBIFMuQS5TLjEPMA0GA1UEBwwGQU1CQVRPMIIC
IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtceNQnldCN8dlA+2XA6rE3YS
d8eHtVDzM8+ykDettZmPMBsu+gGZAvpvSDl+W3naonsjXSPTYeFWhNNglds4F/AT
ztwi1aNyOoCrrSchlanhwsQJGiKUv4Zt1dXDKDLYqU3lV0vvUGp7FULldUdqppit
EpQP5KT6ytAalT4QwcIWx6MjLbZtgh6LVG/B3ZCmQNwEF5SH13ptsJGiH4HxLBZx
REx5n/In0EsbluGaT8QRBcLbiNj2Zi9sVXkAhyt9V6wN6loNWG8SRBbxkmj21EZ3
kkqgWAfMKVw9eX9nt6JTsVarGXZWqxnVAhvfknSbvLM+SQ/iNTIuxzqNnKt9zU6v
eD6MryjA5OBz2SaLkbmjvpPZytzB45qeDdNx20JN3/BZy/gvq/JILMihH3zb7QdU
wfuiQRqJ3GRevY4P5GnaVmU2y+IpkG7mABt9YFIcWxjzrjAotORjzRkglnruAXBn
VJVW8jXGTtduRj/uRKIUIa5uP5P7/BbafMyin7UU3AoeOMQM4ZBmMl4wj3fDS2EQ
vj8Kn13W0k27eHQ5H3ixPXMeLo+OCR9f6m3DocLXedpYGNihWoNmY3OOhc9SG+DB
5LRa8YeZcrnkbTgDRwq6hP9koj8Jhiyq3dNdqB6LN0RONXd4G4GMGGThknvP8Xre
3gw/yGYTOl5RmUbQaesCAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
FgQUE3QO85otcvosx6bXbt7CII960DMwDgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3
DQEBCwUAA4ICAQCt+Ok91nC5rhPFJaq8mqKCWKuESx6bxcTUB8h7V+1LFDND6FVF
tHwHZmWsRgwEWAufY9rVexISH52+9bBOOl27Ej0YJwIYHRDc5hxZX04AXh80XMKd
vmtpXp7knsstIaJbCbUnyViRnTUdUi3Jcnkg8RrJbT7KHlVjgIilw/z/ecg5RumF
QeU34d0XueBlL6wwmS+pI8CYjq1AyrrHyMo38UKkt03z1xW1QxtuAME+99Jmjcae
sDSslXZgvllP0qy0hHiidEcrijWdVP3fAlpF6eu6aQoRngjpPhfV5Ljch4JNtpDs
iz4oTOTC1NAyVdfW38CuDwgrIwj10WHhF/D2O64HfwjS1TSkeECYOW4M4QH/d3W8
+eY+Jqa1KvdvBJEeVRMVgmur4pq4bR3iYmUhmFsXe+H7YrAzOX6dzOytlJnJE5i1
oq3hw4OORFHlZuvneS030e81r6Gm88912hMoWhM3WjtnE3crs2O6a8Qs74qFUVRR
krxe1baZZWsnzgcPWPbNa6FsngDO3iCwmPhmhPkpcHk+0Xk6usLyBv7qJEa+Xtub
0T63e5g+pJZguXzBitqJkAAS8CcPguUkABjlN2k/mFbBD3ZcDjUI8PJxWpkwGMFS
MSA4T/+OJBJwR2CNTcxfhjpNJMAL/wkFBU38AoM+HuxE/r9RdNSyHKXUSg==
-----END CERTIFICATE-----
"""
      let subCaPem = """
-----BEGIN CERTIFICATE-----
MIIG2jCCBMKgAwIBAgIRANENxvt2cGDs48lXyJas6kEwDQYJKoZIhvcNAQELBQAw
gcQxCzAJBgNVBAYTAkVDMRswGQYDVQQKDBJGSVJNQVNFR1VSQSBTLkEuUy4xMDAu
BgNVBAsMJ0VOVElEQUQgREUgQ0VSVElGSUNBQ0lPTiBERSBJTkZPUk1BQ0lPTjET
MBEGA1UECAwKVFVOR1VSQUhVQTFAMD4GA1UEAww3QVVUT1JJREFEIERFIENFUlRJ
RklDQUNJT04gUkFJWiBDQS0xIEZJUk1BU0VHVVJBIFMuQS5TLjEPMA0GA1UEBwwG
QU1CQVRPMB4XDTI0MDIyMTE4MjcxMFoXDTQzMTIyMDE5MjYxMlowgcIxCzAJBgNV
BAYTAkVDMRswGQYDVQQKDBJGSVJNQVNFR1VSQSBTLkEuUy4xMDAuBgNVBAsMJ0VO
VElEQUQgREUgQ0VSVElGSUNBQ0lPTiBERSBJTkZPUk1BQ0lPTjETMBEGA1UECAwK
VFVOR1VSQUhVQTE+MDwGA1UEAww1QVVUT1JJREFEIERFIENFUlRJRklDQUNJT04g
U1VCQ0EtMSBGSVJNQVNFR1VSQSBTLkEuUy4xDzANBgNVBAcMBkFNQkFUTzCCAiIw
DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALPVPM8X7l/IlZT+rGnN8y2MuSpy
QiENKHy+sAtrOgpE6JaA9S6L4M4KlsL5va2isWl9+Q8ogp2K8rjpHyjNGB2jpPd6
3HaAJ0K/zZ6KqzdRIX35EtS0X1IgUSFkssCwG8AIKpSWvkjoWpGlN1TlTl0U6IBL
B282DmkHGHm4Fah9C8m7uHkZakeAvOt6S+oKgxEqcopkZHvqs/C/NVn1u/JSblDV
7tBrDga9b1ejvkErokczE1f/vDSMYO2hJ+3LHtHnQEiKUOP0k1CDcDmP/KglXXH5
KVdoMOrBgkwPqijNnIRabguohcMvrndR8nUKCbpuciapmrSuevF4ZLUFavZyk/Wg
iBbJiKtpYtpZZok4N01oJhAqB1zN4jJ/LuOnKmH0EVe0swvpl+TjJ2sptSW9qyF+
tx781Z0eEJoVcj1vuPOowjzpVEkCcmXgUQWtoiXyyWJOEjvebhB2RPiXXIjORU0I
utlDyEIxwedI0iwlSM8E9uTM9/kgqXDsvvrDNY/nt3Jv1Z0rQpfgvIoqYeb8Q3Ll
NDV2q1ro1u76u7lpg4/P3Y9v2rp8l5hO2S8C6DReBv0q1lC6WF2gQTfKPtUtu1Y+
7ZMQM85jzCu4lBLLQE1jCnkeGwZ31SQPLAYYor40MtgqlMj5gCBRrWWVJGVH7tad
GYgqmV5zC/u+QUbRAgMBAAGjgcYwgcMwEgYDVR0TAQH/BAgwBgEB/wIBADAfBgNV
HSMEGDAWgBQTdA7zmi1y+izHptdu3sIgj3rQMzAdBgNVHQ4EFgQUE0aTaAmu1ySH
M0VjJnffrF5eilEwDgYDVR0PAQH/BAQDAgGGMF0GA1UdHwRWMFQwUqBQoE6GTGh0
dHA6Ly9jYS1jcmwuZmlybWFzZWd1cmFlYy5jb20vY3JsLzc1MjliOTVjLTk4Yzkt
NGJlYy04NGRlLTU1Y2Y0YjhhNzAwZi5jcmwwDQYJKoZIhvcNAQELBQADggIBAKUy
39H37hPR0eAa2fNcjKZyDG56eTI3x+7KQ7n96jge8o39SqH1/ZZz5tNm1O4gDFVa
IIrU1pis9+eagx4VtoMy7oL/weUPaje5fuOe7yT0iT2JpnfAJb+7OjXxEc/31G1k
G/dWONFWGZ4rr9tbP8e1xx4QbkE6a2RU5iJKsrXCrk6K/fr19re7Fjr9hzWdXXww
Hc9erG7LdEH26Su9Qk4hRKH4Cbfk++ZiOFpehvK1tJ9n+3nW1ujJVPAP/BvJ3ftx
oVWSWNH8oUa6gDxrtJDt4dHPcp9wJgGYYR5ee8XV+JPcxGTkngkkVmmQ9D1KCWlF
GQ7MWqjGWkCexKFepU4YNzZ5PrSIPxkG5vxoSw07KxLP6GPaUtfWFjN+IC8a/SKX
gwHdmPJJaVrKUFvT7/jh3RI/uG/YhRMe0uM5GAyJChQ3Phkn/TA2AhB31z5Lrnq1
G6X7qav/+iOUqoOYfMKB8tlWp4/gz20bx5W0XtTjg2jrzOrkOC8gD4oHnuN83BV9
vsUAwHViEZsFaYgJtcpA+LLf/4OjmKAlPbnxPUBrJTNV0j2s+MH1FrLRZz7pZpgt
qJLMf/aDjjubQ6taPTcHjxGhcTAgmL1J5/7/lVCYMir43FAPUchbq5k1BdsZsSsh
qPKU+bM0H9Btm86PyPnoWC6P23Rxky+LXFPT6+4B
-----END CERTIFICATE-----
"""
      func certificateFromPEM(_ pem: String) -> SecCertificate? {
        let lines = pem.components(separatedBy: "\n").filter { !$0.contains("CERTIFICATE-") && !$0.isEmpty }
        let base64 = lines.joined()
        guard let data = Data(base64Encoded: base64) else { return nil }
        return SecCertificateCreateWithData(nil, data as CFData)
      }
      guard let caCert = certificateFromPEM(caPem), let subCaCert = certificateFromPEM(subCaPem) else {
        result(FlutterError(code: "CA_PARSE_ERROR", message: "No se pudo parsear la CA o subCA.", details: nil))
        return
      }
      let policy = SecPolicyCreateBasicX509()
      let certs: [SecCertificate] = [finalCert, subCaCert, caCert]
      var trust: SecTrust?
      let trustStatus = SecTrustCreateWithCertificates(certs as AnyObject, policy, &trust)
      if trustStatus != errSecSuccess || trust == nil {
        result(FlutterError(code: "TRUST_CREATE_ERROR", message: "No se pudo crear el objeto de confianza.", details: nil))
        return
      }
      var error: CFError?
      let isTrusted = SecTrustEvaluateWithError(trust!, &error)
      // Permitir continuar aunque no sea confiable
      // if !isTrusted {
      //   result(FlutterError(code: "CHAIN_NOT_TRUSTED", message: "El certificado no es de una CA confiable.", details: error?.localizedDescription))
      //   return
      // }
      // --- Fin validación de cadena de confianza ---

      // Usar CertificateHelper para obtener todos los valores relevantes del certificado
      guard let certData = SecCertificateCopyData(finalCert) as Data? else {
        result(FlutterError(code: "CERT_DATA_ERROR", message: "No se pudo obtener los datos del certificado.", details: nil))
        return
      }
      let certInfoObj = CertificateHelper.parseCertificateInfo(certData)
      var certInfo: [String: Any] = [:]
      if let dict = certInfoObj as? [String: Any] {
        certInfo = dict
      } else if let str = certInfoObj as? String {
        print("⚠️ Recibido String: \(str)")
        if let data = str.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          certInfo = json
        } else {
          certInfo = ["error": "No se pudo convertir el string en JSON"]
        }
      } else if let data = certInfoObj as? Data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        certInfo = json
      } else {
        let tipo = String(describing: type(of: certInfoObj))
        certInfo = ["error": "Tipo de objeto no manejado: \(tipo)"]
      }
      let resultDict: [String: Any] = [
          "subject": certInfo["subject"] ?? "N/A",
          "issuer": certInfo["issuer"] ?? "N/A",
          "validFrom": certInfo["validFrom"] ?? 0,
          "validTo": certInfo["validTo"] ?? 0,
          "serialNumber": certInfo["serialNumber"] ?? "N/A",
          "commonName": certInfo["commonName"] ?? "N/A",
          "keyUsages": certInfo["keyUsages"] ?? [],
          "isTrusted": isTrusted
      ]
      result(resultDict)
      
    } catch {
      result(FlutterError(code: "FILE_READ_ERROR", message: "No se pudo leer el archivo en la ruta: \(p12Path)", details: error.localizedDescription))
    }
  }

  private func handleSignPdf(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let pdfPath = args["pdfPath"] as? String,
          let p12Path = args["p12Path"] as? String,
          let _ = args["password"] as? String,
          let page = args["page"] as? Int,
          let x = args["x"] as? Double,
          let y = args["y"] as? Double else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Faltan argumentos para firmar el PDF.", details: nil))
      return
    }
    print("[NATIVO] Firmando PDF: \(pdfPath) con certificado: \(p12Path) en página: \(page) posición: (\(x), \(y))")
    // --- Firma visible con PDFKit ---
    guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
      result(FlutterError(code: "PDFKIT_ERROR", message: "No se pudo abrir el PDF con PDFKit.", details: nil))
      return
    }
    guard let pdfPage = pdfDocument.page(at: page) else {
      result(FlutterError(code: "PAGE_ERROR", message: "No se pudo obtener la página indicada del PDF.", details: nil))
      return
    }
    // Datos de la estampilla
    let signerName: String
    if let subject = args["subject"] as? String, !subject.isEmpty {
      signerName = "Firmante: \(subject)"
    } else {
      signerName = "Firmante: Desconocido"
    }
    let issuer = args["issuer"] as? String ?? "N/A"
    let validFromStr: String = {
      if let s = args["validFrom"] as? String, let date = ISO8601DateFormatter().date(from: s) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
      } else { return "N/A" }
    }()
    let validToStr: String = {
      if let s = args["validTo"] as? String, let date = ISO8601DateFormatter().date(from: s) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
      } else { return "N/A" }
    }()
    let stampSize = CGSize(width: 110, height: 44) // Más pequeña
    // Crear imagen de la estampilla
    let renderer = UIGraphicsImageRenderer(size: stampSize)
    let stampImage = renderer.image { ctx in
      // Fondo blanco con borde azul
      let rect = CGRect(origin: .zero, size: stampSize)
      ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.95).cgColor)
      ctx.cgContext.fill(rect)
      ctx.cgContext.setStrokeColor(UIColor.systemBlue.cgColor)
      ctx.cgContext.setLineWidth(2)
      ctx.cgContext.stroke(rect)
      // Icono
      if #available(iOS 13.0, *) {
        let checkmark = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        checkmark?.draw(in: CGRect(x: 4, y: 4, width: 18, height: 18))
      } else {
        // Fallback for iOS 12: draw a simple circle with checkmark
        ctx.cgContext.setFillColor(UIColor.systemBlue.cgColor)
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 18, height: 18))
        circlePath.fill()
        
        // Draw checkmark manually
        ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
        ctx.cgContext.setLineWidth(2)
        ctx.cgContext.move(to: CGPoint(x: 8, y: 12))
        ctx.cgContext.addLine(to: CGPoint(x: 11, y: 15))
        ctx.cgContext.addLine(to: CGPoint(x: 18, y: 8))
        ctx.cgContext.strokePath()
      }
      // Texto
      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .left
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 9),
        .foregroundColor: UIColor.black,
        .paragraphStyle: paragraph
      ]
      let attrs2: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 8),
        .foregroundColor: UIColor.darkGray,
        .paragraphStyle: paragraph
      ]
      (signerName).draw(in: CGRect(x: 26, y: 2, width: 80, height: 12), withAttributes: attrs)
      ("CA: \(issuer)").draw(in: CGRect(x: 4, y: 20, width: 102, height: 10), withAttributes: attrs2)
      ("Desde: \(validFromStr)").draw(in: CGRect(x: 4, y: 30, width: 52, height: 10), withAttributes: attrs2)
      ("Hasta: \(validToStr)").draw(in: CGRect(x: 56, y: 30, width: 52, height: 10), withAttributes: attrs2)
    }
    // Insertar la imagen en la página PDF usando la subclase
    let pdfBounds = pdfPage.bounds(for: .mediaBox)
    let stampRect = CGRect(x: x, y: pdfBounds.height - y - stampSize.height, width: stampSize.width, height: stampSize.height)
    let annotation = CustomImageAnnotation(bounds: stampRect, image: stampImage)
    pdfPage.addAnnotation(annotation)
    // Guardar el PDF firmado
    let originalUrl = URL(fileURLWithPath: pdfPath)
    let signedUrl = originalUrl.deletingLastPathComponent().appendingPathComponent(originalUrl.deletingPathExtension().lastPathComponent + "_signed.pdf")
    if pdfDocument.write(to: signedUrl) {
      result(signedUrl.path)
    } else {
      result(FlutterError(code: "SAVE_ERROR", message: "No se pudo guardar el PDF firmado.", details: nil))
    }
    // --- FIRMA DIGITAL REAL (PKCS#7) ---
    // Aquí es donde debe integrarse la lógica de firma digital real.
    // Pasos sugeridos:
    // 1. Extraer la clave privada y el certificado del archivo .p12 usando SecPKCS12Import.
    // 2. Usar una librería de firma digital (como objective-pdf-signature, OpenSSL, o un SDK comercial como PSPDFKit) para:
    //    a) Crear un campo de firma en el PDF.
    //    b) Generar la firma PKCS#7 usando la clave privada.
    //    c) Insertar la firma digital en el PDF.
    // 3. Guardar el PDF firmado y devolver la ruta.
    // NOTA: PDFKit NO soporta firma digital nativa, por lo que es necesario integrar una librería externa.
    // Ejemplo de integración: https://github.com/ubiqueinnovation/objective-pdf-signature
    // Por ahora, solo se inserta la firma visible (estampilla). La firma digital real se debe implementar aquí.
  }
}

// Subclase para anotación de imagen personalizada
class CustomImageAnnotation: PDFAnnotation {
    let image: UIImage
    init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context)
        image.draw(in: self.bounds)
        UIGraphicsPopContext()
    }
}