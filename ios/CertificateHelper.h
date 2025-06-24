#import <Foundation/Foundation.h>

@interface CertificateHelper : NSObject

+ (NSString *)parseCertificateInfo:(NSData *)certData;

@end
