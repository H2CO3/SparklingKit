// 
// main.m
// SparklingKit
//
// Demo to illustrate the usage of the SparklingKit API
// (more to come)
//
// Created by Árpád Goretity on 02/01/2014
// Licensed under the 2-clause BSD License
//

#import <limits.h>
#import <SparklingKit/SparklingKit.h>


int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	SPNContext *ctx = [[SPNContext alloc] init];

	char buf[LINE_MAX];
	printf("$ ");
	while (fgets(buf, sizeof buf, stdin)) {
		id obj = [ctx executeString:@(buf)];
		if (obj) {
			NSLog(@">>> %@", obj);
		} else {
			NSLog(@"%@\nCall stack: %@", ctx.lastError, [ctx stackTrace]);
		}

		printf("$ ");
	}

	[ctx release];

	[pool release];
	return 0;
}

