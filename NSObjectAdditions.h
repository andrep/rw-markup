//***************************************************************************

#import <Cocoa/Cocoa.h>

//***************************************************************************

@interface NSObject (KVCThreading)

- (void) valueChangedForKey:(NSString*)key;
- (void) setValueOnMainThread:(id)value forKey:(NSString*)key;

@end

//***************************************************************************
