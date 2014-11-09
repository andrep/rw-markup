//***************************************************************************

#import <Cocoa/Cocoa.h>

//***************************************************************************

@interface NSAttributedString (ParagraphTests)

- (BOOL)isRangeAtStartOfParagraph:(const NSRange)range;
- (BOOL)isRangeAtEndOfParagraph:(const NSRange)range;

@end

//***************************************************************************
