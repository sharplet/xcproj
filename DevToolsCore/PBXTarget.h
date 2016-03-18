#import <DevToolsCore/PBXBuildPhase.h>
#import <DevToolsCore/XCConfigurationList.h>
#import <IDEFoundation/IDEBuildParameters.h>

@protocol PBXTarget <NSObject>

- (NSString *) name;

- (id<XCConfigurationList>) buildConfigurationList;

- (NSString *) expandedValueForString:(NSString *)string forBuildParameters:(id<IDEBuildParameters>)buildParameters;

- (void) setBuildSetting:(NSString *)buildSetting forKeyPath:(NSString *)keyPath;

- (id<PBXBuildPhase>) buildPhaseOfClass:(Class)buildPhaseClass;
- (void) addBuildPhase:(id<PBXBuildPhase>)buildPhase;
- (id<PBXBuildPhase>) defaultFrameworksBuildPhase;
- (id<PBXBuildPhase>) defaultLinkBuildPhase;
- (id<PBXBuildPhase>) defaultSourceCodeBuildPhase;
- (id<PBXBuildPhase>) defaultResourceBuildPhase;
- (id<PBXBuildPhase>) defaultHeaderBuildPhase;

@end
