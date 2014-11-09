//***************************************************************************

#include "NSTaskAdditions.h"

#include <assert.h>

//***************************************************************************

@interface Foo : NSObject

- (void)doIt;

@end

//---------------------------------------------------------------------------

static NSConditionLock* lock = nil;

@implementation Foo

- (void)doIt {
  NSAutoreleasePool* topLevelPool = [[NSAutoreleasePool alloc] init];

  static NSString* pathToTextile = @"/Users/andrep/Code/Skunkworks/"
                                   @"RapidWeaver-Plugins/Markup-3.5/"
                                   @"MarkupFilters/Textile.pl";

  // static char* const bytes = "h1. This is a textile test";
  static NSData* testData = nil;
  if (testData == nil)
    testData = [[NSData
        dataWithContentsOfFile:
            @"/Users/andrep/Desktop/Desktop Items/ET_Bitmap_BMP.cpp"] retain];
  assert(testData != nil);

  NSAutoreleasePool* subPool = [[NSAutoreleasePool alloc] init];

  NSData* data = [NSTask launchedTaskWithLaunchPath:pathToTextile
                                          arguments:nil
                                      standardInput:testData];

#if 0
    NSLog(@"Got data (%u): %@",
          [data length],
          [NSString stringWithCString:static_cast<const char*>([data bytes]) length:[data length]]);
#endif

  [subPool release];

  [topLevelPool release];

  [lock unlockWithCondition:YES];
}

@end

//---------------------------------------------------------------------------

int main(const int argc, const char* const argv[]) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  lock = [[NSConditionLock alloc] init];

  for (NSInteger i = 0; i < 10000; i++) {
    Foo* foo = [[Foo alloc] init];

    [lock lockWhenCondition:NO];

    [NSThread detachNewThreadSelector:@selector(doIt)
                             toTarget:foo
                           withObject:nil];

    [lock lockWhenCondition:YES];
    [lock unlockWithCondition:NO];

    [foo release];

    NSLog(@"At iteration %d", i);
  }

  [pool release];
}

//***************************************************************************
