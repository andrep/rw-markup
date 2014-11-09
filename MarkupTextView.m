//***************************************************************************

#import "jrswizzle/JRSwizzle.h"

#import "Markup.h"
#import "MarkupTextView.h"

#import "NSAttributedString+ParagraphTests.h"
#import "NSTaskAdditions.h"

//***************************************************************************

@implementation RWTextView (MarkupTextView)

+ (void)load {
  NSArray *swizzledMethodNames = @[
    @"removeFormattingFromSelection:",
    @"drawBackgroundForCharactersInRange:withColour:",
    @"applyMarkupAttributeToSelection:"
  ];

  for (NSString *methodName in swizzledMethodNames) {
    NSError *error = nil;
    BOOL didSwizzle = [RWTextView
        jr_swizzleMethod:NSSelectorFromString(methodName)
              withMethod:NSSelectorFromString([NSString stringWithFormat:@"mtv_%@", methodName])
                   error:&error];
    if (!didSwizzle) {
      Log(@"Swizzle of %@ failed: %@", methodName, [error localizedDescription]);
    }
  }
}

- (void)mtv_removeFormattingFromSelection:(id)sender {
  [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName
                                range:[self selectedRange]];

  [self mtv_removeFormattingFromSelection:sender];
}

- (void)mtv_drawBackgroundForCharactersInRange:(NSRange)range withColour:(NSColor *)colour {
  NSDictionary *attributeValue =
      [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                            atIndex:range.location
                     effectiveRange:NULL];

  if ([[attributeValue objectForKey:@"name"] isEqualTo:@"filter"]) {
    NSColor *transparentBlue =
        [NSColor colorWithCalibratedRed:0.0f green:0.2f blue:1.0f alpha:0.1f];
    [self mtv_drawBackgroundForCharactersInRange:range withColour:transparentBlue];
  } else {
    [self mtv_drawBackgroundForCharactersInRange:range withColour:colour];
  }
}

- (IBAction)mtv_applyMarkupAttributeToSelection:(id)sender {
  if ([sender tag] == kMarkupTextMenuItemTag) {
    NSRange range = [self selectedRange];

    id maybeAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                              atIndex:range.location
                                       effectiveRange:NULL];

    if ([[maybeAttribute objectForKey:@"style"] isEqualTo:[sender title]]) {
      [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];
      [[self textStorage] removeAttribute:NSFontAttributeName range:range];
    } else {
      [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];

      NSString *markupStyle = [sender title];

      NSDictionary *markupFilterAttribute = [NSDictionary
          dictionaryWithObjectsAndKeys:@"filter", @"name", markupStyle, @"style", nil];

      NSDictionary *markupFilterAttributes =
          [NSDictionary dictionaryWithObjectsAndKeys:markupFilterAttribute,
                                                     kRWTextViewMarkupDirectivesAttributeName,
                                                     [NSFont fontWithName:@"Monaco" size:10.0],
                                                     NSFontAttributeName, markupStyle,
                                                     NSToolTipAttributeName, nil];

      [[self textStorage] addAttributes:markupFilterAttributes range:range];

      [[self textStorage] removeAttribute:kRWTextViewIgnoreFormattingAttributeName range:range];
      [[self textStorage] removeAttribute:NSParagraphStyleAttributeName range:range];
      [[self textStorage] removeAttribute:NSForegroundColorAttributeName range:range];
      [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:range];

      // Remove any attributes for attachments

      NSRange textAttachmentRange;

      for (NSUInteger textAttachmentLocation = range.location;
           textAttachmentLocation < NSMaxRange(range);
           textAttachmentLocation = NSMaxRange(textAttachmentRange)) {
        NSDictionary *maybeTextAttachment = [[self textStorage] attribute:NSAttachmentAttributeName
                                                                  atIndex:textAttachmentLocation
                                                    longestEffectiveRange:&textAttachmentRange
                                                                  inRange:range];

        if (maybeTextAttachment != nil) {
          [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName
                                        range:textAttachmentRange];
        }
      }
    }

    [self didChangeText];
  } else {
    [self mtv_applyMarkupAttributeToSelection:sender];
  }
}

- (void)onToggleSmartQuotes:(id)sender {
  LOG_ENTRY;
}

- (void)onDumpAttributes:(id)sender {
  NSMutableString *string = [NSMutableString string];

  [string appendString:@"\nAttributes"];
  [string appendString:@"\n==========\n"];

  NSTextStorage *textStorage = [self textStorage];

  NSRange range;

  NSRange rangeLimit;
  rangeLimit.location = 0;
  rangeLimit.length = [textStorage length];

  for (NSUInteger currentIndex = 0; currentIndex < rangeLimit.length;
       currentIndex = NSMaxRange(range)) {
    NSDictionary *dict = [textStorage attributesAtIndex:currentIndex
                                  longestEffectiveRange:&range
                                                inRange:rangeLimit];

    [string appendFormat:@"Range %lu-%lu\n", (unsigned long)range.location,
                         (unsigned long)range.length];

    if (dict == nil) {
      [string appendString:@"Attribute: (none)\n"];
    } else {
      [string appendFormat:@"Attribute: %@\n", dict];
    }

    [string appendFormat:@"<%@>\n\n", [[textStorage attributedSubstringFromRange:range] string]];
  }

  Log(@"%@", string);
}

- (NSNumber *)markupEnabledForFilterStyleInSelectedRange:(NSString *)markupStyleName {
  NSRange range = [self selectedRange];

  NSDictionary *markupStyleAttribute = nil;
  if (range.length == 0) {
    markupStyleAttribute =
        [[self typingAttributes] objectForKey:kRWTextViewMarkupDirectivesAttributeName];
  } else {
    NSRange longestRange;

    markupStyleAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                 atIndex:range.location
                                   longestEffectiveRange:&longestRange
                                                 inRange:range];

    if (longestRange.location > range.location || (NSMaxRange(longestRange) < NSMaxRange(range))) {
      return [NSNumber numberWithBool:NO];
    }
  }

  if (markupStyleAttribute == nil) return [NSNumber numberWithBool:NO];

  const BOOL styleEnabled =
      [[markupStyleAttribute objectForKey:@"style"] isEqualTo:markupStyleName];

  return [NSNumber numberWithBool:styleEnabled];
}

@end

//***************************************************************************

@implementation RMHTML (MarkupHTML)

+ (void)load {
  NSError *error = nil;

  BOOL didSwizzle = [RMHTML jr_swizzleMethod:@selector(exportAttributedString:
                                                                       toPath:
                                                                 imagesFolder:
                                                                  imagePrefix:
                                                                 HTMLTemplate:
                                                                   contentTag:
                                                                     fromPage:
                                                              depthCorrection:
                                                                   exportMode:
                                                                    linkStyle:)
                                  withMethod:@selector(mh_exportAttributedString:
                                                                          toPath:
                                                                    imagesFolder:
                                                                     imagePrefix:
                                                                    HTMLTemplate:
                                                                      contentTag:
                                                                        fromPage:
                                                                 depthCorrection:
                                                                      exportMode:
                                                                       linkStyle:)
                                       error:&error];
  if (!didSwizzle) {
    Log(@"RMHTML swizzle failed: %@", [error localizedDescription]);
  }
}

- (NSString *)pathToFilterCommandForMarkupStyleName:(NSString *)markupStyleName {
  for (NSDictionary *markupStyleDefinition in [Markup markupStyles]) {
    if ([[markupStyleDefinition objectForKey:kMarkupStyleName] isEqualTo:markupStyleName]) {
      return [markupStyleDefinition objectForKey:kMarkupStyleFilterCommand];
    }
  }

  return @"/bin/cat";
}

- (NSString *)pathToSmartQuotesFilterCommand {
  return [[Markup sharedBundle] pathForResource:@"SmartyPants"
                                         ofType:@"pl"
                                    inDirectory:@"MarkupFilters"];
}

//---------------------------------------------------------------------------

- (NSString *)mh_exportAttributedString:(NSAttributedString *)str
                                 toPath:(NSString *)path
                           imagesFolder:(NSString *)imagesFolder
                            imagePrefix:(NSString *)imagePrefix
                           HTMLTemplate:(NSMutableString *)theTemplate
                             contentTag:(NSString *)contentTag
                               fromPage:(id)thePage
                        depthCorrection:(NSInteger)depthCorrection
                             exportMode:(RWExportMode)exportMode
                              linkStyle:(RWLinkStyle)linkStyle {
  NSRange range;
  range.location = 0;
  range.length = [str length];

  NSMutableAttributedString *filteredString =
      [[[NSMutableAttributedString alloc] initWithAttributedString:str] autorelease];

  for (NSUInteger currentIndex = 0; currentIndex < [filteredString length];
       currentIndex = NSMaxRange(range)) {
    NSRange rangeLimit;
    rangeLimit.location = 0;
    rangeLimit.length = [filteredString length];

    NSDictionary *attributeValue =
        [filteredString attribute:kRWTextViewMarkupDirectivesAttributeName
                          atIndex:currentIndex
            longestEffectiveRange:&range
                          inRange:rangeLimit];

    if (attributeValue == nil) continue;

    if (![[attributeValue objectForKey:@"name"] isEqualToString:@"filter"]) continue;

    NSString *string = [[filteredString attributedSubstringFromRange:range] string];
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];

    // Replace links with <a href=...>

    NSRange linkRange;
    for (NSUInteger linkIndex = range.location; linkIndex < NSMaxRange(range);
         linkIndex = NSMaxRange(linkRange)) {
      RWLink *link = [filteredString attribute:NSLinkAttributeName
                                       atIndex:linkIndex
                         longestEffectiveRange:&linkRange
                                       inRange:range];

      if (link == nil) continue;

      // Hmm, maybe [link href] refers to MyDocument's -pageFromUniqueID method?
      Log(@"Found link -> %d, %@ (%@), %@, %@, %@", [link internal], [link href],
          [[link href] className], [link anchor], [link name], [[link target] className]);

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

    NSAttributedString *replacedAttributedString = nil;

    if (exportMode == RWExportModeConvertingForWebViewDOM) {
      Log(@"Markup is converting for WebView DOM...");

      NSString *replacedString =
          [[NSString stringWithFormat:@"<pre class=\"rapidweaver-markup\">%@</pre>",
                                      [string stringEscapedForHTMLElementText]] retain];

      NSDictionary *attributes =
          [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                                     kRWTextViewIgnoreFormattingAttributeName, nil];

      replacedAttributedString =
          [[NSAttributedString alloc] initWithString:replacedString attributes:attributes];
    } else {
      NSString *markupStyleName = [attributeValue objectForKey:@"style"];
      NSString *filterCommandPath = [self pathToFilterCommandForMarkupStyleName:markupStyleName];

#if 0
			{
				NSString* markupString = [[filteredString string] substringWithRange:range];
				Log(@"Found filter text at %u/%u (%@) (%@...)", range.location, range.length, markupStyleName,
					[markupString length] <= 40 ? markupString : [markupString substringWithRange:NSMakeRange(0,40)]);
			}
#endif

      NSData *filteredData = [NSTask launchedTaskWithLaunchPath:filterCommandPath
                                                      arguments:[NSArray array]
                                                  standardInput:stringData];
      [filteredData retain];

      NSData *htmlData = nil;

      // Smart Quote the text if necessary
      if ([Markup sharedMarkupPlugin]->usingSmartQuotes) {
        NSString *filterCommandPath = [self pathToSmartQuotesFilterCommand];
        htmlData = [NSTask launchedTaskWithLaunchPath:filterCommandPath
                                            arguments:[NSArray array]
                                        standardInput:filteredData];
        [htmlData retain];

        [filteredData release];
        filteredData = nil;
      } else {
        htmlData = filteredData;
      }

      NSString *trimmedString =
          [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];

      // Released a bit further on in this method
      NSMutableString *replacedString =
          [[trimmedString stringByTrimmingCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];

      [htmlData release];
      htmlData = nil;

      NSDictionary *attributes =
          [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                                     kRWTextViewIgnoreFormattingAttributeName, nil];

      // Kill any <p>'s from the start if it's not the start of a paragraph
      if (![filteredString isRangeAtStartOfParagraph:range]) {
        if ([replacedString length] >= 3 &&
            [[replacedString substringWithRange:NSMakeRange(0, 3)] caseInsensitiveCompare:@"<p>"] ==
                NSOrderedSame) {
          [replacedString deleteCharactersInRange:NSMakeRange(0, 3)];
        }
      }

      // Kill any </p>'s from the end of it's not the end of a paragraph
      if (![filteredString isRangeAtEndOfParagraph:range]) {
        if ([replacedString length] >= 4 &&
            [[replacedString substringWithRange:NSMakeRange([replacedString length] - 4, 4)]
                caseInsensitiveCompare:@"</p>"] == NSOrderedSame) {
          [replacedString deleteCharactersInRange:NSMakeRange([replacedString length] - 4, 4)];
        }
      }

      // Released a bit further on in this method
      replacedAttributedString =
          [[NSAttributedString alloc] initWithString:replacedString attributes:attributes];

      [replacedString release];
      replacedString = nil;
    }

    [filteredString replaceCharactersInRange:range withAttributedString:replacedAttributedString];

    range.length = [replacedAttributedString length];

    [replacedAttributedString release];
    replacedAttributedString = nil;
  }

  return [self mh_exportAttributedString:filteredString
                                  toPath:path
                            imagesFolder:imagesFolder
                             imagePrefix:imagePrefix
                            HTMLTemplate:theTemplate
                              contentTag:contentTag
                                fromPage:thePage
                         depthCorrection:depthCorrection
                              exportMode:exportMode
                               linkStyle:linkStyle];
}

@end

//***************************************************************************
