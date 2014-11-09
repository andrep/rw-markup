//***************************************************************************

#import "NSAttributedString+ParagraphTests.h"

//***************************************************************************

@implementation NSAttributedString (ParagraphTests)

static inline BOOL IsNewlineCharacter(const unichar c) {
  return (c == 10      /* newline (\r) */
          || c == 11   /* vertical tab */
          || c == 12   /* form feed */
          || c == 13   /* carriage return (\n) */
          || c == 2028 /* Unicode line separator */
          || c == 2029 /* Unicode paragraph separator */);
}

- (BOOL)isRangeAtStartOfParagraph:(const NSRange)range {
  if (range.location == 0) {
    return YES;
  } else if (range.location == 1) {
    const unichar firstCharacter = [[self string] characterAtIndex:0];

    if (IsNewlineCharacter(firstCharacter))
      return YES;
    else
      return NO;
  } else if (range.length == 1) {
    return IsNewlineCharacter([[self string] characterAtIndex:0]);
  }

  int i = -2;
  for (; i >= -2 && i <= 0; i++) {
    const NSRange twoCharacterRange = NSMakeRange(range.location + i, 2);

    if (NSMaxRange(twoCharacterRange) >= [self length]) continue;

    NSString* twoCharacters = [[self string] substringWithRange:twoCharacterRange];

    if (IsNewlineCharacter([twoCharacters characterAtIndex:0]) &&
        IsNewlineCharacter([twoCharacters characterAtIndex:1])) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)isRangeAtEndOfParagraph:(const NSRange)range {
  const unsigned indexAtEndOfRange = NSMaxRange(range);

  if (indexAtEndOfRange == [self length]) {
    return YES;
  } else if (indexAtEndOfRange == [self length] - 1) {
    const unichar lastCharacter = [[self string] characterAtIndex:indexAtEndOfRange];

    if (IsNewlineCharacter(lastCharacter))
      return YES;
    else
      return NO;
  }

  int i = -2;
  for (; i >= -2 && i <= 0; i++) {
    const NSRange twoCharactersRange = NSMakeRange(indexAtEndOfRange - 2, 2);

    if (NSMaxRange(twoCharactersRange) >= [self length]) continue;

    NSString* twoCharacters = [[self string] substringWithRange:twoCharactersRange];

    if (IsNewlineCharacter([twoCharacters characterAtIndex:0]) &&
        IsNewlineCharacter([twoCharacters characterAtIndex:1])) {
      return YES;
    }
  }

  return NO;
}

@end

//***************************************************************************
