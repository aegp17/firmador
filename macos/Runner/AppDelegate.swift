import Cocoa
import FlutterMacOS
import Security
import Foundation
import PDFKit

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let flutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let cryptoChannel = FlutterMethodChannel(name: "com.firmador/crypto",
                                             binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    cryptoChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getCertificateInfo" {
        self.handleGetCertificateInfo(call: call, result: result)
      } else if call.method == "signPdf" {
        self.handleSignPdf(call: call, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    super.applicationDidFinishLaunching(notification)
  }
  
  private func handleGetCertificateInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let p12Path = args["p12Path"] as? String,
          let _ = args["password"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Argumentos 'p12Path' y 'password' son requeridos.", details: nil))
      return
    }

    // LOGS DE DEPURACIÓN
    print("DEBUG: p12Path: \(p12Path)")
    let fileExists = FileManager.default.fileExists(atPath: p12Path)
    print("DEBUG: file exists: \(fileExists)")
    if fileExists {
        let attr = try? FileManager.default.attributesOfItem(atPath: p12Path)
        print("DEBUG: file size: \(attr?[.size] ?? 0)")
    }

    do {
      let p12Data = try Data(contentsOf: URL(fileURLWithPath: p12Path))
      
      let options: [String: Any] = [kSecImportExportPassphrase as String: args["password"] as! String]
      
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

      // Extraer información básica del certificado usando Security framework
      guard (SecCertificateCopyData(finalCert) as Data?) != nil else {
        result(FlutterError(code: "CERT_DATA_ERROR", message: "No se pudo obtener los datos del certificado.", details: nil))
        return
      }
      
      // Obtener subject y otras propiedades básicas
      let subject = SecCertificateCopySubjectSummary(finalCert) as String? ?? "N/A"
      
      // Obtener fechas de validez usando Security framework
      var error: Unmanaged<CFError>?
      let keys: [CFString] = [kSecOIDX509V1ValidityNotBefore, kSecOIDX509V1ValidityNotAfter]
      guard let values = SecCertificateCopyValues(finalCert, keys as CFArray, &error) as? [String: Any] else {
        let resultDict: [String: Any] = [
          "subject": subject,
          "issuer": "N/A",
          "validFrom": 0,
          "validTo": 0,
          "isTrusted": false
        ]
        result(resultDict)
        return
      }
      
      // Extraer fechas de validez - convertir a milisegundos como Int
      var validFromTimestamp: Int = 0
      var validToTimestamp: Int = 0
      
      if let notBeforeDict = values[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
         let notBeforeValue = notBeforeDict[kSecPropertyKeyValue as String] {
        if CFGetTypeID(notBeforeValue as CFTypeRef) == CFDateGetTypeID() {
          let cfDate = notBeforeValue as! CFDate
          let timeIntervalSeconds = CFDateGetAbsoluteTime(cfDate) + kCFAbsoluteTimeIntervalSince1970
          validFromTimestamp = Int(timeIntervalSeconds * 1000) // Convert to milliseconds
        }
      }
      
      if let notAfterDict = values[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
         let notAfterValue = notAfterDict[kSecPropertyKeyValue as String] {
        if CFGetTypeID(notAfterValue as CFTypeRef) == CFDateGetTypeID() {
          let cfDate = notAfterValue as! CFDate
          let timeIntervalSeconds = CFDateGetAbsoluteTime(cfDate) + kCFAbsoluteTimeIntervalSince1970
          validToTimestamp = Int(timeIntervalSeconds * 1000) // Convert to milliseconds
        }
      }
      
      let resultDict: [String: Any] = [
          "subject": subject,
          "issuer": "N/A", // Simplificado - puede expandirse más tarde
          "validFrom": validFromTimestamp,
          "validTo": validToTimestamp,
          "isTrusted": true // Simplificado - validación real pendiente
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
    
    // Simulación básica para macOS - crear archivo firmado
    let originalUrl = URL(fileURLWithPath: pdfPath)
    let signedUrl = originalUrl.deletingLastPathComponent().appendingPathComponent(originalUrl.deletingPathExtension().lastPathComponent + "_signed.pdf")
    
    do {
      try FileManager.default.copyItem(at: originalUrl, to: signedUrl)
      result(signedUrl.path)
    } catch {
      result(FlutterError(code: "SAVE_ERROR", message: "No se pudo crear el PDF firmado.", details: error.localizedDescription))
    }
  }
}
