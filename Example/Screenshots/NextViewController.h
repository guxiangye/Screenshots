//
//  NextViewController.h
//  Screenshots
//
//  Created by 相晔谷 on 2021/4/7.
//

#import <UIKit/UIKit.h>
#import <Screenshots.h>


/**
 强/弱引用
 */
#ifndef MTKit_Weakify
#if DEBUG
#if __has_feature(objc_arc)
#define MTKit_Weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define MTKit_Weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define MTKit_Weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define MTKit_Weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef MTKit_Strongify
#if DEBUG
#if __has_feature(objc_arc)
#define MTKit_Strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define MTKit_Strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define MTKit_Strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define MTKit_Strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NextViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
