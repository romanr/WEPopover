//
//  Common.h
//  EyeCandyFramework
//
//  Created by Juan Pedro Gonzalez Gutierrez on 16/01/12.
//  Copyright (c) 2012 JPG-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
void drawCurvedGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor, CGFloat radius);
CGRect rectFor1PxStroke(CGRect rect);
void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
void drawGlossAndGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor);
static inline double radians (double degrees) { return degrees * M_PI/180; }
CGMutablePathRef createArcPathFromBottomOfRect(CGRect rect, CGFloat arcHeight);
CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius);