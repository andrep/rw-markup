//***************************************************************************

#import <Cocoa/Cocoa.h>

#import "RWPluginFramework.h"

@class RMHTML;

//***************************************************************************

@interface MarkupTextView : RWTextView

- (void)onMarkupLanguageHelp:(id)sender;
- (void)onToggleSmartQuotes:(id)sender;
- (void)onDumpAttributes:(id)sender;

- (NSNumber*)markupEnabledForFilterStyleInSelectedRange:
        (NSString*)markupStyleName;

@end

//***************************************************************************

@interface MarkupHTML : RMHTML {
}

- (NSString*)pathToFilterCommandForMarkupStyleName:(NSString*)markupStyleName;
- (NSString*)pathToSmartQuotesFilterCommand;

@end

//***************************************************************************
