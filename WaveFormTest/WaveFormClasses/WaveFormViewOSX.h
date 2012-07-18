//
//  WaveFormView.h
//  CoreAudioTest
//
//  Created by Gyetván András on 6/25/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>
#import "WaveSampleProvider.h"
#import "WaveSampleProviderDelegate.h"

@interface WaveFormViewOSX : NSView<WaveSampleProviderDelegate>
{
	NSProgressIndicator *progress;
	CGPoint* sampleData;
	int sampleLength;
	WaveSampleProvider *wsp;	
	AVPlayer *player;
	float playProgress;
	NSString *infoString;
	NSString *timeString;
	NSColor *green;
	NSColor *gray;
	NSColor *lightgray;
	NSColor *darkgray;
	NSColor *white;
	NSColor *marker;
}

//- (void) openAudio:(NSString *)path;
- (void) openAudioURL:(NSURL *)url;

@end
