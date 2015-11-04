/*

File: MenuBox.m

Abstract: MenuBody and MenuSelection class to draw the background and selection in menus

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
#import "MenuBox.h"

#include <math.h>
#include <float.h>

@implementation MenuBody

#define WIDTH 10.0f

//--------------------------------------------------------------------------------------------------

+ (id)defaultValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"needsDisplayOnBoundsChange"])
		return (id) kCFBooleanTrue;

	return [super defaultValueForKey:key];
}

//--------------------------------------------------------------------------------------------------

- (void)dealloc
{
	if (_fgColor != nil)
		CGColorRelease (_fgColor);
	if (_bgColor != nil)
		CGColorRelease (_bgColor);
	[super dealloc];
}

//--------------------------------------------------------------------------------------------------

- (void)addRect:(CGRect)r toContext:(CGContextRef)ctx
{
	float radius = MIN (20.0f, (r.size.height - 2.0f * WIDTH) * .5f);

	if (!_openLeft)
	{
		CGContextMoveToPoint (ctx, r.origin.x + r.size.width, r.origin.y + WIDTH);
		CGContextAddLineToPoint (ctx, r.origin.x + WIDTH + radius, r.origin.y + WIDTH);
		CGContextAddArc (ctx, r.origin.x + WIDTH + radius, r.origin.y + WIDTH + radius, radius, M_PI * 1.5f, M_PI, true);
		CGContextAddLineToPoint (ctx, r.origin.x + WIDTH, r.origin.y + r.size.height - WIDTH - radius);
		CGContextAddArc (ctx, r.origin.x + WIDTH + radius, r.origin.y + r.size.height - WIDTH - radius, radius, M_PI, M_PI * .5f, true);
		CGContextAddLineToPoint (ctx, r.origin.x + r.size.width, r.origin.y + r.size.height - WIDTH);
	} else {
		CGContextMoveToPoint (ctx, r.origin.x, r.origin.y + WIDTH);
		CGContextAddLineToPoint (ctx, r.origin.x + r.size.width - WIDTH - radius, r.origin.y + WIDTH);
		CGContextAddArc (ctx, r.origin.x + r.size.width - WIDTH - radius, r.origin.y + WIDTH + radius, radius, M_PI * 1.5f, 0.0f, false);
		CGContextAddLineToPoint (ctx, r.origin.x + r.size.width - WIDTH, r.origin.y + r.size.height - WIDTH - radius);
		CGContextAddArc (ctx, r.origin.x + r.size.width - WIDTH - radius, r.origin.y + r.size.height - WIDTH - radius, radius, 0.0f, M_PI * .5f, false);
		CGContextAddLineToPoint (ctx, r.origin.x, r.origin.y + r.size.height - WIDTH);
	}
}

//--------------------------------------------------------------------------------------------------

- (void)drawInContext:(CGContextRef)ctx
{
	CGRect r = [self bounds];

	if (_bgColor != nil)
		CGContextSetFillColorWithColor (ctx, _bgColor);
	else
		CGContextSetGrayFillColor (ctx, 0.0f, .5f);

	if (_fgColor != nil)
		CGContextSetStrokeColorWithColor (ctx, _fgColor);
	else
		CGContextSetGrayStrokeColor (ctx, 1.0f, 1.0f);

	[self addRect:r toContext:ctx];
	CGContextDrawPath (ctx, kCGPathFill);
}

@end

//--------------------------------------------------------------------------------------------------

@implementation MenuSelection

- (id)init
{
	static const float fg[4] = {1.0f, 1.0f, 1.0f, 1.0f};
	static const float bg[4] = {.5f, .1f, .0f, .7f};

	CGColorSpaceRef cs;
	CIFilter    *effect;

	self = [super init];
	if (self == nil)
		return nil;

	_openLeft = true;

	cs = CGColorSpaceCreateDeviceRGB ();
	_fgColor = CGColorCreate (cs, fg);
	_bgColor = CGColorCreate (cs, bg);
	CGColorSpaceRelease (cs);

	effect = [CIFilter filterWithName:@"CIBloom"];
	[effect setDefaults];
	[effect setValue: [NSNumber numberWithFloat: 10.0f]  forKey: @"inputRadius"];
	[effect setName: @"bloom"];

	[self setFilters: [NSArray arrayWithObject:effect]];

	CABasicAnimation *anim;

	anim = [CABasicAnimation animation];
	anim.keyPath = @"filters.bloom.inputIntensity";
	anim.fromValue = [NSNumber numberWithFloat: 0.5];
	anim.toValue = [NSNumber numberWithFloat: 2.0];
	anim.duration = 0.8;
	anim.autoreverses = true;
	anim.repeatCount = FLT_MAX;
	anim.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
	[self addAnimation:anim forKey:nil];
	return self;
}

//--------------------------------------------------------------------------------------------------

- (void)drawInContext:(CGContextRef)ctx
{
	CGRect r = [self bounds];

	if (_bgColor != nil)
		CGContextSetFillColorWithColor (ctx, _bgColor);
	else
		CGContextSetGrayFillColor (ctx, 0.0f, .5f);

	if (_fgColor != nil)
		CGContextSetStrokeColorWithColor (ctx, _fgColor);
	else
		CGContextSetGrayStrokeColor (ctx, 1.0f, 1.0f);

	[self addRect:r toContext:ctx];
	CGContextDrawPath (ctx, kCGPathFill);

	[self addRect:r toContext:ctx];
	CGContextSetLineWidth (ctx, 3.0f);
	CGContextSetShadow (ctx, CGSizeMake (4.0f, -4.0f), 2.0f);
	CGContextStrokePath (ctx);
}

//--------------------------------------------------------------------------------------------------

@end
