#import <DevToolsCore/PBXFileReference.h>
#import <DevToolsCore/PBXBuildStyle.h>

@protocol XCBuildConfiguration <PBXBuildStyle, NSObject>

+ (BOOL) fileReference:(id<PBXFileReference>)reference isValidBaseConfigurationFile:(NSError **)error;

- (void) setBaseConfigurationReference:(id<PBXFileReference>)reference;
- (id<PBXFileReference>) baseConfigurationReference;

@end
