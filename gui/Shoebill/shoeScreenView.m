/*
 * Copyright (c) 2014, Peter Rutenbar <pruten@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "shoeScreenView.h"
#import "shoeScreenWindow.h"
#import "shoeAppDelegate.h"
#import "shoeApplication.h"
#import <Foundation/Foundation.h>

@implementation shoeScreenView


- (void)initCommon
{
    shoeApp = (shoeApplication*) NSApp;
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self initCommon];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        [self initCommon];
    return self;
}

- (void) awakeFromNib
{
    colorspace = CGColorSpaceCreateDeviceRGB();
    
    timer = [NSTimer
             scheduledTimerWithTimeInterval:(1.0/60.0)
             target:self
             selector:@selector(timerFireMethod:)
             userInfo:nil
             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer
                                 forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer
                                 forMode:NSEventTrackingRunLoopMode];
    
    [[self window] setTitle:[NSString stringWithFormat:@"Shoebill"]];
    [[self window] makeKeyAndOrderFront:nil];
}

- (void)timerFireMethod:(NSTimer *)timer
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    const uint8_t slotnum = ((shoeScreenWindowController*)[[self window] windowController])->slotnum;
    
    if (shoeApp->isRunning) {
        shoebill_video_frame_info_t frame = shoebill_get_video_frame(slotnum, 0);
        
        CGContextRef bitmapContext = CGBitmapContextCreate(
               (void*)frame.buf,
               frame.width,
               frame.height,
               8UL /* Bits per channel */,
               4UL * frame.width /* Bytes per row */,
               colorspace,
               kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast
               );
        
        CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
        CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        
        CGContextDrawImage(
                           context,
                           self.frame, cgImage
                           );
        
        shoebill_send_vbl_interrupt(slotnum);
        
        CGContextRelease(bitmapContext);
    }
}

- (void)viewDidMoveToWindow
{
    [[self window] setAcceptsMouseMovedEvents:YES];
    [[self window] makeFirstResponder:self];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [[self window] setAcceptsMouseMovedEvents:YES];
    [[self window] makeFirstResponder:self];
}


- (void)mouseMoved:(NSEvent *)theEvent
{
    if (shoeApp->doCaptureMouse) {
        shoeScreenWindow *win = (shoeScreenWindow*)[self window];
        
        assert(shoeApp->isRunning);
        
        int32_t delta_x, delta_y;
        CGGetLastMouseDelta(&delta_x, &delta_y);
        shoebill_mouse_move_delta(delta_x, delta_y);
        [win warpToCenter];
    }
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [self mouseMoved:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    
    if (shoeApp->doCaptureMouse) {
        assert(shoeApp->isRunning);
        
        // ctrl - left click doesn't get reported as rightMouseDown
        // on Mavericks (and maybe other OS X versions?)
        if ([theEvent modifierFlags] & NSControlKeyMask) {
            shoeScreenWindow *win = (shoeScreenWindow*)[self window];
            [win uncaptureMouse];
        }
        else
            shoebill_mouse_click(1);
        
    }
    else {
        shoeScreenWindow *win = (shoeScreenWindow*)[self window];
        if ([win isKeyWindow]) {
            shoeApp->doCaptureKeys = YES;
            [win captureMouse];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (shoeApp->doCaptureMouse) {
        assert(shoeApp->isRunning);
        shoebill_mouse_click(0);
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (shoeApp->doCaptureMouse) {
        shoeScreenWindow *win = (shoeScreenWindow*)[self window];
        [win uncaptureMouse];
    }
}

/*
 * Ignore keyDown/Up events here.
 * shoeApplication captures and sends them down to the emulator.
 * We need to implement these methods though, because if they make it all
 * the way down to NSOpenGLView, they'll generate a beep, which is annoying.
 */
- (void) keyDown:(NSEvent *)theEvent
{
}
- (void) keyUp:(NSEvent *)theEvent
{
}

@end
