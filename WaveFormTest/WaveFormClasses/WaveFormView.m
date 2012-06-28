//
//  WaveFormView.m
//  CoreAudioTest
//
//  Created by Gyetván András on 6/25/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import "WaveFormView.h"

@interface WaveFormView (Private)
- (void) initView;
- (void) drawRoundRect:(NSRect)bounds fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth;
- (NSRect) playRect;
- (NSRect) progressRect;
- (NSRect) waveRect;
- (NSRect) statusRect;
- (void) setSampleData:(float *)theSampleData length:(int)length;
- (void) startAudio;
- (void) pauseAudio;
- (void) drawTextRigth:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color;
- (void) drawTextCentered:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color;
- (void) drawText:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color;
- (void) drawPlay;
- (void) drawPause;
@end

@implementation WaveFormView

#pragma mark -
#pragma mark Chrome
- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self) {
		[self initView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self initView];
    }
    return self;
}

- (void) initView
{
	playProgress = 0.0;
	progress = [[[NSProgressIndicator alloc] initWithFrame:[self progressRect]]autorelease];
	[progress setBezeled:NO];
	[progress setStyle:NSProgressIndicatorSpinningStyle];
	[progress setControlTint:NSClearControlTint];
	[self addSubview:progress];
	[progress setHidden:TRUE];
	[self setInfoString:@"No Audio"];
	NSRect sr = [self statusRect];
	sr.origin.x += 2;
	sr.origin.y -= 2;
	green = [[NSColor colorWithSRGBRed:143.0/255.0 green:196.0/255.0 blue:72.0/255.0 alpha:1.0]retain];
	gray = [[NSColor colorWithSRGBRed:64.0/255.0 green:63.0/255.0 blue:65.0/255.0 alpha:1.0]retain];
	lightgray = [[NSColor colorWithSRGBRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0]retain];
	darkgray = [[NSColor colorWithSRGBRed:47.0/255.0 green:47.0/255.0 blue:48.0/255.0 alpha:1.0]retain];
	white = [[NSColor whiteColor]retain];
	marker = [[NSColor colorWithSRGBRed:242.0/255.0 green:147.0/255.0 blue:0.0/255.0 alpha:1.0]retain];
}

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	if([self progressRect].size.width < 40) {
		[progress setControlSize:NSSmallControlSize];
	} else {
		[progress setControlSize:NSRegularControlSize];
	}
	[progress setFrame:[self progressRect]];
}

- (void) dealloc
{
	if(sampleData != nil) {
		free(sampleData);
		sampleData = nil;
		sampleLength = 0;
	}
	[infoString release];
	[timeString release];
	[player pause];
	[player release];
	[green release];
	[gray release];
	[lightgray release];
	[darkgray release];
	[white release];
	[marker release];
	[super dealloc];
}

#pragma mark -
#pragma mark Playback
- (void) setInfoString:(NSString *)newInfo
{
	[infoString release];
	infoString = [newInfo retain];
	[self setNeedsDisplay:YES];
}

- (void) setTimeString:(NSString *)newTime
{
	[timeString release];
	timeString = [newTime retain];
	[self setNeedsDisplay:YES];
}

- (void) openAudioURL:(NSURL *)url
{
	[self openAudio:url.path];
}

- (void) openAudio:(NSString *)path
{
	if(player != nil) {
		[player pause];
		[player release];
		player = nil;
	}
	sampleLength = 0;
	[self setNeedsDisplay:YES];
	[progress setHidden:FALSE];
	[progress startAnimation:self];
	wsp = [[WaveSampleProvider alloc]initWithPath:path];
	wsp.delegate = self;
	[wsp createSampleData];
}

- (void) pauseAudio
{
	if(player == nil) {
		[self startAudio];
		[player play];
		[self setInfoString:@"Playing"];
	} else {
		if(player.rate == 0.0) {
			[player play];
			[self setInfoString:@"Playing"];
		} else {
			[player pause];
			[self setInfoString:@"Paused"];
		}
	}
}

- (void) startAudio
{
	if(wsp.status == LOADED) {
		player = [[AVPlayer alloc] initWithURL:wsp.audioURL];
		CMTime tm = CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC);
		[player addPeriodicTimeObserverForInterval:tm queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
			Float64 duration = CMTimeGetSeconds(player.currentItem.duration);
			Float64 currentTime = CMTimeGetSeconds(player.currentTime);
			int dmin = duration / 60;
			int dsec = duration - (dmin * 60);
			int cmin = currentTime / 60;
			int csec = currentTime - (cmin * 60);
			if(currentTime > 0.0) {
				[self setTimeString:[NSString stringWithFormat:@"%02d:%02d/%02d:%02d",dmin,dsec,cmin,csec]];
			}
			playProgress = currentTime/duration;			
			[self setNeedsDisplay:YES];
		}];
	}	
}

#pragma mark -
#pragma mark Mouse Handling
- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];	
	
	NSRect wr = [self waveRect];
	wr.size.width = (wr.size.width - 12);
	wr.origin.x = wr.origin.x + 6;
	
	if(NSPointInRect(local_point, [self playRect])) {
		[self pauseAudio];
	} else if(NSPointInRect(local_point, wr) && player != nil) {
		CGFloat x = local_point.x - wr.origin.x;
		float sel = x / wr.size.width;
		Float64 duration = CMTimeGetSeconds(player.currentItem.duration);
		float timeSelected = duration * sel;
		CMTime tm = CMTimeMakeWithSeconds(timeSelected, NSEC_PER_SEC);
		[player seekToTime:tm];
		NSLog(@"Clicked time : %f",timeSelected);
	}
}

#pragma mark -
#pragma mark Text Drawing
- (void) drawTextCentered:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color
{
	if(text == nil) return;
	[[NSGraphicsContext currentContext] saveGraphicsState];
	NSFont *fnt = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];

	NSRectClip(rect);
	NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y + ((rect.size.height/2)-(fnt.xHeight/2)) + fnt.descender);
	NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
	
	[style setAlignment:NSCenterTextAlignment];
	NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:style,NSParagraphStyleAttributeName,fnt,NSFontAttributeName,color,NSForegroundColorAttributeName, nil];
	NSSize s = [text sizeWithAttributes:attr];
	pt.x = rect.origin.x + (rect.size.width / 2) - (s.width/2);
	
	[text drawAtPoint:pt withAttributes:attr];
	[style release];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) drawTextRight:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color
{
	if(text == nil) return;
	[[NSGraphicsContext currentContext] saveGraphicsState];
	NSRectClip(rect);
	
	NSFont *fnt = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
	
	NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y + ((rect.size.height/2)-(fnt.xHeight/2)) + fnt.descender);
	NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
	
	[style setAlignment:NSRightTextAlignment];
	NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:style,NSParagraphStyleAttributeName,fnt,NSFontAttributeName,color,NSForegroundColorAttributeName, nil];
	NSSize s = [text sizeWithAttributes:attr];
	pt.x = rect.origin.x + (rect.size.width - s.width - 1);
	
	[text drawAtPoint:pt withAttributes:attr];
	[style release];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void) drawText:(NSString *)text inRect:(NSRect)rect color:(NSColor *)color
{
	if(text == nil) return;
	[[NSGraphicsContext currentContext] saveGraphicsState];
	NSRectClip(rect);
	
	NSFont *fnt = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
	
	NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y + ((rect.size.height/2)-(fnt.xHeight/2)) + fnt.descender);
	NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
	
	[style setAlignment:NSLeftTextAlignment];
	NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:style,NSParagraphStyleAttributeName,fnt,NSFontAttributeName,color,NSForegroundColorAttributeName,nil];
//	NSSize s = [text sizeWithAttributes:attr];
	pt.x = rect.origin.x;
	
	[text drawAtPoint:pt withAttributes:attr];
	[style release];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

#pragma mark -
#pragma mark Drawing
- (BOOL) isOpaque
{
	return NO;
}

- (NSRect) playRect
{
	return NSMakeRect(6, 6, self.bounds.size.height - 12, self.bounds.size.height - 12);	
}

- (NSRect) progressRect
{
	return NSMakeRect(10, 10, self.bounds.size.height - 20, self.bounds.size.height - 20);	
}

- (NSRect) waveRect
{
	NSRect sr = [self statusRect];
	CGFloat y = sr.origin.y + sr.size.height + 2;
	return NSMakeRect(self.bounds.size.height, y, self.bounds.size.width - 9 - self.bounds.size.height, self.bounds.size.height - 6 - y);
}

- (NSRect) statusRect
{
	return NSMakeRect(self.bounds.size.height, 6, self.bounds.size.width - 9 - self.bounds.size.height, 16);
}

- (void) drawRoundRect:(NSRect)bounds fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth
{
	CGRect frame = NSMakeRect(bounds.origin.x+(lineWidth/2), bounds.origin.y+(lineWidth/2), bounds.size.width - lineWidth, bounds.size.height - lineWidth);
	
	NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:radius yRadius:radius];
	
	path.lineWidth = lineWidth;
	path.flatness = 0.0;
	
	[fillColor setFill];
	[path fill];
	
	[strokeColor set];
	[path stroke];
	
}

- (void) drawPlay
{
	NSRect playRect = [self playRect];
	NSBezierPath *triangle = [[NSBezierPath alloc] init];
	CGFloat tb = playRect.size.width * 0.22;
	tb = fmax(tb, 6);
	[triangle moveToPoint:NSMakePoint(playRect.origin.x + tb, playRect.origin.y + tb)];
	[triangle lineToPoint:NSMakePoint(playRect.origin.x + playRect.size.width - tb, playRect.origin.y + (playRect.size.height/2))];
	[triangle lineToPoint:NSMakePoint(playRect.origin.x + tb, playRect.origin.y + playRect.size.height - tb)];
	[triangle closePath];
	[green setFill];
	[triangle fill];
	[darkgray set];
	[triangle stroke];
	[triangle release];
	
}

- (void) drawPause
{
	NSRect pr = [self playRect];
	CGFloat w = pr.size.width;
	CGFloat w2 = w / 2.0;
	CGFloat tb = w * 0.22;
	CGFloat ww =  w2 - tb;
	[green setFill];
	NSRectFill(NSMakeRect(pr.origin.x + w2 - ww - (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	NSRectFill(NSMakeRect(pr.origin.x + w2 + (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	[darkgray set];
	NSFrameRect(NSMakeRect(pr.origin.x + w2 - ww - (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	NSFrameRect(NSMakeRect(pr.origin.x + w2 + (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSGraphicsContext currentContext] saveGraphicsState];
//	NSRectFill(self.bounds);
	[self drawRoundRect:self.bounds fillColor:gray strokeColor:green radius:8.0 lineWidht:2.0];
	
	NSRect playRect = [self playRect];
	[self drawRoundRect:playRect fillColor:white strokeColor:darkgray radius:4.0 lineWidht:2.0];
	
	NSRect waveRect = [self waveRect];
	[self drawRoundRect:waveRect fillColor:lightgray strokeColor:darkgray radius:4.0 lineWidht:2.0];
	
	NSRect statusRect = [self statusRect];
	[self drawRoundRect:statusRect fillColor:lightgray strokeColor:darkgray radius:4.0 lineWidht:2.0];
	
	if(sampleLength > 0) {
		if(player.rate == 0.0) {
			[self drawPlay];
		} else {
			[self drawPause];
		}
		CGMutablePathRef halfPath = CGPathCreateMutable();
		CGPathAddLines( halfPath, NULL,sampleData, sampleLength); // magic!
		
		CGMutablePathRef path = CGPathCreateMutable();

		double xscale = (NSWidth(waveRect)-12.0) / (float)sampleLength;
		// Transform to fit the waveform ([0,1] range) into the vertical space 
		// ([halfHeight,height] range)
		double halfHeight = floor( NSHeight( waveRect ) / 2.0 );//waveRect.size.height / 2.0;
		CGAffineTransform xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+6, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, halfHeight-6 );
		CGPathAddPath( path, &xf, halfPath );
		
		// Transform to fit the waveform ([0,1] range) into the vertical space
		// ([0,halfHeight] range), flipping the Y axis
		xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+6, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, -(halfHeight-6));
		CGPathAddPath( path, &xf, halfPath );
		
		CGPathRelease( halfPath ); // clean up!
		// Now, path contains the full waveform path.		
		NSGraphicsContext * nsGraphicsContext = [NSGraphicsContext currentContext];
		CGContextRef cr = (CGContextRef) [nsGraphicsContext graphicsPort];

		[darkgray set];
		CGContextAddPath(cr, path);
		CGContextStrokePath(cr);

		// gauge draw
		if(playProgress > 0.0) {
			NSRect clipRect = waveRect;
			clipRect.size.width = (clipRect.size.width - 12) * playProgress;
			clipRect.origin.x = clipRect.origin.x + 6;
			NSRectClip(clipRect);
			
			[marker setFill];
			CGContextAddPath(cr, path);
			CGContextFillPath(cr);
			NSRectClip(waveRect);
			[darkgray set];
			CGContextAddPath(cr, path);
			CGContextStrokePath(cr);
		}		
		CGPathRelease(path); // clean up!
	}
	[[NSColor clearColor] setFill];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	NSRect infoRect = [self statusRect];
	infoRect.origin.x += 4;
//	infoRect.origin.y -= 2;
	infoRect.size.width -= 65;
	[self drawText:infoString inRect:infoRect color:[NSColor greenColor]];
	NSRect timeRect = [self statusRect];
	timeRect.origin.x = timeRect.origin.x + timeRect.size.width - 65;
//	timeRect.origin.y -= 2;
	timeRect.size.width = 60;
	[self drawTextRight:timeString inRect:timeRect color:[NSColor greenColor]];
	
}

- (void) setSampleData:(float *)theSampleData length:(int)length
{
	[progress setHidden:FALSE];
	[progress startAnimation:self];
	sampleLength = 0;
	
	length += 2;
	CGPoint *tempData = (CGPoint *)calloc(sizeof(CGPoint),length);
	tempData[0] = CGPointMake(0.0,0.0);
	tempData[length-1] = CGPointMake(length-1,0.0);
	for(int i = 1; i < length-1;i++) {
		tempData[i] = CGPointMake(i, theSampleData[i]);
	}
	
	CGPoint *oldData = sampleData;
	
	sampleData = tempData;
	sampleLength = length;

	if(oldData != nil) {
		free(oldData);
	}
	
	free(theSampleData);
	[progress setHidden:TRUE];
	[progress stopAnimation:self];
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Sample Data Provider Delegat
- (void) statusUpdated:(WaveSampleProvider *)provider
{
	[self setInfoString:wsp.statusMessage];
}

- (void) sampleProcessed:(WaveSampleProvider *)provider
{
	if(wsp.status == LOADED) {
		int sdl = 0;
//		float *sd = [wsp dataForResolution:[self waveRect].size.width lenght:&sdl];
		float *sd = [wsp dataForResolution:8000 lenght:&sdl];
		[self setSampleData:sd length:sdl];
		[self setInfoString:@"Paused"];
		int dmin = wsp.minute;
		int dsec = wsp.sec;
		[self setTimeString:[NSString stringWithFormat:@"%02d:%02d/--:--",dmin,dsec]];
		[self startAudio];

	}
}

@end
