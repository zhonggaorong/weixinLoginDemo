//
//  WeixinPayHelper.h
//  weixinLoginDemo
//
//  Created by 张国荣 on 16/7/1.
//  Copyright © 2016年 BateOrganization. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"
#import "AFNetworking.h"
/**
 *  微信支付工具类
 */
@interface WeixinPayHelper : NSObject
@property (nonatomic, strong) AFHTTPSessionManager *request;
@property (nonatomic, copy) NSString *timeStamp;
@property (nonatomic, copy) NSString *nonceStr;
@property (nonatomic, copy) NSString *traceId;
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) NSString *orderPrice;
@property (nonatomic, copy) NSString *orderAllId;
+ (instancetype)shareInstance;


/**
 *  外界调用的微信支付方法
 *
 *  @param ordeNumber  系统下发订单号%100000000 得出的数字，确保唯一。
 *  @param myNumber    订单号  确保唯一
 *  @param price       价格
 付款流程:
 
  1. 获取 AccessToken
  2. 获取 PrepayId 、 包含参数拼接，签名、genPackage等
  3. 调起微信付款
  4. 在appdelegate 中的 onResp 监听 回调方法。 看是付款成功。
 
 回调代码参数说明：
 0  展示成功页面
 -1  可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等。
 -2  用户取消	无需处理。发生场景：用户不支付了，点击取消，返回APP。
 */
- (void)payProductWith:(NSString*)ordeNumber andName:(NSString*)myNumber andPrice:(NSString*)price;

@end
