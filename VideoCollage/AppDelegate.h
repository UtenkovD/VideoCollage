//
//  AppDelegate.h
//  VideoCollage
//
//  Created by Dmitry Utenkov on 12.06.13.
//  Copyright (c) 2013 Video Collage company. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) VideoViewController *viewController;

@end
