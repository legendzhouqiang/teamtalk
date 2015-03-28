//
//  TTHttpsRequest.h
//  TeamTalk
//
//  Created by Michael Scofield on 2015-01-29.
//  Copyright (c) 2015 Michael Hu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTHttpsRequest : NSObject
+ (SecIdentityRef)identityWithTrust;

+ (SecIdentityRef)identityWithCert;

+ (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust fromPKCS12Data:(NSData *)inPKCS12Data;

+ (BOOL)identity:(SecIdentityRef *)outIdentity andCertificate:(SecCertificateRef*)outCert fromPKCS12Data:(NSData *)inPKCS12Data;

@end
@interface opURLProtocal : NSURLProtocol
{
    NSURLConnection *connection;
    NSMutableData *proRespData;
}
@end
