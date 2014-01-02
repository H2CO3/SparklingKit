// 
// SPNValue.h
// SparklingKit
//
// Created by Árpád Goretity on 01/01/2014
// Licensed under the 2-clause BSD License
//

#import <spn/spn.h>
#import <spn/str.h>
#import <spn/array.h>

#import <Foundation/Foundation.h>

@interface SPNValue: NSObject <NSCopying> {
	SpnValue value;
}

// simple getter (non-owning)
// this is non-const only to enable retaining and releasing the
// backing value object, DO NOT MODIFY IT in any other manner
@property (nonatomic, readonly) SpnValue *spnValue;

// should be spn_value_release()'d when you're done
// returns an owning SpnValue structure, so it
// should be released after use
+ (SpnValue)spnValueWithCocoaObject:(id)obj;

// the other way around
+ (id)cocoaObjectWithSpnValue:(SpnValue *)val;

// constructors
+ (id)valueWithSpnValue:(SpnValue *)val;
- (id)initWithSpnValue:(SpnValue *)val;

@end

