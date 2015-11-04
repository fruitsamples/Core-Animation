/* CovertFlow - Catalog.m
 *
 * Abstract: The Catalog represents a collection of DeskopImages.
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

#import "Catalog.h"
#import "DesktopImage.h"

@implementation Catalog

- (id)init
{
	self = [super init];
	if (self == nil)
		return nil;
	
	mutableDict = [[NSMutableDictionary alloc] initWithCapacity:100];
	
	return self;
}

/* we obtain desktop images in a separate thread to keep the UI responsive */
-(void)beginProcessing
{
	threadRunning = true;
	[NSThread detachNewThreadSelector:@selector(threadFunc:) toTarget:[self retain] withObject:nil];
}

- (void)dealloc
{
	[desktopImageDict release];
	[desktopImageArray release];
	[super dealloc];
}

/* every once in a while we keep the main thread informed of our progress */
- (void)postDidChange
{
	@synchronized (self)
    {
		[desktopImageDict release];
		desktopImageDict = [mutableDict copy];
		
		if (delegate != nil && !pendingDidChange)
		{
			pendingDidChange = true;
			[self performSelectorOnMainThread:@selector(invokeDidChange:) withObject:nil waitUntilDone:NO];
		}
    }
}
/* inform the controller that the catalog is updated */
- (void)invokeDidChange:(id)arg
{
	@synchronized (self)
    {
		pendingDidChange = false;
    }
	if ([delegate respondsToSelector:@selector (catalogDidChange:)])
		[delegate catalogDidChange:self];
}

- (void)threadFunc:(id)arg
{
	NSAutoreleasePool *pool;
	NSString *path;
	NSMutableArray *pathArray;
	NSDictionary *prefsDictionary, *subDictionary;
	NSEnumerator *enumerator;
	int counter = 0;
	
	/* as we're not in the main thread, we need our own autorelease pool */
	pool = [[NSAutoreleasePool alloc] init];
	
	/* some place we are likely to find desktop images */
	pathArray = [NSMutableArray arrayWithObject:[[NSOpenStepRootDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Desktop Pictures"]];
	prefsDictionary = [NSDictionary dictionaryWithContentsOfFile:
	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] 
	stringByAppendingPathComponent:@"Preferences"] 
	stringByAppendingPathComponent:@"com.apple.desktop.plist"]];
	prefsDictionary = (NSDictionary *)[prefsDictionary objectForKey:@"Background"];
	enumerator = [prefsDictionary objectEnumerator];
	while (subDictionary = (NSDictionary *)[enumerator nextObject])
	{
		path = [subDictionary valueForKey:@"ChangePath"];
		if (![pathArray containsObject:path])
			[pathArray addObject:path];
	}
	
	enumerator = [pathArray objectEnumerator];
	while(path = (NSString *)[enumerator nextObject])
	{
		NSString *file;
		NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
		
		while (file = [dirEnum nextObject]) 
		{
			if (![NSBitmapImageRep canInitWithData:[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:file]]])
				continue;
			DesktopImage *a;
			NSString *keyString = [[file lastPathComponent] stringByDeletingPathExtension];
			a = [mutableDict objectForKey:keyString];
			if (a == nil)
			{
				a = [[DesktopImage alloc] initWithName:keyString];
				[a setPath:[path stringByAppendingPathComponent:file]];
				[mutableDict setObject:a forKey:keyString];
				[a release];
				if (++counter == 15)
				{
					counter = 0;
					[self postDidChange];
				}
			}
		}
	}
	@synchronized (self)
	{
		finishedLoading = true;
		[self postDidChange];
	}
	[pool release];
	threadRunning = false;
	[self release];
}

- (DesktopImage *)desktopImageForKey:(NSString *)name
{
	DesktopImage *ret = nil;
	
	if (desktopImageDict != nil)
    {
		if (threadRunning)
		{
			@synchronized (self)
			{
				ret = [desktopImageDict objectForKey:name];
			}
		}
		else
			ret = [desktopImageDict objectForKey:name];
    }
	
	return ret;
}

- (NSArray *)allDesktopImages
{
	NSArray *ret = nil;
	
	if (desktopImageArray != nil)
		return [[desktopImageArray retain] autorelease];
	
	if (desktopImageDict != nil)
    {
		if (threadRunning)
		{
			@synchronized (self)
			{
				ret = [desktopImageDict allValues];
			}
		}
		else
		{
			desktopImageArray = [[desktopImageDict allValues] retain];
			return [self allDesktopImages];
		}
    }
	
	return ret;
}

- (id)delegate {return delegate;}
- (void)setDelegate:(id)anObject {delegate = anObject;}

@end
