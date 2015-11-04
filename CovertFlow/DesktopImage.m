/* CovertFlow - DesktopImage.m
 *
 * Abstract: The DesktopImage object represents an individual desktop image.
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

#import "DesktopImage.h"

#import "Controller.h"

#import <pthread.h>
#import <QuartzCore/QuartzCore.h>

NSString *desktopImageImageDidLoadNotification = @"desktopImageImageDidLoadNotification";

@implementation DesktopImage

- (id)initWithName:(NSString *)n
{
	self = [super init];
	if (self == nil)
		return nil;
	
	name = [n copy];
	
	return self;
}

- (void)dealloc
{
	[name release];
	[path release];
	CGImageRelease (image);
	[super dealloc];
}

- (NSString *)name {return name;}

- (int)compareWithDesktopImage:(DesktopImage *)other keys:(const int *)keys
{
	int ret;
	
	if (other == nil)
		return 1;
	
	while (1)
    {
		switch (*keys++)
		{
		case kDesktopImageName:
			ret = [name caseInsensitiveCompare:other->name];
			break;
		case kDesktopImageNil:
			return 0;
		}
		
		if (ret != 0)
			return ret;
    }
}

-(void)setPath:(NSString *)p
{
	path = [p retain];
}

- (NSString *)path
{
	return path;
}

- (CGImageRef)imageOfSize:(CGSize)sz
{
	@synchronized (self)
    {
		if (image == NULL
			|| CGImageGetWidth (image) != sz.width 
		|| CGImageGetHeight (image) != sz.height)
		{
			return NULL;
		}
		
		return CGImageRetain (image);
    }
	return NULL;
}

static pthread_t thread;
static pthread_mutex_t imageMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t imageCond = PTHREAD_COND_INITIALIZER;
static NSMutableArray *imageQueue;

// asynchronously read images
static void *
imageThread (void *arg)
{
	while (1)
    {
		NSAutoreleasePool *pool;
		DesktopImage *desktopImage;
		CGImageRef image = NULL, scaledImage;
		bool done;
		
		pthread_mutex_lock (&imageMutex);
		
		while ([imageQueue count] == 0)
			pthread_cond_wait (&imageCond, &imageMutex);
		
		desktopImage = [[imageQueue objectAtIndex:0] retain];
		[imageQueue removeObjectAtIndex:0];
		
		pthread_mutex_unlock (&imageMutex);
		
		/* load in the next image */
		pool = [[NSAutoreleasePool alloc] init];
		NSString *path = [desktopImage path];
		NSURL * url = [NSURL fileURLWithPath: path];
		CGImageSourceRef isr = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
		if (!isr)
			image = NULL;
		else
		{
			image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
			CFRelease(isr);
		}
		done = false;
		while (!done)
		{
			CGContextRef ctx;
			CGColorSpaceRef space;
			CGRect r;
			CATextLayer *layer;
			CGImageAlphaInfo alpha;
			
			/* redraw the image the correct size */			
			@synchronized (desktopImage)
			{
				r.origin = CGPointZero;
				r.size = desktopImage->imageSize;
			}
			
			alpha = (image != NULL ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
			space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
			ctx = CGBitmapContextCreate(NULL, r.size.width,
										r.size.height, 8, 0, space,
										alpha | kCGBitmapByteOrder32Host);
			if (ctx == NULL)
				break;
			
			if (image != NULL)
			{
				CGContextSetInterpolationQuality (ctx, kCGInterpolationHigh);
				CGContextDrawImage (ctx, r, image);
			}
			else
			{
				/* We're on a thread without a runloop, so we can't rely on
				 the implicit transactions here. */
				
				[CATransaction begin];
				layer = [[CATextLayer alloc] init];
				[layer setFrame:r];
				[layer setString:
				[NSString stringWithFormat:@"%@", desktopImage->name]];
				[layer setCornerRadius:0.0];
				[layer setBackgroundColor:[Controller color:3/*C_GRAY*/]];
				[layer setFontSize:18];
				[layer setWrapped:YES];
				[layer renderInContext:ctx];
				[layer release];
				[CATransaction commit];
			}
			
			CGContextFlush (ctx);
			scaledImage = CGBitmapContextCreateImage(ctx);
			CGContextRelease (ctx);
			
			@synchronized (desktopImage)
			{
				if (CGSizeEqualToSize (r.size, desktopImage->imageSize))
				{
					CGImageRelease (desktopImage->image);
					desktopImage->image = scaledImage;
					desktopImage->requestedImage = false;
					done = true;
				}
				else
					CGImageRelease (scaledImage);
			}
		}
		
		if (image != NULL)
			CGImageRelease (image);
		
		/* let the controller know we've got a new image loaded */
		[desktopImage performSelectorOnMainThread:@selector (postNotificationName:)
		withObject:desktopImageImageDidLoadNotification waitUntilDone:NO];
		
		[desktopImage release];
		[pool release];
    }
	
	pthread_mutex_unlock (&imageMutex);
	
	thread = 0;
	return NULL;
}

- (void)postNotificationName:(NSString *)n
{
	[[NSNotificationCenter defaultCenter] postNotificationName:n object:self];
}

- (bool)requestImageOfSize:(CGSize)size;
{
	if (imageFailed)
		return false;
	
	@synchronized (self)
    {
		markedImage = true;
		
		if (image != nil && CGSizeEqualToSize (size, imageSize))
		{
			[self postNotificationName:desktopImageImageDidLoadNotification];
		}
		else
		{
			imageSize = size;
			
			if (!requestedImage)
			{
				pthread_mutex_lock (&imageMutex);
				
				if (imageQueue == nil)
					imageQueue = [[NSMutableArray alloc] init];
				
				if (thread == 0)
				{
					pthread_attr_t attr;
					
					pthread_attr_init (&attr);
					pthread_attr_setscope (&attr, PTHREAD_SCOPE_SYSTEM);
					pthread_attr_setdetachstate (&attr, PTHREAD_CREATE_DETACHED);
					pthread_create (&thread, &attr, imageThread, NULL);
					pthread_attr_destroy (&attr);
				}
				
				[imageQueue addObject:self];
				
				pthread_cond_signal (&imageCond);
				pthread_mutex_unlock (&imageMutex);
			}
		}
    }
	
	return true;
}

+ (void)sweepImageQueue
{
	size_t i, count;
	DesktopImage *desktopImage;
	
	if (imageQueue == nil)
		return;
	
	pthread_mutex_lock (&imageMutex);
	
	count = [imageQueue count];
	for (i = 0; i < count;)
    {
		desktopImage = [imageQueue objectAtIndex:i];
		if (!desktopImage->markedImage)
		{
			[imageQueue removeObjectAtIndex:i];
			count--;
		}
		else
			i++;
		desktopImage->markedImage = false;
    }
	
	pthread_mutex_unlock (&imageMutex);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<DesktopImage: %p; %@>", self, [self name]];
}

@end
