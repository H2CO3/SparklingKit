// 
// SPNValue.m
// SparklingKit
//
// Created by Árpád Goretity on 01/01/2014
// Licensed under the 2-clause BSD License
//

#import <CoreFoundation/CoreFoundation.h>

#import "SPNValue.h"

@implementation SPNValue

+ (id)cocoaObjectWithSpnValue:(SpnValue *)val
{
	switch (val->t) {
	case SPN_TYPE_NIL:	{
		return [NSNull null];
	}
	case SPN_TYPE_BOOL:	{
		return val->v.boolv ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	}
	case SPN_TYPE_NUMBER:	{
		return val->f & SPN_TFLG_FLOAT ? @(val->v.fltv) : @(val->v.intv);
	}
	case SPN_TYPE_STRING:	{
		SpnString *str = val->v.ptrv;
		return @(str->cstr);
	}
	case SPN_TYPE_ARRAY:	{
		SpnValue key, value;
		SpnArray *arr = val->v.ptrv;
		SpnIterator *it = spn_iter_new(arr);
		size_t n = spn_array_count(arr);
		size_t idx;
		BOOL isAssoc = NO;

		while ((idx = spn_iter_next(it, &key, &value)) < n) {
			if (key.t != SPN_TYPE_NUMBER || key.f & SPN_TFLG_FLOAT || key.v.intv != idx) {
				isAssoc = YES;
				break;
			}
		}

		spn_iter_free(it);
		it = spn_iter_new(arr);

		id container = isAssoc ? [NSMutableDictionary new] : [NSMutableArray new];

		while ((idx = spn_iter_next(it, &key, &value)) < n) {
			id objcValue = [self cocoaObjectWithSpnValue:&value];
			if (isAssoc) {
				id <NSCopying> objcKey = [self cocoaObjectWithSpnValue:&key];
				[container setObject:objcValue forKey:objcKey];
			} else {
				[container addObject:objcValue];
			}
		}

		spn_iter_free(it);

		return [container autorelease];
	}
	case SPN_TYPE_FUNC:
	case SPN_TYPE_USRDAT: {
		// TODO: this should be done better
		return [SPNValue valueWithSpnValue:val];
	}
	default:
		return nil;
	}
}

+ (SpnValue)spnValueWithCocoaObject:(id)obj
{
	if (obj == nil || [obj isKindOfClass:[NSNull class]]) {
		return (SpnValue){ .v = { 0 }, .t = SPN_TYPE_NIL, .f = 0 };
	} else if ([obj isKindOfClass:[NSNumber class]]) {
		// Booleans need special treatment, since NSNumber
		// does not guarantee that the type reported by -objCType
		// will match the type the object was initially created with
		
		if (obj == (id)kCFBooleanFalse) {
			return (SpnValue){ .v.boolv = 0, .t = SPN_TYPE_BOOL, .f = 0 };
		} else if (obj == (id)kCFBooleanTrue) {
			return (SpnValue){ .v.boolv = 1, .t = SPN_TYPE_BOOL, .f = 0 };
		}

		const char *type = [obj objCType];
		if (strcmp(type, @encode(float)) == 0
		 || strcmp(type, @encode(double)) == 0
		 || strcmp(type, @encode(long double)) == 0) {
			// floating-point value
			return (SpnValue) {
				.v.fltv = [obj doubleValue],
				.t = SPN_TYPE_NUMBER,
				.f = SPN_TFLG_FLOAT
			};
		} else {
			// integer value
			return (SpnValue) {
				.v.intv = [obj longValue],
				.t = SPN_TYPE_NUMBER,
				.f = 0
			};
		}
	} else if ([obj isKindOfClass:[NSString class]]) {
		return (SpnValue) {
			.v.ptrv = spn_string_new([obj UTF8String]),
			.t = SPN_TYPE_STRING,
			.f = SPN_TFLG_OBJECT
		};
	} else if ([obj isKindOfClass:[NSArray class]]) {
		SpnArray *arr = spn_array_new();

		size_t n = [obj count];
		for (size_t i = 0; i < n; i++) {
			SpnValue key = { .v.intv = i, .t = SPN_TYPE_NUMBER, .f = 0 };
			SpnValue val = [self spnValueWithCocoaObject:[obj objectAtIndex:i]];
			spn_array_set(arr, &key, &val);
			spn_value_release(&val);
		}

		return (SpnValue){ .v.ptrv = arr, .t = SPN_TYPE_ARRAY, .f = SPN_TFLG_OBJECT };
	} else if ([obj isKindOfClass:[NSDictionary class]]) {
		SpnArray *arr = spn_array_new();
		
		for (id keyObj in obj) {
			SpnValue key = [self spnValueWithCocoaObject:keyObj];
			SpnValue val = [self spnValueWithCocoaObject:[obj objectForKey:keyObj]];
			spn_array_set(arr, &key, &val);
			spn_value_release(&key);
			spn_value_release(&val);
		}

		return (SpnValue){ .v.ptrv = arr, .t = SPN_TYPE_ARRAY, .f = SPN_TFLG_OBJECT };
	} else if ([obj isKindOfClass:[SPNValue class]]) {
		SpnValue *val = [obj spnValue];
		spn_value_retain(val);
		return *val;
	} else {
		[NSException raise:@"SPNTypeException"
			    format:@"Object of class %@ cannot be converted to an SpnValue",
			    	NSStringFromClass([obj class])];
		// shut the compiler up
		return (SpnValue){ { 0 }, 0, 0 };
	}
}

+ (id)valueWithSpnValue:(SpnValue *)val
{
	return [[[self alloc] initWithSpnValue:val] autorelease];
}

- (id)initWithSpnValue:(SpnValue *)val
{
	if (self = [super init]) {
		spn_value_retain(val);
		value = *val;
	}
	return self;
}

- (void)dealloc
{
	spn_value_release(&value);
	[super dealloc];
}

- (SpnValue *)spnValue
{
	return &value;
}

- (NSString *)description
{
	switch (value.t) {
	case SPN_TYPE_FUNC:
		return [NSString stringWithFormat:@"<SPNValue: function %@ { kind: %s }>",
			value.v.fnv.name ? [NSString stringWithFormat:@"%s()", value.v.fnv.name] : @"<lambda>",
			value.f & SPN_TFLG_NATIVE ? "native" : "script"];
	case SPN_TYPE_USRDAT:
		return [NSString stringWithFormat:@"<SPNValue: user data (%p)>", value.v.ptrv];
	default:
		return [[[self class] cocoaObjectWithSpnValue:&value] description];
	}
}

// NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain]; // we're an immutable class
}

- (BOOL)isEqual:(id)other
{
	if ([other isKindOfClass:[SPNValue class]]) {
		SpnValue *otherValue = [other spnValue];
		return spn_value_equal(&value, otherValue);
	}

	return NO;
}

- (NSUInteger)hash
{
	return spn_hash_object(&value);
}

@end

