//
//  ViewController.m
//  Screenshots
//
//  Created by 相晔谷 on 2021/4/6.
//

#import "ViewController.h"
#import "NextViewController.h"
#import <Screenshots.h>

@interface ViewController ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) VTSimplePlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *qrString = @"this is an about Screenshots demo.";
    UIImage *qrImg = [self createQRCodeWithUrl:qrString];
    
    UIImageView *imgView = [UIImageView new];
    [self.view addSubview:imgView];
    
    imgView.image = qrImg;
    imgView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 100, 300, 200, 200);
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"next" forState:UIControlStateNormal];
    btn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 40, 600, 80, 25);
    [btn addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    // 本地服务地址
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/www/"];
    NSLog(@"===================> %@", dir);
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *toPath = [dir stringByAppendingPathComponent:@"qrCode"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:toPath error:nil];
    }
    
    // 启动服务 webserver
    [self.webServer addGETHandlerForBasePath:@"/" directoryPath:dir indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
    [self.webServer startWithPort:10123 bonjourName:nil];
    
    // 设置生成视频的格式
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecTypeH264 withWidth:400. andHeight:400.];
    CEMovieMaker *movieMaker = [[CEMovieMaker alloc] initWithSettings:settings];
    
    @MTKit_Weakify(self)
    @MTKit_Weakify(imgView)
    @MTKit_Weakify(qrImg)
    [movieMaker createMovieFromImages:[@[qrImg] copy] withCompletion:^(NSURL *fileURL){
        NSLog(@"%@", fileURL);
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if ([[NSFileManager defaultManager] createFileAtPath:toPath contents:data attributes:nil]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weak_self.player playURL:@"screenshot://qrCode.m3u8" name:@"qrCode" inView:weak_imgView];
                // 设置原图片模糊
                imgView.image = [weak_self filterWith:weak_qrImg andRadius:5];
            });
        }
    }];
}

#pragma mark --- lazzy
- (GCDWebServer *)webServer {
    if (!_webServer) {
        _webServer = [[GCDWebServer alloc] init];
    }
    return _webServer;
}

- (VTSimplePlayer *)player {
    if (!_player) {
        _player = [[VTSimplePlayer alloc] init];
    }
    return _player;
}

#pragma mark --- dealloc 关闭服务器
- (void)dealloc {
    if (_webServer) {
        [_webServer stop];
        _webServer = nil;
    }
    if (_player) {
        [_player stop];
        _player = nil;
    }
}

- (void)next {
    NextViewController *next = [[NextViewController alloc] init];
    next.modalPresentationStyle = 0;
    [self presentViewController:next animated:YES completion:nil];
}

#pragma mark --- 生成二维码
- (UIImage *)createQRCodeWithUrl:(NSString *)url {
    // 1. 创建一个二维码滤镜实例(CIFilter)
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];

    // 2. 给滤镜添加数据
    NSString *string = url;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    // 使用KVC的方式给filter赋值
    [filter setValue:data forKeyPath:@"inputMessage"];

    // 3. 生成二维码
    CIImage *image = [filter outputImage];
    // 转成高清格式
    UIImage *qrcode = [self createNonInterpolatedUIImageFormCIImage:image withSize:200];

    return qrcode;
}
// 将二维码转成高清的格式
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {

    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));

    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
// 添加logo
- (UIImage *)drawImage:(UIImage *)newImage inImage:(UIImage *)sourceImage {
    CGSize imageSize; //画的背景 大小
    imageSize = [sourceImage size];
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    [sourceImage drawAtPoint:CGPointMake(0, 0)];
    //获得 图形上下文
    CGContextRef context=UIGraphicsGetCurrentContext();
    //画 自己想要画的内容(添加的图片)
    CGContextDrawPath(context, kCGPathStroke);
    // 注意logo的尺寸不要太大,否则可能无法识别
    CGRect rect = CGRectMake(imageSize.width / 2 - 25, imageSize.height / 2 - 25, 50, 50);
//    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);

    [newImage drawInRect:rect];

    //返回绘制的新图形
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark --- CIFilter进行模糊处理（高斯模糊）
- (UIImage *)filterWith:(UIImage *)image andRadius:(CGFloat)radius {
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    CIFilter *affineClampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    CGAffineTransform xform = CGAffineTransformMakeScale(1.0, 1.0);
    [affineClampFilter setValue:inputImage forKey:kCIInputImageKey];
    [affineClampFilter setValue:[NSValue valueWithBytes:&xform
                                               objCType:@encode(CGAffineTransform)]
                         forKey:@"inputTransform"];

    CIImage *extendedImage = [affineClampFilter valueForKey:kCIOutputImageKey];

    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:extendedImage forKey:kCIInputImageKey];
    [blurFilter setValue:@(radius) forKey:@"inputRadius"];

    CIImage *result = [blurFilter valueForKey:kCIOutputImageKey];
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ciContext createCGImage:result fromRect:inputImage.extent];

    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    return uiImage;
}

@end
