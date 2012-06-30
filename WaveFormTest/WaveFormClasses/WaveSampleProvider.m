//
//  WaveSampleProvider.m
//  CoreAudioTest
//
//  Created by Gyetván András on 6/22/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import "WaveSampleProvider.h"

@interface WaveSampleProvider (Private)
- (void) loadSample;
- (void) processSample;
- (void) calculateSampleFromArray:(float**)audio lenght:(int)length;
- (void) normalizeSample;
- (void) status:(WaveSampleStatus)status message:(NSString *)desc;
- (OSStatus) readConsecutive:(SInt64)numFrames intoArray:(float**)audio;
@end

@implementation WaveSampleProvider
@synthesize status, statusMessage, binSize, minute, sec, delegate,audioURL;

- (NSString *)title
{
	return title;	
}

- (void) status:(WaveSampleStatus)theStatus message:(NSString *)desc;
{
	status = theStatus;
	[statusMessage release];
	statusMessage = [desc copy];
	[self performSelectorOnMainThread:@selector(informDelegateOfStatusChange) withObject:nil waitUntilDone:NO];
}

- (id) initWithPath:(NSString *)thePath
{
	self = [super init];
	if(self) {
		extAFNumChannels = 2;
		[self status:LOADING message:@"Processing"];
		binSize = 50;
		path = [[NSString stringWithString:thePath] retain];
		audioURL = [[NSURL fileURLWithPath:path]retain];
		title = [[path lastPathComponent] copy];
	}
	return self;
}

- (void) dealloc
{
	[path release];
	[audioURL release];
	[statusMessage release];
	[sampleData release];
	[normalizedData release];
	[delegate release];
	[title release];
	[super dealloc];
	
}

- (void) createSampleData
{
	sampleData = [[NSMutableArray array]retain];
	[self performSelectorInBackground:@selector(loadSample) withObject:nil];
}

- (void) informDelegateOfFinish
{
	if(delegate != nil) {
		if([delegate respondsToSelector:@selector(sampleProcessed:)]) {
			[delegate sampleProcessed:self];
		}
	}
}

- (void) informDelegateOfStatusChange
{
	if(delegate != nil) {
		if([delegate respondsToSelector:@selector(statusUpdated:)]) {
			[delegate statusUpdated:self];
		}
	}
}

- (void) loadSample
{
	[self processSample];	
	[self performSelectorOnMainThread:@selector(informDelegateOfFinish) withObject:nil waitUntilDone:NO];
}

- (void) processSample
{
	extAFReachedEOF = NO;
	OSStatus err;
	CFURLRef inpUrl = (CFURLRef)audioURL;
	err = ExtAudioFileOpenURL(inpUrl, &extAFRef);
	if(err != noErr) {
		[self status:ERROR message:@"Cannot open audio file"];
		return;
	}
	
	AudioFileID afid;
	AudioFileOpenURL(inpUrl, kAudioFileReadPermission, 0, &afid);
	UInt32 size = 0;
	UInt32 writable;
	OSStatus error = AudioFileGetPropertyInfo(afid, kAudioFilePropertyInfoDictionary, &size, &writable);
	if ( error == noErr ) {
		CFDictionaryRef info = NULL;
		error = AudioFileGetProperty(afid, kAudioFilePropertyInfoDictionary, &size, &info);
		if ( error == noErr ) {
			NSLog(@"file properties: %@", (NSDictionary *)info);
			NSDictionary *dict = (NSDictionary *)info;
			NSString *idTitle = [dict valueForKey:@"title"];
			if(idTitle != nil) {
				[title release];
				title = [idTitle copy];
			}
		}
	} else {
		NSLog(@"Error reading tags");
	}
	AudioFileClose(afid);
	
	AudioStreamBasicDescription fileFormat;
	
    UInt32 propSize = sizeof(fileFormat);
    memset(&fileFormat, 0, sizeof(AudioStreamBasicDescription));
	
    err = ExtAudioFileGetProperty(extAFRef, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
	if(err != noErr) {
		[self status:ERROR message:@"Cannot get audio file properties"];
		return;
	}
	
	Float64 sampleRate = 44100.0;
    extAFRateRatio = sampleRate / fileFormat.mSampleRate;
	
    AudioStreamBasicDescription clientFormat;
    propSize = sizeof(clientFormat);
	
    memset(&clientFormat, 0, sizeof(AudioStreamBasicDescription));
    clientFormat.mFormatID           = kAudioFormatLinearPCM;
    clientFormat.mSampleRate         = sampleRate;
    clientFormat.mFormatFlags        = kAudioFormatFlagsCanonical;//kAudioFormatFlagIsFloat | kAudioFormatFlagIsAlignedHigh | kAudioFormatFlagsCanonical;// | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;// |  kAudioFormatFlagIsNonInterleaved;
    clientFormat.mChannelsPerFrame   = extAFNumChannels;
    clientFormat.mBitsPerChannel     = sizeof(float) * 8;
    clientFormat.mFramesPerPacket    = 1;
    clientFormat.mBytesPerFrame      = extAFNumChannels * sizeof(float);
    clientFormat.mBytesPerPacket     = extAFNumChannels * sizeof(float);
//    clientFormat.mReserved           = 0;
	
    err = ExtAudioFileSetProperty(extAFRef, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
	if(err != noErr) {
		[self status:ERROR message:@"Cannot convert audio file to PCM format"];
		return;
	}

	SInt64 NUM_FRAMES_PER_READ = 500*binSize;
    float *audio[extAFNumChannels];
	
    for (int i=0; i < extAFNumChannels; i++) {
        audio[i] = (float *)malloc(sizeof(float)*NUM_FRAMES_PER_READ);
    }
	int packetReads = 0;
	
	while (!extAFReachedEOF) {
		int k = 0;
        if ((k = [self readConsecutive:NUM_FRAMES_PER_READ intoArray:audio]) < 0) { 
			[self status:ERROR message:@"Cannot read audio file"];
			return;
        }
		[self calculateSampleFromArray:audio lenght:k];
		packetReads += k;
	}
	float allSec = packetReads / 44100;
	lengthInSec = allSec;
	minute = allSec / 60;
	sec = ceil(allSec - ((float)(minute * 60) + 0.5));
	err = ExtAudioFileDispose(extAFRef);
	if(err != noErr) {
		[self status:ERROR message:@"Error closing audio file"];
		return;
	}
    for (int i=0; i < extAFNumChannels; i++) {
        free(audio[i]);
    }
	
//	NSLog(@"Packets read : %d (%ld)",packetReads, sampleData.count);
	[self normalizeSample];
	[self status:LOADED message:@"Sample data loaded"];
}

- (void) normalizeSample
{
	normalizedData = [[NSMutableArray array]retain];
	float min = MAXFLOAT;
	float max = -MAXFLOAT;
	for(NSNumber *num in sampleData) {
		float val = num.floatValue;
		if(val < min) min = val;
		if(val > max) max = val;
	}
//	long double delta = max - min;
//	NSLog(@"Min: %f, Max: %f, Delta: %Lf", min,  max, delta);
	for(NSNumber *num in sampleData) {
		float val = num.floatValue;
		if(val > 1.0) val = 1.0;
		if(val < 0.0) val = 0.0;
		NSNumber *nval = [NSNumber numberWithFloat:val];
		[normalizedData addObject:nval];
	}	
	[sampleData release];
	sampleData = nil;
}

- (void) calculateSampleFromArray:(float**)audio lenght:(int)length
{
	float maxValues[extAFNumChannels];
	for(int i = 0; i < extAFNumChannels;i++) {
		maxValues[i] = 0.0; 
	}
	for(int v = 0; v < length; v+=binSize) {
		for(int c = 0; c < extAFNumChannels;c++) {
//		int c = 0;
			for(int p = 0;p < binSize;p++) {
				int idx = v + p;
				if(idx < length) {
					float val = audio[c][idx];
					if(val > maxValues[c]) maxValues[c] = val;
				} else {
					break;
				}
			}
		}
		float maxValue = 0;
		for(int i = 0; i < extAFNumChannels;i++) {
			if(maxValues[i] > maxValue) maxValue = maxValues[i]; 
		}
		NSNumber *nMaxValue = [NSNumber numberWithFloat:maxValue];
		[sampleData addObject:nMaxValue];
	}
}

- (OSStatus) readConsecutive:(SInt64)numFrames intoArray:(float**)audio
{
    OSStatus err = noErr;
	
    if (!extAFRef)  return -1;
	
    int kSegmentSize;
    if (extAFRateRatio < 1.) 
        kSegmentSize = (int)(numFrames * extAFNumChannels / extAFRateRatio + .5);
    else
        kSegmentSize = (int)(numFrames * extAFNumChannels * extAFRateRatio + .5);
	
    UInt32 loadedPackets;
    float *data = (float*)malloc(kSegmentSize*sizeof(float));
    if (!data) {
		return -1;
    } else {
		
		UInt32 numPackets = numFrames; // Frames to read
		UInt32 samples = numPackets * extAFNumChannels; // 2 channels (samples) per frame
		
		AudioBufferList bufList;
		bufList.mNumberBuffers = 1;
		bufList.mBuffers[0].mNumberChannels = extAFNumChannels; // Always 2 channels in this example
		bufList.mBuffers[0].mData = data; // data is a pointer (float*) to our sample buffer
		bufList.mBuffers[0].mDataByteSize = samples * sizeof(float);
		
		loadedPackets = numPackets;
		
		err = ExtAudioFileRead(extAFRef, &loadedPackets, &bufList);
		if (!err) {
			if (audio) {
				for (long c = 0; c < extAFNumChannels; c++) {
					if (!audio[c]) continue;
					for (long v = 0; v < numFrames; v++) {
						if (v < loadedPackets) audio[c][v] = data[v*extAFNumChannels+c];
						else audio[c][v] = 0.;
					}
				}
			}
		}
		free(data);
		if (err != noErr) return err;
		if (loadedPackets < numFrames) extAFReachedEOF = YES;
		return loadedPackets;
	}
}	

- (void) dumpNormalizedData
{
	NSLog(@"Sample count :%ld",normalizedData.count);
	for(NSNumber *nsd in normalizedData) {
		float val = nsd.floatValue;
//		val = (val * 50);
		NSLog(@"Normalized data %f",val);
	}
}

- (float *)dataForResolution:(int)pixelWide lenght:(int *)length
{
//	int samplePerSec = 44100.0 / binSize;
//	int secPerPixel = (int)lengthInSec / (int)pixelWide;
	int rangeLength = normalizedData.count / pixelWide + 1;
	int retLength = pixelWide;
	float *ret = (float *)calloc(sizeof(float),retLength);
	int k = 0;
	for(int r = 0; r < normalizedData.count; r += rangeLength) {
		float valMax = 0;
		for(int j = 0; j < rangeLength; j++) {
			int idx = r + j;
			if(idx < normalizedData.count) {
				NSNumber *nVal = [normalizedData objectAtIndex:idx];
				float val = nVal.floatValue;
				if(valMax < val) valMax = val;
			}
		}
		ret[k] = valMax;
		k++;
	}
	*length = k;
	return ret;
	
//	float samplePerSec = 44100.0 / binSize;
//	float secPerPixel = (float)lengthInSec / (float)pixelWide;
//	float rangeLength = samplePerSec * secPerPixel;
//	float retLength = (normalizedData.count / rangeLength) + 1;
//	float *ret = (float *)malloc(sizeof(float) *retLength);
//	int k = 0;
//	for(int r = 0; r < normalizedData.count; r += rangeLength) {
//		float valMax = 0;
//		for(int j = 0; j < rangeLength; j++) {
//			int idx = r + j;
//			if(idx < normalizedData.count) {
//				NSNumber *nVal = [normalizedData objectAtIndex:idx];
//				float val = nVal.floatValue;
//				if(valMax < val) valMax = val;
//			}
//		}
//		ret[k] = valMax;
//		k++;
//	}
//	*length = k;
//	return ret;
}
@end
