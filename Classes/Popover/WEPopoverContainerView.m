//
//  WEPopoverContainerViewProperties.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverContainerView.h"
#import "WECommonDrawing.h"

@implementation WEPopoverContainerViewProperties

@synthesize bgImageName, upArrowImageName, downArrowImageName, leftArrowImageName, rightArrowImageName, topBgMargin, bottomBgMargin, leftBgMargin, rightBgMargin, topBgCapSize, leftBgCapSize;
@synthesize leftContentMargin, rightContentMargin, topContentMargin, bottomContentMargin, arrowMargin;

//  Up and down arrow are 18 x 13
#define kWEPopoverArrowWidth 18.0
#define kWEPopoverArrowHeight 13.0
#define kWEPopoverCornerRadius 8.0


- (void)dealloc {
	self.bgImageName = nil;
	self.upArrowImageName = nil;
	self.downArrowImageName = nil;
	self.leftArrowImageName = nil;
	self.rightArrowImageName = nil;
	[super dealloc];
}

@end

@interface WEPopoverContainerView(Private)

- (void)determineGeometryForSize:(CGSize)theSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;
- (CGRect)contentRect;
- (CGSize)contentSize;
- (void)setProperties:(WEPopoverContainerViewProperties *)props;
- (void)initFrame;

@end

@implementation WEPopoverContainerView

@synthesize arrowDirection, contentView;

- (id)initWithSize:(CGSize)theSize 
		anchorRect:(CGRect)anchorRect 
	   displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
		properties:(WEPopoverContainerViewProperties *)theProperties {
	if ((self = [super initWithFrame:CGRectZero])) {
		
		[self setProperties:theProperties];
		correctedSize = CGSizeMake(theSize.width + properties.leftBgMargin + properties.rightBgMargin + properties.leftContentMargin + properties.rightContentMargin, 
								   theSize.height + properties.topBgMargin + properties.bottomBgMargin + properties.topContentMargin + properties.bottomContentMargin);	
		[self determineGeometryForSize:correctedSize anchorRect:anchorRect displayArea:displayArea permittedArrowDirections:permittedArrowDirections];
		[self initFrame];
		self.backgroundColor = [UIColor clearColor];
		
		self.clipsToBounds = YES;
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (void)dealloc {
	[properties release];
	[contentView release];
    CGPathRelease(self->outerPath);
	[super dealloc];
}

- (void)drawRect:(CGRect)rect {
    // Define colors
    UIColor *outerTop = [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:0.95];
    UIColor *outerBottom = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.95];
    UIColor *blackColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    UIColor *highlightStart = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    UIColor *highlightStop = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    //CGFloat outerMargin = 7.5f;
    CGFloat outerMargin = 0.5;
    CGRect outerRect = CGRectInset(self->bodyRect, outerMargin, outerMargin);
    
    // create graphics context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    // Draw gradient for outer path
    CGContextSaveGState(context);
	CGContextAddPath(context, self->outerPath);
	CGContextClip(context);
	drawLinearGradient(context, rect, outerTop.CGColor, outerBottom.CGColor);    
	CGContextRestoreGState(context);
    
    // Inner
   
    if (!CGRectEqualToRect(self->bodyRect, CGRectZero)) {
        CGRect highlightRect = CGRectInset(outerRect, 1.0f, 1.0f);
        CGMutablePathRef highlightPath = createRoundedRectForRect(highlightRect, 6.0);
        
        CGContextSaveGState(context);
        CGContextAddPath(context, outerPath);
        CGContextAddPath(context, highlightPath);
        CGContextEOClip(context);
        
        drawLinearGradient(context, CGRectMake(outerRect.origin.x, outerRect.origin.y, outerRect.size.width, outerRect.size.height/3), highlightStart.CGColor, highlightStop.CGColor);
        CGContextRestoreGState(context);
        
        drawCurvedGradient(context, outerRect, highlightStart.CGColor, highlightStop.CGColor, 180);
        CFRelease(highlightPath);  
    }
    
    
    // Stroke outer path
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, blackColor.CGColor);
    CGContextAddPath(context, outerPath);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // End context
    CGContextFlush(context);
    //CGContextRelease(context);
}

- (void)updatePositionWithAnchorRect:(CGRect)anchorRect 
						 displayArea:(CGRect)displayArea
			permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections {
	[self determineGeometryForSize:correctedSize anchorRect:anchorRect displayArea:displayArea permittedArrowDirections:permittedArrowDirections];
	[self initFrame];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	return CGRectContainsPoint(self.contentRect, point);	
} 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)setContentView:(UIView *)v {
	if (v != contentView) {
		[contentView release];
		contentView = [v retain];		
		contentView.frame = self.contentRect;		
		[self addSubview:contentView];
	}
}



@end

@implementation WEPopoverContainerView(Private)

- (void)initFrame {
	CGRect theFrame = CGRectOffset(CGRectUnion(bgRect, arrowRect), offset.x, offset.y);
	
	//If arrow rect origin is < 0 the frame above is extended to include it so we should offset the other rects
	arrowOffset = CGPointMake(MAX(0, -arrowRect.origin.x), MAX(0, -arrowRect.origin.y));
	bgRect = CGRectOffset(bgRect, arrowOffset.x, arrowOffset.y);
	arrowRect = CGRectOffset(arrowRect, arrowOffset.x, arrowOffset.y);

    /// Create the path
    CGMutablePathRef outPath = CGPathCreateMutable();
    
    switch (arrowDirection) {
		case UIPopoverArrowDirectionUp:
            self->bodyRect = CGRectMake(0.0, self->arrowRect.origin.y + self->arrowRect.size.height, theFrame.size.width, theFrame.size.height - (self->arrowRect.origin.y + self->arrowRect.size.height));
            
			CGPathMoveToPoint(outPath, nil, arrowRect.origin.x, arrowRect.origin.y + arrowRect.size.height);
            CGPathAddLineToPoint(outPath, nil, arrowRect.origin.x + (arrowRect.size.width / 2.0), arrowRect.origin.y);
            CGPathAddLineToPoint(outPath, nil, arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height);
            
            // Top-Right arc
            CGPathAddArc(outPath, nil, theFrame.size.width - kWEPopoverCornerRadius, arrowRect.origin.y + arrowRect.size.height + kWEPopoverCornerRadius, kWEPopoverCornerRadius, 3.0f*M_PI/2.0f, 0.0, 0.0);
            // Bottom-Right arc
            CGPathAddArc(outPath, nil, theFrame.size.width - kWEPopoverCornerRadius, CGRectGetMaxY(self->bgRect) - kWEPopoverCornerRadius, kWEPopoverCornerRadius, 0.0f, M_PI/2.0f, 0);
            // Bottom-Left arc
            CGPathAddArc(outPath, nil, CGRectGetMinX(self->bgRect) + kWEPopoverCornerRadius, CGRectGetMaxY(self->bgRect) - kWEPopoverCornerRadius, kWEPopoverCornerRadius, M_PI/2.0f, M_PI, 0);
            // Top-Left arc
            CGPathAddArc(outPath, nil, CGRectGetMinX(self->bgRect) + kWEPopoverCornerRadius, arrowRect.origin.y + arrowRect.size.height + kWEPopoverCornerRadius, kWEPopoverCornerRadius, M_PI, 3.0f*M_PI/2.0f, 0);
			break;
		case UIPopoverArrowDirectionDown:
            self->bodyRect = CGRectMake(0.0, 0.0, theFrame.size.width, self->arrowRect.origin.y);
            
			CGPathMoveToPoint(outPath, nil, CGRectGetMinX(self->bgRect) + kWEPopoverCornerRadius, CGRectGetMinY(self->bgRect));
            
            // Top-Right arc
            CGPathAddArc(outPath, nil, theFrame.size.width - kWEPopoverCornerRadius, CGRectGetMinY(self->bgRect) + kWEPopoverCornerRadius, kWEPopoverCornerRadius, 3.0f*M_PI/2.0f, 0.0, 0.0);
            // Bottom-Right arc
            CGPathAddArc(outPath, nil, theFrame.size.width - kWEPopoverCornerRadius, CGRectGetMaxY(self->bgRect) - (kWEPopoverCornerRadius + arrowRect.size.height), kWEPopoverCornerRadius, 0.0f, M_PI/2.0f, 0);
            
            // Draw arrow
            CGPathAddLineToPoint(outPath, nil, arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y);
            CGPathAddLineToPoint(outPath, nil, arrowRect.origin.x + (arrowRect.size.width /2.0), arrowRect.origin.y + arrowRect.size.height);
            CGPathAddLineToPoint(outPath, nil, arrowRect.origin.x, arrowRect.origin.y);
            
            // Bottom-Left arc
            CGPathAddArc(outPath, nil, CGRectGetMinX(self->bgRect) + kWEPopoverCornerRadius, CGRectGetMaxY(self->bgRect) - (kWEPopoverCornerRadius + arrowRect.size.height), kWEPopoverCornerRadius, M_PI/2.0f, M_PI, 0);
            // Top-Left arc
            CGPathAddArc(outPath, nil, CGRectGetMinX(self->bgRect) + kWEPopoverCornerRadius, CGRectGetMinY(self->bgRect) + kWEPopoverCornerRadius, kWEPopoverCornerRadius, M_PI, 3.0f*M_PI/2.0f, 0);
            
			break;
		case UIPopoverArrowDirectionLeft:
			//arrowImage = [leftArrowImage retain];
			break;
		case UIPopoverArrowDirectionRight:
			//arrowImage = [rightArrowImage retain];
			break;
	}
    
    // close the path
    CGPathCloseSubpath(outPath);
    
    // Create the outer path
    if (!self->outerPath) {
        CGPathRelease(self->outerPath);
    }
    self->outerPath = CGPathRetain(outPath);
    CGPathRelease(outPath);
    /// Path end
	
	self.frame = theFrame;	
}																		 

- (CGSize)contentSize {
	return self.contentRect.size;
}

- (CGRect)contentRect {
	CGRect rect = CGRectMake(properties.leftBgMargin + properties.leftContentMargin + arrowOffset.x, 
							 properties.topBgMargin + properties.topContentMargin + arrowOffset.y, 
							 bgRect.size.width - properties.leftBgMargin - properties.rightBgMargin - properties.leftContentMargin - properties.rightContentMargin,
							 bgRect.size.height - properties.topBgMargin - properties.bottomBgMargin - properties.topContentMargin - properties.bottomContentMargin);
	return rect;
}

- (void)setProperties:(WEPopoverContainerViewProperties *)props {
	if (properties != props) {
		[properties release];
		properties = [props retain];
	}
}

- (void)determineGeometryForSize:(CGSize)theSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)supportedArrowDirections {	
	
	//Determine the frame, it should not go outside the display area
	UIPopoverArrowDirection theArrowDirection = UIPopoverArrowDirectionUp;
	
	offset =  CGPointZero;
	bgRect = CGRectZero;
	arrowRect = CGRectZero;
	arrowDirection = UIPopoverArrowDirectionUnknown;
    bodyRect = CGRectZero;
	
	CGFloat biggestSurface = 0.0f;
	CGFloat currentMinMargin = 0.0f;
	
	
	while (theArrowDirection <= UIPopoverArrowDirectionRight) {
		
		if ((supportedArrowDirections & theArrowDirection)) {
			
			CGRect theBgRect = CGRectZero;
			CGRect theArrowRect = CGRectZero;
			CGPoint theOffset = CGPointZero;
			CGFloat xArrowOffset = 0.0;
			CGFloat yArrowOffset = 0.0;
			CGPoint anchorPoint = CGPointZero;
			
			switch (theArrowDirection) {
				case UIPopoverArrowDirectionUp:
					
					anchorPoint = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMaxY(anchorRect));
					
					xArrowOffset = theSize.width / 2 - kWEPopoverArrowWidth / 2;
					yArrowOffset = properties.topBgMargin - kWEPopoverArrowHeight;
					
					theOffset = CGPointMake(anchorPoint.x - xArrowOffset - kWEPopoverArrowWidth / 2, anchorPoint.y  - yArrowOffset);
					theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
					
					if (theOffset.x < 0) {
						xArrowOffset += theOffset.x;
						theOffset.x = 0;
					} else if (theOffset.x + theSize.width > displayArea.size.width) {
						xArrowOffset += (theOffset.x + theSize.width - displayArea.size.width);
						theOffset.x = displayArea.size.width - theSize.width;
					}
					
					//Cap the arrow offset
					xArrowOffset = MAX(xArrowOffset, properties.leftBgMargin + properties.arrowMargin);
					xArrowOffset = MIN(xArrowOffset, theSize.width - properties.rightBgMargin - properties.arrowMargin - kWEPopoverArrowWidth);
					
					theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, kWEPopoverArrowWidth, kWEPopoverArrowHeight);
					
					break;
				case UIPopoverArrowDirectionDown:
					
					anchorPoint = CGPointMake(CGRectGetMidX(anchorRect), CGRectGetMinY(anchorRect));
					
					xArrowOffset = theSize.width / 2 - kWEPopoverArrowWidth / 2;
					yArrowOffset = theSize.height - properties.bottomBgMargin;
					
					theOffset = CGPointMake(anchorPoint.x - xArrowOffset - kWEPopoverArrowWidth / 2, anchorPoint.y - yArrowOffset - kWEPopoverArrowHeight);
					theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
					
					if (theOffset.x < 0) {
						xArrowOffset += theOffset.x;
						theOffset.x = 0;
					} else if (theOffset.x + theSize.width > displayArea.size.width) {
						xArrowOffset += (theOffset.x + theSize.width - displayArea.size.width);
						theOffset.x = displayArea.size.width - theSize.width;
					}
					
					//Cap the arrow offset
					xArrowOffset = MAX(xArrowOffset, properties.leftBgMargin + properties.arrowMargin);
					xArrowOffset = MIN(xArrowOffset, theSize.width - properties.rightBgMargin - properties.arrowMargin - kWEPopoverArrowWidth);
					
					theArrowRect = CGRectMake(xArrowOffset , yArrowOffset, kWEPopoverArrowWidth, kWEPopoverArrowHeight);
					
					break;
				case UIPopoverArrowDirectionLeft:
					// Constants are reversed (height = width AND width = height)
					anchorPoint = CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMidY(anchorRect));
					
					xArrowOffset = properties.leftBgMargin - kWEPopoverArrowHeight;
					yArrowOffset = theSize.height / 2  - kWEPopoverArrowWidth / 2;
					
					theOffset = CGPointMake(anchorPoint.x - xArrowOffset, anchorPoint.y - yArrowOffset - kWEPopoverArrowWidth / 2);
					theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
					
					if (theOffset.y < 0) {
						yArrowOffset += theOffset.y;
						theOffset.y = 0;
					} else if (theOffset.y + theSize.height > displayArea.size.height) {
						yArrowOffset += (theOffset.y + theSize.height - displayArea.size.height);
						theOffset.y = displayArea.size.height - theSize.height;
					}
					
					//Cap the arrow offset
					yArrowOffset = MAX(yArrowOffset, properties.topBgMargin + properties.arrowMargin);
					yArrowOffset = MIN(yArrowOffset, theSize.height - properties.bottomBgMargin - properties.arrowMargin - kWEPopoverArrowWidth);
					
					theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, kWEPopoverArrowHeight, kWEPopoverArrowWidth);
					
					break;
				case UIPopoverArrowDirectionRight:
					
					anchorPoint = CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMidY(anchorRect));
					
					xArrowOffset = theSize.width - properties.rightBgMargin;
					yArrowOffset = theSize.height / 2  - kWEPopoverArrowHeight / 2;
					
					theOffset = CGPointMake(anchorPoint.x - xArrowOffset - kWEPopoverArrowHeight, anchorPoint.y - yArrowOffset - kWEPopoverArrowWidth / 2);
					theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
					
					if (theOffset.y < 0) {
						yArrowOffset += theOffset.y;
						theOffset.y = 0;
					} else if (theOffset.y + theSize.height > displayArea.size.height) {
						yArrowOffset += (theOffset.y + theSize.height - displayArea.size.height);
						theOffset.y = displayArea.size.height - theSize.height;
					}
					
					//Cap the arrow offset
					yArrowOffset = MAX(yArrowOffset, properties.topBgMargin + properties.arrowMargin);
					yArrowOffset = MIN(yArrowOffset, theSize.height - properties.bottomBgMargin - properties.arrowMargin - kWEPopoverArrowWidth);
					
					theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, kWEPopoverArrowHeight, kWEPopoverArrowWidth);
					
					break;
			}
			
			CGRect bgFrame = CGRectOffset(theBgRect, theOffset.x, theOffset.y);
			
			CGFloat minMarginLeft = CGRectGetMinX(bgFrame) - CGRectGetMinX(displayArea);
			CGFloat minMarginRight = CGRectGetMaxX(displayArea) - CGRectGetMaxX(bgFrame); 
			CGFloat minMarginTop = CGRectGetMinY(bgFrame) - CGRectGetMinY(displayArea); 
			CGFloat minMarginBottom = CGRectGetMaxY(displayArea) - CGRectGetMaxY(bgFrame); 
			
			if (minMarginLeft < 0) {
			    // Popover is too wide and clipped on the left; decrease width
			    // and move it to the right
			    theOffset.x -= minMarginLeft;
			    theBgRect.size.width += minMarginLeft;
			    minMarginLeft = 0;
			    if (theArrowDirection == UIPopoverArrowDirectionRight) {
			        theArrowRect.origin.x = CGRectGetMaxX(theBgRect) - properties.rightBgMargin;
			    }
			}
			if (minMarginRight < 0) {
			    // Popover is too wide and clipped on the right; decrease width.
			    theBgRect.size.width += minMarginRight;
			    minMarginRight = 0;
			    if (theArrowDirection == UIPopoverArrowDirectionLeft) {
			        theArrowRect.origin.x = CGRectGetMinX(theBgRect) - kWEPopoverArrowHeight + properties.leftBgMargin;
			    }
			}
			if (minMarginTop < 0) {
			    // Popover is too high and clipped at the top; decrease height
			    // and move it down
			    theOffset.y -= minMarginTop;
			    theBgRect.size.height += minMarginTop;
			    minMarginTop = 0;
			    if (theArrowDirection == UIPopoverArrowDirectionDown) {
			        theArrowRect.origin.y = CGRectGetMaxY(theBgRect) - properties.bottomBgMargin;
			    }
			}
			if (minMarginBottom < 0) {
			    // Popover is too high and clipped at the bottom; decrease height.
			    theBgRect.size.height += minMarginBottom;
			    minMarginBottom = 0;
			    if (theArrowDirection == UIPopoverArrowDirectionUp) {
			        theArrowRect.origin.y = CGRectGetMinY(theBgRect) - kWEPopoverArrowHeight + properties.topBgMargin;
			    }
			}
			bgFrame = CGRectOffset(theBgRect, theOffset.x, theOffset.y);
            
			CGFloat minMargin = MIN(minMarginLeft, minMarginRight);
			minMargin = MIN(minMargin, minMarginTop);
			minMargin = MIN(minMargin, minMarginBottom);
			
			// Calculate intersection and surface
			CGRect intersection = CGRectIntersection(displayArea, bgFrame);
			CGFloat surface = intersection.size.width * intersection.size.height;
			
			if (surface >= biggestSurface && minMargin >= currentMinMargin) {
				biggestSurface = surface;
				offset = theOffset;
				arrowRect = theArrowRect;
				bgRect = theBgRect;
				arrowDirection = theArrowDirection;
				currentMinMargin = minMargin;
			}
		}
		
		theArrowDirection <<= 1;
	}
}

@end