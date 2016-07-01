//
//  CommonUtil.h
//  WechatPayDemo
//
//  Created by Alvin on 3/22/14.
//  Copyright (c) 2014 Alvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommonUtil : NSObject

+ (NSString *)md5:(NSString *)input;

+ (NSString *)sha1:(NSString *)input;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;

+ (NSString *)obfuscate:(NSData *)string withKey:(NSString *)key;

+ (NSString*)encodeBase64String:(NSString * )input;

+ (NSString*)decodeBase64String:(NSString* )input;


@end
