//
//  XCPProject.h
//  xcproj
//
//  Created by Adam Sharp on 16/03/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import "XCPContainer.h"
#import "PBXProject.h"

@interface XCPProject : XCPContainer
+ (nullable instancetype)projectWithFile:(nonnull NSString *)projectAbsolutePath;
@end

@interface XCPProject (PBXProject) <PBXProject>
@end
