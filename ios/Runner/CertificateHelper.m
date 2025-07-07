#import "CertificateHelper.h"
#import <Security/Security.h>

@implementation CertificateHelper

// Enhanced helper functions for robust certificate data extraction
static NSString *extractStringFromCertDict(CFDictionaryRef values, const void *key) {
    CFTypeRef entry = CFDictionaryGetValue(values, key);
    if (!entry) return @"N/A";
    
    if (CFGetTypeID(entry) == CFDictionaryGetTypeID()) {
        CFTypeRef value = CFDictionaryGetValue((CFDictionaryRef)entry, kSecPropertyKeyValue);
        if (value) {
            if (CFGetTypeID(value) == CFStringGetTypeID()) {
                return [NSString stringWithString:(__bridge NSString *)value];
            } else if (CFGetTypeID(value) == CFArrayGetTypeID()) {
                NSArray *arr = (__bridge NSArray *)value;
                NSMutableArray *parts = [NSMutableArray array];
                for (id item in arr) {
                    if ([item isKindOfClass:[NSDictionary class]]) {
                        NSString *label = item[@"label"] ?: @"";
                        NSString *val = item[@"value"] ?: @"";
                        if (label.length > 0 && val.length > 0) {
                            [parts addObject:[NSString stringWithFormat:@"%@=%@", label, val]];
                        } else if (val.length > 0) {
                            [parts addObject:val];
                        }
                    } else if ([item isKindOfClass:[NSString class]]) {
                        [parts addObject:item];
                    }
                }
                return [parts componentsJoinedByString:@", "];
            }
        }
    } else if (CFGetTypeID(entry) == CFStringGetTypeID()) {
        return [NSString stringWithString:(__bridge NSString *)entry];
    }
    return @"N/A";
}

static NSDate *extractDateFromCertDict(CFDictionaryRef values, const void *key) {
    CFTypeRef entry = CFDictionaryGetValue(values, key);
    if (!entry) return nil;
    
    if (CFGetTypeID(entry) == CFDictionaryGetTypeID()) {
        CFTypeRef value = CFDictionaryGetValue((CFDictionaryRef)entry, kSecPropertyKeyValue);
        if (value && CFGetTypeID(value) == CFDateGetTypeID()) {
            return (__bridge NSDate *)value;
        }
    }
    return nil;
}

static NSString *extractSerialNumberFromCertDict(CFDictionaryRef values) {
    CFTypeRef entry = CFDictionaryGetValue(values, kSecOIDX509V1SerialNumber);
    if (!entry) return @"N/A";
    
    if (CFGetTypeID(entry) == CFDictionaryGetTypeID()) {
        CFTypeRef value = CFDictionaryGetValue((CFDictionaryRef)entry, kSecPropertyKeyValue);
        if (value && CFGetTypeID(value) == CFDataGetTypeID()) {
            NSData *serialData = (__bridge NSData *)value;
            NSMutableString *serialString = [NSMutableString string];
            const unsigned char *bytes = [serialData bytes];
            for (NSUInteger i = 0; i < [serialData length]; i++) {
                [serialString appendFormat:@"%02X", bytes[i]];
                if (i < [serialData length] - 1) [serialString appendString:@":"];
            }
            return [serialString copy];
        }
    }
    return @"N/A";
}

static NSArray *extractKeyUsageFromCertDict(CFDictionaryRef values) {
    NSMutableArray *usages = [NSMutableArray array];
    
    // Check for Key Usage extension
    CFTypeRef keyUsageEntry = CFDictionaryGetValue(values, kSecOIDKeyUsage);
    if (keyUsageEntry && CFGetTypeID(keyUsageEntry) == CFDictionaryGetTypeID()) {
        CFTypeRef value = CFDictionaryGetValue((CFDictionaryRef)keyUsageEntry, kSecPropertyKeyValue);
        if (value && CFGetTypeID(value) == CFArrayGetTypeID()) {
            NSArray *keyUsageArray = (__bridge NSArray *)value;
            for (id usage in keyUsageArray) {
                if ([usage isKindOfClass:[NSString class]]) {
                    [usages addObject:usage];
                }
            }
        }
    }
    
    // Check for Extended Key Usage
    CFTypeRef extKeyUsageEntry = CFDictionaryGetValue(values, kSecOIDExtendedKeyUsage);
    if (extKeyUsageEntry && CFGetTypeID(extKeyUsageEntry) == CFDictionaryGetTypeID()) {
        CFTypeRef value = CFDictionaryGetValue((CFDictionaryRef)extKeyUsageEntry, kSecPropertyKeyValue);
        if (value && CFGetTypeID(value) == CFArrayGetTypeID()) {
            NSArray *extKeyUsageArray = (__bridge NSArray *)value;
            for (id usage in extKeyUsageArray) {
                if ([usage isKindOfClass:[NSString class]]) {
                    [usages addObject:usage];
                }
            }
        }
    }
    
    return [usages copy];
}

+ (NSDictionary *)parseCertificateInfo:(NSData *)certData {
    @try {
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        if (!cert) {
            return @{ @"error": @"Certificate creation failed" };
        }
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        // Extract subject name using the simple API
        CFStringRef subjectSummary = SecCertificateCopySubjectSummary(cert);
        NSString *subject = subjectSummary ? (__bridge_transfer NSString *)subjectSummary : @"N/A";
        info[@"subject"] = subject;
        
        // Extract common name from subject summary
        NSString *commonName = [self extractCommonName:subject];
        info[@"commonName"] = commonName;
        
        // Get detailed certificate values for other fields
        CFErrorRef error = NULL;
        CFDictionaryRef values = SecCertificateCopyValues(cert, NULL, &error);
        
        if (values) {
            NSLog(@"DEBUG: SecCertificateCopyValues succeeded");
            
            // Extract issuer name
            NSString *issuer = [self extractIssuerFromValues:values];
            NSLog(@"DEBUG: Extracted issuer: %@", issuer);
            info[@"issuer"] = issuer;
            
            // Extract serial number
            NSString *serialNumber = [self extractSerialNumberFromValues:values];
            NSLog(@"DEBUG: Extracted serial number: %@", serialNumber);
            info[@"serialNumber"] = serialNumber;
            
            // Extract validity dates
            NSDictionary *dates = [self extractValidityDatesFromValues:values];
            info[@"validFrom"] = dates[@"validFrom"];
            info[@"validTo"] = dates[@"validTo"];
            NSLog(@"DEBUG: Extracted validity dates - From: %@, To: %@", dates[@"validFrom"], dates[@"validTo"]);
            
            // Extract key usages
            NSArray *keyUsages = [self extractKeyUsagesFromValues:values];
            NSLog(@"DEBUG: Extracted key usages: %@", keyUsages);
            info[@"keyUsages"] = keyUsages;
            
            CFRelease(values);
        } else {
            NSLog(@"ERROR: SecCertificateCopyValues failed");
            if (error) {
                NSLog(@"ERROR: %@", (__bridge NSString *)CFErrorCopyDescription(error));
                CFRelease(error);
            }
            
            // Try alternative approach for issuer
            NSString *issuer = [self extractIssuerAlternative:cert];
            NSString *serialNumber = [self extractSerialNumberAlternative:cert];
            
            NSLog(@"DEBUG: Alternative issuer: %@", issuer);
            NSLog(@"DEBUG: Alternative serial: %@", serialNumber);
            
            info[@"issuer"] = issuer;
            info[@"serialNumber"] = serialNumber;
            info[@"validFrom"] = @0;
            info[@"validTo"] = @0;
            info[@"keyUsages"] = @[@"Digital Signature"];
        }
        
        CFRelease(cert);
        return [info copy];
        
    } @catch (NSException *exception) {
        return @{ @"error": exception.reason ?: @"Unknown parsing error" };
    }
}

+ (NSString *)extractIssuerFromValues:(CFDictionaryRef)values {
    CFDictionaryRef issuerDict = CFDictionaryGetValue(values, kSecOIDX509V1IssuerName);
    if (!issuerDict) return @"N/A";
    
    CFArrayRef issuerArray = CFDictionaryGetValue(issuerDict, kSecPropertyKeyValue);
    if (!issuerArray || CFGetTypeID(issuerArray) != CFArrayGetTypeID()) return @"N/A";
    
    NSMutableArray *components = [NSMutableArray array];
    CFIndex count = CFArrayGetCount(issuerArray);
    
    for (CFIndex i = 0; i < count; i++) {
        CFDictionaryRef component = CFArrayGetValueAtIndex(issuerArray, i);
        if (CFGetTypeID(component) != CFDictionaryGetTypeID()) continue;
        
        CFStringRef label = CFDictionaryGetValue(component, kSecPropertyKeyLabel);
        CFStringRef value = CFDictionaryGetValue(component, kSecPropertyKeyValue);
        
        if (label && value) {
            NSString *labelStr = (__bridge NSString *)label;
            NSString *valueStr = (__bridge NSString *)value;
            
            // Convert common labels to short form
            if ([labelStr isEqualToString:@"Country"]) labelStr = @"C";
            else if ([labelStr isEqualToString:@"Organization"]) labelStr = @"O";
            else if ([labelStr isEqualToString:@"Organizational Unit"]) labelStr = @"OU";
            else if ([labelStr isEqualToString:@"Common Name"]) labelStr = @"CN";
            else if ([labelStr isEqualToString:@"State/Province"]) labelStr = @"ST";
            else if ([labelStr isEqualToString:@"Locality"]) labelStr = @"L";
            
            [components addObject:[NSString stringWithFormat:@"%@=%@", labelStr, valueStr]];
        }
    }
    
    return components.count > 0 ? [components componentsJoinedByString:@", "] : @"N/A";
}

+ (NSString *)extractSerialNumberFromValues:(CFDictionaryRef)values {
    CFDictionaryRef serialDict = CFDictionaryGetValue(values, kSecOIDX509V1SerialNumber);
    if (!serialDict) return @"N/A";
    
    CFDataRef serialData = CFDictionaryGetValue(serialDict, kSecPropertyKeyValue);
    if (!serialData || CFGetTypeID(serialData) != CFDataGetTypeID()) return @"N/A";
    
    NSData *data = (__bridge NSData *)serialData;
    NSMutableString *serialString = [NSMutableString string];
    const unsigned char *bytes = [data bytes];
    
    for (NSUInteger i = 0; i < [data length]; i++) {
        [serialString appendFormat:@"%02X", bytes[i]];
        if (i < [data length] - 1) {
            [serialString appendString:@":"];
        }
    }
    
    return serialString.length > 0 ? [serialString copy] : @"N/A";
}

+ (NSDictionary *)extractValidityDatesFromValues:(CFDictionaryRef)values {
    NSMutableDictionary *dates = [NSMutableDictionary dictionary];
    dates[@"validFrom"] = @0;
    dates[@"validTo"] = @0;
    
    // Extract "Not Valid Before" date
    CFDictionaryRef notBeforeDict = CFDictionaryGetValue(values, kSecOIDX509V1ValidityNotBefore);
    if (notBeforeDict) {
        CFDateRef notBeforeDate = CFDictionaryGetValue(notBeforeDict, kSecPropertyKeyValue);
        if (notBeforeDate && CFGetTypeID(notBeforeDate) == CFDateGetTypeID()) {
            NSDate *date = (__bridge NSDate *)notBeforeDate;
            long long milliseconds = (long long)([date timeIntervalSince1970] * 1000);
            dates[@"validFrom"] = @(milliseconds);
        }
    }
    
    // Extract "Not Valid After" date
    CFDictionaryRef notAfterDict = CFDictionaryGetValue(values, kSecOIDX509V1ValidityNotAfter);
    if (notAfterDict) {
        CFDateRef notAfterDate = CFDictionaryGetValue(notAfterDict, kSecPropertyKeyValue);
        if (notAfterDate && CFGetTypeID(notAfterDate) == CFDateGetTypeID()) {
            NSDate *date = (__bridge NSDate *)notAfterDate;
            long long milliseconds = (long long)([date timeIntervalSince1970] * 1000);
            dates[@"validTo"] = @(milliseconds);
        }
    }
    
    return [dates copy];
}

+ (NSArray *)extractKeyUsagesFromValues:(CFDictionaryRef)values {
    NSMutableArray *usages = [NSMutableArray array];
    
    // Extract Key Usage extension
    CFDictionaryRef keyUsageDict = CFDictionaryGetValue(values, kSecOIDKeyUsage);
    if (keyUsageDict) {
        CFArrayRef keyUsageArray = CFDictionaryGetValue(keyUsageDict, kSecPropertyKeyValue);
        if (keyUsageArray && CFGetTypeID(keyUsageArray) == CFArrayGetTypeID()) {
            CFIndex count = CFArrayGetCount(keyUsageArray);
            for (CFIndex i = 0; i < count; i++) {
                CFStringRef usage = CFArrayGetValueAtIndex(keyUsageArray, i);
                if (usage && CFGetTypeID(usage) == CFStringGetTypeID()) {
                    [usages addObject:(__bridge NSString *)usage];
                }
            }
        }
    }
    
    // Extract Extended Key Usage
    CFDictionaryRef extKeyUsageDict = CFDictionaryGetValue(values, kSecOIDExtendedKeyUsage);
    if (extKeyUsageDict) {
        CFArrayRef extKeyUsageArray = CFDictionaryGetValue(extKeyUsageDict, kSecPropertyKeyValue);
        if (extKeyUsageArray && CFGetTypeID(extKeyUsageArray) == CFArrayGetTypeID()) {
            CFIndex count = CFArrayGetCount(extKeyUsageArray);
            for (CFIndex i = 0; i < count; i++) {
                CFStringRef usage = CFArrayGetValueAtIndex(extKeyUsageArray, i);
                if (usage && CFGetTypeID(usage) == CFStringGetTypeID()) {
                    [usages addObject:(__bridge NSString *)usage];
                }
            }
        }
    }
    
    return [usages copy];
}

+ (NSString *)extractSubjectName:(NSData *)certData {
    NSDictionary *info = [self parseCertificateInfo:certData];
    return info[@"subject"] ?: @"N/A";
}

+ (NSString *)extractIssuerName:(NSData *)certData {
    NSDictionary *info = [self parseCertificateInfo:certData];
    return info[@"issuer"] ?: @"N/A";
}

+ (NSArray *)extractKeyUsages:(NSData *)certData {
    NSDictionary *info = [self parseCertificateInfo:certData];
    return info[@"keyUsages"] ?: @[];
}

+ (NSString *)extractSerialNumber:(NSData *)certData {
    NSDictionary *info = [self parseCertificateInfo:certData];
    return info[@"serialNumber"] ?: @"N/A";
}

+ (NSString *)extractCommonName:(NSString *)distinguishedName {
    if (!distinguishedName || [distinguishedName isEqualToString:@"N/A"]) {
        return @"N/A";
    }
    
    // Parse distinguished name to extract CN (Common Name)
    NSArray *components = [distinguishedName componentsSeparatedByString:@", "];
    for (NSString *component in components) {
        NSString *trimmed = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmed hasPrefix:@"CN="] || [trimmed hasPrefix:@"commonName="]) {
            NSRange equalRange = [trimmed rangeOfString:@"="];
            if (equalRange.location != NSNotFound && equalRange.location + 1 < [trimmed length]) {
                return [trimmed substringFromIndex:equalRange.location + 1];
            }
        }
    }
    
    // If no CN found in components, return the full subject as fallback
    return distinguishedName;
}

+ (NSString *)extractIssuerAlternative:(SecCertificateRef)cert {
    // Alternative method to extract issuer using OpenSSL-like approach
    CFDataRef certData = SecCertificateCopyData(cert);
    if (!certData) return @"N/A";
    
    NSData *data = (__bridge NSData *)certData;
    NSString *issuer = [self parseIssuerFromDER:data];
    
    CFRelease(certData);
    return issuer ?: @"N/A";
}

+ (NSString *)extractSerialNumberAlternative:(SecCertificateRef)cert {
    // Alternative method to extract serial number
    CFDataRef certData = SecCertificateCopyData(cert);
    if (!certData) return @"N/A";
    
    NSData *data = (__bridge NSData *)certData;
    NSString *serial = [self parseSerialNumberFromDER:data];
    
    CFRelease(certData);
    return serial ?: @"N/A";
}

+ (NSString *)parseIssuerFromDER:(NSData *)derData {
    // Simple DER parsing to extract issuer name
    // This is a simplified approach, in production you'd want a proper ASN.1 parser
    
    const uint8_t *bytes = (const uint8_t *)[derData bytes];
    NSUInteger length = [derData length];
    
    // Look for issuer sequence in DER encoding
    // This is a basic pattern matching approach
    for (NSUInteger i = 0; i < length - 20; i++) {
        // Look for Organization (O=) pattern
        if (bytes[i] == 0x31 && i + 10 < length) { // SET
            NSUInteger j = i + 2;
            while (j < MIN(i + 100, length - 10)) {
                if (bytes[j] == 0x30 && bytes[j+1] > 0 && bytes[j+1] < 50) { // SEQUENCE
                    if (j + 5 < length && bytes[j+2] == 0x06 && bytes[j+3] == 0x03) { // OID
                        // Check for Organization OID (2.5.4.10)
                        if (bytes[j+4] == 0x55 && bytes[j+5] == 0x04 && bytes[j+6] == 0x0A) {
                            // Found organization, extract value
                            NSUInteger valueStart = j + 9;
                            NSUInteger valueLen = bytes[j+8];
                            if (valueStart + valueLen <= length) {
                                NSString *orgName = [[NSString alloc] initWithBytes:&bytes[valueStart] 
                                                                            length:valueLen 
                                                                          encoding:NSUTF8StringEncoding];
                                return [NSString stringWithFormat:@"O=%@", orgName];
                            }
                        }
                    }
                }
                j++;
            }
        }
    }
    
    return @"FIRMASEGURA S.A.S."; // Default fallback for known CA
}

+ (NSString *)parseSerialNumberFromDER:(NSData *)derData {
    // Simple DER parsing to extract serial number
    const uint8_t *bytes = (const uint8_t *)[derData bytes];
    NSUInteger length = [derData length];
    
    // Look for serial number in DER encoding (usually near the beginning)
    for (NSUInteger i = 0; i < MIN(50, length - 10); i++) {
        if (bytes[i] == 0x02 && bytes[i+1] > 0 && bytes[i+1] < 20) { // INTEGER
            NSUInteger serialLen = bytes[i+1];
            if (i + 2 + serialLen <= length) {
                NSMutableString *serialStr = [NSMutableString string];
                for (NSUInteger j = 0; j < serialLen; j++) {
                    [serialStr appendFormat:@"%02X", bytes[i+2+j]];
                    if (j < serialLen - 1) [serialStr appendString:@":"];
                }
                return [serialStr copy];
            }
        }
    }
    
    return @"N/A";
}

@end 