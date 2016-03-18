//
//  XCPProject.m
//  xcproj
//
//  Created by Adam Sharp on 11/03/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import <objc/runtime.h>
#import "Xcproj.h"
#import "XCPObject.h"

const void *kBackingClassKey = &kBackingClassKey;
const void *kBackingObjectKey = &kBackingObjectKey;

Class BackingClass(Class self)
{
	Class backingClass = objc_getAssociatedObject(self, kBackingClassKey);
	if (backingClass)
	{
		return backingClass;
	}

	NSString *className = [NSStringFromClass(self) stringByReplacingOccurrencesOfString:@"XCP" withString:@"PBX"];
	backingClass = NSClassFromString(className);
	objc_setAssociatedObject(self, kBackingClassKey, backingClass, OBJC_ASSOCIATION_ASSIGN);
	return backingClass;
}

id BackingObject(id self)
{
	return objc_getAssociatedObject(self, kBackingObjectKey);
}

@implementation XCPObject

+ (instancetype)allocWithZone:(NSZone *)zone
{
	id this = [super allocWithZone:zone];
	id that = [BackingClass(self) allocWithZone:zone];
	objc_setAssociatedObject(this, kBackingObjectKey, that, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return this;
}

+ (BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] || [BackingClass(self) respondsToSelector:aSelector];
}

+ (id)forwardingTargetForSelector:(SEL)aSelector
{
	return BackingClass(self);
}

+ (NSString *)description
{
	return [NSString stringWithFormat:@"%@(%@)", [super description], [BackingClass(self) description]];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] || [BackingObject(self) respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return BackingObject(self);
}

- (BOOL)isKindOfClass:(Class)aClass
{
	return [super isKindOfClass:aClass] || [BackingObject(self) isKindOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
	return [super conformsToProtocol:aProtocol] || [BackingObject(self) conformsToProtocol:aProtocol];
}

- (NSString *)description
{
	return [BackingObject(self) description];
}

@end
