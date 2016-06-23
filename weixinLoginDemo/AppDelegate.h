//
//  AppDelegate.h
//  weixinLoginDemo
//
//  Created by 张国荣 on 16/6/20.
//  Copyright © 2016年 BateOrganization. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WXDelegate <NSObject>

-(void)loginSuccessByCode:(NSString *)code;
-(void)shareSuccessByCode:(int) code;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) id<WXDelegate> wxDelegate;
@end

