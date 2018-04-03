//
//  GBRefreshTableHeaderView.m
//  GBRefreshTableHeaderViewDemo
//
//  Created by 郭一博 on 12-12-12.
//  Copyright (c) 2012年 郭一博. All rights reserved.
//

#import "GBRefreshTableHeaderView.h"
#import <QuartzCore/QuartzCore.h>
//#import "GYBAppDelegate.h"
//#import "CustomTabBarController.h"
#import "Config.h"
#import "CircleView.h"

#define REFRESH_HEADER_HEIGHT 52.0

@implementation GBRefreshTableHeaderView

@synthesize delegate;
@synthesize isIos7Navbarhidden,type,_circleView;


- (void)dealloc
{
    textPull = nil;
    textRelease = nil;
    textLoading = nil;
    refreshLabel = nil;
    refreshArrow = nil;
    refreshSpinner = nil;
    
    delegate = nil;
    
    self._circleView = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        textPull = [[NSString alloc] initWithString: NSLocalizedStringFromTable(@"pull down to refresh status",@"InfoPlist",nil) ];
        textRelease = [[NSString alloc] initWithString: NSLocalizedStringFromTable(@"release to refresh status",@"InfoPlist",nil) ];
        textLoading = [[NSString alloc] initWithString: NSLocalizedStringFromTable(@"Loading",@"InfoPlist",nil) ];
        
        self.frame = CGRectMake(0, frame.origin.y, frame.size.width, frame.size.height);
        //self.backgroundColor = [UIColor clearColor];
        
        refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-52, frame.size.width, REFRESH_HEADER_HEIGHT)];
        refreshLabel.backgroundColor = [UIColor clearColor];
        refreshLabel.textColor = [UIColor colorWithRed:117.0/255.0 green:131.0/255.0 blue:146.0/255.0 alpha:1.0];
        refreshLabel.font = [UIFont systemFontOfSize:14.0];
        refreshLabel.textAlignment = NSTextAlignmentCenter;
        
        refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blueArrow.png"]];
        refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 22) / 2),
                                        (floorf(REFRESH_HEADER_HEIGHT - 22) / 2)+frame.size.height-REFRESH_HEADER_HEIGHT,
                                        22, 22);
        
        refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2)+frame.size.height-REFRESH_HEADER_HEIGHT, 20, 20);
        //refreshSpinner.hidesWhenStopped = YES;
        [refreshSpinner stopAnimating];
        
        [self addSubview:refreshLabel];
        [self addSubview:refreshArrow];
        [self addSubview:refreshSpinner];
        
        [refreshLabel release];
        [refreshArrow release];
        [refreshSpinner release];
        
        CircleView *circleView = [[CircleView alloc] initWithFrame:IOS7_OR_LATER?CGRectMake(self.frame.size.width - 40, self.frame.size.height - 25 , 25, 25):CGRectMake(self.frame.size.width - 40, self.frame.size.height - 42 , 25, 25)];
        self._circleView = circleView;
        [self addSubview:circleView];
        [_circleView release];
        
        UIImageView *lineView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 300-2, frame.size.width, 1)];
        lineView.image = [UIImage imageNamed:@"dottedline@simple.png"];
        [self addSubview:lineView];
        [lineView release],lineView = nil;
        
       // [self loadSounds];
    }
    return self;
}

-(void)updateRefreshHeaderType:(RefreshHeaderType)_type
{
    if (_type == Normal)
    {
        refreshLabel.hidden = NO;
        refreshArrow.hidden = NO;
        //refreshSpinner.hidden = NO;
        _circleView.hidden = YES;
    }
    if (_type == MyInfo)
    {
        refreshLabel.hidden = YES;
        refreshArrow.hidden = YES;
        refreshSpinner.hidden = YES;
        _circleView.hidden = NO;
        
        //_circleView.frame = CGRectMake((self.frame.size.width - 25)/2, self.frame.size.height - 20 - 64, 25, 25);
    }
    if (_type == Otherinfo)
    {
        refreshLabel.hidden = YES;
        refreshArrow.hidden = YES;
        refreshSpinner.hidden = YES;
        _circleView.hidden = NO;
        
        
        [_circleView removeFromSuperview];
        _circleView =  nil;
        NSLog(@"%@",_circleView);
    }
}

-(void)GBRefreshScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (isLoading)
        return;
    isDragging = YES;
}

-(void)GBRefreshScrollViewDidScroll:(UIScrollView *)scrollView
{
    if (isLoading)   //如果正在加载,table被拖到最上侧,则回到原位置,否则如果没到
    {
       // NSLog(@"3~~~~~~~~~~~~~%f",scrollView.contentOffset.y);
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            scrollView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= ((isIos7Navbarhidden == NO)?-REFRESH_HEADER_HEIGHT:-REFRESH_HEADER_HEIGHT))
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    }
    else
    {
        if (isDragging && scrollView.contentOffset.y < 0) //如果处于拖动状态且正在拖动
        {
            // Update the arrow direction and label
            [UIView beginAnimations:nil context:NULL];
            if (scrollView.contentOffset.y < ((isIos7Navbarhidden == NO)?-REFRESH_HEADER_HEIGHT:-REFRESH_HEADER_HEIGHT)) //拖动到偏移52的位置,则改变label值,同时旋转图片,否则还是置于pull状态值,保持图片pull状态
            {
                //NSLog(@"1");
                //User is scrolling above the header
                refreshLabel.text = textRelease;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
                
                //NSLog(@"1~~~~~~~~~~~~~%f",scrollView.contentOffset.y);
                //圈圈
                float moveY = isIos7Navbarhidden == NO?(fabs(scrollView.contentOffset.y)):(fabs(scrollView.contentOffset.y));
                if (moveY < 0)
                {
                    moveY = 0;
                }
                if (moveY >= 50)
                {
                    moveY = 50;
                }
                
                _circleView.progress = moveY / 52;
                [_circleView setNeedsDisplay];
                
                //响一下
                //if ([[NSUserDefaults standardUserDefaults] integerForKey:@"SoundFlag"] == YES && isUpSoundPlayed == NO)
                if (isUpSoundPlayed == NO)
                {
                    isUpSoundPlayed = YES;
                    isDownSoundPlayed = NO;
                    AudioServicesPlaySystemSound(slideDownSound);
                }
            }
            else
            {
                
                //正在往下拖
                refreshLabel.text = textPull;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
                
                
//                NSLog(@"2~~~~~~~~~~~~~%f",scrollView.contentOffset.y);
                //圈圈
                float moveY = isIos7Navbarhidden == NO?(fabs(scrollView.contentOffset.y)):(fabs(scrollView.contentOffset.y));
                //NSLog(@"2~~~~~~~~~~~~~%f",moveY);
                if (moveY < 0)
                {
                    moveY = 0;
                }
                if (moveY >= 50)
                {
                    moveY = 50;
                }
         
                _circleView.progress = moveY / 52;
                [_circleView setNeedsDisplay];
                
                
                //响一下
               // if ([[NSUserDefaults standardUserDefaults] integerForKey:@"SoundFlag"] == YES && isDownSoundPlayed == NO && isUpSoundPlayed == YES)
                if (isDownSoundPlayed == NO && isUpSoundPlayed == YES)
                {
                    isDownSoundPlayed = YES;
                    isUpSoundPlayed = NO;
                    AudioServicesPlaySystemSound(slideUpSound);
                }
            }
            [UIView commitAnimations];
        }
        
        if (isDragging == NO && isLoading == NO && scrollView.contentOffset.y < 0)
        {
            //NSLog(@"5555555----------------");
            float moveY = fabs(scrollView.contentOffset.y) ;
            if (moveY < 0)
            {
                moveY = 0;
            }
            if (moveY >= 50)
            {
                moveY = 50;
            }
    
            _circleView.progress = moveY / 52;
            [_circleView setNeedsDisplay];
        }
        
    }
}

-(void)GBRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView
{
    if (isLoading)
        return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= ((isIos7Navbarhidden == NO)?-REFRESH_HEADER_HEIGHT:-REFRESH_HEADER_HEIGHT))
    {
        isLoading = YES;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        scrollView.contentInset = (isIos7Navbarhidden == NO)?UIEdgeInsetsMake(52, 0, 0, 0):UIEdgeInsetsMake(52, 0, 0, 0);
        refreshLabel.text = textLoading;
        refreshArrow.hidden = YES;
        if (type == Normal)
        {
            [refreshSpinner startAnimating];
        }
        [UIView commitAnimations];

        CABasicAnimation* rotate =  [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotate.removedOnCompletion = FALSE;
        rotate.fillMode = kCAFillModeForwards;
        [rotate setToValue: [NSNumber numberWithFloat: M_PI / 2]];
        rotate.repeatCount = HUGE_VALF;
        rotate.duration = 0.25;
        rotate.cumulative = TRUE;
        rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        
        [_circleView.layer addAnimation:rotate forKey:@"rotateAnimation"];
        
        [delegate GBRefreshScrollViewStartLoading];
    }
    isDownSoundPlayed = NO;
    isUpSoundPlayed = NO;
}


//removeAnimationForKey

-(void)GBRefreshScrollViewStopLoadingNow:(UIScrollView *)scrollView  //TOTO:检查是否会对使用者产生问题
{
    isLoading = NO;
    
    // Hide the header
    UIEdgeInsets tableContentInset = scrollView.contentInset;
    tableContentInset.top = (isIos7Navbarhidden == NO)?0.0:0.0;
    scrollView.contentInset = tableContentInset;
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [_circleView.layer removeAllAnimations];  //TODO:可能有崩溃错误
    _circleView.progress = 0 / 52;
    [_circleView setNeedsDisplay];
}
-(void)GBRefreshScrollViewStopLoading:(UIScrollView *)scrollView
{
    isLoading = NO;
    
    // Hide the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    UIEdgeInsets tableContentInset = scrollView.contentInset;
    tableContentInset.top = (isIos7Navbarhidden == NO)?0.0:0.0;
    scrollView.contentInset = tableContentInset;
    
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [UIView commitAnimations];
    
    
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_circleView.layer removeAllAnimations];  //TODO:可能有崩溃错误
        _circleView.progress = 0 / 52;
        [_circleView setNeedsDisplay];
    });

   // NSLog(@"-------------%f",scrollView.contentOffset.y);
}

- (void)stopLoadingComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    // Reset the header
    refreshLabel.text = textPull;
    refreshArrow.hidden = (type == Normal)?NO:YES;
    [refreshSpinner stopAnimating];
}

-(void)GBRefreshScrollViewStopLoadingImmediately:(UIScrollView *)scrollView
{
    isLoading = NO;
    UIEdgeInsets tableContentInset = scrollView.contentInset;
    tableContentInset.top = (isIos7Navbarhidden == NO)?0.0:0.0;
    scrollView.contentInset = tableContentInset;
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    
    refreshLabel.text = textPull;
    refreshArrow.hidden = (type == Normal)?NO:YES;
    [refreshSpinner stopAnimating];
}

-(void)manualFresh:(UIScrollView *)scrollView
{
    isDragging = NO;
    [scrollView setContentOffset:(isIos7Navbarhidden == NO)?CGPointMake(0, -53):CGPointMake(0, -53) animated:NO];
    [self GBRefreshScrollViewDidEndDragging:scrollView];
}

-(void)loadSounds
{
//	NSString *path=[[NSBundle mainBundle] pathForResource:@"prlm_sound_release" ofType:@"wav"];
//	CFURLRef baseURL=(CFURLRef)[[NSURL alloc] initFileURLWithPath:path];
//	AudioServicesCreateSystemSoundID(baseURL,&slideUpSound);
//    CFRelease(baseURL);
//	
//	NSString *path1=[[NSBundle mainBundle] pathForResource:@"prlm_sound_pull" ofType:@"wav"];
//	CFURLRef baseURL1=(CFURLRef)[[NSURL alloc] initFileURLWithPath:path1];
//	AudioServicesCreateSystemSoundID(baseURL1,&slideDownSound);
//    CFRelease(baseURL1);
}

-(void)changeTextColor:(UIColor *)color
{
    refreshLabel.textColor = color;
}



@end
