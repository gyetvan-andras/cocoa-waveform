//
//  ViewController.h
//  WaveFormTestIOS
//
//  Created by Gyetván András on 7/11/12.
// This software is free.
//

#import <UIKit/UIKit.h>
#import "WaveFormViewIOS.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController<MPMediaPickerControllerDelegate>
@property (retain, nonatomic) IBOutlet WaveFormViewIOS *wfv;

- (IBAction)loadAudio:(id)sender;
@end
