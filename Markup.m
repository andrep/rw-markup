//***************************************************************************

#import "Markup.h"
#import "MarkupTextView.h"
#import "NSObjectAdditions.h"

#include <objc/runtime.h>

//***************************************************************************

@implementation Markup

static NSBundle* bundle = nil;

// TODO: Do we need to make this a singleton?

static Markup* sharedMarkupPlugin = nil;

+ (NSBundle*)sharedBundle {
  return bundle;
}

- (id)init {
  if (sharedMarkupPlugin != nil) {
    [self autorelease];
    self = [sharedMarkupPlugin retain];
  } else {
    if (self = [super init]) {
      sharedMarkupPlugin = self;
    }
  }

  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:NSApplicationDidFinishLaunchingNotification
              object:nil];

  [super dealloc];
}

+ (Markup*)sharedMarkupPlugin {
  if (sharedMarkupPlugin == nil) {
    sharedMarkupPlugin = [[self alloc] init];
  }

  return sharedMarkupPlugin;
}

// This method is called when the plugin is loaded, and the plugin's bundle is
// passed as an argument. If initialization fails, return NO, and if it goes
// alright, return YES.
+ (BOOL)initializeClass:(NSBundle*)theBundle {
  bundle = theBundle;
  [bundle retain];

  [MarkupTextView poseAsClass:[RWTextView class]];

  return YES;
}

+ (void)initialize {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(applicationDidFinishLaunching:)
             name:NSApplicationDidFinishLaunchingNotification
           object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
  [self addMarkupMenuItem];
}

// This should return an NSEnumerator of all the plugins available, initialized
// and ready for use.
+ (NSEnumerator*)pluginsAvailable;
{ return nil; }

+ (NSString*)pluginType {
  return @"Markup";
}

//// User Interface / Editing Front

+ (NSString*)pluginName {
  return @"Markup";
}
// This should return the name of the plugin to appear in RapidWeaver's
// graphical user interface.  This name should describe what the plugin does, if
// possible. For example, if you were making a plugin to maintain a blog, Blog,
// Journal, or Weblog would all make good plugin names.

+ (NSString*)pluginAuthor;
{ return @"Andre Pang <ozone@algorithm.com.au>"; }
// The person and/or company responsible for writing the plugin.

+ (NSImage*)pluginIcon;
{ return nil; }
// The plugin's 32 by 32 icon image for use in RapidWeaver's source list.

+ (NSString*)pluginDescription;
{ return @"Markup"; }
// This should return a human-readable description of what the plugin does.

- (NSString*)uniqueID {
  return _uniqueID;
}
// Should return a unique page ID from setUniqueID:(NSString *)uniqueID.

- (void)setUniqueID:(NSString*)aUniqueID {
  _uniqueID = aUniqueID;
  [_uniqueID retain];
}
// RapidWeaver will call this when it creates a new page. The unique ID is
// currently used in the styled plugin.

static NSMenu* markupLanguagesMenu = nil;

+ (void)addMarkupMenuItem {
  static BOOL addedMarkupTextMenuItem = NO;
  if (addedMarkupTextMenuItem) return;

  markupLanguagesMenu = [[NSMenu alloc] initWithTitle:@"Markup Languages"];
  [markupLanguagesMenu setDelegate:[self sharedMarkupPlugin]];
  [markupLanguagesMenu setAutoenablesItems:YES];

  for (NSDictionary *markupStyleDefinition in [Markup markupStyles]) {
    NSString* markupStyleName =
    [markupStyleDefinition objectForKey:kMarkupStyleName];

    NSMenuItem* markupMenuItem = [markupLanguagesMenu
                                  addItemWithTitle:markupStyleName
                                  action:@selector(applyMarkupAttributeToSelection:)
                                  keyEquivalent:@""];
    
    [markupMenuItem setTag:kMarkupTextMenuItemTag];
  }

  [markupLanguagesMenu addItem:[NSMenuItem separatorItem]];
  NSMenuItem* useSmartQuotesMenuItem =
      [markupLanguagesMenu addItemWithTitle:@"Use Smart Quotes"
                                     action:@selector(onToggleSmartQuotes:)
                              keyEquivalent:@""];
  [useSmartQuotesMenuItem bind:@"value"
                      toObject:[self sharedMarkupPlugin]
                   withKeyPath:@"usingSmartQuotes"
                       options:nil];

  [[self sharedMarkupPlugin] setValue:[NSNumber numberWithInteger:NSOnState]
                               forKey:@"usingSmartQuotes"];
  [useSmartQuotesMenuItem setState:NSOnState];

  // FIXME: Replace ... below with proper ellipsis character
  [markupLanguagesMenu addItem:[NSMenuItem separatorItem]];
  [markupLanguagesMenu addItemWithTitle:@"Help..."
                                 action:@selector(onMarkupLanguageHelp:)
                          keyEquivalent:@""];

  [markupLanguagesMenu addItem:[NSMenuItem separatorItem]];
  [markupLanguagesMenu addItemWithTitle:@"Dump Attributes"
                                 action:@selector(onDumpAttributes:)
                          keyEquivalent:@""];

  NSMenuItem* markupLanguagesMenuItem = [[NSMenuItem alloc] init];
  [markupLanguagesMenuItem setTitle:@"Markup Language"];
  [markupLanguagesMenuItem
      setAction:@selector(applyMarkupAttributeToSelection:)];
  [markupLanguagesMenuItem setSubmenu:markupLanguagesMenu];

  NSMenu* mainMenu = [[NSApplication sharedApplication] mainMenu];
  NSMenu* formatMenu = [[mainMenu itemWithTitle:@"Format"] submenu];
  NSMenuItem* htmlMenuItem = [formatMenu itemWithTitle:@"HTML"];
  NSInteger htmlMenuItemIndex = [formatMenu indexOfItem:htmlMenuItem];
  [formatMenu insertItem:markupLanguagesMenuItem atIndex:htmlMenuItemIndex + 1];

  addedMarkupTextMenuItem = YES;
}

- (NSView*)userInteractionAndEditingView {
  return nil;
}

static NSMutableArray* cachedMarkupStyles = nil;

+ (NSArray*)markupStyles {
  if (cachedMarkupStyles == nil) {
    NSString* filterStylesPropertyListPath =
        [bundle pathForResource:@"MarkupFilters"
                         ofType:@"plist"
                    inDirectory:@"MarkupFilters"];

    NSArray* filterStylesPropertyList =
        [NSArray arrayWithContentsOfFile:filterStylesPropertyListPath];

    cachedMarkupStyles = [[NSMutableArray alloc] init];

    NSArray* keys = [NSArray
        arrayWithObjects:kMarkupStyleName, kMarkupStyleFilterCommand, nil];

    NSEnumerator* e = [filterStylesPropertyList objectEnumerator];
    while (NSDictionary* propertyListEntry = [e nextObject]) {
      NSString* name = [propertyListEntry objectForKey:@"Name"];

      NSString* filterCommandPath =
          [propertyListEntry objectForKey:@"FilterCommand"];

      NSString* path = [bundle
          pathForResource:[filterCommandPath lastPathComponent]
                   ofType:[propertyListEntry
                              objectForKey:@"FilterCommandExtension"]
              inDirectory:[@"MarkupFilters"
                              stringByAppendingPathComponent:
                                  [filterCommandPath
                                          stringByDeletingLastPathComponent]]];

      NSArray* values = [NSArray arrayWithObjects:name, path, nil];

      NSDictionary* markupStyle =
          [NSDictionary dictionaryWithObjects:values forKeys:keys];
      [cachedMarkupStyles addObject:markupStyle];
    }
  }

  return cachedMarkupStyles;
}

// This should return the view to be shown inside RapidWeaver for editing the
// attributes and content associated with your plugin. For example, for a blog
// plugin, this would be a view showing a table view of blog entries and text
// views for editing each entry.

//// Theme-Specific Options

- (id)valueForThemeSpecificOptionKey:(NSString*)key {
  return nil;
}
// This method should return the stored value for a given theme-specific option
// key. See below for further information on these values and their use.

- (void)setValue:(id)value forThemeSpecificOptionKey:(NSString*)key {
}
// This method is called by RapidWeaver if your plugin has any theme-specific
// options available. These options are for customizing your plugin's output
// content-wise from theme to theme. For example, if you made a photo album
// plugin, this concept makes it possible for different themes to use custom
// picture frame graphics for the same plugin. The custom picture frame graphic
// would be specified in the theme's file format, where it might acknowledge
// certain plugins and specify options for them. If you have theme options, and
// your plugin does not get any input from the theme on how it should look, you
// should have defaults ready for use.

//// Plugin Output

+ (NSArray*)extraFilesNeededInExportFolder:(NSDictionary*)params {
  return nil;
}
// This method has the same use as its instance counterpart below, except this
// class version should be used for copying files specific to the plugin itself,
// rather than the plugin instance. For example, the - (NSArray
// *)extraFilesNeededInExportFolder should return the user's photos, and  +
// (NSArray *)extraFilesNeededInExportFolder should return a picture frame
// graphic.

- (NSArray*)extraFilesNeededInExportFolder:(NSDictionary*)params {
  return nil;
}

// This should return an NSArray of NSString file paths if your plugin needs any
// files (such as images, audio, style sheets, and others) copied into the
// export folder when the user exports a site for publishing. The files should
// be located in some sort of temporary directory. Pass an array with no objects
// if you don't need any extra files copied.

- (NSString*)contentHTML:(NSDictionary*)params {
  return nil;
}
// This should return all HTML code resulting from user-interaction. The code
// should be suitable to be placed inside RapidWeaver's content area.

- (NSString*)sidebarHTML:(NSDictionary*)params {
  return nil;
}
// This should return all HTML code generated by the plugin. The code should be
// suitable to be placed inside RapidWeaver's sidebar area.

- (void)cancelExport {
}
// sent from RW to inform the plugin to gracefully cancel

//// Plugin Settings

// return a dirctionary describing the plugin and its exportable settings
- (NSDictionary*)pluginSettings {
  return nil;
}

// apply the settings as returned from -pluginSettings to this plugin
- (void)setPluginSettings:(NSDictionary*)settings {
}

// return YES if this plugin will accept 'settings'
- (BOOL)acceptsPluginSettings:(NSDictionary*)settings {
  return NO;
}

// return YES if this plugin can provide settings (default is NO)
- (BOOL)providesPluginSettings {
  return NO;
}

- (void)encodeWithCoder:(NSCoder*)coder {
  [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder*)decoder {
  self = [super initWithCoder:decoder];

  self = [self init];

  return self;
}

+ (NSNumber*)markupEnabledForFilterStyleInSelectedRange:
                 (NSString*)markupStyleName {
  NSResponder* firstResponder =
      [[[NSApplication sharedApplication] keyWindow] firstResponder];
  if ([firstResponder
          respondsToSelector:@selector(
                                 markupEnabledForFilterStyleInSelectedRange:)])
    return [firstResponder
        performSelector:@selector(markupEnabledForFilterStyleInSelectedRange:)
             withObject:markupStyleName];
  else
    return nil;
}

- (void)menuNeedsUpdate:(NSMenu*)menu {
  NSArray* menuItems = [markupLanguagesMenu itemArray];

  NSEnumerator* e = [menuItems objectEnumerator];
  while (NSMenuItem* menuItem = [e nextObject]) {
    if ([menuItem tag] != kMarkupTextMenuItemTag) continue;

    [menuItem setState:[[Markup markupEnabledForFilterStyleInSelectedRange:
                                    [menuItem title]] boolValue]];
  }
}

@end

//***************************************************************************

const NSString* const kMarkupStyleFilterCommand = @"filterCommand";
const NSString* const kMarkupStyleName = @"name";

const NSInteger kMarkupTextMenuItemTag = 6002;

//***************************************************************************
