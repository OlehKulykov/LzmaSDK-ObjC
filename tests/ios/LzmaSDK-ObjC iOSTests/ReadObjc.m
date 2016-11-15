/*
 *   Copyright (c) 2015 - 2016 Kulykov Oleh <info@resident.name>
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *   THE SOFTWARE.
 */


#import <XCTest/XCTest.h>
#import "TestBaseObjc.h"

@interface ReadObjc : TestBaseObjc <LzmaSDKObjCReaderDelegate>

@end

@implementation ReadObjc

#pragma mark - LzmaSDKObjCReaderDelegate
- (void) onLzmaSDKObjCReader:(LzmaSDKObjCReader *)reader extractProgress:(float)progress {
	NSLog(@"Read progress: %f, %i %%", progress, (int)(progress * 100));
}

- (void) setUp {
    [super setUp];

	NSString * path = [self pathForTestFile:@"lzma.7z"];
	XCTAssertNotNil(path);
	XCTAssert([path length] > 0);

	NSString * writePath = [self tmpWritePath];
	XCTAssertNotNil(writePath);
	XCTAssert([writePath length] > 0);
}

- (void) testRead {

	for (NSString * file in @[@"lzma.7z", @"lzma_aes256.7z", @"lzma_aes256_encfn.7z"]) {
		LzmaSDKObjCReader * reader = [[LzmaSDKObjCReader alloc] initWithFileURL:[NSURL fileURLWithPath:[self pathForTestFile:file]]];

		reader.passwordGetter = ^NSString*(void) {
			return @"1234";
		};

		NSError * error = nil;
		[reader open:&error];
		XCTAssertNil(error);

		NSMutableArray * items = [NSMutableArray array];
		BOOL result = [reader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error){
			XCTAssertNil(error);
			XCTAssertNotNil(item);
			[items addObject:item];
			if ([item.fileName isEqualToString:@"shutuptakemoney.jpg"]) {
				XCTAssertTrue(item.originalSize == 33402);
				XCTAssertTrue(item.crc32 == 0x0b0646c5);
			} else if ([item.fileName isEqualToString:@"SouthPark.jpg"]) {
				XCTAssertTrue(item.originalSize == 40782);
				XCTAssertTrue(item.crc32 == 0x1243b886);
			} else if ([item.fileName isEqualToString:@"zombies.jpg"]) {
				XCTAssertTrue(item.originalSize == 83131);
				XCTAssertTrue(item.crc32 == 0xb5e98c78);
			}
			return YES;
		}];
		XCTAssertTrue(result);

		NSString * extractPath = [self tmpWritePath];
		result = [reader extract:items toPath:extractPath withFullPaths:NO];
		XCTAssertTrue(result);

		NSArray * readed = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extractPath error:&error];
		XCTAssertNotNil(readed);
		XCTAssertNil(error);

		XCTAssertTrue(readed.count == items.count);
		[[NSFileManager defaultManager] removeItemAtPath:extractPath error:&error];
		XCTAssertNil(error);
	}
}

@end
