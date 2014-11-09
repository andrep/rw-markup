//***************************************************************************

#import "NSObjectAdditions.h"

#include <pthread.h>

//***************************************************************************

@implementation NSObject (KVCThreading)

- (void)valueChangedForKey:(NSString*)key {
  // pthread_main_np() appears to be undocumented on the Mac OS X manpages:
  // it returns 1 if it's called from the main thread.

  switch (pthread_main_np()) {
    case 1:
      [self willChangeValueForKey:key];
      [self didChangeValueForKey:key];
      break;
    default:
      [self performSelectorOnMainThread:@selector(willChangeValueForKey:)
                             withObject:key
                          waitUntilDone:YES];
      [self performSelectorOnMainThread:@selector(didChangeValueForKey:)
                             withObject:key
                          waitUntilDone:YES];
      break;
  }
}

- (void)performSelectorOnMainThread:(SEL)aSelector
                         withObject:(id)argument1
                         withObject:(id)argument2
                      waitUntilDone:(BOOL)wait {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  NSInvocation* invocation =
      [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];

  [invocation setSelector:aSelector];
  [invocation setArgument:&argument1 atIndex:2];
  [invocation setArgument:&argument2 atIndex:3];
  [invocation retainArguments];

  [self performSelectorOnMainThread:@selector(handleInvocation:)
                         withObject:invocation
                      waitUntilDone:wait];

  [pool release];
}

- (void)handleInvocation:(NSInvocation*)anInvocation {
  [anInvocation invokeWithTarget:self];
}

- (void)setValueOnMainThread:(id)value forKey:(NSString*)key {
  switch (pthread_main_np()) {
    case 1:
      [self setValue:value forKey:key];
      break;
    default:
      [self performSelectorOnMainThread:@selector(setValue:forKey:)
                             withObject:value
                             withObject:key
                          waitUntilDone:NO];
      break;
  }
}

@end

//***************************************************************************
