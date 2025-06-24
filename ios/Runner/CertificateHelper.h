#import <Foundation/Foundation.h>

@interface CertificateHelper : NSObject

+ (id)parseCertificateInfo:(NSData *)certData;

@end
