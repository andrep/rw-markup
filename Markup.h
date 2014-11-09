//***************************************************************************

#import <Cocoa/Cocoa.h>

#import "RWPluginFramework.h"

//***************************************************************************

#pragma mark Logging

#if ENABLE_LOGGING
#define Log NSLog
#define LOG_ENTRY                         \
  NSLog(@"Entered: %s (%@:%d)", __func__, \
        [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__);
#else
#define Log(...) \
  do {           \
  } while (0);
#define LOG_ENTRY \
  do {            \
  } while (0);
#endif

//***************************************************************************

@interface Markup : RWAbstractPlugin<NSMenuDelegate> {
 @public
  BOOL usingSmartQuotes;
  NSString* _uniqueID;
}

+ (Markup*)sharedMarkupPlugin;
+ (NSBundle*)sharedBundle;

+ (NSArray*)markupStyles;

+ (NSNumber*)markupEnabledForFilterStyleInSelectedRange:(NSString*)markupStyleName;

+ (void)addMarkupMenuItem;

@end

//***************************************************************************

extern const NSString* const kMarkupStyleFilterCommand;
extern const NSString* const kMarkupStyleName;

extern const NSInteger kMarkupTextMenuItemTag;

//***************************************************************************
