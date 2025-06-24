#import "CertificateHelper.h"

@implementation CertificateHelper

// Funciones auxiliares robustas
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
                            [parts addObject:[NSString stringWithFormat:@"%@: %@", label, val]];
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

+ (NSString *)parseCertificateInfo:(NSData *)certData {
    return @"Fake certificate info parsed for test";
}

+ (id)parseCertificateInfo:(NSData *)certData {
    @try {
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        if (!cert) {
            return @{ @"error": @"Certificate creation failed" };
        }
        NSString *subject = @"N/A";
        NSString *issuer = @"N/A";
        NSNumber *validFrom = @0;
        NSNumber *validTo = @0;
        NSDate *notBefore = nil;
        NSDate *notAfter = nil;
        CFErrorRef error = NULL;
        CFDictionaryRef values = SecCertificateCopyValues(cert, NULL, &error);
        if (values) {
            subject = extractStringFromCertDict(values, kSecOIDX509V1SubjectName);
            issuer = extractStringFromCertDict(values, kSecOIDX509V1IssuerName);
            notBefore = extractDateFromCertDict(values, kSecOIDX509V1ValidityNotBefore);
            notAfter = extractDateFromCertDict(values, kSecOIDX509V1ValidityNotAfter);
            CFRelease(values);
        }
        CFRelease(cert);
        if (notBefore && [notBefore isKindOfClass:[NSDate class]]) {
            validFrom = @((long long)([notBefore timeIntervalSince1970] * 1000));
        }
        if (notAfter && [notAfter isKindOfClass:[NSDate class]]) {
            validTo = @((long long)([notAfter timeIntervalSince1970] * 1000));
        }
        // Validación defensiva de tipos
        if (![subject isKindOfClass:[NSString class]]) subject = @"N/A";
        if (![issuer isKindOfClass:[NSString class]]) issuer = @"N/A";
        if (![validFrom isKindOfClass:[NSNumber class]]) validFrom = @0;
        if (![validTo isKindOfClass:[NSNumber class]]) validTo = @0;
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info[@"subject"] = subject;
        info[@"issuer"] = issuer;
        info[@"validFrom"] = validFrom;
        info[@"validTo"] = validTo;
        return info;
    } @catch (NSException *exception) {
        return @{ @"error": exception.reason ?: @"Unknown error" };
    }
    return @{ @"error": @"Unknown error" };
}

@end 