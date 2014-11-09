//***************************************************************************

#import <Cocoa/Cocoa.h>

#import "RWPluginFramework.h"

@class RMHTML;

//***************************************************************************

@interface RWTextView (MarkupTextView)

- (void)onToggleSmartQuotes:(id)sender;
- (void)onDumpAttributes:(id)sender;

- (NSNumber *)markupEnabledForFilterStyleInSelectedRange:(NSString *)markupStyleName;

@end

//***************************************************************************

@interface RMHTML (MarkupHTML)

- (NSString *)pathToFilterCommandForMarkupStyleName:(NSString *)markupStyleName;
- (NSString *)pathToSmartQuotesFilterCommand;

@end

//***************************************************************************
