// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FBSDKCoreKit+Internal.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitor (Testing)

@property (class, nonatomic) Class graphRequestClass;

+ (NSMutableArray<FBSDKMonitorEntry *> *)entries;
+ (void)disable;
+ (void)flush;

@end

@interface FBSDKMonitorTests : XCTestCase

@property (nonatomic) FBSDKMonitorEntry *entry;

@end

@implementation FBSDKMonitorTests

- (void)setUp
{
  [super setUp];

  [FBSDKSettings setAppID:@"fbabc123"];
  self.entry = [TestMonitorEntry testEntry];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKMonitor flush];
  [FBSDKMonitor disable];
}

- (void)testRecordingWhenDisabled {
  [FBSDKMonitor record:self.entry];

  XCTAssertEqual(FBSDKMonitor.entries.count, 0,
                 @"Should not record entries before monitor is enabled");
}

- (void)testEnabling
{
  [FBSDKMonitor enable];

  [FBSDKMonitor record:self.entry];

  XCTAssertEqualObjects(FBSDKMonitor.entries, @[self.entry],
                        @"Should record entries when monitor is enabled");
}

- (void)testFlushing
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [FBSDKMonitor flush];

  XCTAssertEqual(FBSDKMonitor.entries.count, 0,
                 @"Flushing should clear all entries");
}

- (void)testFlushingInvokesNetworker
{
  FBSDKMonitorEntry *entry2 = [TestMonitorEntry testEntryWithName:@"entry2"];
  NSArray<FBSDKMonitorEntry *> *expectedEntries = @[self.entry, entry2];

  id networkerMock = OCMClassMock([FBSDKMonitorNetworker class]);

  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];
  [FBSDKMonitor record:entry2];
  [FBSDKMonitor flush];

  OCMVerify(ClassMethod([networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL(id obj) {
    XCTAssertEqualObjects(obj, expectedEntries);
    return YES;
  }]]));

  [networkerMock stopMocking];
}

@end
