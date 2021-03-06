/* CovertFlow - DesktopImageLayout.m
 *
 * Abstract: The DesktopImageLayout determines the visual layout of the
 * desktop image elements.
 *
 * Copyright (c) 2006-2007 Apple Computer, Inc.
 * All rights reserved.
 */

/* IMPORTANT: This Apple software is supplied to you by Apple Computer,
 Inc. ("Apple") in consideration of your agreement to the following terms,
 and your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms.  If you do not agree with
 these terms, please do not use, install, modify or redistribute this Apple
 software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following text
 and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
 ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
 LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE. */

#import "DesktopImageLayout.h"
#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>

NSString *desktopImageCellSize = @"desktopImageCellSize";
NSString *desktopImageCount = @"desktopImageCount";
NSString *desktopImageIndex = @"desktopImageIndex";
NSString *selectedDesktopImage = @"selectedDesktopImage";

@implementation DesktopImageLayout

static DesktopImageLayout *sharedLayoutManager;

+ (id)layoutManager
{
	if (sharedLayoutManager == nil)
	{
		sharedLayoutManager = [[self alloc] init];
	}
	return sharedLayoutManager;
}

- (DesktopImageLayout *)init
{
	if ([super init])
	{
		/* there's no math behind these; they just happen to look right */
		zCenterPosition = 100.;
		zSidePosition = 0;
		sideSpacingFactor = .75;
		rowScaleFactor = .85;
		float angle = .79;
		leftTransform = CATransform3DMakeRotation(-angle, 0, -1, 0);
		rightTransform = CATransform3DMakeRotation(angle, 0, -1, 0);
		return self;
	}
	return nil;
}

-(float)positionOfSelectedDesktopImageInLayer:(CALayer *)layer
{
	/* extract values from the layer: selected image index, and
	   spacing information */
	NSNumber *number = [layer valueForKey:selectedDesktopImage];
	int selected = number != nil ? [number integerValue] : 0;
	float margin = [[layer valueForKey:@"margin"] sizeValue].width;
	float bounds = [layer bounds].size.width;
	float cellSize = (float)[[layer valueForKey:desktopImageCellSize] sizeValue].width;
	cellSize = cellSize ? cellSize : 100.;
	float count = [[layer valueForKey:desktopImageCount] intValue];
	float spacing = [[layer valueForKey:@"spacing"] sizeValue].width;
	
	// this is the same math used in layoutSublayersOfLayer:, before tweaking
	float x = floor(margin + .5*(bounds - cellSize * count - spacing * (count - 1))) + selected * (cellSize + spacing) - .5 * bounds + .5 * cellSize;
	
	return x;
}

- (CFArrayRef)desktopImageIndicesOfLayer:(CALayer *)layer inRect:(CGRect)r
{
	int x, x0, x1;
	int total;
	CGSize size;
	NSSize margin, spacing;
	NSSize cellSize;
	NSValue *value;
	const void **values;
	int i, count;
	
	size = [layer bounds].size;
	margin = [[layer valueForKey:@"margin"] sizeValue];
	spacing = [[layer valueForKey:@"spacing"] sizeValue];
	value = [layer valueForKey:desktopImageCellSize];
	cellSize = value != nil ? [value sizeValue] : NSMakeSize (100.0, 100.0);
	total = [[layer valueForKey:desktopImageCount] intValue];
	NSNumber *number = [layer valueForKey:selectedDesktopImage];
	float selected = number != nil ? [number integerValue] : 0.;
	
	if (total == 0)
		return NULL;
	
	margin.width += (size.width - cellSize.width * total - spacing.width * (total - 1)) * .5;
	margin.width = floor (margin.width);
	
	// these are the inverse of the equations in layoutSublayersOfLayer:, below
	x0 = floor((r.origin.x - margin.width - (cellSize.width * sideSpacingFactor) * (selected + rowScaleFactor)) / ((1. - sideSpacingFactor) * cellSize.width + spacing.width));
	x1 = ceil((r.origin.x + r.size.width - margin.width - (cellSize.width * sideSpacingFactor) * (selected + rowScaleFactor)) / (cellSize.width * (1. - sideSpacingFactor) + spacing.width));
	if (x0 < 0)
		x0 = 0;
	if (x1 >= total)
		x1 = total - 1;
	
	count = (x1 - x0 + 1);
	if (count <= 0)
		return NULL;
	
	values = alloca (count * sizeof (values[0]));
	
	i = 0;
    for (x = x0; x <= x1; x++)
		values[i++] = (void *)x;
	
	return CFArrayCreate (NULL, values, count, NULL);
}

// this is where the magic happens
- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	NSValue *value;
	NSSize cellSize;
	CGSize size;
	NSSize spacing, margin;
	NSNumber *index;
	NSArray *array;
	CALayer *sublayer, *desktopImageLayer;
	size_t i, count;
	int total, x;
	CGRect rect, desktopImageRect;
	size = [layer bounds].size;
	margin = [[layer valueForKey:@"margin"] sizeValue];
	spacing = [[layer valueForKey:@"spacing"] sizeValue];
	NSNumber *number = [layer valueForKey:selectedDesktopImage];
	int selected = number != nil ? [number integerValue] : 0;
	value = [layer valueForKey:desktopImageCellSize];
	cellSize = value != nil ? [value sizeValue] : NSMakeSize (100.0, 100.0);
	total = [[layer valueForKey:desktopImageCount] intValue];
	
	if (total == 0)
		return;
	
	margin.width += (size.width - cellSize.width * total - spacing.width * (total - 1)) * .5;
	margin.width = floor (margin.width);
	
	array = [layer sublayers];
	count = [array count];
	
	for (i = 0; i < count; i++)
    {
		sublayer = [array objectAtIndex:i];
		desktopImageLayer = [[sublayer sublayers] objectAtIndex:0];
		
		index = [desktopImageLayer valueForKey:desktopImageIndex];
		if (index == nil)
			continue;
		
		x = [index intValue];
		
		rect.size = *(CGSize *)&cellSize;
		rect.origin = CGPointZero;
		desktopImageRect = rect;
		// base position - this would be correct without perspective
		rect.origin.y = size.height / 2 - cellSize.height / 2;
		rect.origin.x = margin.width + x * (cellSize.width + spacing.width);
		
		
		// perspective and according position tweaks
		if (x < selected)		// left
		{
			rect.origin.x += cellSize.width * sideSpacingFactor * (float)(selected - x - rowScaleFactor);
			desktopImageLayer.transform = leftTransform;
			desktopImageLayer.zPosition = zSidePosition;
			sublayer.zPosition = zSidePosition - .01 * (selected - x);
		}
		else if (x > selected)	// right
		{
			rect.origin.x -= cellSize.width * sideSpacingFactor * (float)(x - selected - rowScaleFactor);
			desktopImageLayer.transform = rightTransform;
			desktopImageLayer.zPosition = zSidePosition;
			sublayer.zPosition = zSidePosition - .01 * (x - selected);
		}
		else					// center
		{
			desktopImageLayer.transform = CATransform3DIdentity;
			desktopImageLayer.zPosition = zCenterPosition;
			sublayer.zPosition = zSidePosition;
		}
		[sublayer setFrame:rect];
		[desktopImageLayer setFrame:desktopImageRect];
	}
}

@end
