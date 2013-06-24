//
//  WaveFormView.m
//  WaveFormTest
//
//  Created by Gyetván András on 7/11/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import "WaveFormViewIOS.h"

@interface WaveFormViewIOS (Private)
- (void) initView;
- (void) drawRoundRect:(CGRect)bounds fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth;
- (CGRect) playRect;
- (CGRect) progressRect;
- (CGRect) waveRect;
- (CGRect) statusRect;
- (void) setSampleData:(float *)theSampleData length:(int)length;
- (void) startAudio;
- (void) pauseAudio;
- (void) drawTextRigth:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color;
- (void) drawTextCentered:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color;
- (void) drawText:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color;
- (void) drawPlay;
- (void) drawPause;
@end

@implementation WaveFormViewIOS

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

- (id)initWithFrame:(CGRect)frame
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
	progress = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	progress.frame = [self progressRect];
	[self addSubview:progress];
	[progress setHidden:TRUE];
	[self setInfoString:@"No Audio"];
	CGRect sr = [self statusRect];
	sr.origin.x += 2;
	sr.origin.y -= 2;
	green = [[UIColor colorWithRed:143.0/255.0 green:196.0/255.0 blue:72.0/255.0 alpha:1.0]retain];
	gray = [[UIColor colorWithRed:64.0/255.0 green:63.0/255.0 blue:65.0/255.0 alpha:1.0]retain];
	lightgray = [[UIColor colorWithRed:75.0/255.0 green:75.0/255.0 blue:75.0/255.0 alpha:1.0]retain];
	darkgray = [[UIColor colorWithRed:47.0/255.0 green:47.0/255.0 blue:48.0/255.0 alpha:1.0]retain];
	white = [[UIColor whiteColor]retain];
	marker = [[UIColor colorWithRed:242.0/255.0 green:147.0/255.0 blue:0.0/255.0 alpha:1.0]retain];
}

- (void)setFrame:(CGRect)frameRect
{
	[super setFrame:frameRect];
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
	[wsp release];
	[super dealloc];
}

#pragma mark -
#pragma mark Playback
- (void) setInfoString:(NSString *)newInfo
{
	[infoString release];
	if(wsp.title != nil) {
		infoString = [[NSString stringWithFormat:@"%@ (%@)",newInfo,wsp.title] retain];
	} else {
		infoString = [newInfo copy];
	}
	[self setNeedsDisplay];
}

- (void) setTimeString:(NSString *)newTime
{
	[timeString release];
	timeString = [newTime retain];
	[self setNeedsDisplay];
}

//- (void) openAudioURL:(NSURL *)url
//{
//	[self openAudio:url.path];
//}

- (void) openAudioURL:(NSURL *)url
{
	if(player != nil) {
		[player pause];
		[player release];
		player = nil;
	}
	sampleLength = 0;
	[self setNeedsDisplay];
	[progress setHidden:FALSE];
	[progress startAnimating];
	[wsp release];
	wsp = [[WaveSampleProvider alloc]initWithURL:url];
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
			[self setNeedsDisplay];
		}];
	}	
}

#pragma mark -
#pragma mark Touch Handling
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint local_point = [touch locationInView:self];
	CGRect wr = [self waveRect];
	wr.size.width = (wr.size.width - 12);
	wr.origin.x = wr.origin.x + 6;
	if(CGRectContainsPoint([self playRect],local_point)) {
		NSLog(@"Play/Pause touched");
		[self pauseAudio];
	} else if(CGRectContainsPoint(wr,local_point) && player != nil) {
		CGFloat x = local_point.x - wr.origin.x;
		float sel = x / wr.size.width;
		Float64 duration = CMTimeGetSeconds(player.currentItem.duration);
		float timeSelected = duration * sel;
		CMTime tm = CMTimeMakeWithSeconds(timeSelected, NSEC_PER_SEC);
		[player seekToTime:tm];
		NSLog(@"Clicked time : %f",timeSelected);
	}
}
//- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
//{
//	return YES;
//}
//
//- (void) mouseDown:(NSEvent *)theEvent
//{
//	NSPoint event_location = [theEvent locationInWindow];
//	NSPoint local_point = [self convertPoint:event_location fromView:nil];	
//	
//	CGRect wr = [self waveRect];
//	wr.size.width = (wr.size.width - 12);
//	wr.origin.x = wr.origin.x + 6;
//	
//	if(NSPointInRect(local_point, [self playRect])) {
//		[self pauseAudio];
//	} else if(NSPointInRect(local_point, wr) && player != nil) {
//		CGFloat x = local_point.x - wr.origin.x;
//		float sel = x / wr.size.width;
//		Float64 duration = CMTimeGetSeconds(player.currentItem.duration);
//		float timeSelected = duration * sel;
//		CMTime tm = CMTimeMakeWithSeconds(timeSelected, NSEC_PER_SEC);
//		[player seekToTime:tm];
//		NSLog(@"Clicked time : %f",timeSelected);
//	}
//}

#pragma mark -
#pragma mark Text Drawing
- (void) drawTextCentered:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color
{
	if(text == nil) return;
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(cx);
	CGContextClipToRect(cx, rect);
	CGPoint center = CGPointMake(rect.origin.x + (rect.size.width / 2.0), rect.origin.y + (rect.size.height / 2.0));
	UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	CGSize stringSize = [text sizeWithFont:font];
	CGRect stringRect = CGRectMake(center.x-stringSize.width/2, center.y-stringSize.height/2, stringSize.width, stringSize.height);
	
	[color set];
	[text drawInRect:stringRect withFont:font];
	CGContextRestoreGState(cx);
}

- (void) drawTextRight:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color
{
	if(text == nil) return;
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(cx);
	CGContextClipToRect(cx, rect);
	CGPoint center = CGPointMake(rect.origin.x + (rect.size.width / 2.0), rect.origin.y + (rect.size.height / 2.0));
	UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	CGSize stringSize = [text sizeWithFont:font];
	CGRect stringRect = CGRectMake(rect.origin.x + rect.size.width - stringSize.width, center.y-stringSize.height/2, stringSize.width, stringSize.height);
	
	[color set];
	[text drawInRect:stringRect withFont:font];
	CGContextRestoreGState(cx);
}

- (void) drawText:(NSString *)text inRect:(CGRect)rect color:(UIColor *)color
{
	if(text == nil) return;
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(cx);
	CGContextClipToRect(cx, rect);
	CGPoint center = CGPointMake(rect.origin.x + (rect.size.width / 2.0), rect.origin.y + (rect.size.height / 2.0));
	UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	
	CGSize stringSize = [text sizeWithFont:font];
	CGRect stringRect = CGRectMake(rect.origin.x, center.y-stringSize.height/2, stringSize.width, stringSize.height);
	
	[color set];
	[text drawInRect:stringRect withFont:font];
	CGContextRestoreGState(cx);
}

#pragma mark -
#pragma mark Drawing
- (BOOL) isOpaque
{
	return NO;
}

- (CGRect) playRect
{
	return CGRectMake(6, 6, self.bounds.size.height - 12, self.bounds.size.height - 12);	
}

- (CGRect) progressRect
{
	return CGRectMake(10, 10, self.bounds.size.height - 20, self.bounds.size.height - 20);	
}

- (CGRect) waveRect
{
	CGRect sr = [self statusRect];
	CGFloat y = 6;//sr.origin.y + sr.size.height + 2;
	return CGRectMake(self.bounds.size.height, y, self.bounds.size.width - 9 - self.bounds.size.height, self.bounds.size.height - 12 - sr.size.height);
}

- (CGRect) statusRect
{
	return CGRectMake(self.bounds.size.height, self.bounds.size.height - 6 - 16, self.bounds.size.width - 9 - self.bounds.size.height, 16);
//	return CGRectMake(self.bounds.size.height, 6, self.bounds.size.width - 9 - self.bounds.size.height, 16);
}

- (void) drawRoundRect:(CGRect)bounds fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth
{
	CGRect rrect = CGRectMake(bounds.origin.x+(lineWidth/2), bounds.origin.y+(lineWidth/2), bounds.size.width - lineWidth, bounds.size.height - lineWidth);
	
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
	CGContextRef cx = UIGraphicsGetCurrentContext();
	
	CGContextMoveToPoint(cx, minx, midy);
	CGContextAddArcToPoint(cx, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(cx, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(cx, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(cx, minx, maxy, minx, midy, radius);
	CGContextClosePath(cx);
	
	CGContextSetStrokeColorWithColor(cx, strokeColor.CGColor);
	CGContextSetFillColorWithColor(cx, fillColor.CGColor);
	CGContextDrawPath(cx, kCGPathFillStroke);
}

- (void) drawPlay
{
	CGRect playRect = [self playRect];
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGFloat tb = playRect.size.width * 0.22;
	tb = fmax(tb, 6);
	CGContextMoveToPoint(cx, playRect.origin.x + tb, playRect.origin.y + tb);
	CGContextAddLineToPoint(cx,playRect.origin.x + playRect.size.width - tb, playRect.origin.y + (playRect.size.height/2));
	CGContextAddLineToPoint(cx,playRect.origin.x + tb, playRect.origin.y + playRect.size.height - tb);
	CGContextClosePath(cx);
	CGContextSetStrokeColorWithColor(cx, darkgray.CGColor);
	CGContextSetFillColorWithColor(cx, green.CGColor);
	CGContextDrawPath(cx, kCGPathFillStroke);
}

- (void) drawPause
{
	CGRect pr = [self playRect];
	CGFloat w = pr.size.width;
	CGFloat w2 = w / 2.0;
	CGFloat tb = w * 0.22;
	CGFloat ww =  w2 - tb;
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(cx, darkgray.CGColor);
	CGContextSetFillColorWithColor(cx, green.CGColor);
	CGContextAddRect(cx,CGRectMake(pr.origin.x + w2 - ww - (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	CGContextAddRect(cx,CGRectMake(pr.origin.x + w2 + (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	CGContextAddRect(cx,CGRectMake(pr.origin.x + w2 - ww - (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	CGContextAddRect(cx,CGRectMake(pr.origin.x + w2 + (tb/3), tb+2, ww, pr.origin.y + pr.size.height - (tb * 2)));
	CGContextDrawPath(cx, kCGPathFillStroke);
}

- (void)drawRect:(CGRect)dirtyRect
{
	CGContextRef cx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(cx);
	
	CGContextSetFillColorWithColor(cx, [UIColor clearColor].CGColor);
	CGContextFillRect(cx, self.bounds);
	
	[self drawRoundRect:self.bounds fillColor:gray strokeColor:green radius:8.0 lineWidht:2.0];
	
	CGRect playRect = [self playRect];
	[self drawRoundRect:playRect fillColor:white strokeColor:darkgray radius:4.0 lineWidht:2.0];
	
	CGRect waveRect = [self waveRect];
	[self drawRoundRect:waveRect fillColor:lightgray strokeColor:darkgray radius:4.0 lineWidht:2.0];
	
	CGRect statusRect = [self statusRect];
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
		
		double xscale = (CGRectGetWidth(waveRect)-12.0) / (float)sampleLength;
		// Transform to fit the waveform ([0,1] range) into the vertical space 
		// ([halfHeight,height] range)
		double halfHeight = floor( CGRectGetHeight(waveRect) / 2.0 );//waveRect.size.height / 2.0;
		CGAffineTransform xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+6, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, -(halfHeight-6) );
		CGPathAddPath( path, &xf, halfPath );
		
		// Transform to fit the waveform ([0,1] range) into the vertical space
		// ([0,halfHeight] range), flipping the Y axis
		xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+6, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, (halfHeight-6));
		CGPathAddPath( path, &xf, halfPath );
		
		CGPathRelease( halfPath ); // clean up!
		// Now, path contains the full waveform path.		
		CGContextRef cx = UIGraphicsGetCurrentContext();
		
		[darkgray set];
		CGContextAddPath(cx, path);
		CGContextStrokePath(cx);
		
		// gauge draw
		if(playProgress > 0.0) {
			CGRect clipRect = waveRect;
			clipRect.size.width = (clipRect.size.width - 12) * playProgress;
			clipRect.origin.x = clipRect.origin.x + 6;
			CGContextClipToRect(cx,clipRect);
			
			[marker setFill];
			CGContextAddPath(cx, path);
			CGContextFillPath(cx);
			CGContextClipToRect(cx,waveRect);
			[darkgray set];
			CGContextAddPath(cx, path);
			CGContextStrokePath(cx);
		}		
		CGPathRelease(path); // clean up!
	}
	[[UIColor clearColor] setFill];
	CGContextRestoreGState(cx);
	CGRect infoRect = [self statusRect];
	infoRect.origin.x += 4;
	//	infoRect.origin.y -= 2;
	infoRect.size.width -= 65;
	[self drawText:infoString inRect:infoRect color:[UIColor greenColor]];
	CGRect timeRect = [self statusRect];
	timeRect.origin.x = timeRect.origin.x + timeRect.size.width - 65;
	//	timeRect.origin.y -= 2;
	timeRect.size.width = 60;
	[self drawTextRight:timeString inRect:timeRect color:[UIColor greenColor]];
	
}

- (void) setSampleData:(float *)theSampleData length:(int)length
{
	[progress setHidden:FALSE];
	[progress startAnimating];
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
	[progress stopAnimating];
	[self setNeedsDisplay];
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
		playProgress = 0.0;
		int dmin = wsp.minute;
		int dsec = wsp.sec;
		[self setTimeString:[NSString stringWithFormat:@"%02d:%02d/--:--",dmin,dsec]];
		[self startAudio];
	}
	[wsp release];
	wsp = nil;
}
@end
