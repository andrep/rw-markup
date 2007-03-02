//***************************************************************************

#import "NSAttributedString+ParagraphTests.h"

//***************************************************************************

@implementation NSAttributedString (ParagraphTests)

static inline BOOL IsNewlineCharacter(const unichar c)
{
	return (c == 10 /* \r */ || c == 13 /* \n */);
}
									  
- (BOOL) isRangeAtStartOfParagraph:(const NSRange)range
{
	if(range.location == 0) return YES;
	
	if(range.location == 1)
	{
		const unichar firstCharacter = [[self string] characterAtIndex:0];
		
		if(IsNewlineCharacter(firstCharacter)) return YES;
		else return NO;
	}
		
	const NSRange previousTwoCharactersRange = NSMakeRange(range.location-2, 2);
	
	if(previousTwoCharactersRange.location >= 0
	   && previousTwoCharactersRange.location+previousTwoCharactersRange.length < [self length])
	{
		NSString* previousTwoCharacters = [[self string] substringWithRange:previousTwoCharactersRange];
		
		if(IsNewlineCharacter([previousTwoCharacters characterAtIndex:0])
		   && IsNewlineCharacter([previousTwoCharacters characterAtIndex:1]))
		{
			return YES;
		}
	}

	return NO;
}

- (BOOL) isRangeAtEndOfParagraph:(const NSRange)range
{
	const unsigned indexAtEndOfRange = range.location+range.length;
	
	if(indexAtEndOfRange == [self length]) return YES;
	
	if(indexAtEndOfRange == [self length]-1)
	{
		const unichar lastCharacter = [[self string] characterAtIndex:indexAtEndOfRange];
		
		if(IsNewlineCharacter(lastCharacter)) return YES;
		else return NO;
	}
	
	const NSRange nextTwoCharactersRange = NSMakeRange(indexAtEndOfRange, 2);
	
	NSString* nextTwoCharacters = [[self string] substringWithRange:nextTwoCharactersRange];
	
	if(IsNewlineCharacter([nextTwoCharacters characterAtIndex:0])
	   && IsNewlineCharacter([nextTwoCharacters characterAtIndex:1]))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

@end

//***************************************************************************
