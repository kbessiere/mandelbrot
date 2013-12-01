//
//  MandelbrotView.m
//  Mandelbrot
//
//  Created by Kevin Bessiere on 11/30/13.
//  Copyright (c) 2013 Kevin. All rights reserved.
//

#import "MandelbrotView.h"

@interface MandelbrotView()
{
    unsigned int * buffer;
    CGRect _location;
    CGPoint _translate;
}

@end

@implementation MandelbrotView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

-(void)awakeFromNib
{
    [self addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)]];
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)]];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
    buffer = malloc(self.frame.size.width * self.frame.size.height * sizeof(unsigned int));
    _location.origin.x = -2.5;
    _location.origin.y = -2;
    _location.size.width = 3;
    _location.size.height = self.frame.size.height* 3 / self.frame.size.width;
    _translate = CGPointZero;
}


#pragma mark - PinchGesture
         
- (void)handlePinchGesture:(UIGestureRecognizer *)aGestureRegonizer
{
    UIPinchGestureRecognizer * pinchGesture = (UIPinchGestureRecognizer *)aGestureRegonizer;
    NSLog(@"scale %f", pinchGesture.scale);
    [self zoomWithScale:pinchGesture.scale atPoint:[pinchGesture locationInView:self]];
    [self setNeedsDisplay];
}

- (void)handlePanGesture:(UIGestureRecognizer *)aGestureRecognizer
{
    if (aGestureRecognizer.state != UIGestureRecognizerStateBegan)
        [self moveFrom:_translate toPoint:[aGestureRecognizer locationInView:self]];
    _translate = [aGestureRecognizer locationInView:self];
}

- (void)handleTapGesture:(UIGestureRecognizer *)aGestureRecognizer
{
    CGPoint point = [aGestureRecognizer locationInView:self];
    [self zoomWithScale:1.2 atPoint:point];
    [self setNeedsDisplay];
}

- (void)moveFrom:(CGPoint)origin toPoint:(CGPoint)translate
{
    CGSize sizeToTranslate = CGSizeMake((translate.x - origin.x) * _location.size.width / self.frame.size.width ,
                                  -(translate.y - origin.y) * _location.size.height / self.frame.size.height);
    _location.origin.x -= sizeToTranslate.width;
    _location.origin.y -= sizeToTranslate.height;
    [self setNeedsDisplay];
}

- (void)zoomWithScale:(CGFloat)scale atPoint:(CGPoint)originPoint
{
    CGRect zoomRect;
    zoomRect.size.height = _location.size.height / scale;
    zoomRect.size.width  = _location.size.width / scale;

    zoomRect.origin = _location.origin;
    CGPoint coordinateMandelbrot = CGPointMake(originPoint.x * _location.size.width / self.frame.size.width,
                                               originPoint.y * _location.size.height / self.frame.size.height);
    zoomRect.origin.x = _location.origin.x - coordinateMandelbrot.x - (zoomRect.size.width / 2);
    zoomRect.origin.y = _location.origin.y - (coordinateMandelbrot.y - (zoomRect.size.height / 2));
    _location = zoomRect;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    unsigned int width = self.frame.size.width;
    unsigned int height = self.frame.size.height;
    
    float dX = _location.size.width / width;
    float dY = _location.size.height / height;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_apply(height, queue, ^(size_t j) {
        for (int i = 0; i < width; i++)
        {
            float x = _location.origin.x + i * dX;
            float y = _location.origin.y + j * dY;
            float a = x;
            float b = y;
            int iteration = 0;
            while (a*a + b*b < 2*2 && iteration < 50)
            {
                float aa = a * a;
                float bb = b * b;
                float twoab = 2.0 * a * b;
                a = aa - bb + x;
                b = twoab + y;
                iteration = iteration + 1;
            }
            if (iteration == 50)
                buffer[i + j * (unsigned int)self.frame.size.width] = 0;
            else
                buffer[i + j * (unsigned int)self.frame.size.width] = iteration * 8;
        }
    });
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(
                                                       buffer,
                                                       self.frame.size.width,
                                                       self.frame.size.height,
                                                       8, // bitsPerComponent
                                                       4 * self.frame.size.width, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipLast);
    CFRelease(colorSpace);
    
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    
    CGSize viewSize = self.bounds.size;
    CGContextDrawImage(context, CGRectMake(0, 0, viewSize.width, viewSize.height), image);
    CGImageRelease(image);
}
         
@end
