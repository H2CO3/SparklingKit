// 
// SPNContext.m
// SparklingKit
//
// Created by Árpád Goretity on 01/01/2014
// Licensed under the 2-clause BSD License
//

#import "SPNContext.h"
#import "SPNValue.h"


@implementation SPNContext

- (id)init
{
	if (self = [super init]) {
		context = spn_ctx_new();
		pool = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void)dealloc
{
	spn_ctx_free(context);
	[pool release];
	[super dealloc];
}

// property getters and setters

- (NSString *)lastError
{
	return context->errmsg ? @(context->errmsg) : nil;
}

- (void *)userInfo
{
	return spn_vm_getcontext(context->vm);
}

- (void)setUserInfo:(void *)info
{
	spn_vm_setcontext(context->vm, info);
}

//////////

+ (id)context
{
	return [[[self alloc] init] autorelease];
}

// interpreter API

- (NSData *)loadString:(NSString *)str
{
	spn_uword *words = spn_ctx_loadstring(context, str.UTF8String);
	return words ? [NSData dataWithBytesNoCopy:words
					    length:context->bclist->len * sizeof(spn_uword)
				      freeWhenDone:NO] : nil;
}

- (NSData *)loadSourceFile:(NSString *)file
{
	spn_uword *words = spn_ctx_loadsrcfile(context, file.UTF8String);
	return words ? [NSData dataWithBytesNoCopy:words
					    length:context->bclist->len * sizeof(spn_uword)
				      freeWhenDone:NO] : nil;
}

- (NSData *)loadObjectFile:(NSString *)file
{
	spn_uword *words = spn_ctx_loadobjfile(context, file.UTF8String);
	return words ? [NSData dataWithBytesNoCopy:words
					    length:context->bclist->len * sizeof(spn_uword)
				      freeWhenDone:NO] : nil;
}

- (NSData *)loadURL:(NSURL *)url
{
	NSError *error = nil;
	NSString *str = [NSString stringWithContentsOfURL:url usedEncoding:NULL error:&error];
	return error ? nil : [self loadString:str];
}

- (id)executeBytecode:(NSData *)bc
{
	SpnValue retval;
	if (spn_ctx_execbytecode(context, (spn_uword *)bc.bytes, &retval) != 0) {
		return nil;
	}

	id retObj = [SPNValue cocoaObjectWithSpnValue:&retval];
	spn_value_release(&retval);
	return retObj;
}

- (id)executeString:(NSString *)str
{
	SpnValue retval;
	if (spn_ctx_execstring(context, str.UTF8String, &retval) != 0) {
		return nil;
	}

	id retObj = [SPNValue cocoaObjectWithSpnValue:&retval];
	spn_value_release(&retval);
	return retObj;
}

- (id)executeSourceFile:(NSString *)file
{
	SpnValue retval;
	if (spn_ctx_execsrcfile(context, file.UTF8String, &retval) != 0) {
		return nil;
	}

	id retObj = [SPNValue cocoaObjectWithSpnValue:&retval];
	spn_value_release(&retval);
	return retObj;
}

- (id)executeObjectFile:(NSString *)file
{
	SpnValue retval;
	if (spn_ctx_execobjfile(context, file.UTF8String, &retval) != 0) {
		return nil;
	}

	id retObj = [SPNValue cocoaObjectWithSpnValue:&retval];
	spn_value_release(&retval);
	return retObj;
}

// Miscellaneous

- (void)addGlobals:(NSDictionary *)lib
{
	// because the C strings representing the names are not copied by
	// spn_vm_addglobals(), we need to make sure that all the names are
	// valid throughout the lifetime of the context.
	// We achieve this by retaining the dictionary.
	[pool addObject:lib];

	SpnExtValue *globals = malloc(lib.count * sizeof(globals[0]));
	size_t i = 0;

	for (NSString *key in lib) {
		globals[i].name = key.UTF8String;
		globals[i].value = [SPNValue spnValueWithCocoaObject:lib[key]];
		i++;
	}

	spn_vm_addglobals(context->vm, globals, lib.count);

	for (i = 0; i < lib.count; i++) {
		spn_value_release(&globals[i].value);
	}

	free(globals);
}

- (void)addLib:(const SpnExtFunc [])lib count:(size_t)n
{
	spn_vm_addlib(context->vm, lib, n);
}

- (id)callFunction:(SPNValue *)func withArguments:(NSArray *)args
{
	SpnValue *argv = malloc(args.count * sizeof(argv[0]));
	SpnValue retVal, funcVal = func.spnValue;

	for (size_t i = 0; i < args.count; i++) {
		argv[i] = [SPNValue spnValueWithCocoaObject:args[i]];
	}

	spn_vm_callfunc(context->vm, &funcVal, &retVal, args.count, argv);

	for (size_t i = 0; i < args.count; i++) {
		spn_value_release(&argv[i]);
	}

	free(argv);

	id retObj = [SPNValue cocoaObjectWithSpnValue:&retVal];
	spn_value_release(&retVal);
	return retObj;
}

- (NSArray *)stackTrace
{
	size_t n;
	const char **st = spn_vm_stacktrace(context->vm, &n);
	NSMutableArray *arr = [[NSMutableArray alloc] init];

	for (size_t i = 0; i < n; i++) {
		[arr addObject:@(st[i])];
	}

	free(st);
	return [arr autorelease];
}

@end

