//
//  WeixinPayHelper.m
//  weixinLoginDemo
//
//  Created by 张国荣 on 16/7/1.
//  Copyright © 2016年 BateOrganization. All rights reserved.
//

#import "WeixinPayHelper.h"
#import "CommonUtil.h"
#import "Constant.h"

#define ISOFTEN_WECHARPAY_URL            @"xxxx"

@interface WeixinPayHelper()

@end

@implementation WeixinPayHelper

NSString *AccessTokenKey = @"access_token";
NSString *PrePayIdKey = @"prepayid";
NSString *errcodeKey = @"errcode";
NSString *errmsgKey = @"errmsg";
NSString *expiresInKey = @"expires_in";

/**
 *  微信开放平台申请得到的 appid, 需要同时添加在 URL schema
 */
NSString * const WXAppId = @"app id";
/**
 * 微信开放平台和商户约定的支付密钥
 *
 * 注意：不能hardcode在客户端，建议genSign这个过程由服务器端完成
 */
NSString * const WXAppKey = @"appkey";

/**
 * 微信开放平台和商户约定的密钥
 *
 * 注意：不能hardcode在客户端，建议genSign这个过程由服务器端完成
 */
NSString * const WXAppSecret = @"app Secret";

/**
 * 微信开放平台和商户约定的支付密钥
 *
 * 注意：不能hardcode在客户端，建议genSign这个过程由服务器端完成
 */
NSString * const WXPartnerKey = @"秘钥、 放服务器的，这儿方便演示";
/**
 *  微信公众平台商户模块生成的ID
 */
NSString * const WXPartnerId = @"商户id";


+ (instancetype)shareInstance
{
    static WeixinPayHelper *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[WeixinPayHelper  alloc] init];
    });
    return sharedClient;
}
/**
 *  外界调起微信下单的方法
 *
 *  @param ordeNumber 订单号 ，由服务器下发、经过处理的  生成genPackage 需要用到
 *  @param myNumber   订单号 ，由服务器下发  生成genPackage 需要用到
 *  @param price      商品价格   生成genPackage 需要用到
 
 
 
 */
- (void)payProductWith:(NSString *)ordeNumber andName:(NSString *)myNumber andPrice:(NSString *)price{
    self.orderId = ordeNumber;
    self.orderPrice = price;
    self.orderAllId = myNumber;
    [self getAccessToken];
}

#pragma mark - 生成各种参数

#pragma mark 时间戳 生成
- (NSString *)genTimeStamp
{
    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
}

/**
 * 注意：商户系统内部的订单号,32个字符内、可包含字母,确保在商户系统唯一
 */
- (NSString *)genNonceStr
{
    return [CommonUtil md5:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
}

/**
 * 建议 traceid 字段包含用户信息及订单信息，方便后续对订单状态的查询和跟踪
 */
- (NSString *)genTraceId
{
    return [NSString stringWithFormat:@"crestxu_%@", [self genTimeStamp]];
}

- (NSString *)genOutTradNo
{
    return [CommonUtil md5:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
}

#pragma mark genPackage 这个应该是服务器完成。 在这儿方便演示。
- (NSString *)genPackage
{
    // 构造参数列表
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"WX" forKey:@"bank_type"];
    [params setObject:[NSString stringWithFormat:@"拾裳%@订单", self.orderAllId] forKey:@"body"];
    [params setObject:@"1" forKey:@"fee_type"];
    [params setObject:@"UTF-8" forKey:@"input_charset"];
    [params setObject:ISOFTEN_WECHARPAY_URL forKey:@"notify_url"];
    [params setObject:[self genOutTradNo] forKey:@"out_trade_no"];
    [params setObject:WXPartnerId forKey:@"partner"];
    [params setObject:[CommonUtil getIPAddress:YES] forKey:@"spbill_create_ip"];
    [params setObject:self.orderPrice forKey:@"total_fee"];    // 1 =＝ ¥0.01
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[[NSURL URLWithString:@"https://www.sizzee.com"] absoluteURL]];
    NSHTTPCookie *cookie;
    NSMutableArray* arr=[NSMutableArray array];
    for (cookie in cookies) {
        if (![cookie.name isEqualToString:@"app_code"]) {
            NSString* str=[NSString stringWithFormat:@"%@||%@",cookie.name,cookie.value];
            [arr addObject:str];
        }
    }
    
    
    NSString* aa=[arr componentsJoinedByString:@"||"];
    [params setObject:[NSString stringWithFormat:@"%@||%@||%@",self.orderId,[CommonUtil md5:[NSString stringWithFormat:@"1219929601fef54y3d5wsxf5yu55t5g5d5e35yujki%@",self.orderId]],aa] forKey:@"attach"];
    
    NSArray *keys = [params allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    // 生成 packageSign
    NSMutableString *package = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        [package appendString:key];
        [package appendString:@"="];
        [package appendString:[params objectForKey:key]];
        [package appendString:@"&"];
    }
    
    [package appendString:@"key="];
    [package appendString:WXPartnerKey]; // 注意:不能hardcode在客户端,建议genPackage这个过程都由服务器端完成
    
    // 进行md5摘要前,params内容为原始内容,未经过url encode处理
    NSString *packageSign = [[CommonUtil md5:[package copy]] uppercaseString];
    package = nil;
    
    // 生成 packageParamsString
    NSString *value = nil;
    package = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        [package appendString:key];
        [package appendString:@"="];
        value = [params objectForKey:key];
        
        // 对所有键值对中的 value 进行 urlencode 转码
        value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)value, nil, (CFStringRef)@"!*'&=();:@+$,/?%#[]", kCFStringEncodingUTF8));
        
        [package appendString:value];
        [package appendString:@"&"];
    }
    NSString *packageParamsString = [package substringWithRange:NSMakeRange(0, package.length - 1)];
    
    NSString *result = [NSString stringWithFormat:@"%@&sign=%@", packageParamsString, packageSign];
    
    
    
    return result;
}

- (NSString *)genSign:(NSDictionary *)signParams
{
    // 排序
    NSArray *keys = [signParams allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    // 生成
    NSMutableString *sign = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        [sign appendString:key];
        [sign appendString:@"="];
        [sign appendString:[signParams objectForKey:key]];
        [sign appendString:@"&"];
    }
    NSString *signString = [[sign copy] substringWithRange:NSMakeRange(0, sign.length - 1)];
    
    NSString *result = [CommonUtil sha1:signString];
    
    return result;
}

- (NSMutableDictionary *)getProductArgs
{
    self.timeStamp = [self genTimeStamp];
    self.nonceStr = [self genNonceStr]; // traceId 由开发者自定义，可用于订单的查询与跟踪，建议根据支付用户信息生成此id
    self.traceId = [self genTraceId];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:WXAppId forKey:@"appid"];
    [params setObject:WXAppKey forKey:@"appkey"];
    [params setObject:self.timeStamp forKey:@"noncestr"];
    [params setObject:self.timeStamp forKey:@"timestamp"];
    [params setObject:self.traceId forKey:@"traceid"];
    [params setObject:[self genPackage] forKey:@"package"];
    [params setObject:[self genSign:params] forKey:@"app_signature"];
    [params setObject:@"sha1" forKey:@"sign_method"];
    
    NSError *error = nil;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error: &error];
    
    return params;
}

#pragma mark - 主体流程 - 获取 accessToken ， 然后调用再拿着accessToken调用微信的支付接口。
- (void)getAccessToken
{
    //字段
    NSString *getAccessTokenUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%@&secret=%@", WXAppId, WXAppSecret];

    self.request = [AFHTTPSessionManager manager];
    
    
    __weak WeixinPayHelper *weakSelf = self;
    self.request.requestSerializer = [AFJSONRequestSerializer serializer];//请求
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
    self.request.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json",@"text/plain", nil];

    [self.request POST:getAccessTokenUrl parameters:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions                           error:&error];
        if (error) {
            [weakSelf showAlertWithTitle:@"错误" msg:@"获取 AccessToken 失败"];
            return;
        }
        NSString *accessToken = dict[AccessTokenKey];
        if (accessToken) {
            __strong WeixinPayHelper *strongSelf = weakSelf;
            [strongSelf getPrepayId:accessToken];
        } else {
            NSString *strMsg = [NSString stringWithFormat:@"errcode: %@, errmsg:%@", dict[errcodeKey], dict[errmsgKey]];
            [weakSelf showAlertWithTitle:@"错误" msg:strMsg];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakSelf showAlertWithTitle:@"错误" msg:@"获取 AccessToken 失败"];

    }];
    
}

#pragma mark 根据accessToken 获取 PrePayID . 然后进行下单。

- (void)getPrepayId:(NSString *)accessToken
{
    
    NSString *getPrepayIdUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/pay/genprepay?access_token=%@", accessToken];

    NSMutableDictionary *postData = [self getProductArgs];
    __weak WeixinPayHelper *weakSelf = self;
    
    self.request = [AFHTTPSessionManager manager];
    self.request.requestSerializer = [AFJSONRequestSerializer serializer];//请求
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
    self.request.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json",@"text/plain", nil];

    [self.request POST:getPrepayIdUrl parameters:postData progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions  error:&error];
        if (error) {
            [weakSelf showAlertWithTitle:@"错误" msg:@"获取 PrePayId 失败"];
            return;
        }
        
        NSString *prePayId = dict[PrePayIdKey];
        if (prePayId) {
            // 调起微信支付
            PayReq *request   = [[PayReq alloc] init];
            request.partnerId = WXPartnerId;
            request.prepayId  = prePayId;
            request.package   = @"Sign=WXPay";      // 文档为 `Request.package = _package;` , 但如果填写上面生成的 `package` 将不能支付成功
            request.nonceStr  = weakSelf.nonceStr;
            request.timeStamp = [weakSelf.timeStamp longLongValue];
            
            // 构造参数列表
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setObject:WXAppId forKey:@"appid"];
            [params setObject:WXAppKey forKey:@"appkey"];
            [params setObject:request.nonceStr forKey:@"noncestr"];
            [params setObject:request.package forKey:@"package"];
            [params setObject:request.partnerId forKey:@"partnerid"];
            [params setObject:request.prepayId forKey:@"prepayid"];
            [params setObject:weakSelf.timeStamp forKey:@"timestamp"];
            request.sign = [weakSelf genSign:params];
            
            // 在支付之前，如果应用没有注册到微信，应该先调用 [WXApi registerApp:appId] 将应用注册到微信
            [WXApi sendReq:request];
            
        } else {
            NSString *strMsg = [NSString stringWithFormat:@"errcode: %@, errmsg:%@", dict[errcodeKey], dict[errmsgKey]];
            [weakSelf showAlertWithTitle:@"错误" msg:strMsg];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         [weakSelf showAlertWithTitle:@"错误" msg:@"获取 PrePayId 失败"];
    }];
   
}

#pragma mark - Alert

- (void)showAlertWithTitle:(NSString *)title msg:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message: msg delegate: self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];

}
@end
