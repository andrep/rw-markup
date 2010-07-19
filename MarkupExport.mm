//***************************************************************************

#import "MarkupTextView.h"

//***************************************************************************

@interface MarkupTextView (NewExport)

- (void) onNewExport:(id)sender;
- (NSArray*) stringBySplittingBlockLevelHTMLElements:(NSAttributedString*)rawSourceString;

@end

//***************************************************************************

@implementation MarkupTextView (NewExport)

- (void) onNewExport:(id)sender
{
    // We export the HTML in two passes: the first pass splits the string into
    // block-level elements in HTML, such as paragraphs, headings, tables, etc.
    // (To avoid confusion with NSTextBlocks and NSTextTableBlocks, we use the
    // term 'chunk' here.)  The second pass processes each block for span-level
    // elements.
    
    //NSMutableString* html = [[NSMutableString alloc] init];
    
    NSTextStorage* textStorage = [self textStorage];
    
    NSRange rangeLimit = NSMakeRange(0, [textStorage length]);
    
    // First pass: split the entire string into block-level elements ("chunks")
    
	//NSArray* array = [self stringBySplittingBlockLevelHTMLElements:[self textStorage]];
}

- (NSArray*) latestMarkupTags
{
	NSData* markupData = [NSData dataWithContentsOfFile:[[NSBundle bundleWithIdentifier:@"com.realmac.rwkit"] 
										pathForResource:@"Markup" 
												 ofType:@"plist"]];
	
	NSArray* markup = [NSPropertyListSerialization propertyListFromData:markupData 
													   mutabilityOption:NSPropertyListImmutable
																 format:nil
													   errorDescription:nil];
	
	return markup;
}

- (NSArray*) stringBySplittingBlockLevelHTMLElements:(NSAttributedString*)rawAttributedSourceString
{
	// Note that we use both an NSAttributedString and an NSString here, since
	// the NSString API is much richer and enables us to much more easily
	// perform certain operations (such as string searching).  In general, we
	// try to work with the NSAttributedString, but if it doesn't easily support
	// the operation we want, we find out the appropriate range in the NSString
	// and then apply the required transformation to both the NSAttributedString
	// and the NSString.
	
	NSMutableArray* chunks = [[[NSMutableArray alloc] init] autorelease];

	NSMutableAttributedString* attributedSourceString = [[[NSMutableAttributedString alloc] initWithAttributedString:rawAttributedSourceString] autorelease];

	NSMutableString* sourceString = [[[NSMutableString alloc] initWithString:[attributedSourceString string]] autorelease];

	// Canonicalise line endings to \n
	
	for(;;){
		BOOL foundUncanonicalisedLineEnding = NO;
		
		NSLog(@"Canonicalise line endings...");
		
		NSRange rnRange = [sourceString rangeOfString:@"\r\n"];
		if(rnRange.location != NSNotFound){
			foundUncanonicalisedLineEnding = YES;
			[attributedSourceString replaceCharactersInRange:rnRange withString:@"\n"];
			[sourceString replaceCharactersInRange:rnRange withString:@"\n"];
		}
		
		NSRange rRange = [sourceString rangeOfString:@"\r"];
		if(rRange.location != NSNotFound){
			foundUncanonicalisedLineEnding = YES;
			[attributedSourceString replaceCharactersInRange:rRange withString:@"\n"];
			[sourceString replaceCharactersInRange:rRange withString:@"\n"];
		}
				
		if(!foundUncanonicalisedLineEnding) break;
	}
	
	// Read in the latest markup tags from RWKit's markup.plist
	// file, and turn it into a key-value dictionary so we can look up tag names
	// quickly
	
	NSArray* latestMarkupTagsArray = [self latestMarkupTags];
	NSMutableDictionary* latestMarkupTags = [[NSMutableDictionary alloc] init];
	NSEnumerator* latestMarkupTagsEnumerator = [latestMarkupTagsArray objectEnumerator];
	NSDictionary* markupTag = nil;
	while(markupTag = [latestMarkupTagsEnumerator nextObject]){
		NSString* markupTagName = [markupTag objectForKey:@"name"];
		if(markupTagName == nil) continue;
		
		[latestMarkupTags setObject:markupTag forKey:markupTagName];
	}
	NSLog(@"Latest markup tags:\n%@", latestMarkupTags);
	
	// Find the first occurence of either \n\n or a RapidWeaver attribute that's
	// an HTML block (such as a heading)
	
	NSRange fullRangeLimit = NSMakeRange(0, [attributedSourceString length]);
	
	BOOL inTextBlock = NO;
	unsigned int currentIndex = 0;
	while (currentIndex < fullRangeLimit.length){
		NSLog(@"Looking for next block... (current index is %u)", currentIndex);
		
		// Find out where the next kRWTextViewMarkupDirectivesAttribute is
		NSRange rangeLimit = NSMakeRange(currentIndex, fullRangeLimit.length-currentIndex);
		NSRange textBlockLevelRWMarkupAttributeRange = NSMakeRange(NSNotFound, 0);
		NSRange range = NSMakeRange(currentIndex, 0);
		
		NSLog(@"rangeLimit now %u/%u", rangeLimit.location, rangeLimit.length);
		
		for (unsigned int attributeSearchLocationIndex = currentIndex;
			 attributeSearchLocationIndex < NSMaxRange(rangeLimit);
			 attributeSearchLocationIndex = NSMaxRange(range)){
			
			rangeLimit = NSMakeRange(attributeSearchLocationIndex, fullRangeLimit.length-attributeSearchLocationIndex);
			
			NSDictionary* attributes = [attributedSourceString attributesAtIndex:attributeSearchLocationIndex
														   longestEffectiveRange:&range
																		 inRange:rangeLimit];
			NSDictionary* rwMarkupAttribute = [attributes objectForKey:@"kRWTextViewMarkupDirectivesAttribute"];
			
			if (rwMarkupAttribute == nil){
				NSLog(@"not in an rwMarkupAttribute block! %u/%u", range.location, range.length);
				if (inTextBlock){
					NSLog(@"adding...");
					inTextBlock = NO;
					textBlockLevelRWMarkupAttributeRange = range;
					break;
				}else {
					continue;
				}
			}
			
			rwMarkupAttribute = [latestMarkupTags objectForKey:[rwMarkupAttribute objectForKey:@"name"]];
			
			if([[rwMarkupAttribute objectForKey:@"level"] isEqualTo:@"textblock"]){
				NSLog(@"found a text block");
				textBlockLevelRWMarkupAttributeRange = range;
				inTextBlock = YES;
				break;
			}
			
			NSLog(@"End: current range is %u/%u (%u): %@",
				  range.location, range.length, attributeSearchLocationIndex, rwMarkupAttribute);
		}
		
		NSLog(@"textBlockLevelRWMarkupAttributeRange is %u/%u",
			  textBlockLevelRWMarkupAttributeRange.location, textBlockLevelRWMarkupAttributeRange.length);
		
		if (textBlockLevelRWMarkupAttributeRange.location == NSNotFound) break;
		
		// Find where the next \n\n is within the attribute range, if any
		NSRange nnSearchRange = textBlockLevelRWMarkupAttributeRange;
		while (nnSearchRange.location != NSNotFound){
			nnSearchRange = [sourceString rangeOfString:@"\n\n" options:0 range:nnSearchRange];
			
			if (nnSearchRange.location != NSNotFound){
				[chunks addObject:[attributedSourceString attributedSubstringFromRange:nnSearchRange]];
				NSLog(@"NN at %u/%u", nnSearchRange.location, nnSearchRange.length);
			}
		}
		
		// Break out if there's no more textblock markers
		if (textBlockLevelRWMarkupAttributeRange.location == NSNotFound) break;
		
		assert(NSMaxRange(textBlockLevelRWMarkupAttributeRange) < [attributedSourceString length]);
		
		NSLog(@"RWAttribute block at %u/%u", textBlockLevelRWMarkupAttributeRange.location, textBlockLevelRWMarkupAttributeRange.length);
		
		[chunks addObject:[attributedSourceString attributedSubstringFromRange:textBlockLevelRWMarkupAttributeRange]];
		
		currentIndex = NSMaxRange(textBlockLevelRWMarkupAttributeRange);
	}

	NSLog(@"Chunks:\n%@", chunks);
	
	return chunks;
}

@end

//***************************************************************************
