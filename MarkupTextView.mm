//***************************************************************************

#import "Markup.h"
#import "MarkupTextView.h"
#import "NSAttributedString+ParagraphTests.h"
#import "NSTaskAdditions.h"

//***************************************************************************

@implementation MarkupTextView

- (void) removeFormattingFromSelection:(id)sender
{
    LOG_ENTRY;
    
    [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:[self selectedRange]];
    
    [super removeFormattingFromSelection:sender];
}

- (void) drawBackgroundForCharactersInRange:(NSRange)range withColour:(NSColor*)colour
{
    NSDictionary* attributeValue = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                         atIndex:range.location
                                                  effectiveRange:NULL];
    
    if ([[attributeValue objectForKey:@"name"] isEqualTo:@"filter"])
    {
        NSColor* transparentBlue = [NSColor colorWithCalibratedRed:0.0f green:0.2f blue:1.0f alpha:0.1f];
        [super drawBackgroundForCharactersInRange:range withColour:transparentBlue];
    }
    else
    {
        [super drawBackgroundForCharactersInRange:range withColour:colour];
    }
}

- (IBAction) applyMarkupAttributeToSelection:(id)sender
{
    if ([sender tag] == kMarkupTextMenuItemTag)
    {
        NSRange range = [self selectedRange];
        
        id maybeAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                  atIndex:range.location
                                           effectiveRange:NULL];
        
        if ([[maybeAttribute objectForKey:@"style"] isEqualTo:[sender title]])
        {
            [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];
            [[self textStorage] removeAttribute:NSFontAttributeName range:range];
        }
        else
        {
            [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];
            
            NSString* markupStyle = [sender title];
            
            NSDictionary* markupFilterAttribute = [NSDictionary dictionaryWithObjectsAndKeys:
                @"filter", @"name",
                markupStyle, @"style",
                nil];
            
            NSDictionary* markupFilterAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                markupFilterAttribute, kRWTextViewMarkupDirectivesAttributeName,
                [NSFont fontWithName:@"Monaco" size:10.0], NSFontAttributeName,
                markupStyle, NSToolTipAttributeName,
                nil];
            
            [[self textStorage] addAttributes:markupFilterAttributes range:range];

            [[self textStorage] removeAttribute:kRWTextViewIgnoreFormattingAttributeName range:range];
            [[self textStorage] removeAttribute:NSParagraphStyleAttributeName range:range];
            [[self textStorage] removeAttribute:NSForegroundColorAttributeName range:range];
            [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:range];
            
            // Remove any attributes for attachments
            
            NSRange textAttachmentRange;
            
            for (unsigned textAttachmentLocation = range.location;
                 textAttachmentLocation < range.location + range.length;
                 textAttachmentLocation = textAttachmentRange.location + textAttachmentRange.length)
            {
                NSDictionary* maybeTextAttachment = [[self textStorage] attribute:NSAttachmentAttributeName
                                                                          atIndex:textAttachmentLocation
                                                            longestEffectiveRange:&textAttachmentRange
                                                                          inRange:range];
                
                if (maybeTextAttachment != nil)
                {
                    [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName 
                                                  range:textAttachmentRange];                    
                }
            }
        }
		
        [self didChangeText];
    }
    else
    {
        [super applyMarkupAttributeToSelection:sender];
    }
}

- (void) onMarkupLanguageHelp:(id)sender
{
    LOG_ENTRY;
}

- (void) onToggleSmartQuotes:(id)sender
{
    LOG_ENTRY;
}

- (void) onDumpAttributes:(id)sender
{
    LOG_ENTRY;
    
    NSMutableString* string = [NSMutableString string];
    
    [string appendString:@"\nAttributes"];
    [string appendString:@"\n==========\n"];
    
    NSTextStorage* textStorage = [self textStorage];
    
    NSRange range;
    
    NSRange rangeLimit;
    rangeLimit.location = 0;
    rangeLimit.length = [textStorage length];
    
    for (unsigned int currentIndex = 0;
         currentIndex < rangeLimit.length;
         currentIndex = range.location + range.length)
    {
        NSDictionary* dict = [textStorage attributesAtIndex:currentIndex
                                      longestEffectiveRange:&range
                                                    inRange:rangeLimit];
        
        [string appendFormat:@"Range %u-%u\n", range.location, range.length];
            
        if (dict == nil)
        {
            [string appendString:@"Attribute: (none)\n"];
        }
        else
        {
            [string appendFormat:@"Attribute: %@\n", dict];
        }
        
        [string appendFormat:@"<%@>\n\n", [[textStorage attributedSubstringFromRange:range] string]];
    }
    
    Log(@"%@", string);
}

- (NSNumber*) markupEnabledForFilterStyleInSelectedRange:(NSString*)markupStyleName
{
    NSRange range = [self selectedRange];
    
    NSDictionary* markupStyleAttribute = nil;
    if(range.length == 0)
    {
        markupStyleAttribute = [[self typingAttributes] objectForKey:kRWTextViewMarkupDirectivesAttributeName];
    }
    else
    {
        NSRange longestRange;
        
        markupStyleAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName atIndex:range.location longestEffectiveRange:&longestRange inRange:range];
        
        if(longestRange.location > range.location
           || (longestRange.location + longestRange.length) < (range.location + range.length))
        {
            return [NSNumber numberWithBool:NO];
        }
    }

    if(markupStyleAttribute == nil) return [NSNumber numberWithBool:NO];
    
    const BOOL styleEnabled = [[markupStyleAttribute objectForKey:@"style"] isEqualTo:markupStyleName];
    
    return [NSNumber numberWithBool:styleEnabled];
    
}

@end

//***************************************************************************

@implementation MarkupHTML

- (NSString*) pathToFilterCommandForMarkupStyleName:(NSString*)markupStyleName
{
    NSEnumerator* e = [[Markup markupStyles] objectEnumerator];
    
    while (NSDictionary* markupStyleDefinition = [e nextObject])
    {
        if ([[markupStyleDefinition objectForKey:kMarkupStyleName] isEqualTo:markupStyleName])
        {
            return [markupStyleDefinition objectForKey:kMarkupStyleFilterCommand];
        }
    }
    
    return @"/bin/cat";
}

- (NSString*) pathToSmartQuotesFilterCommand
{
    return [[Markup sharedBundle] pathForResource:@"SmartyPants" ofType:@"pl" inDirectory:@"MarkupFilters"];
}


- (NSString*) exportAttributedString:(NSAttributedString*)str
                              toPath:(NSString*)path
                        imagesFolder:(NSString*)imagesFolder
                         imagePrefix:(NSString*)imagePrefix
                        HTMLTemplate:(NSMutableString*)theTemplate
                          contentTag:(NSString*)contentTag
                            fromPage:(id)thePage
                     depthCorrection:(int)depthCorrection;
{
    NSRange range;
    range.location = 0;
    range.length = [str length];

    NSMutableAttributedString* filteredString = [[[NSMutableAttributedString alloc] initWithAttributedString:str] autorelease];

    for (unsigned int currentIndex = 0;
         currentIndex < [filteredString length];
         currentIndex = range.location + range.length)
    {
        NSRange rangeLimit;
        rangeLimit.location = 0;
        rangeLimit.length = [filteredString length];
        
        NSDictionary* attributeValue = [filteredString attribute:kRWTextViewMarkupDirectivesAttributeName
                                                         atIndex:currentIndex
                                           longestEffectiveRange:&range
                                                         inRange:rangeLimit];
        
        if (attributeValue == nil) continue;

		if (![[attributeValue objectForKey:@"name"] isEqualToString:@"filter"]) continue;
			
		NSString* string = [[filteredString attributedSubstringFromRange:range] string];
		NSData* stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
		
		// Replace links with <a href=...>
		
		NSRange linkRange;
		for(unsigned linkIndex = range.location;
			linkIndex < range.location + range.length;
			linkIndex = linkRange.location + linkRange.length)
		{
			RWLink* link = [filteredString attribute:NSLinkAttributeName
											 atIndex:linkIndex
							   longestEffectiveRange:&linkRange
											 inRange:range];
			
			if(link == nil) continue;
			
			// Hmm, maybe [link href] refers to MyDocument's -pageFromUniqueID method?
			Log(@"Found link -> %d, %@ (%@), %@, %@, %@",
				  [link internal], [link href], [[link href] className], [link anchor], [link name], [[link target] className]);
			
#if 0
			NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:YES], kRWTextViewIgnoreFormattingAttributeName,
				nil];
			
			NSAttributedString* replacedLink =
				[[[NSAttributedString alloc] initWithString:[link href] attributes:attributes] autorelease];
			
			[filteredString replaceCharactersInRange:linkRange withAttributedString:replacedLink];
			
			linkRange.length = [replacedLink length];
#endif
		}
		
		
		NSString* markupStyleName = [attributeValue objectForKey:@"style"];
		NSString* filterCommandPath = [self pathToFilterCommandForMarkupStyleName:markupStyleName];                
		
#ifdef ENABLE_LOGGING
		{
			NSString* markupString = [[filteredString string] substringWithRange:range];
			Log(@"Found filter text at %u/%u (%@) (%@...)", range.location, range.length, markupStyleName,
				[markupString length] <= 40 ? markupString : [markupString substringWithRange:NSMakeRange(0,40)]);
		}
#endif
		
		NSData* filteredData = [NSTask launchedTaskWithLaunchPath:filterCommandPath
														arguments:[NSArray array]
													standardInput:stringData];
		[filteredData retain];
		
		NSData* htmlData = nil;
		
		// Smart Quote the text if necessary
		if([Markup sharedMarkupPlugin]->usingSmartQuotes)
		{
			NSString* filterCommandPath = [self pathToSmartQuotesFilterCommand];
			htmlData = [NSTask launchedTaskWithLaunchPath:filterCommandPath
												arguments:[NSArray array]
											standardInput:filteredData];
			[htmlData retain];
			
			[filteredData release];
			filteredData = nil;
		}
		else
		{
			htmlData = filteredData;
		}
		
		NSString* trimmedString = [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];

		// Released a bit further on in this method
		NSMutableString* replacedString = [[trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
		
		[htmlData release];
		htmlData = nil;
		
		NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES], kRWTextViewIgnoreFormattingAttributeName,
			nil];
		
		// Kill any <p>'s from the start if it's not the start of a paragraph
		if(![filteredString isRangeAtStartOfParagraph:range])
		{
			if([replacedString length] >= 3
			   && [[replacedString substringWithRange:NSMakeRange(0,3)] caseInsensitiveCompare:@"<p>"] == NSOrderedSame)
			{
				[replacedString deleteCharactersInRange:NSMakeRange(0,3)];
			}
		}
		
		// Kill any </p>'s from the end of it's not the end of a paragraph
		if(![filteredString isRangeAtEndOfParagraph:range])
		{
			if([replacedString length] >= 4
			   && [[replacedString substringWithRange:NSMakeRange([replacedString length]-4,4)] caseInsensitiveCompare:@"</p>"] == NSOrderedSame)
			{
				[replacedString deleteCharactersInRange:NSMakeRange([replacedString length]-4,4)];
			}
		}
		
		// Released a bit further on in this method
		NSAttributedString* replacedAttributedString =
			[[NSAttributedString alloc] initWithString:replacedString attributes:attributes];
		
		[replacedString release];
		replacedString = nil;
		
		[filteredString replaceCharactersInRange:range withAttributedString:replacedAttributedString];
		
		[replacedAttributedString release];
		replacedAttributedString = nil;
		
		range.length = [replacedString length];
    }

    return [super exportAttributedString:filteredString
                                  toPath:path
                            imagesFolder:imagesFolder
                             imagePrefix:imagePrefix
                            HTMLTemplate:theTemplate
                              contentTag:contentTag 
                                fromPage:thePage
                         depthCorrection:depthCorrection];
}

@end

//***************************************************************************
