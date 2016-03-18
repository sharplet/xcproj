//
//  XCPProject.m
//  xcproj
//
//  Created by Adam Sharp on 16/03/2016.
//  Copyright © 2016 Cédric Luthi. All rights reserved.
//

#import <objc/runtime.h>
#import "Xcproj.h"
#import "XCPProject.h"
#import "XCPObject+Private.h"

@implementation XCPProject

+ (instancetype)projectWithFile:(NSString *)projectAbsolutePath {
	id project = [BackingClass(self) projectWithFile:projectAbsolutePath];
	if (!project) { return nil; }
	id this = [self new];
	objc_setAssociatedObject(this, kBackingObjectKey, project, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return this;
}

@end
