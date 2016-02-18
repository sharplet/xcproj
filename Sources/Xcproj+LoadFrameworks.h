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

@interface Xcproj (LoadFrameworks)

+ (void) loadFrameworks;

@end
