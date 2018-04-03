//
//  TextView.m
//  Magazin
//
//  Created by 郭一博 on 13-5-28.
//  Copyright (c) 2013年 郭一博. All rights reserved.
//

#import "TextView.h"
#import <CoreText/CoreText.h>
#import "AHMarkedHyperlink.h"
#import "Utility.h"
#import "Config.h"

@implementation TextView

@synthesize links,rectArray,delegate,fontSize,lineSpaceSize,liveCode;

-(void)dealloc
{
    self.images= nil;
    self.links = nil;
    self.rectArray = nil;
    self.delegate = nil;
    self.liveCode = nil;
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.images = [[NSMutableArray alloc] initWithCapacity:0];
        self.rectArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

-(void)setCTFrame:(id)f
{
    ctFrame = f;
}




-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //path
    CGMutablePathRef path = CGPathCreateMutable(); //2
    CGPathAddRect(path, NULL, self.frame);
    
    
    //绘制点击方框
    if (_touchedLink)
    {
        NSArray *lines = (NSArray *)CTFrameGetLines((CTFrameRef)ctFrame);
        
        for (int i = 0; i < lines.count; i++)
        {
            CTLineRef line = (CTLineRef)[lines objectAtIndex:i];
			NSArray *runs = (NSArray *)CTLineGetGlyphRuns(line);
            
            for (int j = 0; j < runs.count; j++)
			{
                CTRunRef run = (CTRunRef)[runs objectAtIndex:j];
				
				CFRange runRange = CTRunGetStringRange(run);
                
                if ((((runRange.location >= [_touchedLink range].location) && (runRange.location < [_touchedLink range].location + [_touchedLink range].length)) &&
					 ((runRange.location + runRange.length) <= ([_touchedLink range].location + [_touchedLink range].length))))
                {
                    CGRect runBounds = CGRectZero;
					
					CGFloat ascent, descent, leading;
					CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
					runBounds.size.width = width;
					runBounds.size.height = ascent + fabs(descent) + leading;
                    
                    const CGPoint *positions = CTRunGetPositionsPtr(run);
					
					// get the origins of the lines
					CGPoint lineOrigins[lines.count];
					CTFrameGetLineOrigins((CTFrameRef)ctFrame, CFRangeMake(0, 0), lineOrigins);
					
					//CGRect rect = CGPathGetBoundingBox(path);
					CGPoint origin = lineOrigins[i];
					
					// set the x position for the glyph run
					runBounds.origin.x += positions[0].x;
					runBounds.origin.x += origin.x;
					runBounds.origin.x += 0;
                    runBounds.size.height = fontSize + lineSpaceSize;
                    
                    
                    CGFloat y = rect.origin.y + rect.size.height - origin.y;
					runBounds.origin.y += y - (fontSize / 1.3);
					
					// adjust the rect to be slightly bigger than the text
//					runBounds.origin.x -= 17 / 4;
//					runBounds.size.width += 17 / 2;
//					runBounds.origin.y -= 17 / 8;                // this is more favourable
//					runBounds.size.height += 17 / 4;
                    
                    //CGRect rectS = CGRectMake(51, 0, 13.6, 21);
                    
                    CGRect lastRect = CGRectFromString([rectArray lastObject]);
                    CGPoint lastPoint = CGPointMake(lastRect.origin.x+lastRect.size.width,lastRect.origin.y);
                    
                   // NSLog(@"%f",lastPoint.y);
                   // NSLog(@"%f",runBounds.origin.y);
                    
                    NSString *pointStrX1 = [NSString stringWithFormat:@"%f",lastPoint.x];
                    NSString *pointStrX2 = [NSString stringWithFormat:@"%f",runBounds.origin.x];
                    
//                    NSString *pointStrY1 = [NSString stringWithFormat:@"%f",lastPoint.y];
//                    NSString *pointStrY2 = [NSString stringWithFormat:@"%f",runBounds.origin.y];
                    
                
                    int cha = fabsf([pointStrX2 floatValue] - [pointStrX1 floatValue]);
                    //cgfloat放入比较有问题
                    if ( cha <= 2.0f ) //&& [pointStrY1 isEqualToString:pointStrY2])
                    {
                        runBounds.origin = CGPointMake(lastRect.origin.x, runBounds.origin.y);//lastRect.origin;
                        runBounds.size = CGSizeMake(lastRect.size.width+runBounds.size.width, runBounds.size.height);
                    }
                   
                    [rectArray addObject:NSStringFromCGRect(runBounds)];
//                    NSLog(@"这一个:%f",runBounds.origin.x);
//                    NSLog(@"上一个:%f",runBounds.origin.x + runBounds.size.width);
                    

                    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:167.0/255.0 green:167.0/255.0 blue:167.0/255.0 alpha:1.0] CGColor]);
					
                    //NSLog(@"1~~~~~~~~~:%f 2~~~~~~~~~~~~:%f 3~~~~~~~~~~~:%f",runBounds.origin.x,runBounds.size.width,runBounds.origin.y);
                    CGPathRef highlightPath = [self newPathForRoundedRect:runBounds radius:0];//(runBounds.size.height / 6)];
                    //CGPathRef highlightPath = [self newPathForRoundedRect:runBounds radius:(runBounds.size.height / 8)];
					CGContextAddPath(context, highlightPath);
					CGContextFillPath(context);
					CGPathRelease(highlightPath);
                }
            }
        }
    }
    
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.frame.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFrameDraw((CTFrameRef)ctFrame, context);
    
       
    for (NSArray* imageData in self.images)
    {
        if ([[imageData objectAtIndex:2] isEqual:IMG_EMOJI])
        {
            UIImage* img = [UIImage imageNamed:[imageData objectAtIndex:0]];
            CGRect imgBounds = CGRectFromString([imageData objectAtIndex:1]);
            CGContextDrawImage(context, imgBounds, img.CGImage);
        }
        else
            if ([[imageData objectAtIndex:2] isEqual:BTN_LOCATION])
            {
                CGRect imgBounds = CGRectFromString([imageData objectAtIndex:1]);
            
                CGRect mirrorBounds = CGRectMake(imgBounds.origin.x, self.bounds.size.height-imgBounds.origin.y-imgBounds.size.height, imgBounds.size.width, imgBounds.size.height+4);
                
                CGSize titleSize;
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] isEqual:@"0"] || ![[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] || [[[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] isEqual:@"1"])
                {
                    titleSize = [[imageData objectAtIndex:3] sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(kMaxTextWidth, 16) lineBreakMode:NSLineBreakByWordWrapping];
                }
                else
                {
                    titleSize = [[imageData objectAtIndex:3] sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(kMaxTextWidthOfTextMode, 16) lineBreakMode:NSLineBreakByWordWrapping];
                }
                
                CGRect btnFrame;
                if (titleSize.width > 120)
                {
                   // btnFrame = CGRectMake(mirrorBounds.origin.x, mirrorBounds.origin.y, 80 + 23 + 5, imgBounds.size.height+4);
                    btnFrame = CGRectMake(mirrorBounds.origin.x+3, mirrorBounds.origin.y, 120 + 23 + 5, 20);
                }
                else
                {
                   // btnFrame = CGRectMake(mirrorBounds.origin.x, mirrorBounds.origin.y, titleSize.width  + 23 + 5, imgBounds.size.height+4);
                    btnFrame = CGRectMake(mirrorBounds.origin.x+3, mirrorBounds.origin.y, titleSize.width  + 23 + 5, 20);
                }
                
                
                UIImage *image = [UIImage imageNamed:@"Location.png"];
                
                if (!locationBtn)
                {
                    //在这里进行特殊化处理,如果是按钮,则显示按钮,否则绘制图片
                    locationBtn = [LocationBtn buttonWithType:UIButtonTypeCustom];
                }
                locationBtn.frame = btnFrame;
                locationBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                [locationBtn setBackgroundImage:[image stretchableImageWithLeftCapWidth:20 topCapHeight:0] forState:UIControlStateNormal];
                locationBtn.contentEdgeInsets = UIEdgeInsetsMake(5, 18, 4, 5);
                // btn.titleLabel.backgroundColor = [UIColor blueColor];
                [locationBtn setTitleColor:[UIColor colorWithRed:94/255.0 green:128/255.0 blue:176.0/255.0 alpha:1] forState:UIControlStateNormal];
                
                locationBtn.titleLabel.font = [UIFont systemFontOfSize:12];
                [locationBtn setTitle:[imageData objectAtIndex:3] forState:UIControlStateNormal];
                locationBtn.longitude = [[imageData objectAtIndex:4] floatValue];
                locationBtn.latitude = [[imageData objectAtIndex:5] floatValue];
                [locationBtn addTarget:self action:@selector(locationBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:locationBtn];
            }
            else
            {
                NSLog(@"没有任何标签");
            }
    }
    
    CFRelease(path);
}

-(void)locationBtnPressed:(id)sender
{
    LocationBtn *btn = (LocationBtn *)sender;
    //NSLog(@"点击的位置是:经度%f  纬度:%f",btn.longitude,btn.latitude);
    
    [delegate clickPostionBtn:btn.longitude latitude:btn.latitude];
}


- (CGPathRef)newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
	CGMutablePathRef retPath = CGPathCreateMutable();
	
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    if (!CGRectIsEmpty(innerRect))
    {
        //innerRect = CGRectZero;
        
       // return CGRectZero;
    }
    
	
	
	CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
	CGFloat outside_right = rect.origin.x + rect.size.width;
	CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
	CGFloat outside_bottom = rect.origin.y + rect.size.height;
	
	CGFloat inside_top = innerRect.origin.y;
	CGFloat outside_top = rect.origin.y;
	CGFloat outside_left = rect.origin.x;
	
	CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
	
	CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
	CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
	
	CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
	
	CGPathCloseSubpath(retPath);
	
	return retPath;
}


#pragma mark -
#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //[super touchesBegan:touches withEvent:event];
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	//_linkLocation = location;
	
	location.y += fontSize/1.3;//(self.fontSize / yAdjustmentFactor);
	location.x -= 0;
	
	CFArrayRef lines = CTFrameGetLines((CTFrameRef)ctFrame);
	
	CGPoint origins[CFArrayGetCount(lines)];
	CTFrameGetLineOrigins((CTFrameRef)ctFrame, CFRangeMake(0, 0), origins);
	
	CTLineRef line = NULL;
	CGPoint lineOrigin = CGPointZero;
	for (int i= 0; i < CFArrayGetCount(lines); i++)
	{
		CGPoint origin = origins[i];
		CGPathRef path = CTFrameGetPath((CTFrameRef)ctFrame);
		CGRect rect = CGPathGetBoundingBox(path);
		
		CGFloat y = rect.origin.y + rect.size.height - origin.y;
        
		if ((location.y >= y) && (location.x >= origin.x))
		{
			line = CFArrayGetValueAtIndex(lines, i);
			lineOrigin = origin;
		}
	}
	
	location.x -= lineOrigin.x;
	CFIndex index = CTLineGetStringIndexForPosition(line, location);
	
//    NSLog(@"~~~~~~~%f",location.x);
//    NSLog(@"~~~~~~~%f",CTLineGetTypographicBounds(line, NULL, NULL, NULL));
    
    if (kCFNotFound == index)
    {
        //NSLog(@"没在范围内");
        [super touchesBegan:touches withEvent:event];
        return;
    }

    
    //如果点击的位置不在范围内
    if (location.x > self.frame.size.width || location.x > CTLineGetTypographicBounds(line, NULL, NULL, NULL))//CTLineGetTypographicBounds(line).size.width)
    {
        index++;
    }
    
	for (AHMarkedHyperlink *link in links)
	{
		if (((index >= [link range].location) && (index <= ([link range].length + [link range].location))))
		{
			_touchedLink = link;
			[self setNeedsDisplay];
		}
	}
    
    if(_touchedLink == nil)
    {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
//	location.y += (self.fontSize / yAdjustmentFactor);
//	location.x -= self.paddingLeft;
    location.y += fontSize/1.3;//(self.fontSize / yAdjustmentFactor);
	location.x -= 0;
	
	CFArrayRef lines = CTFrameGetLines((CTFrameRef)ctFrame);
	
	CGPoint origins[CFArrayGetCount(lines)];
	CTFrameGetLineOrigins((CTFrameRef)ctFrame, CFRangeMake(0, 0), origins);
	
	CTLineRef line = NULL;
	CGPoint lineOrigin = CGPointZero;
	for (int i= 0; i < CFArrayGetCount(lines); i++)
	{
		CGPoint origin = origins[i];
		CGPathRef path = CTFrameGetPath((CTFrameRef)ctFrame);
		CGRect rect = CGPathGetBoundingBox(path);
		
		CGFloat y = rect.origin.y + rect.size.height - origin.y;
		
		if ((location.y >= y) && (location.x >= origin.x))
		{
			line = CFArrayGetValueAtIndex(lines, i);
			lineOrigin = origin;
		}
	}
	
	location.x -= lineOrigin.x;
	CFIndex index = CTLineGetStringIndexForPosition(line, location);
	
    if (kCFNotFound == index)
    {
        NSLog(@"没在范围内");
        return;
    }
    
    //如果点击的位置不在范围内
    if (location.x > self.frame.size.width || location.x > CTLineGetTypographicBounds(line, NULL, NULL, NULL))//CTLineGetTypographicBounds(line).size.width)
    {
        index++;
    }
    
	_touchedLink = nil;
	
	for (AHMarkedHyperlink *link in links)
	{
		if (((index >= [link range].location) && (index <= ([link range].length + [link range].location))))
		{
			_touchedLink = link;
		}
	}
	
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
	_touchedLink = nil;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
	if (_touchedLink)
	{
        [delegate clickTag:self];
	}
}

-(void)clearTouch
{
    _touchedLink = nil;
    [self setNeedsDisplay];
}

-(NSString *)touchStr
{
    return [[_touchedLink parentString] substringWithRange:[_touchedLink range]];
}


@end


@implementation LocationBtn

@synthesize longitude,latitude;

-(void)dealloc
{
    
    [super dealloc];
}

@end
