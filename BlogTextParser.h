//
//  BlogTextParser.h
//  CuctvWeibo
//
//  Created by 郭一博 on 13-6-6.
//
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface BlogTextParser : NSObject
{
   
   

}

//这三需要自己设
@property (retain, nonatomic) NSString* font;
@property (assign, nonatomic) NSInteger fontSize;
@property (assign, nonatomic) CGFloat lineSpace;

@property (retain, nonatomic) UIColor* color;
@property (retain, nonatomic) UIColor* strokeColor;
@property (assign, readwrite) float strokeWidth;
@property (retain, nonatomic) NSMutableArray* images;
@property (retain, nonatomic) NSMutableArray* links;


-(NSAttributedString*)attrStringFromMarkup:(NSString*)markup withLocationName:(NSString *)locationName withLongitude:(CGFloat)longitude withLatitude:(CGFloat)latitude withLiveCode:(NSString *)codeId;

-(void)parseLinkStr:(NSString *)text;

@end
