//
//  ViewController.m
//  weixinLoginDemo
//
//  Created by 张国荣 on 16/6/20.
//  Copyright © 2016年 BateOrganization. All rights reserved.
//

#import "ViewController.h"
#import "WXApi.h"
#import "AppDelegate.h"
//微信开发者ID
#define URL_APPID @"wx5efead4057f98bc0"
#define URL_SECRET @"8faed9acaf9579485bd2b18b4ba28365"
#import "AFNetworking.h"
#import "WeixinPayHelper.h"

@interface ViewController ()<WXDelegate>
{
    AppDelegate *appdelegate;
    WeixinPayHelper *helper;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
#pragma mark 微信登录
- (IBAction)weixinLoginAction:(id)sender {
    
    if ([WXApi isWXAppInstalled]) {
        SendAuthReq *req = [[SendAuthReq alloc]init];
        req.scope = @"snsapi_userinfo";
        req.openID = URL_APPID;
        req.state = @"1245";
        appdelegate = [UIApplication sharedApplication].delegate;
        appdelegate.wxDelegate = self;

        [WXApi sendReq:req];
    }else{
        //把微信登录的按钮隐藏掉。
    }
}
#pragma mark 微信登录回调。
-(void)loginSuccessByCode:(NSString *)code{
    NSLog(@"code %@",code);
    __weak typeof(*&self) weakSelf = self;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];//请求
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json",@"text/plain", nil];
    //通过 appid  secret 认证code . 来发送获取 access_token的请求
    [manager GET:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",URL_APPID,URL_SECRET,code] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
       
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {  //获得access_token，然后根据access_token获取用户信息请求。

        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"dic %@",dic);
        
        /*
         access_token	接口调用凭证
         expires_in	access_token接口调用凭证超时时间，单位（秒）
         refresh_token	用户刷新access_token
         openid	授权用户唯一标识
         scope	用户授权的作用域，使用逗号（,）分隔
         unionid	 当且仅当该移动应用已获得该用户的userinfo授权时，才会出现该字段
         */
        NSString* accessToken=[dic valueForKey:@"access_token"];
        NSString* openID=[dic valueForKey:@"openid"];
        [weakSelf requestUserInfoByToken:accessToken andOpenid:openID];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
     NSLog(@"error %@",error.localizedFailureReason);
    }];
    
}

-(void)requestUserInfoByToken:(NSString *)token andOpenid:(NSString *)openID{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",token,openID] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        //开发人员拿到相关微信用户信息后， 需要与后台对接，进行登录
        NSLog(@"login success dic  ==== %@",dic);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error %ld",(long)error.code);
    }];
}

#pragma mark 微信好友分享
/**
 *  微信分享对象说明
 *
 *  @param sender 
WXMediaMessage    多媒体内容分享
WXImageObject      多媒体消息中包含的图片数据对象
WXMusicObject      多媒体消息中包含的音乐数据对象
WXVideoObject      多媒体消息中包含的视频数据对象
WXWebpageObject    多媒体消息中包含的网页数据对象
WXAppExtendObject  返回一个WXAppExtendObject对象
WXEmoticonObject   多媒体消息中包含的表情数据对象
WXFileObject       多媒体消息中包含的文件数据对象
WXLocationObject   多媒体消息中包含的地理位置数据对象
WXTextObject       多媒体消息中包含的文本数据对象
 
 */
- (IBAction)weixinShareAction:(id)sender {
 [self isShareToPengyouquan:NO];
    
}

#pragma mark 微信朋友圈分享
- (IBAction)friendShareAction:(id)sender {
    
    [self isShareToPengyouquan:YES];
}
-(void)isShareToPengyouquan:(BOOL)isPengyouquan{
    /** 标题
     * @note 长度不能超过512字节
     */
    // @property (nonatomic, retain) NSString *title;
    /** 描述内容
     * @note 长度不能超过1K
     */
    //@property (nonatomic, retain) NSString *description;
    /** 缩略图数据
     * @note 大小不能超过32K
     */
    //  @property (nonatomic, retain) NSData   *thumbData;
    /**
     * @note 长度不能超过64字节
     */
    // @property (nonatomic, retain) NSString *mediaTagName;
    /**
     * 多媒体数据对象，可以为WXImageObject，WXMusicObject，WXVideoObject，WXWebpageObject等。
     */
    // @property (nonatomic, retain) id        mediaObject;
    
    /*! @brief 设置消息缩略图的方法
     *
     * @param image 缩略图
     * @note 大小不能超过32K
     */
    //- (void) setThumbImage:(UIImage *)image;
    //缩略图
    UIImage *image = [UIImage imageNamed:@"消息中心 icon"];
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = @"微信分享测试";
    message.description = @"微信分享测试----描述信息";
    //png图片压缩成data的方法，如果是jpg就要用 UIImageJPEGRepresentation
    message.thumbData = UIImagePNGRepresentation(image);
    [message setThumbImage:image];
    

    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = @"http://www.baidu.com";
    message.mediaObject = ext;
    message.mediaTagName = @"ISOFTEN_TAG_JUMP_SHOWRANK";
    
    SendMessageToWXReq *sentMsg = [[SendMessageToWXReq alloc]init];
    sentMsg.message = message;
    sentMsg.bText = NO;
    //选择发送到会话(WXSceneSession)或者朋友圈(WXSceneTimeline)
    if (isPengyouquan) {
        sentMsg.scene = WXSceneTimeline;  //分享到朋友圈
    }else{
        sentMsg.scene =  WXSceneSession;  //分享到会话。
    }
    
    //如果我们想要监听是否成功分享，我们就要去appdelegate里面 找到他的回调方法
    // -(void) onResp:(BaseResp*)resp .我们可以自定义一个代理方法，然后把分享的结果返回回来。
    appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    //添加对appdelgate的微信分享的代理
    appdelegate.wxDelegate = self;
    BOOL isSuccess = [WXApi sendReq:sentMsg];
    
    
    
    
}

#pragma mark 监听微信分享是否成功 delegate
-(void)shareSuccessByCode:(int)code{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"分享成功" message:[NSString stringWithFormat:@"reason : %d",code] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
}

#pragma mark 微信支付
- (IBAction)weixinPayAction:(id)sender {
    
    
    /**
     *  外界调用的微信支付方法
     *
     *  @param ordeNumber  系统下发订单号%100000000 得出的数字，确保唯一。
     *  @param myNumber    订单号  确保唯一
     *  @param price       价格
     付款流程:
     
     1. 获取 AccessToken
     2. 获取 genPackage
     3. 调起微信付款
     4. 在appdelegate 中的 onResp 监听 回调方法。 看是付款成功。
     
     回调代码参数说明：
     0  展示成功页面
     -1  可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等。
     -2  用户取消	无需处理。发生场景：用户不支付了，点击取消，返回APP。
     */

    helper = [[WeixinPayHelper alloc] init];
    [helper payProductWith:@"Test Product" andName:@"product number 1" andPrice:[NSString stringWithFormat:@"%d",1500]];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
