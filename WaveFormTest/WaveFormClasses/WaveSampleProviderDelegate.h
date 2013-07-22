//
//  WaveSampleProviderDelegate.h
//  CoreAudioTest
//
//  Created by Gyetván András on 6/26/12.
// This software is free.
//

#import <Foundation/Foundation.h>
@class WaveSampleProvider;

@protocol WaveSampleProviderDelegate <NSObject>

- (void) sampleProcessed:(WaveSampleProvider *)provider;
- (void) statusUpdated:(WaveSampleProvider *)provider;

@end
