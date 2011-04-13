#import "PBXReference.h"

@protocol PBXGroup <PBXReference, NSObject>

+ (id<PBXGroup>) groupWithName:(NSString *)aName;

- (NSArray *) children; // PBXReference

- (void) addItem:(id<PBXReference>)item;
- (void) insertItem:(id<PBXReference>)item atIndex:(NSUInteger)index;

// The 'files' parameter must be an array of absolute paths (NSString)
- (NSArray *) addFiles:(NSArray *)files copy:(BOOL)copy createGroupsRecursively:(BOOL)createGroupsRecursively; // PBXFileReference

@end
