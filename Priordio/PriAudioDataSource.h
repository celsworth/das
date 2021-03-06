//
//  PriAudioDataSource.h
//  Priordio
//
//  Created by Chris Elsworth on 10/01/2014.
//  Copyright (c) 2014 Chris Elsworth. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreAudio/CoreAudio.h"

@class PriAudioDevice;
@interface PriAudioDataSource : NSObject


// the audio device this output belongs to
@property (nonatomic, retain) PriAudioDevice *device;

@property (nonatomic, assign) UInt32 dataSource;



//@property (nonatomic, retain) NSString *dataSourceName;

-(id)initWithDevice:(PriAudioDevice *)device dataSource:(UInt32)dataSource;
-(id)initWithDevice:(PriAudioDevice *)device;

-(NSString *)name;

-(BOOL)isDefault;
-(void)setAsDefault;

@end
