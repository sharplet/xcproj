#import <DevToolsCore/PBXGroup.h>
#import <DevToolsCore/PBXFileReference.h>

@protocol PBXContainer <NSObject>

- (id<PBXGroup>) rootGroup;

- (id<PBXFileReference>) fileReferenceForPath:(NSString *)path;

@end
