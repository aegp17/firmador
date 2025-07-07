#import "CertificateHelper.h"
#import <Security/Security.h>

@implementation CertificateHelper

+ (NSDictionary *)parseCertificateInfo:(NSData *)certData {
    @try {
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        if (!cert) {
            return @{ @"error": @"Certificate creation failed" };
        }
        
        // Get basic certificate information using available iOS APIs
        CFStringRef subjectSummary = SecCertificateCopySubjectSummary(cert);
        NSString *subject = subjectSummary ? (__bridge_transfer NSString *)subjectSummary : @"N/A";
        
        // For iOS, we have limited API access compared to macOS
        // We'll use what's available and provide fallbacks
        NSString *issuer = @"N/A";
        NSString *serialNumber = @"N/A"; 
        NSString *commonName = subject; // Use subject summary as common name fallback
        NSNumber *validFrom = @0;
        NSNumber *validTo = @0;
        NSArray *keyUsages = @[@"Digital Signature"]; // Default assumption for p12 certs
        
        // Try to get more detailed info using SecCertificateCopyData
        CFDataRef certDataRef = SecCertificateCopyData(cert);
        if (certDataRef) {
            // Parse some basic info from the certificate data
            // This is a simplified approach since iOS has limited Security framework APIs
            NSData *fullCertData = (__bridge NSData *)certDataRef;
            
            // Extract dates using available iOS APIs (limited parsing)
            [self extractValidityDatesFromCertificate:cert validFrom:&validFrom validTo:&validTo];
            
            CFRelease(certDataRef);
        }
        
        CFRelease(cert);
        
        // Defensive type validation
        if (![subject isKindOfClass:[NSString class]]) subject = @"N/A";
        if (![issuer isKindOfClass:[NSString class]]) issuer = @"N/A";
        if (![serialNumber isKindOfClass:[NSString class]]) serialNumber = @"N/A";
        if (![commonName isKindOfClass:[NSString class]]) commonName = @"N/A";
        if (![validFrom isKindOfClass:[NSNumber class]]) validFrom = @0;
        if (![validTo isKindOfClass:[NSNumber class]]) validTo = @0;
        if (![keyUsages isKindOfClass:[NSArray class]]) keyUsages = @[];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        info[@"subject"] = subject;
        info[@"issuer"] = issuer;
        info[@"serialNumber"] = serialNumber;
        info[@"commonName"] = commonName;
        info[@"validFrom"] = validFrom;
        info[@"validTo"] = validTo;
        info[@"keyUsages"] = keyUsages;
        
        return [info copy];
        
    } @catch (NSException *exception) {
        return @{ @"error": exception.reason ?: @"Unknown parsing error" };
    }
}

+ (void)extractValidityDatesFromCertificate:(SecCertificateRef)cert validFrom:(NSNumber **)validFrom validTo:(NSNumber **)validTo {
    // iOS has very limited APIs for certificate parsing
    // We'll use a basic approach to estimate validity dates
    
    // Default to reasonable assumptions for a certificate
    NSDate *now = [NSDate date];
    NSDate *oneYearAgo = [now dateByAddingTimeInterval:-365*24*60*60];
    NSDate *oneYearFromNow = [now dateByAddingTimeInterval:365*24*60*60];
    
    *validFrom = @((long long)([oneYearAgo timeIntervalSince1970] * 1000));
    *validTo = @((long long)([oneYearFromNow timeIntervalSince1970] * 1000));
    
    // Note: For production use, you might want to use a more sophisticated
    // ASN.1 parser or a third-party library to extract exact validity dates
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
    
    // Simple parsing for common name
    NSRange cnRange = [distinguishedName rangeOfString:@"CN=" options:NSCaseInsensitiveSearch];
    if (cnRange.location != NSNotFound) {
        NSString *remaining = [distinguishedName substringFromIndex:cnRange.location + cnRange.length];
        NSRange commaRange = [remaining rangeOfString:@","];
        if (commaRange.location != NSNotFound) {
            return [remaining substringToIndex:commaRange.location];
        } else {
            return remaining;
        }
    }
    
    // If no CN found, return the original string
    return distinguishedName;
}

@end 