/*

File: MenuLayoutManagers.m

Abstract:	A set of custom LayoutManagers that deal with the arrangements of
			sublayers to form a menu.

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

Copyright ¬© 2006 Apple Computer, Inc., All Rights Reserved

*/ 

#import "MenuLayoutManagers.h"

#import <QuartzCore/CAScrollLayer.h>
#import <Foundation/Foundation.h>


@implementation MenuBoxLayoutManager

//--------------------------------------------------------------------------------------------------

+ (id)layoutManager
{
	static MenuBoxLayoutManager *_layout;

	if (_layout == nil)
		_layout = [[self alloc] init];

	return _layout;
}

//--------------------------------------------------------------------------------------------------

- (CGSize)preferredSizeOfLayer:(CALayer *)self_layer
{
	const CGSize spacing = CGSizeMake(8.0, 8.0f);
	const CGSize margin = CGSizeMake(30.0f, 30.0f);

	CGSize total, max, size;
	NSArray *array;
	int i, n;

	array = [self_layer sublayers];
	n = [array count];
	total = CGSizeZero;
	max = CGSizeZero;

	for (i = 0; i < n; i++)
	{
		CALayer *layer = [array objectAtIndex:i];
		CGSize sz;

		sz = [layer preferredFrameSize];
		total.width += sz.width;
		total.height += sz.height;
		max.width = MAX (max.width, sz.width);
		max.height = MAX (max.height, sz.height);
	}
	size.width = max.width + margin.width * 2.0f;
	size.height = total.height + (n - 1) * spacing.height + margin.height * 2.0f;

	return size;
}

//--------------------------------------------------------------------------------------------------

- (void)layoutSublayersOfLayer:(CALayer *)self_layer
{
	const CGSize spacing = CGSizeMake(8.0, 8.0f);
	const CGSize margin = CGSizeMake(30.0f, 30.0f);

	NSArray *array;
	int n, i, j;
	CGRect r = [self_layer bounds], fr;
	CGSize sz;
	float x0, y0, x1, y1;
	float *w, *h, *x, *y;
	float p, width, space;
	CALayer **sublayers;

	x0 = r.origin.y + margin.height;
	y0 = r.origin.x + margin.width;
	x1 = r.origin.y + r.size.height - margin.height;
	y1 = r.origin.x + r.size.width - margin.width;
	space = spacing.height;

	array = [self_layer sublayers];
	n = [array count];
	sublayers = alloca (sizeof (CALayer *) * n);
	x = alloca (sizeof (float) * n);
	y = alloca (sizeof (float) * n);
	w = alloca (sizeof (float) * n);
	h = alloca (sizeof (float) * n);

	for (i = j = 0; i < n; i++)
	{
		sublayers[j] = [array objectAtIndex:i];
		sz = [sublayers[j] preferredFrameSize];
		w[j] = sz.height, h[j] = sz.width;
		j++;
	}

	width = x1 - x0 - (space * (j - 1));

	for (p = x0, i = 0; i < j; p += w[i] + space, i++)
	{
		// Fill
		w[i] = floor (width / j);
		//	Expand
		h[i] = y1 - y0;

		x[i] = p;

		y[i] = y0; 
	}

	for (i = 0; i < j; i++)
		x[i] = x1 - (x[i] + w[i] - x0);

	for (i = 0; i < j; i++)
	{
		fr = CGRectMake (y[i], x[i], h[i], w[i]);
		[sublayers[i] setFrame:fr];
	}
}

//--------------------------------------------------------------------------------------------------

@end

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------

@implementation MenuScrollLayoutManager

//--------------------------------------------------------------------------------------------------

+ (id)layoutManager
{
	static id _layout;

	if (_layout == nil)
		_layout = [[self alloc] init];

	return _layout;
}

//--------------------------------------------------------------------------------------------------

- (CGSize)preferredSizeOfLayer:(CALayer *)self_layer
{
	NSEnumerator *e;
	CALayer *layer;
	CGSize size, tem;

	e = [self_layer.sublayers objectEnumerator];
	size = CGSizeZero;
	while ((layer = [e nextObject]) != nil)
	{
		tem = [layer preferredFrameSize];
		size.width = MAX (size.width, tem.width);
		size.height = MAX (size.height, tem.height);
	}
	return size;
}

//--------------------------------------------------------------------------------------------------

- (void)layoutSublayersOfLayer:(CALayer *)self_layer
{
	NSString *str;
	NSEnumerator *e;
	CALayer *layer;
	CGSize boundsSize, size;
	CGRect r;

	boundsSize = [self_layer bounds].size;
	str = [(CAScrollLayer *)self_layer scrollMode];

	e = [self_layer.sublayers objectEnumerator];
	while ((layer = [e nextObject]) != nil)
	{
		size = [layer preferredFrameSize];

		r.origin = CGPointZero;
		r.size = boundsSize;

		r.size.height = MAX (size.height, r.size.height);

		[layer setFrame:r];
	}
}

//--------------------------------------------------------------------------------------------------

@end

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------


@implementation MenuTableLayoutManager

//--------------------------------------------------------------------------------------------------

+ (id)layoutManager
{
	static MenuTableLayoutManager *_layout;

	if (_layout == nil)
		_layout = [[self alloc] init];

	return _layout;
}

//--------------------------------------------------------------------------------------------------

- (CGSize)preferredSizeOfLayer:(CALayer *)self_layer
{
	const CGSize spacing = CGSizeMake(8.0, 8.0f);
	const CGSize margin = CGSizeMake(30.0f, 30.0f);

	float *widths, *heights;
	float width_sum, height_sum;
	CALayer *layer;
	CGSize sz;
	NSArray *sublayers;
	unsigned int rows, columns, i, n, x, y;

	sublayers = [self_layer sublayers];

	rows = [sublayers count]; [[self_layer valueForKey:@"myTableRows"] intValue];
	columns = [[self_layer valueForKey:@"myTableColumns"] intValue];

	for (i = 0, n = [sublayers count]; i < n; i++)
	{
		layer = [sublayers objectAtIndex:i];

		rows = MAX (rows, [[layer valueForKey:@"TableRow"] intValue] + 1);
		columns = MAX (columns, [[layer valueForKey:@"TableColumn"] intValue] + 1);
	}

	if (rows == 0 || columns == 0)
	return margin;

	widths = alloca (sizeof (widths[0]) * columns);
	heights = alloca (sizeof (heights[0]) * rows);
	memset (widths, 0, sizeof (widths[0]) * columns);
	memset (heights, 0, sizeof (heights[0]) * rows);

	for (i = 0, n = [sublayers count]; i < n; i++)
	{
		layer = [sublayers objectAtIndex:i];

		sz = [layer preferredFrameSize];
		x = [[layer valueForKey:@"myTableColumn"] intValue];
		y = [[layer valueForKey:@"myTableRow"] intValue];

		widths[x] = MAX (widths[x], sz.width);
		heights[y] = MAX (heights[y], sz.height);
	}

	width_sum = height_sum = 0.0f;

	for (i = 0; i < columns; i++)
		width_sum += widths[i];

	for (i = 0; i < rows; i++)
		height_sum += heights[i];

	width_sum += spacing.width * (columns - 1) + margin.width * 2.0f;
	height_sum += spacing.height * (rows - 1) + margin.height * 2.0f;

	sz = CGSizeMake (width_sum, height_sum);

	return sz;
}

//--------------------------------------------------------------------------------------------------

- (void)layoutSublayersOfLayer:(CALayer *)self_layer
{
	const CGSize spacing = CGSizeMake(8.0, 8.0f);
	const CGSize margin = CGSizeMake(30.0f, 30.0f);

	CALayer **layers;
	CGRect r = [self_layer bounds];
	CGSize *sizes, size;
	float *widths, *heights;
	float width_sum, height_sum;
	float x0, y0, x1, y1, w, h, px, py;
	CALayer *layer;
	NSArray *sublayers;
	unsigned int rows, columns;
	unsigned int i, n, x, y;

	sublayers = [self_layer sublayers];

	rows = [[self_layer valueForKey:@"myTableRows"] intValue];
	columns = [[self_layer valueForKey:@"myTableColumns"] intValue];

	for (i = 0, n = [sublayers count]; i < n; i++)
	{
		layer = [sublayers objectAtIndex:i];
		rows = MAX (rows, [[layer valueForKey:@"myTableRow"] intValue] + 1);
		columns = MAX (columns, [[layer valueForKey:@"myTableColumn"] intValue] + 1);
	}

	if (rows == 0 || columns == 0)
		return;

	layers = alloca (sizeof (layers[0]) * rows * columns);
	sizes = alloca (sizeof (sizes[0]) * rows * columns);
	widths = alloca (sizeof (widths[0]) * columns);
	heights = alloca (sizeof (heights[0]) * rows);
	memset (layers, 0, rows * columns * sizeof (layers[0]));
	memset (sizes, 0, rows * columns * sizeof (sizes[0]));
	memset (widths, 0, columns * sizeof (widths[0]));
	memset (heights, 0, rows * sizeof (heights[0]));

	for (i = 0, n = [sublayers count]; i < n; i++)
	{
		layer = [sublayers objectAtIndex:i];

		size = [layer preferredFrameSize];
		x = [[layer valueForKey:@"myTableColumn"] intValue];
		y = [[layer valueForKey:@"myTableRow"] intValue];

		layers[y*columns+x] = layer;
		sizes[y*columns+x] = size;

		widths[x] = MAX (widths[x], size.width);
		heights[y] = MAX (heights[y], size.height);
	}

	x0 = r.origin.x + margin.width;
	y0 = r.origin.y + margin.height;
	x1 = r.origin.x + r.size.width - margin.width;
	y1 = r.origin.y + r.size.height - margin.height;
	w = (x1 - x0) - (spacing.width * (columns - 1));
	h = (y1 - y0) - (spacing.height * (rows - 1));

	if (w < 1.0f || h < 1.0f)
		return;

	width_sum = height_sum = 0.0f;

	for (i = 0; i < columns; i++)
		width_sum += widths[i];
	for (i = 0; i < rows; i++)
		height_sum += heights[i];

	/* If width_sum > w, find widest column and scale by 2/3. Repeat until
	 width_sum <= w. And same for vertical dimension. */

	while (width_sum > w)
	{
		float	max_width = widths[0];
		int		max_index = 0;

		for (i = 1; i < columns; i++)
			if (widths[i] > max_width)
				max_width = widths[i], max_index = i;

		widths[max_index] = MAX (max_width * (2.0f / 3.0f), widths[max_index] - (width_sum - w));
		width_sum -= max_width - widths[max_index];
	}

	while (height_sum > h)
	{
		float	max_height = heights[0];
		int		max_index = 0;

		for (i = 1; i < rows; i++)
			if (heights[i] > max_height)
				max_height = heights[i], max_index = i;

		heights[max_index] = MAX (max_height * (2.0f / 3.0f), heights[max_index] - (height_sum - h));
		height_sum -= max_height - heights[max_index];
	}

	for (y = 0, py = y0; y < rows; y++)
	{
		for (x = 0, px = x0; x < columns; x++)
		{
			layer = layers[y*columns+x];
			if (layer != nil)
			{
				CGRect lr;

				lr.size.width = widths[x];
				lr.size.height = sizes[y*columns+x].height;
				lr.origin.x = px;
				lr.origin.y = py;
				lr.origin.y = y1 - (lr.origin.y + lr.size.height - y0);
				[layer setFrame:lr];
			}
			px += widths[x] + spacing.width;
		}
		py += heights[y] + spacing.height;
	}
}

//--------------------------------------------------------------------------------------------------

@end
