//
//  BlogTextParser.m
//  CuctvWeibo
//
//  Created by 郭一博 on 13-6-6.
//
//

#import "BlogTextParser.h"
#import "AHMarkedHyperlink.h"
#import "Utility.h"
#import "Config.h"


/* Callbacks */
static void deallocCallback( void* ref ){
    [(id)ref release];
}
static CGFloat ascentCallback( void *ref ){
    return [(NSString*)[(NSDictionary*)ref objectForKey:@"height"] floatValue];
}
static CGFloat descentCallback( void *ref ){
    return [(NSString*)[(NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
static CGFloat widthCallback( void* ref ){
    return [(NSString*)[(NSDictionary*)ref objectForKey:@"width"] floatValue];
}

@implementation BlogTextParser
@synthesize font, fontSize, lineSpace, color, strokeColor, strokeWidth;
@synthesize images,links;

-(void)dealloc
{
    self.font = nil;
    self.color = nil;
    self.strokeColor = nil;
    self.images = nil;
    self.links = nil;
    
    [super dealloc];
}

-(id)init
{
    self = [super init];
    if (self) {
        self.font = @"Helvetica";
        //self.color = [UIColor blackColor];
        self.strokeColor = [UIColor whiteColor];
        self.strokeWidth = 0;
        self.images = [[NSMutableArray alloc] initWithCapacity:0];
        self.links  = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

-(NSAttributedString*)attrStringFromMarkup:(NSString*)markup withLocationName:(NSString *)locationName withLongitude:(CGFloat)longitude withLatitude:(CGFloat)latitude  withLiveCode:(NSString *)codeId
{
    if (markup.length == 0)
    {
        return [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    }
    
    NSString *faceStr;
    NSString *linkStr;
    if ([locationName isEqualToString:@"(null)"])
    {
        locationName = @"";
    }
    
    
   // if (![Utility isBlankString:locationName] || longitude != 0 || latitude!= 0)
    if (![Utility isBlankString:locationName])
    {
        faceStr = [Utility transformToLocationStr:[Utility transformToEmojiString:markup]];
        linkStr = [Utility transformToLocationStr:[Utility transformEmojiStringBlank:markup]];
    }
    else
    {
        if ([Utility isBlankString:codeId]) //如果是空的
        {
            faceStr = [Utility transformToEmojiString:markup];
            linkStr = [Utility transformEmojiStringBlank:markup];
        }
        else //如果不是空的
        {
            //直播类型的肯定不带地址
            faceStr = [Utility transformToLiveBtn:[Utility transformToEmojiString:markup]];
            linkStr = [Utility transformToLiveBtn:[Utility transformEmojiStringBlank:markup]];
        }
    }
    
    [self parseLinkStr:linkStr];
    
    //NSLog(@"原始长度:%@",faceStr);
    //NSLog(@"原始长度:%d",faceStr.length);
    
    
    NSMutableAttributedString* aString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease]; //1
    NSRegularExpression* regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"(.*?)(<[^>]+>|\\Z)"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                  error:nil]; //2
    
    NSArray* chunks = [regex matchesInString:faceStr options:0
                                       range:NSMakeRange(0, [faceStr length])];
    
    [regex release];
    
    for (NSTextCheckingResult* b in chunks)
    {
        //NSString *imageStr = [faceStr substringWithRange:b.range];
        //NSLog(@"%@",imageStr);
        
        
        NSArray* parts = [[faceStr substringWithRange:b.range] componentsSeparatedByString:@"<"]; //1
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.font,self.fontSize, NULL);
        CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(fontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontBoldTrait);
        //
        NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               (id)self.color.CGColor, kCTForegroundColorAttributeName,
                               (id)newFont, kCTFontAttributeName,
                               (id)self.strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                               (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                               nil];
        
        if ([parts count]>1)
        {
            NSString* tag = (NSString*)[parts objectAtIndex:1];
            if ([tag hasPrefix:@"Gyb_img"]) //有特定标签的情况
            {
                    [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs] autorelease]];
                    //第二部分
                    __block NSString* fileName = @"";
                    //image
                    NSRegularExpression* srcRegex = [[[NSRegularExpression alloc] initWithPattern:@"(?<=src=\")[^\"]+" options:0 error:NULL] autorelease];
                    [srcRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                        fileName = [tag substringWithRange: match.range];
                    }];
                    
                    //add the image for drawing
                    
                    [self.images addObject:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:16], @"width",
                      [NSNumber numberWithInt:16], @"height",
                      fileName, @"fileName",
                      [NSNumber numberWithInt: (int)[aString length]], @"location", //图片字符的起始位置,每次循环根据aString里面的字符数进行确定
                      IMG_EMOJI,@"type",
                      @"",@"title",
                      [NSNumber numberWithFloat:0], @"longitude",
                      [NSNumber numberWithFloat:0], @"latitude",
                      nil]
                     ];
                    
                    CTRunDelegateCallbacks callbacks;
                    callbacks.version = kCTRunDelegateVersion1;
                    callbacks.getAscent = ascentCallback;
                    callbacks.getDescent = descentCallback;
                    callbacks.getWidth = widthCallback;
                    callbacks.dealloc = deallocCallback;
                    
                    NSDictionary* imgAttr = [[NSDictionary dictionaryWithObjectsAndKeys: //2
                                              [NSNumber numberWithInt:16], @"width",
                                              [NSNumber numberWithInt:16], @"height",
                                              nil] retain];
                    
                    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, imgAttr); //3
                    NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            //set the delegate
                                                            (id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                                            nil];
                    
                    
                    //add a space to the text so that it can call the delegate
                    [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:attrDictionaryDelegate] autorelease]];
                    CFRelease(delegate);
            }
            else
                if ([tag hasPrefix:@"Gyb_location"])
                {
                    //先加入"<"左边的部分
                    [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs] autorelease]];
                    //计算按钮文字长度
                    CGSize titleSize;
                    if ([[[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] isEqual:@"0"] || ![[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] || [[[NSUserDefaults standardUserDefaults] objectForKey:KReadMode] isEqual:@"1"])
                    {
                        titleSize = [locationName sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(kMaxTextWidth, 16) lineBreakMode:NSLineBreakByWordWrapping];
                    }
                    else
                    {
                        titleSize = [locationName sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(kMaxTextWidthOfTextMode, 16) lineBreakMode:NSLineBreakByWordWrapping];
                    }
                    
                    NSString *_locationName;
                
                    //特殊怕暖
                        if ([Utility isBlankString:locationName])
                        {
                            _locationName = @"位置";
                        }
                        else
                        {
                             _locationName = [NSString stringWithString:locationName];
                        }
               
                    
                    [self.images addObject:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithFloat:titleSize.width+28], @"width",
                      [NSNumber numberWithFloat:16.0], @"height",
                      @"Location2.png", @"fileName",
                      [NSNumber numberWithInt: (int)[aString length]], @"location", //图片字符的起始位置,每次循环根据aString里面的字符数进行确定
                      BTN_LOCATION,@"type",
                      _locationName,@"title",//用于显示按钮上的文字
                      [NSNumber numberWithFloat:longitude], @"longitude",
                      [NSNumber numberWithFloat:latitude], @"latitude",
                      nil]
                     ];
                    
                    CTRunDelegateCallbacks callbacks;
                    callbacks.version = kCTRunDelegateVersion1;
                    callbacks.getAscent = ascentCallback;
                    callbacks.getDescent = descentCallback;
                    callbacks.getWidth = widthCallback;
                    callbacks.dealloc = deallocCallback;
                    
                    NSDictionary* imgAttr = [[NSDictionary dictionaryWithObjectsAndKeys: //2
                                              [NSNumber numberWithFloat:titleSize.width+28], @"width",
                                              [NSNumber numberWithInt:16], @"height",
                                              nil] retain];
                    
                    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, imgAttr); //3
                    NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            (id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                                            nil];
                    
                    [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:attrDictionaryDelegate] autorelease]];
                    CFRelease(delegate);
                }
                else  //没有特定标签
                {
                    [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@<%@",[parts objectAtIndex:0],[parts objectAtIndex:1]] attributes:attrs] autorelease]];
                }
        }
        else
        {
               [aString appendAttributedString:[[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs] autorelease]];
        }
        
        
        CFRelease(fontRef);
        //NSLog(@"原始长度:%d",aString.length);
    }
    
    for (AHMarkedHyperlink *link in links)
    {
        NSRange strRange = [link range];
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.font,self.fontSize, NULL);
        CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(fontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontBoldTrait);    //将默认黑体字设置为其它字体
        NSDictionary* attrs2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                (id)[UIColor colorWithRed:99.0/255.0 green:134.0/255.0 blue:187.0/255.0 alpha:1.0f].CGColor, kCTForegroundColorAttributeName,
                                (id)newFont, kCTFontAttributeName,
                                (id)self.strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                                (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                                nil];
        
        
        //在此做一个异常处理,防止崩溃
        if ([aString length] < strRange.length + strRange.location)
        {
            break;
        }
        else
            // if ([aString length] > strRange.length && [aString length] > strRange.location)
        {
            //NSLog(@"原始长度:%d",aString.length);
            [aString setAttributes:attrs2 range:strRange];
        }
    }
    
    
    
    //////
    //创建文本行间距
//    CGFloat lineSpace = lineSpace;//间距数据
    CTParagraphStyleSetting lineSpaceStyle;
    lineSpaceStyle.spec=kCTParagraphStyleSpecifierLineSpacing;//指定为行间距属性
    lineSpaceStyle.valueSize=sizeof(lineSpace);
    lineSpaceStyle.value = &lineSpace;
    
    //换行模式
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping;
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);

    
    //创建样式数组
    CTParagraphStyleSetting settings[] =
    {
        lineSpaceStyle,
        lineBreakMode
    };
    
    //设置样式
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 2);
    
    //给字符串添加样式attribute
    [aString addAttribute:(id)kCTParagraphStyleAttributeName
                    value:(id)paragraphStyle
                    range:NSMakeRange(0, [aString length])];
    CFRelease(paragraphStyle);
    
    
    //NSLog(@"处理后的长度:%d",aString.length);
    
    return aString;
}

-(void)parseLinkStr:(NSString *)text
{
    NSArray *expressions = [[[NSArray alloc] initWithObjects:
                             @"@[^@\\s:：#＃[ '.,:：#＃;*?~`!@#$%^&+=)(<>{}]\\]\\[]{1,32}",//@"@[\u4E00-\u9FA50-9a-zA-Z-_]+",//@"@[^@\\?\\=\\/：:#\\s\\[\\]<>&\u3000]{1,32}", //screen names@"(@[a-zA-Z0-9_]+)"
                             @"(#[^#]+#)",//@"(#[\u4e00-\u9fa5a-zA-Z0-9_-]+)#", //hash tags
                             @"(https?|ftp|file)://[-A-Z0-9+&@#/%?=~_|!:,.;]*[-A-Z0-9+&@#/%=~_|]",
                             @"(\\[观看直播\\])",//@"/'.'【观看直播】'.'/iU",
                             nil] autorelease];
    
	//get #hashtags and @usernames
	for (NSString *expression in expressions)
	{
		NSError *error = NULL;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
																			   options:NSRegularExpressionCaseInsensitive
																				 error:&error];
		NSArray *matches = [regex matchesInString:text
										  options:0
											range:NSMakeRange(0, [text length])];
        
		NSString *matchedString = nil;
		for (NSTextCheckingResult *match in matches)
		{
			matchedString = [[text substringWithRange:[match range]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			if ([matchedString hasPrefix:@"@"]) // usernames
			{
				NSString *username = matchedString;
				//NSLog(@"1~~~~~~~~~~~~~~~~~~~~~%@",username);
				AHMarkedHyperlink *hyperlink = [[[AHMarkedHyperlink alloc] initWithString:username
																	 withValidationStatus:AH_URL_VALID
																			 parentString:text
																				 andRange:[match range]] autorelease];
				[links addObject:hyperlink];
			}
			else if ([matchedString hasPrefix:@"#"]) // hash tag
			{
                //在这里加入处理,如果除去两个#为空,则
                NSString *mesureString = [matchedString substringWithRange:NSMakeRange(1, matchedString.length-2)];
                //NSLog(@"======%d",mesureString.length);
                if ([Utility isBlankString:mesureString])
                {
                    return;
                }

                
                NSString *searchTerm = [[matchedString substringToIndex:matchedString.length - 1]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				//NSLog(@"2~~~~~~~~~~~~~~~~~~~~~%@_",searchTerm);
				AHMarkedHyperlink *hyperlink = [[[AHMarkedHyperlink alloc] initWithString:searchTerm
																	 withValidationStatus:AH_URL_VALID
																			 parentString:text
																				 andRange:[match range]] autorelease];
                [links addObject:hyperlink];
			}
            else if ([matchedString hasPrefix:@"http"]) // hash tag
			{
				NSString *searchTerm = [matchedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
                //NSLog(@"3~~~~~~~~~~~~~~~~~~~~~%@_",searchTerm);
				AHMarkedHyperlink *hyperlink = [[[AHMarkedHyperlink alloc] initWithString:searchTerm
																	 withValidationStatus:AH_URL_VALID
																			 parentString:text
																				 andRange:[match range]] autorelease];
				[links addObject:hyperlink];
            }
            else if ([matchedString isEqualToString:@"[观看直播]"])
            {
                NSString *searchTerm = [matchedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                //NSLog(@"3~~~~~~~~~~~~~~~~~~~~~%@_",searchTerm);
                AHMarkedHyperlink *hyperlink = [[[AHMarkedHyperlink alloc] initWithString:searchTerm
                                                                     withValidationStatus:AH_URL_VALID
                                                                             parentString:text
                                                                                 andRange:[match range]] autorelease];
                [links addObject:hyperlink];
            }
		}
	}
}


@end
