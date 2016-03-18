//
//  Xcproj.h
//  xcproj
//
//  Created by Cédric Luthi on 07.02.11.
//  Copyright Cédric Luthi 2011. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Xcproj/DevToolsCore.h>
#import <Xcproj/IDEFoundation.h>
#import <Xcproj/XCPObject.h>
#import <Xcproj/XCPContainer.h>
#import <Xcproj/XCPProject.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *XcprojErrorDomain;
extern NSString *XcprojClassLoadErrorsKey;

extern Class PBXGroup;
extern Class PBXProject;
extern Class PBXReference;
extern Class XCBuildConfiguration;
extern Class IDEBuildParameters;

typedef NS_ENUM(NSInteger, XcprojError) {
	XcprojErrorXcodeBundleNotFound = 1,
	XcprojErrorFrameworksNotLoaded = 2,
	XcprojErrorIDEInitializeNotFound = 3,
	XcprojErrorXCInitializeCoreIfNeededNotFound = 4,
	XcprojErrorClassLoadingFailed = 5,
};

@interface Xcproj : NSObject

- (nullable id<PBXProject>)projectAtPath:(NSString *)path;

- (void) addGroupNamed:(NSString *)groupName beforeGroupNamed:(NSString *)otherGroupName;
- (void) addGroupNamed:(NSString *)groupName inGroupNamed:(NSString *)otherGroupName;
- (nullable id<PBXFileReference>) addFileAtPath:(NSString *)filePath;
- (BOOL) addFileReference:(id<PBXFileReference>)fileReference inGroupNamed:(NSString *)groupName;
- (BOOL) addFileReference:(id<PBXFileReference>)fileReference toBuildPhase:(NSString *)buildPhaseName;

@end

NS_ASSUME_NONNULL_END
