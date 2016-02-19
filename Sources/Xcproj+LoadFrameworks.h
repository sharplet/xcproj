//
//  XcodeFrameworkLoader.h
//  xcproj
//
//  Created by Adam Sharp on 19/02/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import "Xcproj.h"

extern Class PBXGroup;
extern Class PBXProject;
extern Class PBXReference;
extern Class XCBuildConfiguration;
extern Class IDEBuildParameters;

extern NSString *XcprojErrorDomain;

typedef NS_ENUM(NSInteger, XcprojError) {
	XcprojErrorXcodeBundleNotFound = 1,
	XcprojErrorFrameworksNotLoaded = 2,
	XcprojErrorIDEInitializeNotFound = 3,
	XcprojErrorXCInitializeCoreIfNeededNotFound = 4,
};

@interface Xcproj (LoadFrameworks)

+ (BOOL) loadFrameworks:(NSError **)error;

@end
