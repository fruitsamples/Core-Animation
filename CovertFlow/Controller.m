/* CovertFlow - Controller.m
 *
 * Abstract: The Controller drives the application based on user input.
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

#import "Controller.h"

#import "DesktopImage.h"
#import "DesktopImageLayout.h"
#import "Catalog.h"
#import "View.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation Controller

/* useful color values to have around */
enum colors
{
	C_WHITE,
	C_BLACK,
	C_GRAY,
	C_LIGHT_GRAY,
	C_TRANSPARENT,
	C_COUNT
};

static const CGFloat colorValues[C_COUNT][4] =
{
	{1.0, 1.0, 1.0, 1.0},
	{0.0, 0.0, 0.0, 1.0},
	{1.0, 1.0, 1.0, 0.5},
	{1.0, 1.0, 1.0, 0.1},
	{0.0, 0.0, 0.0, 0.0}
};

/* create a CGColor based on the array above */
+ (CGColorRef)color:(int)name
{
	static CGColorRef colors[C_COUNT];
	static CGColorSpaceRef space;
	
	if (colors[name] == NULL)
    {
		if (space == NULL)
			space = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
		colors[name] = CGColorCreate (space, colorValues[name]);
    }
	
	return colors[name];
}

- (id)init
{
	NSSize size;
	CALayer *rootLayer;
	
	float cellSpacing = 5;
	float cellSize = 160;
	
	self = [super init];
	if (self == nil)
		return nil;
	
	[NSBundle loadNibNamed:@"View" owner:self];
	[[view window] setDelegate:self];
	
	/* sign up to be informed when a new image loads */
	[[NSNotificationCenter defaultCenter] addObserver:self
	selector:@selector(imageDidLoadNotification:)
	name:desktopImageImageDidLoadNotification object:nil];
	
	layerDictionary = CFDictionaryCreateMutable (NULL, 0,
	&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	/* this enables a perspective transform.  The value of zDistance
	   affects the sharpness of the transform */
	float zDistance = 420.;
	sublayerTransform = CATransform3DIdentity; 
	sublayerTransform.m34 = 1. / -zDistance;
	
	textStyle = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInteger:12], @"cornerRadius",
	[NSValue valueWithSize:NSMakeSize(5, 0)], @"margin",
	@"BankGothic-Light", @"font",
	[NSNumber numberWithInteger:18], @"fontSize",
	kCAAlignmentCenter, @"alignmentMode",
	nil];
	
	/* here we set up the hierarchy of layers.
	   This means child/parent relationships as well as
	   constraint (position) relationships. */
	// the root layer for the view--serves to attach the hierarchy to an NSView
	rootLayer = [CALayer layer];
	rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	rootLayer.backgroundColor = [Controller color:C_BLACK];
	
	// informative header text
	headerTextLayer = [CATextLayer layer];
	headerTextLayer.name = @"header";
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-10]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"header" attribute:kCAConstraintMaxY offset:-64]];
	headerTextLayer.string = @"Loading Images...";
	headerTextLayer.style = textStyle;
	headerTextLayer.fontSize = 24;
	headerTextLayer.wrapped = YES;
	[rootLayer addSublayer:headerTextLayer];
	
	// the background canvas on which we'll arrange the other layers
	CALayer *containerLayer = [CALayer layer];
	containerLayer.name = @"body";
	[containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
	[containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth offset:-20]];
	[containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"status" attribute:kCAConstraintMaxY offset:10]];
	[containerLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"header" attribute:kCAConstraintMinY offset:-10]];
	[rootLayer addSublayer:containerLayer];
	
	// the central scrolling layer; this will contain the images
	bodyLayer = [CAScrollLayer layer];
	bodyLayer.scrollMode = kCAScrollHorizontally;
	bodyLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	bodyLayer.layoutManager = [DesktopImageLayout layoutManager];
	[bodyLayer setValue:[NSValue valueWithSize:NSMakeSize(cellSpacing, cellSpacing)] forKey:@"spacing"];
	[bodyLayer setValue:[NSValue valueWithSize:NSMakeSize(cellSize, cellSize)] forKey:@"desktopImageCellSize"];
	[containerLayer addSublayer:bodyLayer];
	
	// the footer containing status info...
	CALayer *statusLayer = [CALayer layer];
	statusLayer.name = @"status";
	statusLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"body" attribute:kCAConstraintMidX]];
	[statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"body" attribute:kCAConstraintWidth]];
	[statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:10]];
	[statusLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"status" attribute:kCAConstraintMinY offset:32]];
	[rootLayer addSublayer:statusLayer];
	
	//...such as the image count
	desktopImageCountLayer = [CATextLayer layer];
	desktopImageCountLayer.name = @"desktopImage-count";
	desktopImageCountLayer.style = textStyle;
	[desktopImageCountLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
	[desktopImageCountLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[statusLayer addSublayer:desktopImageCountLayer];
	
	/* done setting up layers */
	
	size = [[bodyLayer valueForKey:desktopImageCellSize] sizeValue];
	desktopImageSize = *(CGSize *)&size;
	/* these two lines inform the view that it will hold (and display)
	   Core Animation objects */
	[view setLayer:rootLayer];
	[view setWantsLayer:YES];
	[bodyLayer setDelegate:self];
	
	// create a gradient image to use for our image shadows
	CGRect r;
	r.origin = CGPointZero;
	r.size = desktopImageSize;
	size_t bytesPerRow = 4*r.size.width;
	void* bitmapData = malloc(bytesPerRow * r.size.height);
	CGContextRef context = CGBitmapContextCreate(bitmapData, r.size.width,
				r.size.height, 8,  bytesPerRow, 
				CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:.5] endingColor:[NSColor colorWithDeviceWhite:0 alpha:1.]];
	NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsContext];
	[gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:90];
	[NSGraphicsContext restoreGraphicsState];
	shadowImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(bitmapData);
	[gradient release];
	
	/* create a pleasant gradient mask around our central layer.
	   We don't have to worry about re-creating these when the window
	   size changes because the images will be automatically interpolated
	   to their new sizes; and as gradients, they are very well suited to
	   interpolation. */
	CALayer *maskLayer = [CALayer layer];
	CALayer *leftGradientLayer = [CALayer layer];
	CALayer *rightGradientLayer = [CALayer layer];
	CALayer *bottomGradientLayer = [CALayer layer];
	
	// left
	r.origin = CGPointZero;
	r.size.width = [view frame].size.width;
	r.size.height = [view frame].size.height;
	bytesPerRow = 4*r.size.width;
	bitmapData = malloc(bytesPerRow * r.size.height);
	context = CGBitmapContextCreate(bitmapData, r.size.width,
				r.size.height, 8,  bytesPerRow, 
				CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
	gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0. alpha:1.] endingColor:[NSColor colorWithDeviceWhite:0. alpha:0]];
	nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsContext];
	[gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:0];
	[NSGraphicsContext restoreGraphicsState];
	CGImageRef gradientImage = CGBitmapContextCreateImage(context);
	leftGradientLayer.contents = (id)gradientImage;
	CGContextRelease(context);
	CGImageRelease(gradientImage);
	free(bitmapData);
	
	// right
	bitmapData = malloc(bytesPerRow * r.size.height);
	context = CGBitmapContextCreate(bitmapData, r.size.width,
				r.size.height, 8,  bytesPerRow, 
				CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
	nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsContext];
	[gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:180];
	[NSGraphicsContext restoreGraphicsState];
	gradientImage = CGBitmapContextCreateImage(context);
	rightGradientLayer.contents = (id)gradientImage;
	CGContextRelease(context);
	CGImageRelease(gradientImage);
	free(bitmapData);
	
	// bottom
	r.size.width = [view frame].size.width;
	r.size.height = 32;
	bytesPerRow = 4*r.size.width;
	bitmapData = malloc(bytesPerRow * r.size.height);
	context = CGBitmapContextCreate(bitmapData, r.size.width,
				r.size.height, 8,  bytesPerRow, 
				CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedFirst);
	nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsContext];
	[gradient drawInRect:NSMakeRect(0, 0, r.size.width, r.size.height) angle:90];
	[NSGraphicsContext restoreGraphicsState];
	gradientImage = CGBitmapContextCreateImage(context);
	bottomGradientLayer.contents = (id)gradientImage;
	CGContextRelease(context);
	CGImageRelease(gradientImage);
	free(bitmapData);
	[gradient release];
	
	// the autoresizing mask allows it to change shape with the parent layer
	maskLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	maskLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	[leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
	[leftGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:-desktopImageSize.width / 2]];
	[rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
	[rightGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:.5 offset:desktopImageSize.width / 2]];
	[bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[bottomGradientLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMinY offset:32]];
	
	bottomGradientLayer.masksToBounds = YES;
	
	[maskLayer addSublayer:rightGradientLayer];
	[maskLayer addSublayer:leftGradientLayer];
	[maskLayer addSublayer:bottomGradientLayer];
	// we make it a sublayer rather than a mask so that the overlapping alpha will work correctly
	// without the use of a compositing filter
	[containerLayer addSublayer:maskLayer];
	
	// create the catalog and start it processing desktop images
	catalog = [[Catalog alloc] init];
	[catalog setDelegate:self];
	[catalog beginProcessing];
	
	sortKeys[0] = kDesktopImageName;
	sortKeys[1] = 0;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[catalog release];
	CGImageRelease(shadowImage);  
	if (layerDictionary != NULL)
		CFRelease (layerDictionary);
	[super dealloc];
}

- (View *)view
{
	return view;
}

- (CALayer *)layerForDesktopImage:(DesktopImage *)desktopImage
{
	/* we have to do this sublayer thing because the actual layer
	   stored for the key is the layer containing both the desktop image
	   and its reflection.
	 */
	CALayer *containerLayer = (CALayer *)CFDictionaryGetValue (layerDictionary, desktopImage);
	return (CALayer *)[[containerLayer sublayers] objectAtIndex:0];
}

- (void)updateImageForLayer:(CALayer *)layer fromDesktopImage:(DesktopImage *)desktopImage
{
	CGImageRef image;
	CGSize size;
	
	size = [layer bounds].size;
	
	image = [desktopImage imageOfSize:size];
	
	if (image != NULL)
	{
		// set the image for the layer...
		[layer setContents:(id) image];
		// ...and for its shadow (which we know to be the first sublayer)
		NSArray *sublayers = layer.sublayers;
		CALayer *sublayer = (CALayer *)[sublayers objectAtIndex:0];
		[sublayer setContents:(id)image];
		[sublayer setBackgroundColor:NULL];
	}
	else
		[desktopImage requestImageOfSize:size];
}

- (void)updateImage
{
	CGRect visRect;
	CFArrayRef indices;
	DesktopImageLayout *layout;
	DesktopImage *desktopImage;
	size_t i, count, idx;
	
	visRect = [bodyLayer visibleRect];
	layout = [bodyLayer layoutManager];
	indices = [layout desktopImageIndicesOfLayer:bodyLayer inRect:visRect];
	
	if (indices != NULL)
    {
		count = CFArrayGetCount (indices);
		for (i = 0; i < count; i++)
		{
			idx = (uintptr_t) CFArrayGetValueAtIndex (indices, i);
			
			if (idx < totalDesktopImages)
			{
				desktopImage = [desktopImages objectAtIndex:idx];
				[self updateImageForLayer:[self layerForDesktopImage:desktopImage] fromDesktopImage:desktopImage];
			}
		}
		CFRelease(indices);
    }
	[DesktopImage sweepImageQueue];
}

- (void)updateSelection
{
	CALayer *layer;
	CGRect r;
	
	DesktopImageLayout *layout = [bodyLayer layoutManager];
	[bodyLayer setValue:[NSNumber numberWithInteger: selectedDesktopImageIndex] forKey:selectedDesktopImage];
	
	// here is where we ask the layout manager to reflect the new selected image
	[bodyLayer layoutIfNeeded];
	
	layer = [self layerForDesktopImage:[desktopImages objectAtIndex:selectedDesktopImageIndex]];
	if (layer == nil)
		return;
	
	r = [layer frame];
	/* we scroll so the selected image is centered, but the layout manager
	   doesn't know about this--as far as it is concerned everything takes
	   place in a very wide frame */
	[bodyLayer scrollToPoint:CGPointMake([layout positionOfSelectedDesktopImageInLayer:bodyLayer], r.origin.y)];
	[headerTextLayer setString:[(DesktopImage *)[layer delegate] name]];
	
	[self updateImage];
}

- (void)moveSelection:(int)dx
{
	selectedDesktopImageIndex += dx;
	
	if (selectedDesktopImageIndex >= totalDesktopImages)
		selectedDesktopImageIndex = totalDesktopImages - 1;
	if (selectedDesktopImageIndex < 0)
		selectedDesktopImageIndex = 0;
	
	[self updateSelection];
}

- (void)select
{
	DesktopImage *desktopImage;
	
	desktopImage = [desktopImages objectAtIndex:selectedDesktopImageIndex];
	if (desktopImage == nil)
		return;
	/* if the user hits enter, open the image in the default app
	   (probably Preview) */
	[[NSWorkspace sharedWorkspace] openFile:[desktopImage path]];
}

/* catalog delegate methods. */

static int compareDesktopImages (id a, id b, void *ctx)
{
	Controller *self = ctx;
	return [a compareWithDesktopImage:b keys:self->sortKeys];
}

- (void)catalogDidChange:(Catalog *)cat
{
	id *values;
	DesktopImage *desktopImage;
	size_t i, count;
	CALayer *layer, *desktopImageLayer;
	CGRect r;
	
	[desktopImages release];
	desktopImages = [[catalog allDesktopImages] mutableCopy];
	count = [desktopImages count];
	
	values = malloc (count * sizeof (values[0]));
	if (values == NULL)
		return;
	
	[desktopImages sortUsingFunction:compareDesktopImages context:self];
	[desktopImages getObjects:values];
	
	for (i = 0; i < count; i++)
    {
		desktopImage = values[i];
		desktopImageLayer = [self layerForDesktopImage:desktopImage];
		
		if (desktopImageLayer == nil)
		{
			layer = [CALayer layer];
			desktopImageLayer = [CALayer layer];
			CFDictionarySetValue (layerDictionary, desktopImage, layer);
			
			[desktopImageLayer setDelegate:desktopImage];
			
			/* default appearance - will persist until image loads */
			r.origin = CGPointZero;
			r.size = desktopImageSize;
			[desktopImageLayer setBounds:r];
			[desktopImageLayer setBackgroundColor:[Controller color:C_GRAY]];
			desktopImageLayer.name = @"desktopImage";
			[layer setBounds:r];
			[layer setBackgroundColor:[Controller color:C_TRANSPARENT]];
			[layer setSublayers:[NSArray arrayWithObject:desktopImageLayer]];
			[layer setSublayerTransform:sublayerTransform];
			
			/* and the desktop image's reflection layer */
			CALayer *sublayer = [CALayer layer];
			r.origin = CGPointMake(0, -r.size.height);
			[sublayer setFrame:r];
			sublayer.name = @"reflection";
			CATransform3D transform = CATransform3DMakeScale(1,-1,1);
			sublayer.transform = transform;
			[sublayer setBackgroundColor:[Controller color:C_GRAY]];
			[desktopImageLayer addSublayer:sublayer];
			CALayer *gradientLayer = [CALayer layer];
			r.origin.y += r.size.height;
			// if the gradient rect is exactly the correct size,
			// antialiasing sometimes gives us a line of bright pixels
			// at the edges
			r.origin.x -= .5;
			r.size.height += 1;
			r.size.width += 1;
			[gradientLayer setFrame:r];
			[gradientLayer setContents:(id)shadowImage];
			[gradientLayer setOpaque:NO];
			[sublayer addSublayer:gradientLayer];
		}	 
		[desktopImageLayer setValue:[NSNumber numberWithInt:i] forKey:desktopImageIndex];
		values[i] = [desktopImageLayer superlayer];
    }
	
	totalDesktopImages = count;
	[bodyLayer setValue:[NSNumber numberWithInt:totalDesktopImages] forKey:desktopImageCount];
	
	[bodyLayer setSublayers:[NSArray arrayWithObjects:values count:count]];
	free (values);
	[desktopImageCountLayer setString:[NSString stringWithFormat:@"%d images", totalDesktopImages]];
	
	[self updateSelection];
}

- (void)imageDidLoadNotification:(NSNotification *)note
{
	DesktopImage *desktopImage;
	CALayer *layer;
	CGImageRef image;
	
	desktopImage = [note object];
	
	layer = [self layerForDesktopImage:desktopImage];
	
	if (layer != nil)
    {
		image = [desktopImage imageOfSize:[layer bounds].size];
		if (image != NULL)
		{
			// main image
			[layer setContents:(id)image];
			[layer setBackgroundColor:NULL];
			NSArray *sublayers = layer.sublayers;
			// reflection
			CALayer *sublayer = (CALayer *)[sublayers objectAtIndex:0];
			[sublayer setContents:(id)image];
			[sublayer setBackgroundColor:NULL];
			CGImageRelease (image);
		}
    }
}

/* NSWindow delegate methods. */

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[view window] setDelegate:nil];
	[self release];
}

- (IBAction)fullScreenAction:(id)sender
{
	if (![view isInFullScreenMode])
		[view enterFullScreenMode:[[view window] screen] withOptions:nil];
	else
		[view exitFullScreenModeWithOptions:nil];
}

@end
