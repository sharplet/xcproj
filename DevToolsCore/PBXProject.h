#import "PBXTarget.h"
#import "XCConfigurationList.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PBXProject <PBXContainer, NSObject>

+ (BOOL) isProjectWrapperExtension:(NSString *)extension;
+ (nullable id<PBXProject>) projectWithFile:(NSString *)projectAbsolutePath;

- (NSArray<id <PBXTarget>> *) targets;
- (nullable id<PBXTarget>) targetNamed:(NSString *)targetName;

@property (nonatomic, copy, readonly) NSString *name;

- (id<XCConfigurationList>) buildConfigurationList;

- (nullable NSString *) expandedValueForString:(NSString *)string forBuildParameters:(id<IDEBuildParameters>)buildParameters;

- (BOOL) writeToFileSystemProjectFile:(BOOL)projectWrite userFile:(BOOL)userWrite checkNeedsRevert:(BOOL)checkNeedsRevert;

@end

NS_ASSUME_NONNULL_END
