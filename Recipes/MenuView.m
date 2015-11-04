/*

File: MenuView.m

Abstract: Custom view that creates the content for the menu pages and deals with the event handling and interaction.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright Â© 2006 Apple Computer, Inc., All Rights Reserved

*/ 
#import "MenuView.h"
#import <QuartzCore/QuartzCore.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QTKit/QTKit.h>
#import "TextLayerAdditions.h"
#import "MenuLayoutManagers.h"

@interface MenuView (local)
- (void)setSelection:(CALayer *)layer;
@end


@implementation MenuView

static CGImageRef cremeImage = NULL;
static QTMovie *qtMovie = nil;


//--------------------------------------------------------------------------------------------------

- initWithFrame: (NSRect)frame
{
    if(!cremeImage)
    {
        CGImageSourceRef source;

        source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"CremeBruleeSmall" ofType:@"tiff"]], NULL);

        cremeImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
    }

    if(!qtMovie)
    {
        NSError *error;
        
        qtMovie = [[QTMovie movieWithFile: [[NSBundle mainBundle] pathForResource: @"creme" ofType:@"mov"] error:&error] retain];
    }

    return [super initWithFrame: frame];
}

//--------------------------------------------------------------------------------------------------

- (void)setPageTitle:(NSString *)title andBody:(CALayer *)l2 direction:(NSString *)dir
{
	CATextLayer *header;

	header = [CATextLayer layerWithText:title fontSize:64];
	[header setForegroundColor:CGColorCreateGenericRGB(0.9f, 0.83f, 0.18f, 1.0f)];
	[header setShadowOpacity:0.75f];

	if (dir != nil)
		[CATransaction setValue:dir forKey:@"ovitTransitionType"];

	[[_page header] setSublayers:[NSArray arrayWithObjects:header, nil]];
	[[_page body] setSublayers:[NSArray arrayWithObjects:l2, nil]];
	[_page setValue:nil forKey:@"MenuViewContainer"];
	[_page setValue:nil forKey:@"MenuViewScroller"];
	[_page layoutIfNeeded];
}

//--------------------------------------------------------------------------------------------------

- (void)selectRootPage
{
	NSString	*title = @"The Recipes";
	NSArray		*items = [NSArray arrayWithObjects: @"Appetizers",
													@"Salads",
													@"Entrees",
													@"Desserts",
													@"Drinks",
													@"Snacks",
													nil];

	CALayer		*box;
	int			i, n;

	[CATransaction begin];

	box = [CALayer layer];

	[box setLayoutManager:[MenuBoxLayoutManager layoutManager]];
	for (i = 0, n = [items count]; i < n; i++)
		[box addSublayer:[CATextLayer layerWithText:[items objectAtIndex:i]]];

	[self setPageTitle:title andBody:box direction:@"fromLeft"];
	[_page setValue:box forKey:@"MenuViewContainer"];

	[self setSelection:[[box sublayers] objectAtIndex:1]];

	[CATransaction commit];

	_pageName = MenuPageRoot;
}

//--------------------------------------------------------------------------------------------------

- (void)selectDessertsPage
{
	NSString	*title = @"Dessert";
	NSArray		*items = [NSArray arrayWithObjects: [NSArray arrayWithObjects:[NSNull null],
													 @"Calvados Crme BržlŽe", @"576", [NSNull null], nil],
													[NSArray arrayWithObjects: [NSNull null],
													 @"Key Lime Pie", @"376", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Beignets with Honey", @"147", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Bee Sting Cake", @"180", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Baklava", @"236", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Cappuccino Cheesecake", @"313", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Apple-Cranberry Pie", @"331", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Zabaglione with Strawberries", @"305", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Cinnamon Twist", @"286", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Bear Claw", @"376", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Crepes Suzette", @"181", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Cinnamon Thyme Poached Pears", @"304", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Honey Almond Ice Cream", @"357", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Blackberry Tart", @"46", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Almond Apricot Macaroons", @"117", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Baked Peaches with Almond Paste", @"250", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Viennese Apple Strudel", @"345", [NSNull null], nil],
													[NSArray arrayWithObjects:[NSNull null],
													 @"Bittersweet Chocolate Mousse", @"344", [NSNull null], nil],
													nil];

	CALayer			*table, *selection = nil;
	CAScrollLayer	*scroller;
	int				i, j, n, m;
	NSString		*dir;

	[CATransaction begin];

	table = [CALayer layer];
	[table setLayoutManager:[MenuTableLayoutManager layoutManager]];
	id	obj = [NSNumber numberWithUnsignedInteger:[items count]];
	[table setValue:obj forKey:@"myTableRows"];

	for (i = 0, n = [items count]; i < n; i++)
	{
		NSArray *item = [items objectAtIndex:i];

		for (j = 0, m = [item count]; j < m; j++)
		{
			CATextLayer *layer;

			if ([[item objectAtIndex:j] isKindOfClass:[NSString class]])
			layer = [CATextLayer layerWithText:[item objectAtIndex:j]];
			else
			layer = nil;

			if (j == 1)
			[layer setTruncationMode:@"end"];
			else
			[layer setAlignmentMode:@"right"];

			if (layer != nil)
			{
				[layer setValue:[NSNumber numberWithInt:i] forKey:@"myTableRow"];
				[layer setValue:[NSNumber numberWithInt:j] forKey:@"myTableColumn"];
				[table addSublayer:layer];
				if (i == 0)
					selection = layer;
			}
		}
	}

	scroller = [CAScrollLayer layer];
	[scroller setLayoutManager:[MenuScrollLayoutManager layoutManager]];
	[scroller addSublayer:table];
	[scroller setScrollMode:@"vertically"];

	dir = _pageName >= MenuPageDesserts ? @"fromLeft" : @"fromRight";
	[self setPageTitle:title andBody:scroller direction:dir];
	[_page setValue:table forKey:@"MenuViewContainer"];
	[_page setValue:scroller forKey:@"MenuViewScroller"];

	[self setSelection:selection];

	[CATransaction commit];

	_pageName = MenuPageDesserts;
}

//--------------------------------------------------------------------------------------------------

- (void)selectIngredientsPage
{
	NSString *title = @"Calvados Crme BržlŽe";
	NSString *summary = @"Crme bržlŽe is a dessert consisting of a rich custard base topped with a layer of hard caramel, created by burning sugar under an intense heat source.\n\nThis scrumptious variation uses caramelized apples and Calvados to give it a rich flavor. It can be made two to four days ahead, and actually gets better as it ages.";


	CALayer *layer, *body, *menu, *pic;
	CATextLayer *textLayer;
	NSString *dir;

	[CATransaction begin];

	body = [CALayer layer];
	[body setLayoutManager:[CAConstraintLayoutManager layoutManager]];

	textLayer = [CATextLayer layerWithText:summary fontSize:24];
	[textLayer setWrapped:YES];
	[textLayer setName:@"summary"];
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"menu" attribute:kCAConstraintMaxY]];
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"picture" attribute:kCAConstraintMinX offset: -10.0f]];
	[body addSublayer:textLayer];

	pic = [CALayer layer];
	[pic setContents: (id)cremeImage];
	[pic setBounds: CGRectMake(0,0, .8*CGImageGetWidth(cremeImage), .8*CGImageGetHeight(cremeImage))];
	[pic setName: @"picture"];
	[pic addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:0.0f]];
	[pic addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[body addSublayer: pic];

	layer = [CALayer layer];
	[layer setLayoutManager:[MenuBoxLayoutManager layoutManager]];
	[layer setName:@"menu"];
	[layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[layer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"picture" attribute:kCAConstraintMinX]];
	[body addSublayer:layer];
	menu = layer;

	[layer addSublayer:[CATextLayer layerWithText: @"Video" fontSize:24]];

	dir = _pageName >= MenuPageIngredients ? @"fromLeft" : @"fromRight";
	[self setPageTitle:title andBody:body direction:dir];

	[self setSelection:[[menu sublayers] objectAtIndex:0]];
	[_page setValue:menu forKey:@"MenuViewContainer"];

	[CATransaction commit];

	_pageName = MenuPageIngredients;
}

//--------------------------------------------------------------------------------------------------

- (void)selectVideoPage
{
	NSString *title = @"Calvados Crme BržlŽe";
	NSString *dir;

	QTMovieLayer  *movie;

	movie = [QTMovieLayer layerWithMovie: qtMovie];
	movie.beginTime = CACurrentMediaTime ();		// set the start time for the layer
	movie.cornerRadius  = 20.0;
	movie.masksToBounds = TRUE;

	[movie addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[movie addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[movie addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[movie addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];

	dir = _pageName >= MenuPageVideo ? @"fromLeft" : @"fromRight";
	[self setPageTitle:title andBody:movie direction:dir];
	[_page setSelection:nil];

	_pageName = MenuPageVideo;
}

//--------------------------------------------------------------------------------------------------

- (void)selectPage:(int)p
{
	switch (p)
	{
		case MenuPageRoot:
			[self selectRootPage];
			break;

		case MenuPageDesserts:
			[self selectDessertsPage];
			break;

		case MenuPageIngredients:
			[self selectIngredientsPage];
			break;

		case MenuPageVideo:
			[self selectVideoPage];
			break;
	}
}

//--------------------------------------------------------------------------------------------------

- (void)movePage:(int)delta
{
	if (_pageName + delta < 0 || _pageName + delta >= MenuPageCount)
		return; // can't go beyond our valid page range

	[self selectPage:_pageName + delta];
}

//--------------------------------------------------------------------------------------------------

- (void)setSelection:(CALayer *)layer
{
	CAScrollLayer *scroller;

	if (layer != nil)
	{
		scroller = [_page valueForKey:@"MenuViewScroller"];
		[scroller scrollToRect:[layer frame]];
	}

	[_page setSelection:layer];
}

//--------------------------------------------------------------------------------------------------

- (void)moveSelection:(int)delta
{
	NSArray *sublayers;
	CALayer *container, *layer;
	CAScrollLayer *scroller;
	id manager;
	int sel, i, n;
	id obj;

	container = [_page valueForKey:@"MenuViewContainer"];
	if (container == nil)
	return;

	scroller = [_page valueForKey:@"MenuViewScroller"];

	manager = [container layoutManager];
	if ([manager isKindOfClass:[MenuBoxLayoutManager class]])
	{
		sublayers = [container sublayers];
		n = [sublayers count];
		obj = [_page selection];

		if (obj == nil)
		sel = delta > 0 ? 0 : n - 1;
		else
		sel = [sublayers indexOfObject:obj] + delta;

		if (sel >= 0 && sel < n)
		{
			layer = [sublayers objectAtIndex:sel];
			[self setSelection:layer];
		}
	} else if ([manager isKindOfClass:[MenuTableLayoutManager class]]) {
		n = [[container valueForKey:@"myTableRows"] intValue];
		obj = [_page selection];

		if (obj == nil)
		sel = delta > 0 ? 0 : n - 1;
		else
		sel = [[obj valueForKey:@"myTableRow"] intValue] + delta;

		if (sel >= 0 && sel < n)
		{
			sublayers = [container sublayers];
			for (i = [sublayers count] - 1; i >= 0; i--)
			{
				layer = [sublayers objectAtIndex:i];
				if ([[layer valueForKey:@"myTableRow"] intValue] == sel)
				{
					[self setSelection:layer];
					break;
				}
			}
			if (i < 0)
				[self setSelection:nil];
		}
	}
}

//--------------------------------------------------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
	return YES;
}

//--------------------------------------------------------------------------------------------------

- (void)keyDown:(NSEvent *)e
{
	[CATransaction begin];

	if ([e modifierFlags] & (NSAlphaShiftKeyMask|NSShiftKeyMask))
		[CATransaction setValue:[NSNumber numberWithFloat:2.0f] forKey:@"animationDuration"];

	switch ([e keyCode])
	{
		case 123:				/* LeftArrow */
			[self movePage:-1];
			break;

		case 124:				/* RightArrow */
			[self movePage:+1];
			break;

		case 125:				/* DownArrow */
			[self moveSelection:+1];
			break;

		case 126:				/* UpArrow */
			[self moveSelection:-1];
			break;

		default:
			[super keyDown:e];
	}

	[CATransaction commit];
}

//--------------------------------------------------------------------------------------------------

- (void)awakeFromNib
{
	_page = [[MenuPage alloc] init];

	[self setWantsLayer:YES];							// setup the content view to use layers
	[self setLayer:_page];
	[self selectRootPage];
}

//--------------------------------------------------------------------------------------------------

@end
