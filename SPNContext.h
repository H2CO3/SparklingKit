// 
// SPNContext.h
// SparklingKit
//
// Created by Árpád Goretity on 01/01/2014
// Licensed under the 2-clause BSD License
//

#import <spn/spn.h>
#import <spn/ctx.h>

#import <Foundation/Foundation.h>

#import "SPNValue.h"

@interface SPNContext: NSObject {
	SpnContext *context;
	NSMutableArray *pool;
}

// last error message
@property (nonatomic, readonly) NSString *lastError;

// this user info will be passed to called native functions;
// the default is the backing SpnContext structure
@property (nonatomic) void *userInfo;

// YES if the last error was a runtime error, NO otherwise (syntax/semantic error)
@property (nonatomic, readonly) BOOL isRuntimeError;

// returns a new autoreleased context instance
+ (id)context;

// interpreter API
// 
// load* methods parse and compile the source if necessary,
// then they add the resulting bytecode to an internal list,
// returning the created bytecode as an NSData object
// 
// execute*** methods will also run the resulting bytecode,
// and they return the result of the execution
// their return value is a serializable object:
//  - NSNull		nil
//  - NSNumber		booleans, integral and floating-point numbers)
//  - NSString		strings)
//  - NSArray		only arrays with consecutive integer keys that start from 0)
//  - NSDictionary	every other kind of (associative) array
//  - SPNValue		functions and user data (this is a subclass of NSValue)
//
- (NSData *)loadString:(NSString *)str;
- (NSData *)loadSourceFile:(NSString *)file;
- (NSData *)loadObjectFile:(NSString *)file;
- (NSData *)loadURL:(NSURL *)url;

- (id <NSCopying>)executeBytecode:(NSData *)bc;
- (id <NSCopying>)executeString:(NSString *)str;
- (id <NSCopying>)executeSourceFile:(NSString *)file;
- (id <NSCopying>)executeObjectFile:(NSString *)file;

// this roughly corresponds to and spn_vm_addglobals()
// the keys must be NSString objects, the values can be of any of the
// serializable types discussed above.
- (void)addGlobals:(NSDictionary *)lib;

// this maps 1:1 to spn_vm_addlib
- (void)addLib:(const SpnExtFunc [])lib count:(size_t)n;

// `func' shall wrap an SpnValue of function type, which this method will call
// with the specified arguments. Returns the return value of the function
// which should be spn_value_release()'d after use
- (id)callFunction:(SPNValue *)func withArguments:(NSArray *)args;

// returns an array of strings that contain the names of the functions
// on the call stack of the virtual machine
- (NSArray *)stackTrace;

@end

