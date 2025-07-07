#import <Foundation/Foundation.h>

@interface CertificateHelper : NSObject

+ (NSDictionary *)parseCertificateInfo:(NSData *)certData;
+ (NSString *)extractSubjectName:(NSData *)certData;
+ (NSString *)extractIssuerName:(NSData *)certData;
+ (NSArray *)extractKeyUsages:(NSData *)certData;
+ (NSString *)extractSerialNumber:(NSData *)certData;
+ (NSString *)extractCommonName:(NSString *)distinguishedName;

@end
