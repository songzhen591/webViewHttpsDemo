//
//  ViewController.m
//  webViewHttpsDemo
//
//  Created by 又土又木 on 16/6/15.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) UIWebView *webView;

@end

@implementation ViewController
{
    BOOL _Authenticated;
    NSURLRequest *_FailedRequest;
    NSURLSessionDataTask *task;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.webView];
}

- (UIWebView *)webView
{
    if (_webView) {
        return _webView;
    }
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.delegate = self;
//    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.ytuymu.com/course/aa2deadc-65c8-42ab-b639-c7e61c65ccbc.html"]]];
//    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.ytuymu.com/test.html"]]];
//    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.ytuymu.com/aec/v220/book.html?bookid=000bac54-f86b-4a8b-af28-0200078c00dd&itemid=6e2a28d2-3080-4667-9415-0e4606383dda&token=11d83772-d872-4bfd-a569-9d720c35e713&source=0"]]];
//    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.ytuymu.com/aec/test.html"]]];
    
    return _webView;
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request  navigationType:(UIWebViewNavigationType)navigationType {
    
    
//    BOOL result = _Authenticated;
    if (!_Authenticated) {
    
        [webView stopLoading];
    
        _FailedRequest = request;
//        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//        [urlConnection start];
    
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.HTTPAdditionalHeaders = @{@"Access-Control-Allow-Origin" : @"*", @"Access-Control-Allow-Headers" : @"Content-Type"};
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        [[urlSession dataTaskWithRequest:request] resume];
    
        return NO;
    }
    return YES;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        
        if (!_Authenticated) {
//            SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
//            SecKeyRef serverKey = SecTrustCopyPublicKey(serverTrust);
            
            //获取der格式CA证书路径
            NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ytuymu" ofType:@"cer"];
            
            // 提取二进制内容
            NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
            
            // 根据二进制内容提取证书信息
            SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
            
            // 形成钥匙链
            //        NSArray *trustedCertificates = @[CFBridgingRelease(certificate)];
            NSArray *chain = @[(__bridge id)certificate];
            
            CFArrayRef caChainArrayRef = CFBridgingRetain(chain);
            
            //取出服务器证书
            SecTrustRef trust = challenge.protectionSpace.serverTrust;
            SecTrustResultType trustResult = 0;
            
            //设置为我们自有的CA证书钥匙连
            int err = SecTrustSetAnchorCertificates(trust, caChainArrayRef);
            if (err == noErr) {
                
                // 用CA证书验证服务器证书
                err = SecTrustEvaluate(trust, &trustResult);
                
                BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed)||(trustResult == kSecTrustResultConfirm) || (trustResult == kSecTrustResultUnspecified));
                
                NSLog(@"trustResult = %d", trustResult);
                
//                if (trusted) {
//                    NSLog(@"验证成功");
                    //验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
                    NSURLCredential *cre = [NSURLCredential credentialForTrust:trust];
                    [challenge.sender useCredential:cre forAuthenticationChallenge:challenge];
                    completionHandler(NSURLSessionAuthChallengeUseCredential, cre);
                    
//                }else{
//                    [challenge.sender cancelAuthenticationChallenge:challenge];
//                    NSLog(@"验证失败");
//                }
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    _Authenticated = YES;
    [task cancel];
    [_webView loadRequest:_FailedRequest];
    completionHandler(NSURLSessionResponseAllow);
}

//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//{
//    if (challenge.previousFailureCount == 0) {
////        _authed = YES;
//        //获取der格式CA证书路径
//        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ytuymu" ofType:@"cer"];
//
//        // 提取二进制内容
//        NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
//
//        // 根据二进制内容提取证书信息
//        SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
//
//        // 形成钥匙链
////        NSArray *trustedCertificates = @[CFBridgingRelease(certificate)];
//        NSArray *trustedCertificates = @[(__bridge id)certificate];
//
//        CFArrayRef caChainArrayRef = CFBridgingRetain(trustedCertificates);
//
//        //取出服务器证书
//        SecTrustRef trust = challenge.protectionSpace.serverTrust;
//        SecTrustResultType trustResult = 0;
//
//        //设置为我们自有的CA证书钥匙连
//        int err = SecTrustSetAnchorCertificates(trust, caChainArrayRef);
//        if (err == noErr) {
//
//            // 用CA证书验证服务器证书
//            err = SecTrustEvaluate(trust, &trustResult);
//
//            BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed)||(trustResult == kSecTrustResultConfirm) || (trustResult == kSecTrustResultUnspecified));
//            NSLog(@"trusted = %d", trustResult);
//
////            if (trusted) {
//                // 验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
//                NSURLCredential *cre = [NSURLCredential credentialForTrust:trust];
//                [challenge.sender useCredential:cre forAuthenticationChallenge:challenge];
////            }
//        }
////        CFRelease(trust);
////        SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)trustedCertificates);
////
////        OSStatus status = SecTrustEvaluate(trust, &trustResult);
////
//////        DLog(@"%d", status);
////
////        if (status == errSecSuccess && (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified)) {
////
////            //验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
////            NSURLCredential *cre = [NSURLCredential credentialForTrust:trust];
////            [challenge.sender useCredential:cre forAuthenticationChallenge:challenge];
////        }else{
////            //验证失败，取消这次验证流程
////            [challenge.sender cancelAuthenticationChallenge:challenge];
////        }
//    }
//}
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    _Authenticated = YES;
//    [self.webView loadRequest:_FailedRequest];
//    [connection cancel];
//}


@end
