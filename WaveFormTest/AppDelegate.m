//
//  AppDelegate.m
//  WaveFormTest
//
//  Created by Gyetván András on 6/28/12.
// This software is free.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize wfv = _wfv;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (IBAction)loadAudioFile:(id)sender {
	NSArray *fileTypes = [NSArray arrayWithObjects: @"AIFF", @"aif", @"aiff", @"aifc", @"wav", @"WAV",@"mp3", nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:NO];
	[oPanel setAllowedFileTypes:fileTypes];
    [oPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
		if(result == NSFileHandlingPanelOKButton) {
			if(oPanel.URLs.count == 1) {
				NSURL *url = nil;
				url = [oPanel.URLs objectAtIndex:0];
				[_wfv openAudioURL:url];
			}
		};
	}];

}
@end
