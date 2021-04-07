//
//  VTSimplePlayer.h
//  VTAntiScreenCapture_Example
//
//  Created by Vincent on 2018/12/31.
//  Copyright © 2018 mightyme@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VTSimplePlayer : NSObject

- (void)playURL:(NSString *)url name:(NSString *)name inView:(UIView *)container;
- (void)resume;
- (void)pause;
- (void)stop;

@end
