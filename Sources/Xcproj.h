//
//  XcodeFrameworkLoader.h
//  xcproj
//
//  Created by Adam Sharp on 19/02/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DevToolsCore/DevToolsCore.h>
#import <IDEFoundation/IDEFoundation.h>

extern Class PBXGroup;
extern Class PBXProject;
extern Class PBXReference;
extern Class XCBuildConfiguration;
extern Class IDEBuildParameters;

@interface Xcproj : NSObject

+ (void) loadFrameworks;

@end
