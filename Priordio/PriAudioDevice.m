//
//  PriAudioDevice.m
//  Priordio
//
//  Created by Chris Elsworth on 10/01/2014.
//  Copyright (c) 2014 Chris Elsworth. All rights reserved.
//

#import "PriAudioDevice.h"

#import "PriAudioSystem.h"
#import "PriAudioDataSource.h"

@implementation PriAudioDevice

-(id)initWithDevice:(AudioDeviceID)device
{
	//NSLog(@"init PriAudioDevice with device=%d", device);
	
	if (self = [super init])
	{
		_device = device;
		
		_dataSources = [self enumerateDataSources];
		
		[self setupNotifications];
	}
	
	//[self transportType];
	
	return self;
}

-(id)initWithDefaultDevice
{
	if (self = [self initWithDevice:[PriAudioDevice defaultAudioDevice]])
	{
		NSLog(@"setup for default %@ done", [self name]);
	}
	
	return self;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ ; %@ ; %@ (%d output channels) (%@)",
			[self name], [self uid], [PriAudioDevice transportTypeAsName:[self transportType]],
			[self outputChannelCount],
			[[self dataSources] componentsJoinedByString:@", "]];
}

-(AudioDeviceID)deviceID
{
	return [self device];
}

+(AudioDeviceID)defaultAudioDevice
{
	const AudioObjectPropertyAddress pa = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	AudioDeviceID defaultDevice = 0;
	UInt32 defaultSize = sizeof(AudioDeviceID);
	OSStatus ret = AudioObjectGetPropertyData(kAudioObjectSystemObject, &pa, 0, NULL, &defaultSize, &defaultDevice);
	if (ret)
		abort(); // FIXME
	
	return defaultDevice;
}

-(void)setupNotifications
{
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyDataSource,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	AudioObjectPropertyListenerBlock b = ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses)
	{
		// triggered when a datasource changes
		
		NSLog(@"datasource change block fired");
		
		switch([self currentDataSource])
		{
			case kAudioDeviceOutputSpeaker:
				NSLog(@"speakers");
				break;
			case kAudioDeviceOutputHeadphone:
				NSLog(@"headphones");
				break;
		}
		
		// TODO: post NSNotification?
		
	};
	
	
	OSStatus ret = AudioObjectAddPropertyListenerBlock([self device], &pa, dispatch_get_main_queue(), b);
	if (ret)
	{
		abort(); // FIXME
	}
}

-(NSString *)name
{
	AudioObjectPropertyAddress addr = {
		kAudioObjectPropertyName,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	
	CFStringRef deviceName;
	UInt32 propSize = sizeof(CFStringRef);
	OSStatus ret = AudioObjectGetPropertyData([self device], &addr, 0, NULL, &propSize, &deviceName);
	if (ret)
	{
		NSLog(@"%s kAudioObjectPropertyName ret=%@", __PRETTY_FUNCTION__, [PriAudioSystem osError:ret]);
		return NULL;
	}
	
	return (__bridge NSString *)deviceName;
}

-(NSString *)uid
{
	AudioObjectPropertyAddress addr = {
		kAudioDevicePropertyDeviceUID,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	
	CFStringRef uid;
	UInt32 propSize = sizeof(CFStringRef);
	OSStatus ret = AudioObjectGetPropertyData([self device], &addr, 0, NULL, &propSize, &uid);
	if (ret)
	{
		NSLog(@"%s kAudioDevicePropertyDeviceUID ret=%@", __PRETTY_FUNCTION__, [PriAudioSystem osError:ret]);
		return NULL;
	}
	
	return (__bridge NSString *)uid;
}


-(UInt32)transportType
{
	AudioObjectPropertyAddress addr = {
		kAudioDevicePropertyTransportType,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	
	UInt32 tt;
	UInt32 propSize = sizeof(UInt32);
	OSStatus ret = AudioObjectGetPropertyData(_device, &addr, 0, NULL, &propSize, &tt);
	if (ret)
	{
		NSLog(@"%s kAudioDevicePropertyTransportType ret=%@", __PRETTY_FUNCTION__, [PriAudioSystem osError:ret]);
		return 0;
	}
	
	return tt;
}
+(NSString *)transportTypeAsName:(UInt32)transportType
{
	switch (transportType)
	{
		case kAudioDeviceTransportTypeBuiltIn:       return @"Built-in";
		case kAudioDeviceTransportTypeAggregate:     return @"Aggregate";
		case kAudioDeviceTransportTypeAutoAggregate: return @"Auto Aggregate";
		case kAudioDeviceTransportTypeVirtual:       return @"Virtual";
		case kAudioDeviceTransportTypePCI:           return @"PCI";
		case kAudioDeviceTransportTypeUSB:           return @"USB";
		case kAudioDeviceTransportTypeFireWire:      return @"FireWire";
		case kAudioDeviceTransportTypeBluetooth:     return @"Bluetooth";
		case kAudioDeviceTransportTypeHDMI:          return @"HDMI";
		case kAudioDeviceTransportTypeDisplayPort:   return @"DisplayPort";
		case kAudioDeviceTransportTypeAirPlay:       return @"AirPlay";
		case kAudioDeviceTransportTypeAVB:           return @"AVB";
		case kAudioDeviceTransportTypeThunderbolt:   return @"Thunderbolt";
		case kAudioDeviceTransportTypeUnknown:
		default:                                     return @"UNKNOWN";
	}
}


-(UInt32)outputChannelCount
{
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyStreamConfiguration,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	UInt32 size = 0;
	OSStatus ret = AudioObjectGetPropertyDataSize([self device], &pa, 0, NULL, &size);
	if (ret)
	{
		NSLog(@"%s kAudioDevicePropertyStreamConfiguration/size ret=%@", __PRETTY_FUNCTION__, [PriAudioSystem osError:ret]);
		return 0;
	}
	
	AudioBufferList *tmp = calloc(size, sizeof(AudioBufferList));
	UInt32 tmpSize = size * sizeof(AudioBufferList);
	
	UInt32 outputChannelCount = 0;
	
	ret = AudioObjectGetPropertyData([self device], &pa, 0, NULL, &tmpSize, tmp);
	if (ret)
	{
		NSLog(@"%s kAudioDevicePropertyStreamConfiguration ret=%@", __PRETTY_FUNCTION__, [PriAudioSystem osError:ret]);
		goto out;
	}
	
	for(int j = 0 ; j<tmp->mNumberBuffers ; j++)
		outputChannelCount += tmp->mBuffers[j].mNumberChannels;
	
	out:
	free(tmp);
	return outputChannelCount;
}

-(BOOL)supportsDataSources
{
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyDataSources,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	return AudioObjectHasProperty([self device], &pa);
}

-(UInt32)currentDataSource
{
	if (![self supportsDataSources])
		return 0;
	
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyDataSource,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	UInt32 dataSourceId = 0;
	UInt32 dataSourceIdSize = sizeof(UInt32);
	
	OSStatus ret = AudioObjectGetPropertyData([self device], &pa, 0, NULL,
											  &dataSourceIdSize, &dataSourceId);
	if (ret)
	{
		NSLog(@"%s %@ kAudioDevicePropertyDataSource ret=%@", __PRETTY_FUNCTION__, self, [PriAudioSystem osError:ret]);
		return 0;
	}
	return dataSourceId;
}

-(UInt32)dataSourceCount
{
	if (![self supportsDataSources])
	/* doesn't support datasources, so we make up a dummy one */
		return 1;
	
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyDataSources,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	// could use AudioObjectHasProperty instead
	
	UInt32 size = 0;
	OSStatus ret = AudioObjectGetPropertyDataSize([self device], &pa, 0, NULL, &size);
	if (ret)
	{
		NSLog(@"%s %@ kAudioDevicePropertyDataSources/size ret=%@",
			  __PRETTY_FUNCTION__, self, [PriAudioSystem osError:ret]);
		return 0;
	}
	
	return size;
}

-(NSArray *)enumerateDataSources
{
	NSMutableArray *arr = [NSMutableArray new];
	
	if (![self supportsDataSources])
	{
		/* doesn't support datasources, so we make up a dummy one */
		[arr addObject:[[PriAudioDataSource alloc] initWithDevice:self]];
		return [NSArray arrayWithArray:arr];
	}
	
	UInt32 count = [self dataSourceCount];
	
	if (count == 0)
		return arr;
	
	// temporary storage for the datasource results
	UInt32 *tmp = calloc(count, sizeof(UInt32));
	UInt32 tmpSize = count * sizeof(UInt32);
	
	AudioObjectPropertyAddress pa = {
		kAudioDevicePropertyDataSources,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMaster
	};
	
	// could use AudioObjectHasProperty instead
	
	OSStatus ret = AudioObjectGetPropertyData([self device], &pa, 0, NULL, &tmpSize, tmp);
	if (ret)
	{
		NSLog(@"%s %@ kAudioDevicePropertyDataSource ret=%@",
			  __PRETTY_FUNCTION__, self, [PriAudioSystem osError:ret]);
		goto out;
	}
	
	for (int i = 0; i < count; i++) {
		if (tmp[i] == 0) continue;
		
		PriAudioDataSource *addObj = [[PriAudioDataSource alloc] initWithDevice:self
																	 dataSource:tmp[i]];
		[arr addObject:addObj];
	}
	
	out:
	free(tmp);
	
	return [NSArray arrayWithArray:arr];
}

@end