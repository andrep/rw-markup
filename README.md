# Markup Plugin for RapidWeaver

I'm a big fan of lightweight markup languages, popular with server-side blogging
software such as [Movable
Type](http://www.sixapart.com/movabletype/) and
[Wordpress](http://wordpress.org/): they're perfect for
writing Web pages, where you want mostly freeform text, and when formatted
text controls sometimes get in your way more than they help. Since [RapidWeaver](https://realmacsoftware.com/rapidweaver/) uses
a rich-text control for styling text that I just couldn't get used to, I wrote
a little plugin named Markup so you can write in a markup language instead. It
simply adds a _Markup Language_ menu item below RapidWeaver's HTML menu item,
where you can pick from a small but excellent set of markup languages, such
as:

  * John Gruber's [Markdown](http://daringfireball.net/projects/markdown/) ([syntax](http://daringfireball.net/projects/markdown/syntax)), 
  * Textism and Brad Choate's [Textile](http://en.wikipedia.org/wiki/Textile_\(markup_language\)) ([syntax](http://www.bradchoate.com/mt/docs/mtmanual_textile2.html)), and 
  * David Grudl's [Texy](http://texy.info/en/) ([syntax](http://texy.info/en/syntax)). 

For the UNIX wizards, you can also have bash markup: i.e. markup that's
filtered through the UNIX /bin/bash shell that's installed on every Mac OS X
computer. It can also add "smart" punctuation to your Web pages via [SmartyPants](http://daringfireball.net/projects/smartypants/), if
you're one of those folks (like me) who appreciates seeing proper em-dashes,
ellipses and open quotes.

There's a ton of improvements that I still have to make to it, but hey,
something is better than nothing!

## Download

You can download the Markup plugin at the GitHub releases page, at
https://github.com/andrep/rw-markup/releases.

Markup 0.16 may also even work with RapidWeaver 3.2 and Mac OS X 10.3.9, although
that's not officially supported.

If you do find any bugs, just email me: I'll add it to my to-
do list. Ditto for feature suggestions, for which I'm sure you have many
ideas!

## Tips and Tricks

  * You can use the `bash` markup language to treat the markup text as
    a UNIX shell script, which will be run and have its standard output
    emitted. For instance, simply type in `Last updated on date +'%A, %B
    %Y, %e'` into any RapidWeaver styled text area, select the "`date
    +'%A, %B %Y, %e'`" bit, and choose the `bash` markup language from the
    Format -> Markup Language menu. Note that RapidWeaver 6+ runs inside
    a [Sandbox](https://developer.apple.com/library/mac/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html#//apple_ref/doc/uid/TP40011183-CH3-SW6).
    Keep this in mind if your bash commands expect to access data outside
    of RapidWeaver!

## Developers

The source code is on GitHub, at https://github.com/andrep/rw-markup.

## Other Markup Plugins

It seems that I'm not alone in wanting to add markup support for RapidWeaver. At
least two other enterprising developers have their own markup-esque plugins
available for RapidWeaver, which you may prefer:

  * plessl's [Markdown plugin](http://archive.org/web/20080828003902/http://plesslweb.ch/2006/08/13/markdown-plugin-09/) (with accompanying [source code](http://archive.org/web/20080828003902/http://plesslweb.ch/2006/08/24/source-code-of-markdownplugin-091-for-rapidweaver/)\--yeah for open source!). Note that plessl's plugin takes a different approach to mine: whereas plessl's Markdown plugin offers a new RapidWeaver page style, my Markup plugin enables you to use markup text in any RapidWeaver styled text area, such as the sidebar for each page. 
  * Loghound's [PlusKit](http://www.loghound.com/pluskit/), which offers a slightly different approach to markup text (via explicit `<markdown>` and `</markdown>` tags), and also does a lot more besides that (such as being to merge other page styles into the current page, ala [Blocks 2](http://www.yourhead.com/blocks/index.html)). 

