//
//  ViewController.m
//  WaveFormTestIOS
//
//  Created by Gyetván András on 7/11/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()

@end

@implementation ViewController
@synthesize wfv;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
	[self setWfv:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (void)dealloc {
	[wfv release];
	[super dealloc];
}
- (IBAction)loadAudio:(id)sender {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp3"];
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSURL *songURL = [NSURL fileURLWithPath:path];
		[wfv openAudioURL:songURL];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Audio !"
								   message: @"You should add a sample.mp3 file to the project before test it."
								  delegate: self
						 cancelButtonTitle: @"OK"
						 otherButtonTitles: nil];
		[alert show];
		[alert release]; 
	}
}


@end
