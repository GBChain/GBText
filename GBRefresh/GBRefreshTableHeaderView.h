//
//  GBRefreshTableHeaderView.h
//  GBRefreshTableHeaderViewDemo
//
//  Created by 郭一博 on 12-12-12.
//  Copyright (c) 2012年 郭一博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

@protocol GBRefreshTableHeaderViewDelegate <NSObject>

-(void)GBRefreshScrollViewStartLoading;

@end

typedef enum
{
    Normal = 10,
    MyInfo = 11, //用于我的详情页面
    Otherinfo = 12
} RefreshHeaderType;

@class CircleView;
@interface GBRefreshTableHeaderView : UIView
{
    UILabel *refreshLabel;  //状态显示
    UIImageView *refreshArrow; //箭头标志
    UIActivityIndicatorView *refreshSpinner; //小菊花
    BOOL isDragging;    //正在拖动状态
    BOOL isLoading;     //正在加载状态
    NSString *textPull; //拉着状态
    NSString *textRelease; //释放的状态
    NSString *textLoading; //加载状态
    NSString *textColor;   //文字颜色
    
    id<GBRefreshTableHeaderViewDelegate> delegate;
    
    SystemSoundID slideDownSound;
	SystemSoundID slideUpSound;
    
    BOOL isUpSoundPlayed;
    BOOL isDownSoundPlayed;
    
    CircleView *_circleView;
}

@property (nonatomic, assign) id<GBRefreshTableHeaderViewDelegate> delegate;
@property (nonatomic, assign) BOOL isIos7Navbarhidden;  //IOS 7下如果table是在有导航栏的页面中，而且是坐标从00开始的时候要设置为no
@property (nonatomic, assign) RefreshHeaderType type;
@property (nonatomic, retain)  CircleView *_circleView;

-(void)GBRefreshScrollViewWillBeginDragging:(UIScrollView *)scrollView;
-(void)GBRefreshScrollViewDidScroll:(UIScrollView *)scrollView;
-(void)GBRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView;
-(void)GBRefreshScrollViewStopLoadingNow:(UIScrollView *)scrollView;
-(void)GBRefreshScrollViewStopLoading:(UIScrollView *)scrollView;
-(void)GBRefreshScrollViewStopLoadingImmediately:(UIScrollView *)scrollView;

-(void)updateRefreshHeaderType:(RefreshHeaderType)_type;


-(void)manualFresh:(UIScrollView *)scrollView;

-(void)loadSounds;

-(void)changeTextColor:(UIColor *)color;
@end
