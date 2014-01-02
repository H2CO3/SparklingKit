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

@interface SPNValue: NSValue {
	NSValue *helper;
}

// simple getter (non-owning)
@property (nonatomic, readonly) SpnValue spnValue;

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

