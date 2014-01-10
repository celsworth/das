//
//  AppDelegate.m
//  Default Audio Switcher
//
//  Created by Chris Elsworth on 10/01/2014.
//  Copyright (c) 2014 Chris Elsworth. All rights reserved.
//

#import "AppDelegate.h"

#import "CoreAudio/CoreAudio.h"

#import "CaeAudioDevice.h"

@implementation AppDelegate


-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	CaeAudioDevice *defaultDevice = [[CaeAudioDevice alloc] initAsDefaultDevice];
		
	NSMutableArray *dataSources = [defaultDevice dataSources];
	
	NSLog(@"default device has %lu datasources", [dataSources count]);
	
	NSLog(@"current datasource on default device is %d", [defaultDevice currentDataSource]);
	
	[dataSources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSLog(@"datasource is %@", [obj name]);
	}];
	
	
	// testing..
	AudioObjectPropertyAddress addr = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	
	AudioObjectPropertyListenerBlock b = ^(UInt32 inNumberAddresses,
										   const AudioObjectPropertyAddress *inAddresses)
	{
		NSLog(@"test block fired");
		
		
	};
	
	OSStatus ret = AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &addr,
													   dispatch_get_main_queue(), b);

	
}

@end