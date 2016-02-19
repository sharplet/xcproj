//
//  XcodeFrameworkLoader.m
//  xcproj
//
//  Created by Adam Sharp on 19/02/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import "Xcproj+LoadFrameworks.h"

#import <dlfcn.h>
#import <objc/runtime.h>
#import "DDCommandLineInterface.h"
#import "XCDUndocumentedChecker.h"
#import "XMLPlistDecoder.h"

NSString *XcprojErrorDomain = @"xcproj";
NSString *XcprojClassLoadErrorsKey = @"XcprojClassLoadErrors";

static NSString *XcodeBundleIdentifier = @"com.apple.dt.Xcode";

static NSBundle * XcodeBundleAtPath(NSString *path)
{
	NSBundle *xcodeBundle = [NSBundle bundleWithPath:path];
	return [xcodeBundle.bundleIdentifier isEqualToString:XcodeBundleIdentifier] ? xcodeBundle : nil;
}

static NSBundle * LocateXcodeBundle(NSError **error)
{
	NSString *xcodeAppPath = NSProcessInfo.processInfo.environment[@"XCPROJ_XCODE_APP_PATH"];
	NSBundle *xcodeBundle = XcodeBundleAtPath(xcodeAppPath);
	if (!xcodeBundle)
	{
		NSTask *task = [NSTask new];
		task.launchPath = @"/usr/bin/xcode-select";
		task.arguments = @[@"--print-path"];
		task.standardOutput = [NSPipe new];

		[task launch];
		[task waitUntilExit];

		if (task.terminationStatus == 0)
		{
			NSData *outputData = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
			NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
			NSString *xcodePath = [[outputString stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
			xcodeBundle = XcodeBundleAtPath(xcodePath);
		}
	}

	if (!xcodeBundle)
	{
		NSURL *xcodeURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:XcodeBundleIdentifier];
		xcodeBundle = XcodeBundleAtPath(xcodeURL.path);
	}
	
	if (!xcodeBundle)
	{
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: @"Xcode.app not found."};
		*error = [NSError errorWithDomain:XcprojErrorDomain code:XcprojErrorXcodeBundleNotFound userInfo:errorInfo];
		return nil;
	}
	
	if (xcodeAppPath && ![[xcodeAppPath stringByResolvingSymlinksInPath] isEqualToString:xcodeBundle.bundlePath])
	{
		ddfprintf(stderr, @"WARNING: '%@' does not point to an Xcode app, using '%@'\n", xcodeAppPath, xcodeBundle.bundlePath);
	}
	
	return xcodeBundle;
}

static BOOL LoadXcodeFrameworks(NSBundle *xcodeBundle, NSError **error)
{
	NSURL *xcodeContentsURL = [[xcodeBundle privateFrameworksURL] URLByDeletingLastPathComponent];
	
	NSString *xcodeFrameworks = NSProcessInfo.processInfo.environment[@"XCPROJ_XCODE_FRAMEWORKS"];
	NSArray *frameworks;
	if (xcodeFrameworks)
	{
		frameworks = [xcodeFrameworks componentsSeparatedByString:@":"];
	}
	else
	{
		// Xcode 5 requires DVTFoundation, CSServiceClient, IDEFoundation and Xcode3Core
		// Xcode 6 requires DVTFoundation, DVTSourceControl, IDEFoundation and Xcode3Core
		// Xcode 7 requires DVTFoundation, DVTSourceControl, IBFoundation, IBAutolayoutFoundation, IDEFoundation and Xcode3Core
		// Xcode 7.3 requires DVTFoundation, DVTSourceControl, DVTServices, DVTPortal, IBFoundation, IBAutolayoutFoundation, IDEFoundation and Xcode3Core
		frameworks = @[ @"DVTFoundation.framework", @"DVTSourceControl.framework", @"DVTServices.framework", @"DVTPortal.framework", @"CSServiceClient.framework", @"IBFoundation.framework", @"IBAutolayoutFoundation.framework", @"IDEFoundation.framework", @"Xcode3Core.ideplugin" ];
	}
	
	for (NSString *framework in frameworks)
	{
		BOOL loaded = NO;
		NSArray *xcodeSubdirectories = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:xcodeContentsURL includingPropertiesForKeys:nil options:0 error:NULL];
		for (NSURL *frameworksDirectoryURL in xcodeSubdirectories)
		{
			NSURL *frameworkURL = [frameworksDirectoryURL URLByAppendingPathComponent:framework];
			NSBundle *frameworkBundle = [NSBundle bundleWithURL:frameworkURL];
			if (frameworkBundle)
			{
				NSError *loadError = nil;
				loaded = [frameworkBundle loadAndReturnError:&loadError];
				if (!loaded)
				{
					NSString *errorDescription = [NSString stringWithFormat:@"The %@ %@ failed to load", [framework stringByDeletingPathExtension], [framework pathExtension]];
					NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: errorDescription, NSUnderlyingErrorKey: loadError};
					*error = [NSError errorWithDomain:XcprojErrorDomain code:XcprojErrorFrameworksNotLoaded userInfo:errorInfo];
					return NO;
				}
			}
			
			if (loaded)
				break;
		}
	}

	return YES;
}

static BOOL InitializeXcodeFrameworks(NSError **error)
{
	void(*IDEInitialize)(int initializationOptions, NSError **error) = dlsym(RTLD_DEFAULT, "IDEInitialize");
	if (!IDEInitialize)
	{
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: @"IDEInitialize function not found."};
		*error = [NSError errorWithDomain:XcprojErrorDomain code:XcprojErrorIDEInitializeNotFound userInfo:errorInfo];
		return NO;
	}
	
	void(*XCInitializeCoreIfNeeded)(int initializationOptions) = dlsym(RTLD_DEFAULT, "XCInitializeCoreIfNeeded");
	if (!XCInitializeCoreIfNeeded)
	{
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: @"XCInitializeCoreIfNeeded function not found."};
		*error = [NSError errorWithDomain:XcprojErrorDomain code:XcprojErrorXCInitializeCoreIfNeededNotFound userInfo:errorInfo];
		return NO;
	}
	
	// Temporary redirect stderr to /dev/null in order not to print plugin loading errors
	// Adapted from http://stackoverflow.com/questions/4832603/how-could-i-temporary-redirect-stdout-to-a-file-in-a-c-program/4832902#4832902
	fflush(stderr);
	int saved_stderr = dup(STDERR_FILENO);
	int dev_null = open("/dev/null", O_WRONLY);
	dup2(dev_null, STDERR_FILENO);
	close(dev_null);
	// Xcode3Core.ideplugin`-[Xcode3CommandLineBuildTool run] calls IDEInitialize(NSClassFromString(@"NSApplication") == nil, &error)
	IDEInitialize(1, NULL);
	// DevToolsCore`+[PBXProject projectWithFile:errorHandler:readOnly:] calls XCInitializeCoreIfNeeded(NSClassFromString(@"NSApplication") == nil)
	XCInitializeCoreIfNeeded(0);
	fflush(stderr);
	dup2(saved_stderr, STDERR_FILENO);
	close(saved_stderr);

	return YES;
}

static void WorkaroundRadar18512876(void)
{
	NSString *xmlPlist = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><string>&#x1F680;</string></plist>";
	NSData *xmlPlistData = [xmlPlist dataUsingEncoding:NSUTF8StringEncoding];
	BOOL shouldWorkaroundRadar18512876 = ![@"\U0001F680" isEqual:[NSPropertyListSerialization propertyListWithData:xmlPlistData options:0 format:NULL error:NULL]];
	if (shouldWorkaroundRadar18512876)
	{
		Method plistWithDescriptionData = class_getClassMethod([NSDictionary class], @selector(plistWithDescriptionData:));
		id (*plistWithDescriptionDataIMP)(id, SEL, NSData *) = (__typeof__(plistWithDescriptionDataIMP))method_getImplementation(plistWithDescriptionData);
		method_setImplementation(plistWithDescriptionData, imp_implementationWithBlock(^(id _self, NSData *data) {
			if (data.length >= 5 && [[data subdataWithRange:NSMakeRange(0, 5)] isEqualToData:[@"<?xml" dataUsingEncoding:NSASCIIStringEncoding]])
				return [XMLPlistDecoder plistWithData:data];
			else
				return plistWithDescriptionDataIMP(_self, @selector(plistWithDescriptionData:), data);
		}));
	}
}

@implementation Xcproj (LoadFrameworks)

Class PBXGroup = Nil;
Class PBXProject = Nil;
Class PBXReference = Nil;
Class XCBuildConfiguration = Nil;
Class IDEBuildParameters = Nil;

+ (void) setPBXGroup:(Class)class                  { PBXGroup = class; }
+ (void) setPBXProject:(Class)class                { PBXProject = class; }
+ (void) setPBXReference:(Class)class              { PBXReference = class; }
+ (void) setXCBuildConfiguration:(Class)class      { XCBuildConfiguration = class; }
+ (void) setIDEBuildParameters:(Class)class        { IDEBuildParameters = class; }
+ (void) setValue:(id)value forUndefinedKey:(NSString *)key { /* ignore */ }

+ (BOOL) loadFrameworks:(NSError **)error
{
	static BOOL initialized = NO;
	if (initialized)
		return YES;
	
	NSBundle *xcodeBundle = LocateXcodeBundle(error);
	if (!xcodeBundle)
	{
		return NO;
	}

	BOOL frameworksLoaded = LoadXcodeFrameworks(xcodeBundle, error);
	if (!frameworksLoaded)
	{
		return NO;
	}

	BOOL xcodeInitialized = InitializeXcodeFrameworks(error);
	if (!xcodeInitialized)
	{
		return NO;
	}

	WorkaroundRadar18512876();
	
	NSArray *protocols = @[@protocol(PBXBuildFile),
	                       @protocol(PBXBuildPhase),
	                       @protocol(PBXContainer),
	                       @protocol(PBXFileReference),
	                       @protocol(PBXGroup),
	                       @protocol(PBXProject),
	                       @protocol(PBXReference),
	                       @protocol(PBXTarget),
	                       @protocol(XCBuildConfiguration),
	                       @protocol(XCConfigurationList),
	                       @protocol(IDEBuildParameters)];
	
	NSMutableArray *classErrors = [NSMutableArray new];
	for (Protocol *protocol in protocols)
	{
		NSError *classError = nil;
		Class class = XCDClassFromProtocol(protocol, &classError);
		if (class)
			[self setValue:class forKey:[NSString stringWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding]];
		else
		{
			[classErrors addObject:classError];
		}
	}
	
	BOOL isSafe = classErrors.count == 0;
	if (!isSafe)
	{
		NSString *errorDescription = @"Failed to load some classes";
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: errorDescription, XcprojClassLoadErrorsKey: classErrors};
		*error = [NSError errorWithDomain:XcprojErrorDomain code:XcprojErrorClassLoadingFailed userInfo:errorInfo];
		return NO;
	}
	
	initialized = YES;
	return YES;
}

@end
