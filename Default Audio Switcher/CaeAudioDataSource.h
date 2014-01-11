//
//  CaeAudioDataSource.h
//  Default Audio Switcher
//
//  Created by Chris Elsworth on 10/01/2014.
//  Copyright (c) 2014 Chris Elsworth. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreAudio/CoreAudio.h"

#import "CaeAudioDevice.h"

@interface CaeAudioDataSource : NSObject {
}

// the audio device this output belongs to
@property (nonatomic, retain) CaeAudioDevice *device;

@property (nonatomic, assign) UInt32 dataSource;

// need to decide which of these will be saved to persistant storage

//@property (nonatomic, retain) NSString *dataSourceName;

-(id)initWithDevice:(CaeAudioDevice *)device dataSource:(UInt32)dataSource;
-(id)initWithDevice:(CaeAudioDevice *)device;

-(NSString *)name;

@end
