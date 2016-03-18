#import <DevToolsCore/PBXFileReference.h>
#import <DevToolsCore/XCBuildConfiguration.h>

@protocol XCConfigurationList <NSObject>

- (NSArray<XCBuildConfiguration> *) buildConfigurations;
- (NSArray<NSString> *) buildConfigurationNames;

- (NSString *) defaultConfigurationName;

@end
