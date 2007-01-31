//***************************************************************************

#import "NSObjectAdditions.h"
#import "NSTaskAdditions.h"

#include <unistd.h>

//***************************************************************************

@interface NSFileManager (TemporaryFileCreating)

+ (NSString*) pathToEmptyTemporaryFile;

@end

//---------------------------------------------------------------------------

@implementation NSFileManager (TemporaryFileCreating)

+ (NSString*) pathToEmptyTemporaryFile
{
    char* const pathTemplate = strdup("/tmp/temp.XXXXXXXXXX");
    char* const cPath = mktemp(pathTemplate);
    
    NSString* path = [NSString stringWithUTF8String:cPath];
    
    const int fileDescriptor = open(cPath, O_WRONLY|O_CREAT|O_EXCL, S_IRUSR|S_IWUSR);
    if(fileDescriptor == -1)
    {
        perror("open failed");
        
        return nil;
    }
        
    const int closeReturnValue = close(fileDescriptor);
    if(closeReturnValue != 0) NSLog(@"fclose() returned %d instead of 0?", closeReturnValue);
    
    free(pathTemplate);
    
    return path;
}

@end

//***************************************************************************

@interface NSString (ShellQuoting)

- (NSString*) stringByShellQuoting;

@end

//---------------------------------------------------------------------------

@implementation NSString (ShellQuoting)

- (NSString*) stringByShellQuoting
{
    NSMutableString* shellQuotedString = [NSMutableString stringWithString:self];
    
    [shellQuotedString replaceOccurrencesOfString:@"'" withString:@"'\\''" options:0 range:NSMakeRange(0, [shellQuotedString length])];
    
    [shellQuotedString insertString:@"'" atIndex:0];
    [shellQuotedString insertString:@"'" atIndex:[shellQuotedString length]];
    
    return shellQuotedString;
}

@end

//***************************************************************************

@implementation NSTask (StringPipeAdditions)

+ (NSData*) launchedTaskWithLaunchPath:(NSString*)path
                             arguments:(NSArray*)arguments
                         standardInput:(NSData*)stdinData
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSString* stdinTemporaryFilePath = [NSFileManager pathToEmptyTemporaryFile];
    [stdinData writeToFile:stdinTemporaryFilePath atomically:NO];
    
    NSString* stdoutTemporaryFilePath = [NSFileManager pathToEmptyTemporaryFile];
    
    NSMutableArray* quotedArguments = [[[NSMutableArray alloc] init] autorelease];
    NSEnumerator* e = [arguments objectEnumerator];
    while(NSString* argument = [e nextObject]) [quotedArguments addObject:[argument stringByShellQuoting]];
    
    NSString* commandLineString = [NSString stringWithFormat:@"%@ %@ < %@ > %@",
        [path stringByShellQuoting],
        [quotedArguments componentsJoinedByString:@" "],
        [stdinTemporaryFilePath stringByShellQuoting],
        [stdoutTemporaryFilePath stringByShellQuoting]];
    
    const int systemReturnValue = system([commandLineString UTF8String]);
    assert(systemReturnValue != -1 && systemReturnValue != 127);
    
    NSFileHandle* temporaryFileReader = [NSFileHandle fileHandleForReadingAtPath:stdoutTemporaryFilePath];

    NSData* stdoutData = [[temporaryFileReader readDataToEndOfFile] retain];

    [[NSFileManager defaultManager] removeFileAtPath:stdinTemporaryFilePath handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:stdoutTemporaryFilePath handler:nil];
    
    [pool release];
    
    return [stdoutData autorelease];
}

@end

//***************************************************************************
