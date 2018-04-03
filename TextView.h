//
//  TextView.h
//  Magazin
//
//  Created by 郭一博 on 13-5-28.
//  Copyright (c) 2013年 郭一博. All rights reserved.
//  只负责绘制

#import <UIKit/UIKit.h>

@class AHMarkedHyperlink;
@protocol TextViewDelegate;
@class LocationBtn;

@interface TextView : UIView
{
    id ctFrame;
    //CGPoint _linkLocation;
   
    AHMarkedHyperlink *_touchedLink;
    
    id delegate;
    
    LocationBtn *locationBtn;
}


@property (assign, nonatomic) NSInteger fontSize;
@property (assign, nonatomic) CGFloat lineSpaceSize;
@property (retain, nonatomic) NSMutableArray* images;
@property (retain, nonatomic)  NSMutableArray *links;
@property (retain, nonatomic) NSMutableArray *rectArray;
@property (assign, nonatomic) id<TextViewDelegate> delegate;

@property (retain, nonatomic) NSString *liveCode;


-(void)setCTFrame:(id)f;
-(void)clearTouch;
-(NSString *)touchStr;

@end

@protocol TextViewDelegate <NSObject>

-(void)clickTag:(TextView *)view;
-(void)clickPostionBtn:(CGFloat)Longitude latitude:(CGFloat)Latitude;

@end


@interface LocationBtn : UIButton

@property (assign, nonatomic)    CGFloat longitude;
@property (assign, nonatomic)    CGFloat latitude;

@end

