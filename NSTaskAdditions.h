//***************************************************************************

#import <Cocoa/Cocoa.h>

//***************************************************************************

@interface NSTask (StringPipeAdditions)

+ (NSData*)launchedTaskWithLaunchPath:(NSString*)path
                            arguments:(NSArray*)arguments
                        standardInput:(NSData*)stdinData;

@end

//***************************************************************************
