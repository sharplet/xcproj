//
//  Xcproj.m
//  xcproj
//
//  Created by Cédric Luthi on 07.02.11.
//  Copyright Cédric Luthi 2011. All rights reserved.
//

#import "Xcproj+CLI.h"
#import <objc/runtime.h>

@implementation Xcproj (CLI)

static void *kProjectKey = &kProjectKey;
static void *kTargetNameKey = &kTargetNameKey;
static void *kConfigurationNameKey = &kConfigurationNameKey;

static void *kTargetKey = &kTargetKey;

// MARK: - Options

- (void) application:(DDCliApplication *)app willParseOptions:(DDGetoptLongParser *)optionsParser
{
	DDGetoptOption optionTable[] = 
	{
		// Long           Short  Argument options
		{"project",       'p',   DDGetoptRequiredArgument},
		{"target",        't',   DDGetoptRequiredArgument},
		{"configuration", 'c',   DDGetoptRequiredArgument},
		{"help",          'h',   DDGetoptNoArgument},
		{"version",       'V',   DDGetoptNoArgument},
		{nil,           0,    0},
	};
	[optionsParser addOptionsFromTable:optionTable];
}

- (id<PBXProject>) project
{
	return objc_getAssociatedObject(self, kProjectKey);
}

- (void) setProject:(NSString *)projectName
{
	if (![PBXProject isProjectWrapperExtension:[projectName pathExtension]])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The project name %@ does not have a valid extension.", projectName] exitCode:EX_USAGE];
	
	NSString *projectPath = projectName;
	if (![projectName isAbsolutePath])
		projectPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:projectName];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:projectPath])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The project %@ does not exist in this directory.", projectName] exitCode:EX_NOINPUT];
	
	objc_setAssociatedObject(self, kProjectKey, [PBXProject projectWithFile:projectPath], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	if (!objc_getAssociatedObject(self, kProjectKey))
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The '%@' project is corrupted.", projectName] exitCode:EX_DATAERR];
}

- (NSString *) targetName
{
	return objc_getAssociatedObject(self, kTargetNameKey);
}

- (id<PBXTarget>) target
{
	return objc_getAssociatedObject(self, kTargetKey);
}

- (void) setTarget:(NSString *)targetName
{
	if (objc_getAssociatedObject(self, kTargetNameKey) == targetName)
		return;
	
	objc_setAssociatedObject(self, kTargetNameKey, targetName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *) configurationName
{
	return objc_getAssociatedObject(self, kConfigurationNameKey);
}

- (void) setConfiguration:(NSString *)confiturationName
{
	if (objc_getAssociatedObject(self, kConfigurationNameKey) == confiturationName)
		return;
	
	objc_setAssociatedObject(self, kConfigurationNameKey, confiturationName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setHelp:(NSNumber *)help
{
	if ([help boolValue])
		[self printUsage:EX_OK];
}

- (void) setVersion:(NSNumber *)version
{
	if ([version boolValue])
	{
		ddprintf(@"%@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
		exit(EX_OK);
	}
}

// MARK: - App run

- (int) application:(DDCliApplication *)app runWithArguments:(NSArray *)arguments
{
	if ([arguments count] < 1)
		[self printUsage:EX_USAGE];
	
	[self.class loadFrameworks];
	
	NSString *currentDirectoryPath = [[NSFileManager defaultManager] currentDirectoryPath];
	
	if (![self project])
	{
		for (NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentDirectoryPath error:NULL])
		{
			if ([PBXProject isProjectWrapperExtension:[fileName pathExtension]])
			{
				if (![self project])
					[self setProject:fileName];
				else
				{
					ddfprintf(stderr, @"%@: The directory %@ contains more than one Xcode project. You will need to specify the project with the --project option.\n", app, currentDirectoryPath);
					return EX_USAGE;
				}
			}
		}
	}
	
	if (![self project])
	{
		ddfprintf(stderr, @"%@: The directory %@ does not contain an Xcode project.\n", app, currentDirectoryPath);
		return EX_USAGE;
	}
	
	if ([self targetName])
	{
		objc_setAssociatedObject(self, kTargetKey, [[self project] targetNamed:[self targetName]], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		if (![self target])
			@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The target %@ does not exist in this project.", [self targetName]] exitCode:EX_DATAERR];
	}
	else
	{
		NSArray *targets = [[self project] targets];
		if ([targets count] == 0)
			@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The project %@ does not contain any target.", [[self project] name]] exitCode:EX_DATAERR];
	}
	
	if ([self configurationName])
	{
		if (![[[[self project] buildConfigurationList] buildConfigurationNames] containsObject:[self configurationName]])
			@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The project %@ does not contain a configuration named \"%@\".", [[self project] name], [self configurationName]] exitCode:EX_DATAERR];
	}
	
	NSString *action = [arguments objectAtIndex:0];
	if (![[self allowedActions] containsObject:action])
		[self printUsage:EX_USAGE];
	
	if ([@[ @"list-headers", @"add-resources-bundle" ] containsObject:action] && ![self target])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The \"%@\" action requires a target to be specified.", action] exitCode:EX_USAGE];
	
	NSArray *actionArguments = nil;
	if ([arguments count] >= 2)
		actionArguments = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];
	else
		actionArguments = [NSArray array];
	
	NSArray *actionParts = [[action componentsSeparatedByString:@"-"] valueForKeyPath:@"capitalizedString"];
	NSMutableString *selectorString = [NSMutableString stringWithString:[actionParts componentsJoinedByString:@""]];
	[selectorString replaceCharactersInRange:NSMakeRange(0, 1) withString:[[selectorString substringToIndex:1] lowercaseString]];
	[selectorString appendString:@":"];
	SEL actionSelector = NSSelectorFromString(selectorString);
	return [[self performSelector:actionSelector withObject:actionArguments] intValue];
}

// MARK: - Actions

- (NSArray *) allowedActions
{
	return [NSArray arrayWithObjects:@"list-targets", @"list-headers", @"read-build-setting", @"write-build-setting", @"add-xcconfig", @"add-resources-bundle", @"touch", nil];
}

- (void) printUsage:(int)exitCode
{
	ddprintf(@"Usage: %@ [options] <action> [arguments]\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleExecutableKey]);
	ddprintf(@"\nOptions:\n"
	         @" -h, --help              Show this help text and exit\n"
	         @" -V, --version           Show program version and exit\n"
	         @" -p, --project           Path to an Xcode project (*.xcodeproj file). If not specified, the project in the current working directory is used\n"
	         @" -t, --target            Name of the target. If not specified, the action is performed at the project level. Required for the `list-headers` and `add-resources-bundle` actions\n"
	         @" -c, --configuration     Name of the configuration. If not specified, the default configuration (i.e. for command-line builds) is used\n"
	         @"\nActions:\n"
	         @" * list-targets\n"
	         @"     List all the targets in the project\n\n"
	         @" * list-headers [All|Public|Project|Private] (default=Public)\n"
	         @"     List headers from the `Copy Headers` build phase\n\n"
	         @" * read-build-setting <build_setting>\n"
	         @"     Evaluate a build setting and print its value. If the build setting does not exist, nothing is printed\n\n"
	         @" * write-build-setting <build_setting> <value>\n"
	         @"     Assign a value to a build setting. If the build setting does not exist, it is added to the target\n\n"
	         @" * add-xcconfig <xcconfig_path>\n"
	         @"     Add an xcconfig file to the project and base all configurations on it\n\n"
	         @" * add-resources-bundle <bundle_path>\n"
	         @"     Add a bundle to the project and in the `Copy Bundle Resources` build phase\n\n"
	         @" * touch\n"
	         @"     Rewrite the project file\n");
	exit(exitCode);
}

- (NSNumber *) listTargets:(NSArray *)arguments
{
	if ([arguments count] > 0)
		[self printUsage:EX_USAGE];
	
	for (id<PBXTarget> target in [[self project] targets])
		ddprintf(@"%@\n", [target name]);
	
	return [[[self project] targets] count] > 0 ? @(EX_OK) : @(EX_SOFTWARE);
}

- (NSNumber *) listHeaders:(NSArray *)arguments
{
	if ([arguments count] > 1)
		[self printUsage:EX_USAGE];
	
	NSString *headerRole = @"Public";
	if ([arguments count] == 1)
		headerRole = [[arguments objectAtIndex:0] capitalizedString];
	
	NSArray *allowedValues = [NSArray arrayWithObjects:@"All", @"Public", @"Project", @"Private", nil];
	if (![allowedValues containsObject:headerRole])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"list-headers argument must be one of {%@}.", [allowedValues componentsJoinedByString:@", "]] exitCode:EX_USAGE];
	
	id<PBXBuildPhase> headerBuildPhase = [[self target] defaultHeaderBuildPhase];
	for (id<PBXBuildFile> buildFile in [headerBuildPhase buildFiles])
	{
		NSArray *attributes = [buildFile attributes];
		if ([attributes containsObject:headerRole] || [headerRole isEqualToString:@"All"])
			ddprintf(@"%@\n", [buildFile absolutePath]);
	}
	
	return @(EX_OK);
}

- (NSNumber *) readBuildSetting:(NSArray *)arguments
{
	if ([arguments count] != 1)
		[self printUsage:EX_USAGE];
	
	NSString *buildSetting = [arguments objectAtIndex:0];
	NSString *settingString = [NSString stringWithFormat:@"$(%@)", buildSetting];
	NSString *configurationName = [self configurationName] ?: [[[self project] buildConfigurationList] defaultConfigurationName];
	id<IDEBuildParameters> buildParameters = [[IDEBuildParameters alloc] initForBuildWithConfigurationName:configurationName];
	NSString *expandedString;
	if ([self target])
		expandedString = [[self target] expandedValueForString:settingString forBuildParameters:buildParameters];
	else
		expandedString = [[self project] expandedValueForString:settingString forBuildParameters:buildParameters];
	
	if ([expandedString length] > 0)
		ddprintf(@"%@\n", expandedString);
	
	return @(EX_OK);
}

- (NSNumber *) writeBuildSetting:(NSArray *)arguments
{
	if ([arguments count] != 2)
		[self printUsage:EX_USAGE];
	
	NSString *buildSetting = arguments[0];
	NSString *value = arguments[1];
	if ([self target])
	{
		[[self target] setBuildSetting:value forKeyPath:buildSetting];
	}
	else
	{
		for (id<XCBuildConfiguration> buildConfiguration in [[[self project] buildConfigurationList] buildConfigurations])
		{
			if ([self configurationName])
			{
				if ([[buildConfiguration name] isEqualToString:[self configurationName]])
				{
					[buildConfiguration setBuildSetting:value forKeyPath:buildSetting];
					break;
				}
			}
			else
			{
				[buildConfiguration setBuildSetting:value forKeyPath:buildSetting];
			}
		}
	}
	
	return [self writeProject];
}

- (NSNumber *) writeProject
{
	BOOL written = [[self project] writeToFileSystemProjectFile:YES userFile:NO checkNeedsRevert:NO];
	if (!written)
	{
		ddfprintf(stderr, @"Could not write '%@' to file system.", [self project]);
		return @(EX_IOERR);
	}
	return @(EX_OK);
}

- (NSNumber *) addXcconfig:(NSArray *)arguments
{
	if ([arguments count] != 1)
		[self printUsage:EX_USAGE];
	
	NSString *xcconfigPath = [arguments objectAtIndex:0];

	if (![[NSFileManager defaultManager] fileExistsAtPath:xcconfigPath])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The configuration file %@ does not exist in this directory.", xcconfigPath] exitCode:EX_NOINPUT];
	
	id<PBXFileReference> xcconfig = [self addFileAtPath:xcconfigPath];
	
	NSError *error = nil;
	if (![XCBuildConfiguration fileReference:xcconfig isValidBaseConfigurationFile:&error])
		@throw [DDCliParseException parseExceptionWithReason:[NSString stringWithFormat:@"The configuration file %@ is not valid. %@", xcconfigPath, [error localizedDescription]] exitCode:EX_USAGE];
	
	id<XCConfigurationList> buildConfigurationList = [[self project] buildConfigurationList];
	NSArray *buildConfigurations = [buildConfigurationList buildConfigurations];
	for (id<XCBuildConfiguration> configuration in buildConfigurations)
		[configuration setBaseConfigurationReference:xcconfig];
	
	[self addGroupNamed:@"Configurations" beforeGroupNamed:@"Frameworks"];
	[self addFileReference:xcconfig inGroupNamed:@"Configurations"];
	
	return [self writeProject];
}

- (NSNumber *) addResourcesBundle:(NSArray *)arguments
{
	[self addGroupNamed:@"Bundles" inGroupNamed:@"Frameworks"];
	
	for (NSString *resourcesBundlePath in arguments)
	{
		id<PBXFileReference> bundleReference = [self addFileAtPath:resourcesBundlePath];
		[self addFileReference:bundleReference inGroupNamed:@"Bundles"];
		[self addFileReference:bundleReference toBuildPhase:@"Resources"];
	}
	
	return [self writeProject];
}

- (NSNumber *) touch:(NSArray *)arguments
{
	return [self writeProject];
}

/*
- (void) printBuildPhases
{
	for (NSString *buildPhase in [NSArray arrayWithObjects:@"Frameworks", @"Link", @"SourceCode", @"Resource", @"Header", nil])
	{
		ddprintf(@"%@\n", buildPhase);
		SEL buildPhaseSelector = NSSelectorFromString([NSString stringWithFormat:@"default%@BuildPhase", buildPhase]);
		id<PBXBuildPhase> buildPhase = [target performSelector:buildPhaseSelector];
		for (id<PBXBuildFile> buildFile in [buildPhase buildFiles])
		{
			ddprintf(@"\t%@\n", [buildFile absolutePath]);
		}
		ddprintf(@"\n");
	}
}
*/

// MARK: - Xcode project manipulation

- (id<PBXGroup>) groupNamed:(NSString *)groupName inGroup:(id<PBXGroup>)rootGroup parentGroup:(id<PBXGroup> *) parentGroup
{
	for (id<PBXGroup> group in [rootGroup children])
	{
		if ([group isKindOfClass:[PBXGroup class]])
		{
			if (parentGroup)
				*parentGroup = rootGroup;
			
			if ([[group name] isEqualToString:groupName])
			{
				return group;
			}
			else
			{
				id<PBXGroup> subGroup = [self groupNamed:groupName inGroup:group parentGroup:parentGroup];
				if (subGroup)
					return subGroup;
			}
		}
	}
	
	if (parentGroup)
		*parentGroup = nil;
	return nil;
}

- (id<PBXGroup>) groupNamed:(NSString *)groupName parentGroup:(id<PBXGroup> *) parentGroup
{
	return [self groupNamed:groupName inGroup:[[self project] rootGroup] parentGroup:parentGroup];
}

- (void) addGroupNamed:(NSString *)groupName beforeGroupNamed:(NSString *)otherGroupName
{
	id<PBXGroup> parentGroup = nil;
	id<PBXGroup> otherGroup = [self groupNamed:otherGroupName parentGroup:&parentGroup];
	NSUInteger otherGroupIndex = [[parentGroup children] indexOfObjectIdenticalTo:otherGroup];
	
	if (otherGroupIndex == NSNotFound)
		otherGroupIndex = 0;
	
	id<PBXGroup> previousGroup = [[parentGroup children] objectAtIndex:MAX((NSInteger)(otherGroupIndex) - 1, 0)];
	if ([[previousGroup name] isEqualToString:groupName])
		return;
	
	id<PBXGroup> group = [PBXGroup groupWithName:groupName];
	[parentGroup insertItem:group atIndex:otherGroupIndex];
}

- (void) addGroupNamed:(NSString *)groupName inGroupNamed:(NSString *)otherGroupName
{
	id<PBXGroup> otherGroup = [self groupNamed:otherGroupName parentGroup:NULL];
	
	for (id<PBXGroup> group in [otherGroup children])
	{
		if ([group isKindOfClass:[PBXGroup class]] && [[group name] isEqualToString:groupName])
			return;
	}
	
	id<PBXGroup> group = [PBXGroup groupWithName:groupName];
	[otherGroup addItem:group];
}

- (id<PBXFileReference>) addFileAtPath:(NSString *)filePath
{
	if (![filePath hasPrefix:@"/"])
		filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:filePath];
	
	id<PBXFileReference> fileReference = [[self project] fileReferenceForPath:filePath];
	if (!fileReference)
	{
		NSArray *references = [[[self project] rootGroup] addFiles:[NSArray arrayWithObject:filePath] copy:NO createGroupsRecursively:NO];
		fileReference = [references lastObject];
	}
	return fileReference;
}

- (BOOL) addFileReference:(id<PBXFileReference>)fileReference inGroupNamed:(NSString *)groupName
{
	id<PBXGroup> group = [self groupNamed:groupName parentGroup:NULL];
	if (!group)
		group = [[self project] rootGroup];
	
	if ([group containsItem:fileReference])
		return YES;
	
	[group addItem:fileReference];
	
	return YES;
}

- (BOOL) addFileReference:(id<PBXFileReference>)fileReference toBuildPhase:(NSString *)buildPhaseName
{
	Class buildPhaseClass = NSClassFromString([NSString stringWithFormat:@"PBX%@BuildPhase", buildPhaseName]);
	id<PBXBuildPhase> buildPhase = [[self target] buildPhaseOfClass:buildPhaseClass];
	if (!buildPhase)
	{
		if ([buildPhaseClass respondsToSelector:@selector(buildPhase)])
		{
			buildPhase = [buildPhaseClass performSelector:@selector(buildPhase)];
			[[self target] addBuildPhase:buildPhase];
		}
	}
	
	if ([buildPhase containsFileReferenceIdenticalTo:fileReference])
		return YES;
	
	return [buildPhase addReference:fileReference];
}

@end
