/*

File: MenuPage.m

Abstract:	Custom layer that holds the content of the menu system. 
			It handles the structural elements of the menu pages.

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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 
#import "MenuPage.h"
#import "MenuBox.h"
#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>

@interface MenuContent : CALayer
@end

@implementation MenuPage

static CGImageRef berriesImage = NULL;

//--------------------------------------------------------------------------------------------------

- (id)init
{
	if(!berriesImage)
	{
		CGImageSourceRef source;

		source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:
			[[NSBundle mainBundle] pathForResource:@"Strawberries" ofType:@"jpg"]], NULL);

		berriesImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
		CFRelease(source);
	}

	if(self = [super init])
	{
		[self setContents: (id)berriesImage];
		[self setBounds: CGRectMake(0,0, CGImageGetWidth(berriesImage), CGImageGetHeight(berriesImage))];
	}
	/* The background is opaque; this propagates that into the surface. */
	[self setOpaque:YES];

	_body = [[MenuBody alloc] init];

	_content = [[MenuContent alloc] init];
	[_content setLayoutManager:[MenuBoxLayoutManager layoutManager]];

	_header = [[CALayer alloc] init];
	[_header setLayoutManager:[MenuBoxLayoutManager layoutManager]];

	/* constraint based layout of the page. */

	[self setLayoutManager:[CAConstraintLayoutManager layoutManager]];

	[_header setName:@"header"];
	[_body setName:@"body"];
	[_content setName:@"content"];

	[_body addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:50.0f]];
	[_body addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:.7f offset:0.0f]];
	[_body addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[_body addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:.9f offset:0.0f]];
	[_header addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"body" attribute:kCAConstraintMaxY offset:20.0f]];
	[_header addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"body" attribute:kCAConstraintMidX]];

	[_content addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"body" attribute:kCAConstraintMinY]];
	[_content addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"body" attribute:kCAConstraintMaxY]];
	[_content addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"body" attribute:kCAConstraintMinX]];
	[_content addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"body" attribute:kCAConstraintMaxX]];

	[self addSublayer:_body];
	[self addSublayer:_content];
	[self addSublayer:_header];

	return self;
}

//--------------------------------------------------------------------------------------------------

- (void)dealloc
{
	[_header release];
	[_body release];
	[_content release];
	[_highlight release];
	[_selection release];
	[super dealloc];
}

//--------------------------------------------------------------------------------------------------

- (CALayer *)header
{
	return _header;
}

//--------------------------------------------------------------------------------------------------

- (CALayer *)body
{
	return _content;
}

//--------------------------------------------------------------------------------------------------

- (void)updateSelection
{
	CGRect r;

	if (_selection != nil)
	{
		if (_highlight == nil)
			_highlight = [[MenuSelection alloc] init];

		/* Position the highlight layer under the selected layer, and
		 make it extend to the far left of the page. */

		r = CGRectInset ([_selection frame], -15.0f, -15.0f);
		r = [self convertRect:r fromLayer:[_selection superlayer]];
		r.size.width += r.origin.x + 10;
		r.origin.x = 0.0f;
		r = [_body convertRect:r fromLayer:self];

		[_highlight setFrame:r];
		[_body insertSublayer:_highlight atIndex:0];
	} else {
		[_highlight removeFromSuperlayer];
	}
}

//--------------------------------------------------------------------------------------------------

- (void)setSelection:(CALayer *)layer
{
	if (_selection != layer)
	{
		[_selection release];
		_selection = [layer retain];
		[self updateSelection];
	}
}

//--------------------------------------------------------------------------------------------------

- (CALayer *)selection
{
	return [[_selection retain] autorelease];
}

//--------------------------------------------------------------------------------------------------

@end

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------

@implementation MenuContent

//--------------------------------------------------------------------------------------------------

+ (id<CAAction>)defaultActionForKey:(NSString *)key
{
	CAMediaTimingFunction *curve;
	CATransition *anim;
	id obj, action;

	if ([key isEqualToString:@"sublayers"])
	{
		anim = [CATransition animation];
		[anim setType:@"push"];
		curve = [CAMediaTimingFunction functionWithControlPoints:.2 :.0 :.2 :1.0];
		if ([CATransaction valueForKey:@"animationDuration"] == nil)
			[anim setDuration:.5f];
		[anim setTimingFunction:curve];
		obj = [CATransaction valueForKey:@"ovitTransitionType"];
		if (obj != nil)
			[anim setSubtype:obj];
		action = anim;
	} else {
		action = [super defaultActionForKey:key];
	}
	return action;
}

//--------------------------------------------------------------------------------------------------

@end

