#import <Cocoa/Cocoa.h>

// C++ (and thus Objective-C++) has 'template' as a keyword, which is used
// as the name of an argument to a method in RWAbstractPlugin.h...

#define template aTemplate
#import <RWKit/RWAbstractPlugin.h>
#undef template

//#import <RWKit/RWPluginInterface.h>
#import <RWKit/RMHTML.h>

//***************************************************************************

// You can thank class-dump for these definitions :)

//---------------------------------------------------------------------------

@interface RWPage : NSObject<NSCoding>

- (NSDictionary*)pageAssets;

@end

//---------------------------------------------------------------------------

@interface RWLink : NSObject

- (NSString*)href;
- (NSString*)anchor;
- (NSString*)name;
- (NSString*)target;
- (BOOL)internal;

@end

//---------------------------------------------------------------------------

@interface MyDocument : NSDocument

- (NSWindow*)window;

@end

//---------------------------------------------------------------------------

@interface RWTheme

- (NSString*)themeName;
- (NSString*)path;
- (id)html;
- (id)themeFiles;

@end

//---------------------------------------------------------------------------

@interface RWDocument : NSDocument

- (RWPage*)pageFromUniqueID:(NSString*)uniqueID;
- (RWTheme*)theme;

@end

//---------------------------------------------------------------------------

@interface RWPageAsset : NSObject

+ (int)version;
+ (void)initialize;
- (id)init;
- (id)initWithCoder:(id)fp8;
- (void)encodeWithCoder:(id)fp8;
- (void)dealloc;
- (id)name;
- (void)setName:(id)fp8;
- (id)url;
- (void)setUrl:(id)fp8;
- (id)path;
- (id)pathWithResolution;
- (id)displayUrl;
- (void)setDisplayUrl:(id)fp8;
- (id)assetID;
- (void)setAssetID:(id)fp8;
- (id)reference;
- (void)setReference:(id)fp8;
- (id)referencePath;
- (void)setReferencePath:(id)fp8;
- (void)setAttributes:(id)fp8;
- (BOOL)exists;
- (id)color;
- (id)resolve;

@end

//---------------------------------------------------------------------------

@interface RWTextView : NSTextView {
  NSColor* _ignoreBackground;
  NSColor* _htmlBackground;
  unsigned int _addedNotificationObserver : 1;
}

- (id)initWithFrame:(NSRect)fp8;
- (id)initWithCoder:(id)fp8;
- (void)dealloc;
- (void)awakeFromNib;
- (void)fixUpAttachments;
- (void)drawBackgroundForCharactersInRange:(NSRange)fp8 withColour:(id)fp16;
- (void)drawBackgroundsForAttribute:(id)fp8 colour:(id)fp12;
- (void)drawRect:(NSRect)fp8;
- (void)replaceCharactersInRange:(NSRange)fp8 withRTFD:(id)fp16;
- (void)addSelectionToUndoManager:(NSRange)fp8 afterDeleting:(NSRange)fp16;
- (void)undoApplyChangeToSelection:(id)fp8;
- (void)applyChangeToSelection:(SEL)fp8 param:(id)fp12;
- (void)applyFontChangeToSelection:(id)fp8;
- (void)applyThemeDefaultFont:(id)fp8;
- (void)applyWebSafeFont:(id)fp8;
- (void)applyFontSizeChangeToSelection:(id)fp8;
- (void)changeSelectionFontSize:(id)fp8;
- (void)bigger:(id)fp8;
- (void)smaller:(id)fp8;
- (void)applyRemoveFormattingChangeToSelection:(id)fp8;
- (void)removeFormattingFromSelection:(id)fp8;
- (id)currentSelectionIgnoreFormattingAttribute;
- (void)applyIgnoreFormattingToSelection:(id)fp8;
- (void)applyMarkupAttributeToSelection:(id)fp8;
- (void)pasteAsPlainText:(id)fp8;
- (BOOL)validateMenuItem:(id)fp8;
- (void)textDidChange:(id)fp8;
- (id)attachmentsForRange:(NSRange)fp8;
- (id)attachments;
- (id)selectedAttachments;

@end

extern NSString* kRWTextViewMarkupDirectivesAttributeName;
extern NSString* kRWTextViewIgnoreFormattingAttributeName;
