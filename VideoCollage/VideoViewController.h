//
//  ViewController.h
//  VideoCollage
//
//  Created by Dmitry Utenkov on 12.06.13.
//  Copyright (c) 2013 Video Collage company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton *collageButton;

- (IBAction)collageButtonPressed:(id)sender;

@end
