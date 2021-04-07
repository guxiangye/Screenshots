//
//  NextViewController.m
//  Screenshots
//
//  Created by 相晔谷 on 2021/4/7.
//

#import "NextViewController.h"

@interface NextViewController ()

@property (nonatomic, strong) UITextField *tf;
@property (nonatomic, strong) VTSimplePlayer *player;
@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tf = [UITextField new];
    self.tf.enabled = NO;
    self.tf.textColor = [UIColor yellowColor];
    self.tf.font = [UIFont systemFontOfSize:17];
    self.tf.textAlignment = NSTextAlignmentCenter;
    self.tf.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 100, 100, 200, 45);
    self.tf.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:self.tf];
    
    
    NSArray *arr = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @"", @0, @""];
    CGFloat width = 16 * 20 / 3;
    CGFloat height = width;
    
    UIImageView *bg = [UIImageView new];
    bg.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 16 * 20 * 0.5, 200, 16 * 20, height * 4);
    [self.view addSubview:bg];
    
    for (int i = 0; i < 12; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:[NSString stringWithFormat:@"%@", arr[i]] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:34];
        btn.backgroundColor = [UIColor cyanColor];
        btn.frame = CGRectMake(width * (i % 3), height * (i / 3), width, height);
        btn.layer.borderColor = [UIColor greenColor].CGColor;
        btn.layer.borderWidth = 1;
        [btn addTarget:self action:@selector(input:) forControlEvents:UIControlEventTouchUpInside];
        [bg addSubview:btn];
    }
    
    UIImageView *bg2 = [UIImageView new];
    bg2.userInteractionEnabled = YES;
    bg2.frame = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 16 * 20 * 0.5, 200, 16 * 20, height * 4);
    [self.view addSubview:bg2];
    for (int i = 0; i < 12; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:[NSString stringWithFormat:@"%@", arr[i]] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:34];
        [btn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = CGRectMake(width * (i % 3), height * (i / 3), width, height);
        [btn addTarget:self action:@selector(input:) forControlEvents:UIControlEventTouchUpInside];
        [bg2 addSubview:btn];
    }
    
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/www/"];
    NSLog(@"===================> %@", dir);
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *toPath = [dir stringByAppendingPathComponent:@"keyboard"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:toPath error:nil];
    }
    
    UIImage *image = [self viewToImage:bg];
    bg.image = image;
    
    
    // 启动服务 webserver
    [self.webServer addGETHandlerForBasePath:@"/" directoryPath:dir indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
    [self.webServer startWithPort:10123 bonjourName:nil];
    
    // 设置生成视频的格式
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecTypeH264 withWidth:bg.frame.size.width andHeight:bg.frame.size.height];
    CEMovieMaker *movieMaker = [[CEMovieMaker alloc] initWithSettings:settings];
    
    @MTKit_Weakify(self)
    @MTKit_Weakify(bg)
    @MTKit_Weakify(image)
    [movieMaker createMovieFromImages:[@[image] copy] withCompletion:^(NSURL *fileURL){
        NSLog(@"%@", fileURL);
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if ([[NSFileManager defaultManager] createFileAtPath:toPath contents:data attributes:nil]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weak_self.player playURL:@"screenshot://keyboard.m3u8" name:@"keyboard" inView:weak_bg];
                // 设置原图片模糊
                bg.image = [weak_self filterWith:weak_image andRadius:30];
            });
        }
    }];
}

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

- (void)input:(UIButton *)sender {
    NSMutableString *input = [NSMutableString stringWithString:self.tf.text];
    [input appendString:sender.titleLabel.text];
    self.tf.text = input;
}

- (UIImage *)viewToImage:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0f);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
