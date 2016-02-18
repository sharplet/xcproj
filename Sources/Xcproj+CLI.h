//
//  Xcproj.h
//  xcproj
//
//  Created by Cédric Luthi on 07.02.11.
//  Copyright Cédric Luthi 2011. All rights reserved.
//

#import "Xcproj.h"
#import "DDCommandLineInterface.h"

@interface Xcproj (CLI) <DDCliApplicationDelegate>

- (void) addGroupNamed:(NSString *)groupName beforeGroupNamed:(NSString *)otherGroupName;
- (void) addGroupNamed:(NSString *)groupName inGroupNamed:(NSString *)otherGroupName;
- (id<PBXFileReference>) addFileAtPath:(NSString *)filePath;
- (BOOL) addFileReference:(id<PBXFileReference>)fileReference inGroupNamed:(NSString *)groupName;
- (BOOL) addFileReference:(id<PBXFileReference>)fileReference toBuildPhase:(NSString *)buildPhaseName;

@end
