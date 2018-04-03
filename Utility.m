//
//  Utility.m
//  CuctvWeibo
//
//  Created by miti on 11-9-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Utility.h"
#import "Reachability.h"
#import "Config.h"
#import <CommonCrypto/CommonDigest.h>
#import "MBProgressHUD.h"
#import "MicroVideo.h"
#import "edcode.h"
//#import "NSStringExtention.h"
//#import "NSData+Compress.h"
#import "UIDevice+IdentifierAddition.h"
#import "NSString+Base64.h"
#import "RegexKitLite.h"
#import "ATMHud.h"
#import "LoginInfo.h"
#import <CoreText/CoreText.h>
#import "CuctvWeiboAppDelegate.h"
#import "FileOperation.h"
#import <AddressBook/AddressBook.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "UIDevice+IdentifierAddition.h"


#define App_ID @"426896981"    //此应用的appid
#define LAST_RUN_VERSION_KEY        @"last_run_version_of_application"
#define WZB_KEY "cuctv!@#mobile$%^stat"

@implementation Utility

+(NSDictionary *)addExtraInfoToRequest:(NSInteger)netType
{
    NSString *appVersion=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *systemVersion=[[UIDevice currentDevice] systemVersion];
    NSString *device = [[UIDevice currentDevice] model];
    NSString *model = [[UIDevice currentDevice] systemName];
    NSString *netStr = [NSString stringWithFormat:@"%ld",(long)netType];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:kPushDeviceToken];
    
    NSDictionary *extraDic = [NSDictionary dictionaryWithObjectsAndKeys:
                              appVersion,@"appver",
                              systemVersion,@"osver",
                              device,@"device",
                              model,@"model",
                              netStr,@"net",
                              APPID,@"appid",
                              pushToken,@"devicetoken",nil];
    
    return extraDic;
}


+(int)getAddressBookToArray:(NSMutableArray*)theArray
{
    int nCount = 0;
    ABAddressBookRef addressRef = nil;
    if (&ABAddressBookRequestAccessWithCompletion != NULL && [[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressRef = ABAddressBookCreateWithOptions(NULL, NULL);
        
        //等待同意后向下执行
      //  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
        {
            ABAddressBookRequestAccessWithCompletion(addressRef, ^(bool granted, CFErrorRef error)
                                                     {
                                                       //  dispatch_semaphore_signal(sema);
                                                     });
            
           // dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
        }
       // dispatch_release(sema);
    }
    else
    {
        //打开电话本数据库
        addressRef=ABAddressBookCreate();
    }
    if (addressRef)
    {
        //返回所有联系人到一个数组中
        CFArrayRef personArray = ABAddressBookCopyArrayOfAllPeople(addressRef);
        
        //循环读取每个联系人
        for (int i =0;i<ABAddressBookGetPersonCount(addressRef);i++)
        {
            
            //得到当前联系人
            ABRecordRef personRef=CFArrayGetValueAtIndex(personArray, i);
            
            //==============================================================================
            //得到个别属性值(对于唯有一项的属性直接读取即可)
            //如需在此获得其它属性，如生日，职务，公司等只需要修改kab....property即可
            CFStringRef firstname=ABRecordCopyValue(personRef, kABPersonFirstNameProperty);
            CFStringRef lastname=ABRecordCopyValue(personRef, kABPersonLastNameProperty);
            
            //NSLog(@"%d===%@--%@.",i,(NSString*)firstname,(NSString*)lastname);
            //==============================================================================
            //[nameArray addObject:[NSString stringWithFormat:@"%@%@",lastname,firstname]];
            NSString *aNameStr = (NSString*)firstname;
            NSString *bNameStr = (NSString*)lastname;
            //用于循环计数
            int j;
            //用于保存有多项的属性值
            ABMultiValueRef values ;
            
            //==============================================================================
            //循环读出该项的所有值，如果需要修改读出其它具有多项值的属性，只需修改KAB...Property
            //具有多项值的属性有电话，地址，email
            values = (ABMultiValueRef) ABRecordCopyValue(personRef , kABPersonPhoneProperty);
            for(j = 0 ;j < ABMultiValueGetCount(values); j++)
            {
                //NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(values, j));
                NSString *numberStrhave_ = (NSString *)ABMultiValueCopyValueAtIndex(values, j);
                NSString *numberStr = [numberStrhave_ stringByReplacingOccurrencesOfString:@"-" withString:@""];
                NSString *myMobile = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileString"];
                if (numberStr && [numberStr length] >= 11 && (myMobile != nil && NO == [myMobile isEqualToString:numberStr]))
                {
                    NSString *phoneNumerStr = [numberStr substringWithRange:NSMakeRange(([numberStr length] - 11), 11)];
                    NSString *phoneNumerStr1 = [phoneNumerStr substringToIndex:1];
                    if(numberStr && [phoneNumerStr1 isEqualToString:@"1"] && [self isPureInt:phoneNumerStr] == YES)
                    {
                        NSString *userNameStr = nil;
                        if (aNameStr && [aNameStr length] > 0 && bNameStr && [bNameStr length] > 0)
                        {
                            userNameStr = [NSString stringWithFormat:@"%@%@",bNameStr,aNameStr];
                        }
                        else if(aNameStr && [aNameStr length] > 0 && (bNameStr == nil || [bNameStr length] == 0))
                        {
                            userNameStr = aNameStr;
                        }
                        else if((aNameStr == nil || [aNameStr length] == 0 )&& bNameStr && [bNameStr length] > 0)
                        {
                            userNameStr = bNameStr;
                        }
                        if (userNameStr &&  [userNameStr length] > 0 )
                        {
                            Person *auser = [[Person alloc] init];
                            auser.username = userNameStr;
                            auser.mobileString = phoneNumerStr;
                            [theArray addObject:auser];
                            [auser release];
                            nCount++;
                            //NSLog(@"%d===%@--%@.",nCount,userNameStr,phoneNumerStr);
                        }
                        
                    }
                }
                [numberStrhave_ release];
                //[numberArray addObject:(NSString *)ABMultiValueCopyValueAtIndex(values, j)];
            }
        }
        CFRelease(personArray);
        if (&ABAddressBookRequestAccessWithCompletion != NULL && [[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
        {
            if (addressRef)
            {
                CFRelease(addressRef);
                addressRef = NULL;
            }
        }
    }
    else
    {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
        {
            //            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"打开通讯录失败" message:@"请到系统设置-隐私-通讯录内打开视友开关" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
            //            [alertView show];
            //            [alertView release];
            nCount = -1;
        }
    }
    return nCount;
    
   // return 1;
}
//星期
+(NSString*)chineseWeekMark:(SInt8)day
{
    NSString *weekday = nil;
    switch (day) {
        case 1:
            weekday = @"日";
            break;
        case 2:
            weekday = @"一";
            break;
        case 3:
            weekday = @"二";
            break;
        case 4:
            weekday = @"三";
            break;
        case 5:
            weekday = @"四";
            break;
        case 6:
            weekday = @"五";
            break;
        case 7:
            weekday = @"六";
            break;
            
        default:
            break;
    }
    return weekday;
}

//是否为整形
+(BOOL)isPureInt:(NSString*)string
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
    
}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

//创建一个错误信息的提示框
+(void)getHUDWithView:(UIView*)view target:(id)delegate info:(NSString *)Str
{
    MBProgressHUD *HUD = [[[MBProgressHUD alloc] initWithView:view] autorelease];
    UILabel *lbError = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    lbError.numberOfLines = 0;
    lbError.textAlignment = NSTextAlignmentCenter;
    lbError.lineBreakMode = NSLineBreakByWordWrapping;
    lbError.textColor = [UIColor whiteColor];
    lbError.font = [UIFont systemFontOfSize:17];
    lbError.text = Str;
    lbError.backgroundColor = [UIColor clearColor];
    HUD.customView = lbError;
//    HUD.delegate = delegate;
    [lbError release];
    HUD.mode = MBProgressHUDModeCustomView;
    [view addSubview:HUD];
    [HUD show:YES];
	[HUD hide:YES afterDelay:1.5];
}

//创建一个网络访问失败提示窗2
+(void)getErrorHUDWithView:(UIView*)view target:(id)delegate
{
    MBProgressHUD *HUD = [[[MBProgressHUD alloc] initWithView:view] autorelease];
    UILabel *lbError = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 50)];
    lbError.numberOfLines = 0;
    lbError.lineBreakMode = NSLineBreakByWordWrapping;
    lbError.textColor = [UIColor whiteColor];
    lbError.textAlignment = NSTextAlignmentCenter;
    lbError.font = [UIFont systemFontOfSize:17];
    lbError.text = NETWORK_ERROR;
    lbError.backgroundColor = [UIColor clearColor];
    HUD.customView = lbError;
    [lbError release];
    HUD.mode = MBProgressHUDModeCustomView;
    [view addSubview:HUD];
    [HUD show:YES];
	[HUD hide:YES afterDelay:0.5];
}



//ATMHud错误信息提示
+(void)ATMHudWithView:(UIView*)view target:(id)delegate wrongInfo:(NSString *)Str
{
    ATMHud *hud = [[[ATMHud alloc] initWithDelegate:delegate] autorelease];
    hud.accessoryPosition = ATMHudAccessoryPositionTop;
	[view addSubview:hud.view];
    
    [hud setCaption:Str];
    //[hud setImage:[UIImage imageNamed:@"wrong.png"]];
    [hud show];
    [hud hideAfter:2.0];
}


+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size roundSize:(CGSize)roundSize
{
    // the size of CGContextRef
    int w = size.width;
    int h = size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, roundSize.width, roundSize.height);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), image.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *image2 = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    return image2;
}

+(UIImage*) circleImage:(UIImage*)image
{
    int w = image.size.width;
    int h = image.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, image.size.width/2.0, image.size.height/2.0);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), image.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *image2 = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    return image2;
}

//按比例改变图片大小  ----- 不建议使用  性能不好  会导致白边
+(UIImage*)changeImageSizeWithOriginalImage:(UIImage*)image percent:(float)percent
{
    // change the image size
	UIImage *changedImage=nil;
	float iwidth=image.size.width*percent;
	float iheight=image.size.height*percent;
	if (image.size.width != iwidth && image.size.height != iheight)
	{
        CGSize itemSize = CGSizeMake(iwidth, iheight);
		UIGraphicsBeginImageContext(itemSize);
		CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
		[image drawInRect:imageRect];
		changedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
    }
    else
    {
        changedImage = image;
    }
	
	return changedImage;
}

//分别按比例改变图片大小
+(UIImage*)changeImageSizeWithOriginalImage:(UIImage*)image percentX:(float)percentX percentY:(float)percentY
{
    // change the image size 
	UIImage *changedImage=nil;
	float iwidth = image.size.width*percentX;
	float iheight = image.size.height*percentY;
	if (image.size.width != iwidth && image.size.height != iheight)
	{
        CGSize itemSize = CGSizeMake(iwidth, iheight);
		UIGraphicsBeginImageContext(itemSize);
		CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
		[image drawInRect:imageRect];
		changedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
    }
    else
    {
        changedImage = image;
    }
	
	return changedImage;
}



//获取文件长度（字节数）
+(NSUInteger)getFileLengthByPath:(NSString*)filePath
{
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        return [attributes fileSize];
    }
    return 0;
}

//获取文件数组长度（字节数）
+(NSUInteger)getFileArrayLengthByPath:(NSArray*)filePathArray
{
    NSUInteger fileLength = 0;
    for (NSString *filePath in filePathArray)
    {
        fileLength += [self getFileLengthByPath:filePath];
    }
    return fileLength;
}

//获取文件
+(NSData *)getDataByPath:(NSString *)filePath
{
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        
        NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:filePath];
        return fileData;
    }
    return nil;
}

//根据范围获取部分文件数据
+(NSData *)subdataWithRange:(NSRange)range filePath:(NSString*)filePath
{
    NSData *subData = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    [fileHandle seekToFileOffset:range.location];
    subData = [fileHandle readDataOfLength:range.length];
    [fileHandle closeFile];
    return subData;
}

+(NSString *)get9SecVideoPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *nineVideoPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"nineVideo"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:nineVideoPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:nineVideoPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    
    return nineVideoPath;
}

//返回outbox路径（用来存放待发文件）
+(NSString*)getOutboxPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *outboxPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Outbox"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:outboxPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:outboxPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    
    return outboxPath;
}

//根据当前时间和扩展名生成文件路径
+(NSString*)getFilePathInOutboxWithExt:(NSString*)file_ext
{
    NSString *filePath = [NSString stringWithFormat:@"%@.%@",[Utility getCurrentTimeStr],file_ext];
    return [[Utility getOutboxPath] stringByAppendingPathComponent:filePath];
}

//根据当前时间和扩展名生成文件路径
+(NSString*)getFilePathInOutboxWithExtAndMarked:(NSString*)file_ext andMark:(NSString *)mark
{
    NSString *filePath = [NSString stringWithFormat:@"%@%@.%@",[Utility getCurrentTimeStr],mark,file_ext];
    return [[Utility getOutboxPath] stringByAppendingPathComponent:filePath];
}

#pragma mark - cache


+(NSString*)getDataCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dataCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"DataCache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataCachePath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    
    return dataCachePath;
}

+(NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [[Utility getDataCachePath] stringByAppendingPathComponent:filename];
}

+(NSData*)cacheDataForKey:(NSString*)key
{
    NSData *cacheData = [NSData dataWithContentsOfFile:[Utility cachePathForKey:key]];
    return cacheData;
}

#pragma mark - custom

//给定显示宽度，按原图比例计算应该显示的图片高度
+(float)getImageHeightByDisplayWidth:(float)width ori_width:(float)ori_width ori_height:(float)ori_height 
{
    if (ori_width==0) {
        return 0.0f;
    }
    return width*(ori_height/ori_width);
}

+(UILabel*)getTitleLabelWithText:(NSString*)text
{
	UILabel *lbTitle=[[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 25)] autorelease];
    lbTitle.text = text;
	lbTitle.backgroundColor=[UIColor clearColor];
	lbTitle.font=[UIFont boldSystemFontOfSize:20];
    lbTitle.textColor = [UIColor colorWithRed:76.0f/255.0f green:91.0f/255.0f blue:117.0f/255.0f alpha:1];
	lbTitle.textAlignment=NSTextAlignmentCenter;
	lbTitle.shadowColor=[UIColor whiteColor];
	lbTitle.shadowOffset=CGSizeMake(0.0f, 1.0f);
	return lbTitle;
}

+(NSString*)getImageUrl:(NSString*)ori_url Width:(int)width height:(int)height
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }
    
    NSString *url_prefix = [ori_url substringToIndex:range_dot.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    //"http://img.cuctv.com/uphoto/000/015/372/15372.jpg"
    NSString *video_url = [NSString stringWithFormat:@"%@_%dX%d.%@",url_prefix,width,height,ext_str];
    return video_url;
}


+(void)alert:(NSString*)title message:(NSString*)message delegate:(id)delegate tag:(int)tag
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Cuctv_OK", nil), nil];
    alert.tag = tag;
	[alert show];
    [alert release];
}



+(NSArray*)getEmojiFaceArray
{
//    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
//	NSString *filePath = [resourcePath stringByAppendingPathComponent:@"emoji.plist"];
//	
//	NSDictionary *faceDict = [[[NSDictionary alloc] initWithContentsOfFile:filePath] autorelease];
	
    NSString *aa = @"xiao,\U0001F604,feiwen,\U0001F618,jidong,\U0001F602,tushetou,\U0001F61D,cixia,\U0001F632,youyu,\U0001F614,haipa,\U0001F631,hengheng,\U0001F60F,keai,\U0001F60A,huaxin,\U0001F60D,ganga,\U0001F625,emo,\U0001F47F,guihun,\U0001F47B,tangguohe,\U0001F49D,qidao,\U0001F64F,qiangzhuang,\U0001F4AA,qian,\U0001F4B0,dangao,\U0001F382,qiqiu,\U0001F388,liwu,\U0001F381,xiuse,\U0001F60C,buxie,\U0001F612,shengbing,\U0001F637,guilian,\U0001F61C,haixiu,\u263A,dengyan,\U0001F633,chijing,\U0001F628,ku,\U0001F62D,han,\U0001F613,keshui,\U0001F62A,hongxin,\u2764,xinsui,\U0001F494,ok,\U0001F44C,guzhang,\U0001F44F,chajin,\U0001F44E,lihai,\U0001F44D,quantou,\U0001F44A,dani,\u270A,shengli,\u270C,diyi,\u261D,mifan,\U0001F35A,miantiao,\U0001F35C,pijiu,\U0001F37A,kafei,\u2615,xigua,\U0001F349,zuqiu,\u26BD,qunzi,\U0001F457,yusan,\u2614,taiyang,\u2600,shandian,\u26A1,qiche,\U0001F697,shijian,\U0001F55A,xinfeng,\U0001F4E9,hongchun,\U0001F48B,jingxi,\U0001F389,meigui,\U0001F339,hudiejie,\U0001F380,zhutou,\U0001F437,shengdan,\U0001F385,tianshi,\U0001F47C";
    //@"\u263A"
    NSArray *a = [aa componentsSeparatedByString:@","];
    
	return a;
}


+(NSDictionary*)getDefaultFaceDict
{
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *filePath = [resourcePath stringByAppendingPathComponent:@"face.plist"];
	
	NSDictionary *faceDict=[[[NSDictionary alloc] initWithContentsOfFile:filePath] autorelease];
    
	return faceDict;
}

//get face dict
+(NSDictionary*)getFaceDict
{
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *filePath = [resourcePath stringByAppendingPathComponent:@"face.plist"];
	
	NSMutableDictionary *faceDict=[[[NSMutableDictionary alloc] initWithContentsOfFile:filePath] autorelease];
    
    NSString *emojialiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"aliInfo.plist"];
    NSDictionary *emojialiDic = [[NSDictionary alloc] initWithContentsOfFile:emojialiFilePath];
    [faceDict addEntriesFromDictionary:emojialiDic];
	[emojialiDic release];
	return faceDict;
}


+(CGRect)findRightRect:(UIImage*)image maxWidth:(float)mWidth maxHeight:(float)mHeight containerWidth:(float)cWidth containerHeight:(float)cHeight
{
	float height = 0.0f;
	float width = 0.0f;
	float x,y;
	
	if (image.size.height >0 && image.size.width>0) {
		
		if (image.size.height > image.size.width) {  //竖直图
			height = mHeight; //限定高度
			width = (image.size.width/image.size.height)*height;
		}
		else {  //水平图
			width =mWidth; //限定宽度
			height = (image.size.height/image.size.width)*width;
		}
	}
	
	x = (cWidth-width)/2;
	y = (cHeight-height)/2;
	
	CGRect ivImageRect = CGRectZero;
	ivImageRect.size.width = width;
	ivImageRect.size.height = height;
	ivImageRect.origin.x = x;
	ivImageRect.origin.y = y;	
	
	return ivImageRect;
}

//检查链接可用性
+(BOOL)checkConnection:(NSString*)url
{
	BOOL result = YES;
    Reachability *reach=[Reachability reachabilityWithHostName:@"www.baidu.com"];
    NetworkStatus status = [reach currentReachabilityStatus];
    switch (status)
    {
        case NotReachable:
        {
            result=NO;  
            break;
        }
            
        //case ReachableViaWWAN:
        case  ReachableVia2G:
        case  ReachableVia3G:
        {
            result=YES;
            break;
        }
        case ReachableViaWiFi:
        {
			result=YES;
            break;
		}
    }    
	
	return result;
}



+(NSString *)MacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            msgBuffer =(char*) malloc(length) ;
            if ((msgBuffer) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        //  DLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    // DLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

+ (NSString*) IPAddress
{
	NSString* IPAddress = nil;
	UInt32 address = 0;
    struct ifaddrs *interfaces;
    
    if( getifaddrs(&interfaces) == 0 )
    {
		struct ifaddrs *interface;
		for(interface=interfaces; interface; interface=interface->ifa_next)
        {
			if((interface->ifa_flags & IFF_UP) && ! (interface->ifa_flags & IFF_LOOPBACK))
            {
				const struct sockaddr_in *addr = (const struct sockaddr_in*) interface->ifa_addr;
                
				if( addr && addr->sin_family==AF_INET )
                {
					address = addr->sin_addr.s_addr;
					break;
				}
			}
		}
        
		freeifaddrs(interfaces);
    }
    
    if(address != 0 )
    {
		const UInt8* addrBytes = (const UInt8*)&address;
		IPAddress = [NSString stringWithFormat: @"%u.%u.%u.%u",
					 (unsigned)addrBytes[0],(unsigned)addrBytes[1],
					 (unsigned)addrBytes[2],(unsigned)addrBytes[3]];
    }
    
	return IPAddress;
}

+(NSString *)getAppID
{
    return App_ID;
}

+(NSString*)getAppVersion
{
	NSString *version =[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	return version;
}

+(void)showWeiPai:(id)target
{
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
    
    //传递用户信息，以切换直播程序的登录帐号
	NSString *url = [NSString stringWithFormat:@"cuctvWeiPai://com.cuctv.WeiPai?userid=%@&username=%@&password=%@",userid,username,password];
    //NSLog(@"%@",url);
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
	
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]]) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:@"请到AppStore下载视友微拍" delegate:target cancelButtonTitle:NSLocalizedString(@"Back", nil) otherButtonTitles:NSLocalizedString(@"Cuctv_OK", nil), nil];
        [alert show];
        [alert release];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    
}
+(void)showWeiZhiBo:(id)target
{
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
    
    //传递用户信息，以切换直播程序的登录帐号
	NSString *url = [NSString stringWithFormat:@"cuctvLive://com.cuctv.CucLiveMedia?userid=%@&username=%@&password=%@",userid,username,password];
    //NSString *url = [NSString stringWithFormat:@"cuctvSchoolTV://com.cuctv.SchoolTV?userid=%@&username=%@&password=%@",userid,username,password];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"%@",url);
	
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]]) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:@"请到AppStore下载微直播" delegate:target cancelButtonTitle:NSLocalizedString(@"Back", nil) otherButtonTitles:NSLocalizedString(@"Cuctv_OK", nil), nil];
        alert.tag = 1002;
        [alert show];
        [alert release];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

+(NSString*)clipHeaderImageToSpecifiedSize:(NSString*)ori_url Width:(int)width height:(int)height
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }

    NSString *url_prefix = [ori_url substringToIndex:range_dot.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    NSString *pic_url = [NSString stringWithFormat:@"%@_%dX%d.%@",url_prefix,width,height,ext_str];
    return pic_url;
}

+(NSString*)compressionImageToSpecifiedSize:(NSString*)ori_url withFunctionStr:(NSString *)functionStr
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }
    
    NSString *url_prefix = [ori_url substringToIndex:range_dot.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    NSString *pic_url = [NSString stringWithFormat:@"%@_%@.%@",url_prefix,functionStr,ext_str];
    return pic_url;
}


+(NSString*)getImageNoSpecifiedSize:(NSString*)ori_url
{
    if (ori_url==nil || [ori_url isEqualToString:@""])
    {
        return nil;
    }
    
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_dot.length == 0 || range_dot.location >= [ori_url length])
    {
        return nil;
    }
    
    NSString *url_prefix = [ori_url substringToIndex:range_dot.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    NSRange range__ = [url_prefix rangeOfString:@"_" options:NSBackwardsSearch];
    
    if (range__.length == 0 || range__.location >= [url_prefix length])
    {
        NSString *pic_url = [NSString stringWithFormat:@"%@.%@",url_prefix,ext_str];
        return pic_url;
    }
    else
    {
        NSString *url_prefix_ = [url_prefix substringToIndex:range__.location];
        NSString *pic_url = [NSString stringWithFormat:@"%@.%@",url_prefix_,ext_str];
        return pic_url;
    }
}
+(NSString *)clipImageToSpecifiedSize:(NSString *)ori_url Width:(int)width height:(int)height
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    //NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    NSRange range_underline = [ori_url rangeOfString:@"_" options:NSBackwardsSearch];
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_underline.length==0 || range_underline.location >= [ori_url length] || range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }
    
    NSString *url_prefix = [ori_url substringToIndex:range_underline.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    //http://img.cuctv.com/LivePic/11/1213/8703443/d_iphone_870344320111213105659_440X330.jpg
    NSString *pic_url = [NSString stringWithFormat:@"%@_%dX%d.%@",url_prefix,width,height,ext_str];
    return pic_url;
}

//适用于新版本多图的url
+(NSString *)clipImageToSpecifiedSize2:(NSString *)ori_url Width:(int)width height:(int)height
{
    if (ori_url == nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_dot.length == 0 || range_dot.location >= [ori_url length])
    {
        return nil;
    }
    
    NSString *headStr = [ori_url substringToIndex:range_dot.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    NSString *pic_url = [NSString stringWithFormat:@"%@_%dX%d.%@",headStr,width,height,ext_str];
    return pic_url;
}

+(NSString *)cancelClipImageToSpecifiedSize:(NSString *)ori_url
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    //NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    NSRange range_underline = [ori_url rangeOfString:@"_" options:NSBackwardsSearch];
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_underline.length==0 || range_underline.location >= [ori_url length] || range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }
    
    NSString *url_prefix = [ori_url substringToIndex:range_underline.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    //http://img.cuctv.com/LivePic/11/1213/8703443/d_iphone_870344320111213105659_440X330.jpg
    NSString *pic_url = [NSString stringWithFormat:@"%@.%@",url_prefix,ext_str];
    return pic_url;
}


//截取一部分图片
+ (UIImage *)clipFromImage:(UIImage *)image inRect:(CGRect)rect
{
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}


+(NSString *)changeUrlToTestUrl:(NSString *)imageUrl
{
    if ([Utility isBlankString:imageUrl])
    {
        return @"";
    }
    if ([imageUrl rangeOfString:@"test"].length > 0)
    {
        return  [NSString stringWithFormat:@"http://test.client.%@",[imageUrl substringFromIndex:12]];
    }
    else
    {
        //gif图片前缀不变
        if ([imageUrl rangeOfString:@".gif"].length > 0)
        {
             return  imageUrl;
        }
        else
        {
             return  [NSString stringWithFormat:@"http://client.%@",[imageUrl substringFromIndex:7]];
        }
    }
}



+(NSString*)getADPictureUrl:(NSString*)ori_url Width:(int)width height:(int)height
{
    if (ori_url==nil || [ori_url isEqualToString:@""]) {
        return nil;
    }
    
    NSRange range_virgule = [ori_url rangeOfString:@"/" options:NSBackwardsSearch];
    NSRange range_dot = [ori_url rangeOfString:@"." options:NSBackwardsSearch];
    
    if (range_virgule.length==0 || range_virgule.location >= [ori_url length] || range_dot.length == 0 || range_dot.location >= [ori_url length]) {
        return nil;
    }
    
    NSString *middle_str = [ori_url substringWithRange:NSMakeRange(range_virgule.location+1, range_dot.location-range_virgule.location-1)];
    NSString *url_prefix = [ori_url substringToIndex:range_virgule.location];
    NSString *ext_str = [ori_url substringFromIndex:range_dot.location+1];
    
    //http://img.cuctv.com/LivePic/11/1213/8703443/d_iphone_870344320111213105659_440X330.jpg
    NSString *video_url = [NSString stringWithFormat:@"%@/%@_%dX%d.%@",url_prefix,middle_str,width,height,ext_str];
    //NSLog(@"v:%@",video_url);
    return video_url;
}

+(NSString*)getCurrentTimeStrForDraft //草稿箱使用
{
	NSDate *date=[NSDate date];
	NSDateFormatter *formatter=[[[NSDateFormatter alloc] init] autorelease];
	//[formatter setDateStyle:kCFDateFormatterNoStyle];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *time=[formatter stringFromDate:date];
	return time;
}

+(NSString*)getCurrentTimeStr //发送图片使用
{
	NSDate *date=[NSDate date];
	NSDateFormatter *formatter=[[[NSDateFormatter alloc] init] autorelease];
	//[formatter setDateStyle:kCFDateFormatterNoStyle];
	[formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	NSString *time=[formatter stringFromDate:date];
	return time;
}

//获取Document文件路径
+ (NSString *) getDocumentPath:(NSString*)strName 
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:strName];
}

//用于合并文件地址并用,隔开
+(NSString *)retAllFilePath:(NSArray *)array
{
    NSMutableString *allFilePathStr = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
    for (NSString *str in array)
    {
        if (allFilePathStr.length < 1)
        {
            [allFilePathStr appendString:str];
        }
        else
        {
            [allFilePathStr appendString:@","];
            [allFilePathStr appendString:str];
        }
    }
    return allFilePathStr;
}

//是否同一分钟
+(BOOL)isSameTime_min:(NSString *)lastTime currentTime:(NSString *)currentTime
{
    if ([self isBlankString:lastTime] ||
        [self isBlankString:currentTime])
    {
        return NO;
    }
    
  
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *lastDate = [formatter dateFromString:lastTime];

    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

    //上一个时间
    NSDateComponents *comps = [calendar components:unitFlags fromDate:lastDate];
    NSInteger lastYear = [comps year];
    NSInteger lastMonth = [comps month];
    NSInteger lastDay = [comps day];
    NSInteger lastHour = [comps hour];
    NSInteger lastMin = [comps minute];
    
    //下一个下一个时间
    NSDate *currentDate = [formatter dateFromString:currentTime];
    NSDateComponents *currentComps = [calendar components:unitFlags fromDate:currentDate];
    NSInteger currentYear = [currentComps year];
    NSInteger currentMonth = [currentComps month];
    NSInteger currentDay = [currentComps day];
    NSInteger currentHour = [currentComps hour];
    NSInteger currentMin = [currentComps minute];
    
    [calendar release],calendar = nil;
    
    
    if (lastYear == currentYear &&
        lastMonth == currentMonth &&
        lastDay == currentDay &&
        lastHour == currentHour &&
        lastMin == currentMin)
    {
         return YES;
    }
    
    
    return NO;
}


+(NSString *)handleDate:(NSString *)dataStr
{
    if ([self isBlankString:dataStr])
    {
        return @"";
    }
    
    NSString *formatDateStr;
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *videoDate = [formatter dateFromString:dataStr];
    
    //[formatter setDateFormat:@"yyyy-MM-dd"];
    //NSString *time = [formatter stringFromDate:date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *compsCurrent = [calendar components:unitFlags fromDate:date]; //当前时间
    
    NSInteger yearCurrent = [compsCurrent year];
    NSInteger monthCurrent = [compsCurrent month];
    NSInteger dayCurrent = [compsCurrent day];
    NSInteger hourCurrent = [compsCurrent hour];
    NSInteger minCurrent = [compsCurrent minute];
    
    
    NSDateComponents *comps = [calendar components:unitFlags fromDate:videoDate]; //时间
    NSInteger year = [comps year];
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    
    
    [calendar release],calendar = nil;
    
    
    if (yearCurrent == year)
    {
        if (monthCurrent == month && day == dayCurrent) //同一天
        {
            if (hourCurrent == hour) //同一小时
            {
                if (min >= minCurrent) //同一分钟
                {
                    formatDateStr = [NSString stringWithFormat:@"刚刚"];
                }
                else
                {
                    formatDateStr = [NSString stringWithFormat:@"%ld分钟前",minCurrent - min,nil];
                }
            }
            else
            {
                NSTimeInterval cha = [videoDate timeIntervalSinceDate:date]/3600*(-1);
                if (cha <= 0)
                {
                    formatDateStr = [NSString stringWithFormat:@"刚刚"];
                }
                else
                    if (cha < 1) //若在1小时内
                    {
                        formatDateStr = [NSString stringWithFormat:@"%ld分钟前",(NSInteger)[videoDate timeIntervalSinceDate:date]/60*(-1),nil];
                    }
                    else
                    {
                        formatDateStr = [NSString stringWithFormat:@"%ld小时前", (NSInteger)[videoDate timeIntervalSinceDate:date]/3600*(-1)];
                    }
                
                //  formatDateStr = [NSString stringWithFormat:@"%ld小时前", hourCurrent - hour];
            }
        }
        else
        {
            if (dayCurrent - day == 1 )
            {
                formatDateStr = [NSString stringWithFormat:@"昨天 %02ld:%02ld", (long)hour,min];
            }
            else
            {
                formatDateStr = [NSString stringWithFormat:@"%ld月%ld日 %02ld:%02ld",(long)month,day,hour,min];
            }
        }
    }
    else //不在同一年,则直接显示
    {
        formatDateStr = [NSString stringWithFormat:@"%ld年%ld月%ld日",(long)year,month,day];
    }
    
    return formatDateStr;
}

//将时间转化为当前时间对比后的时间
+(NSString *)handleDateInPrivateMessage:(NSString *)dataStr
{
    if ([self isBlankString:dataStr])
    {
        return @"";
    }
    
    NSString *formatDateStr;
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *videoDate = [formatter dateFromString:dataStr];
    
    //[formatter setDateFormat:@"yyyy-MM-dd"];
    //NSString *time = [formatter stringFromDate:date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *compsCurrent = [calendar components:unitFlags fromDate:date]; //当前时间
    
    NSInteger yearCurrent = [compsCurrent year];
    NSInteger monthCurrent = [compsCurrent month];
    NSInteger dayCurrent = [compsCurrent day];
    NSInteger hourCurrent = [compsCurrent hour];
    NSInteger minCurrent = [compsCurrent minute];
    
    
    NSDateComponents *comps = [calendar components:unitFlags fromDate:videoDate]; //时间
    NSInteger year = [comps year];
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    
    
    [calendar release],calendar = nil;
    
    
    if (yearCurrent == year)
    {
        if (monthCurrent == month && day == dayCurrent) //同一天
        {
            formatDateStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)hour,min];
        }
        else
        {
            if (dayCurrent - day == 1 )
            {
                formatDateStr = [NSString stringWithFormat:@"昨天 %02ld:%02ld", (long)hour,min];
            }
            else
            {
                formatDateStr = [NSString stringWithFormat:@"%ld月%ld日 %02ld:%02ld",(long)month,day,hour,min];
            }
        }
    }
    else //不在同一年,则直接显示
    {
        formatDateStr = [NSString stringWithFormat:@"%ld年%ld月%ld日 %02ld:%02ld",(long)year,month,day,hour,min];
    }
    
    return formatDateStr;
}


//根据当前时间和扩展名生成本地文件路径
+(NSString*)getFilePathWithExt:(NSString*)file_ext
{
    NSString *filePath = [NSString stringWithFormat:@"%@.%@",[self getCurrentTimeStr],file_ext];
    return [self getDocumentPath:filePath];
}

//保存文件到本地
+(BOOL)saveFileToDisk:(NSData*)file_data withFilePath:(NSString*)file_path 
{
    return [file_data writeToFile:file_path atomically:YES];
}

+(BOOL)saveFileToDisk:(NSData *)file_data withFilePath:(NSString *)file_path andWithError:(NSError **)aError
{
    return [file_data writeToFile:file_path options:NSDataWritingWithoutOverwriting error:aError];
}

//删除指定位置文件
+(BOOL)deleteFile:(NSString*)file_path
{
    if([[NSFileManager defaultManager] fileExistsAtPath:file_path])
	{
        return [[NSFileManager defaultManager] removeItemAtPath:file_path error:nil];
    }
    
    return FALSE;
}

+(void)showNoticeAlert:(NSString*)strNotice
{
    [self showNoticeAlert:strNotice afterDelay:1.0f];
}

+(void)showNoticeAlert:(NSString*)strNotice afterDelay:(float)theTime
{
    UIAlertView *noticeAlert=[[UIAlertView alloc] initWithTitle:nil message:strNotice delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [noticeAlert show];
    [self performSelector:@selector(dismissNoticeAlert:) withObject:noticeAlert afterDelay:theTime];
}

+(void)dismissNoticeAlert:(UIAlertView*)noticeAlert
{
	[noticeAlert dismissWithClickedButtonIndex:0 animated:YES];
	[noticeAlert release];
}

+(NSUInteger) unicodeLengthOfString: (NSString *) text
{
    NSUInteger asciiLength = 0;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar uc = [text characterAtIndex: i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    NSUInteger unicodeLength = asciiLength / 2;
    
    if(asciiLength % 2) {
        unicodeLength++;
    }
    return unicodeLength;
}

+ (NSString*)URLencode:(NSString *)originalString stringEncoding:(NSStringEncoding)stringEncoding
{
    //!  @  $  &  (  )  =  +  ~  `  ;  '  :  ,  /  ?
    //%21%40%24%26%28%29%3D%2B%7E%60%3B%27%3A%2C%2F%3F
//    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
//                            @"@" , @"&" , @"=" , @"+" ,    @"$" , @"," ,
//                            @"!", @"'", @"(", @")", @"*", nil];
//    
//    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F", @"%3F" , @"%3A" ,
//                             @"%40" , @"%26" , @"%3D" , @"%2B" , @"%24" , @"%2C" ,
//                             @"%21", @"%27", @"%28", @"%29", @"%2A", nil];
//    
//    int len = [escapeChars count];
    
    NSMutableString *temp = [[originalString
                              stringByAddingPercentEscapesUsingEncoding:stringEncoding]
                             mutableCopy];
    
//    int i;
//    for (i = 0; i < len; i++) {
//        
//        [temp replaceOccurrencesOfString:[escapeChars objectAtIndex:i]
//                              withString:[replaceChars objectAtIndex:i]
//         options:NSLiteralSearch
//                                   range:NSMakeRange(0, [temp length])];
//    }
    
    NSString *outStr = [NSString stringWithString: temp];
    
    return outStr;
}

+ (NSString *)URLEncodedString:(NSString *)resultStr
{
    NSString *encodedValue = (NSString*)CFURLCreateStringByAddingPercentEscapes(nil,
                                                                                (CFStringRef)resultStr, nil,
                                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
    return encodedValue;
}


+(NSInteger)checkStringCharCount:(NSString*)string
{
    NSUInteger asciiLength = 0;
    for (NSUInteger i = 0; i < string.length; i++) {
        unichar uc = [string characterAtIndex: i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    NSUInteger unicodeLength = asciiLength / 2;
    
    if(asciiLength % 2) {
        unicodeLength++;
    }
    return unicodeLength;
}


//是否是合法的手机号,满足两个条件,11位,前三位正确
+(BOOL)checkisChinaMobile:(NSString *)mobileNumberString
{
    if (mobileNumberString.length == 11)
    {
//        NSRange range = NSMakeRange(0, 3);
//        NSString *hearNumString = [mobileNumberString substringWithRange:range];
//        NSArray * numArray = [NSArray arrayWithObjects:@"134",@"135",@"136",@"137",@"138",@"139",@"147",//中国移动
//                              @"150",@"151",@"152",@"157",@"158",@"159",@"182",@"187",@"188",@"183",//中国移动
//                              @"130",@"131",@"132",@"155",@"156",@"185",@"186",//中国联通
//                              @"133",@"153",@"181",@"189",@"180",nil];//中国电信
//        if ([numArray containsObject:hearNumString])
    //{
            return YES;
//        }
//        else
//        {
//            return NO;
//        }
    }
    else
    {
        return NO;
    }
}

//检查是否是手机号
+ (BOOL)isMobileNumber:(NSString *)mobileNum
{
    //判断是不是纯数字
    [NSCharacterSet decimalDigitCharacterSet];
    NSString *str = [mobileNum stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    
    if ([str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length >0)
    {
        NSLog(@"不是纯数字");
        return NO;
    }
    else
    {
        NSLog(@"纯数字");
        return YES;
    }
}

/**
 *检验当时使用网络是否是wifi，并且验证是否可访问
 *@return BOOL
 */
+(BOOL)checkNetWorkIsWifi{
    return ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable);
}


//用于检查是否是客户端的第一次登入
+(BOOL)isFirstRunApp
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:kFirstUseApp])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

+(NSString *)getStatString
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    NSString *systemVersion=[[UIDevice currentDevice] systemVersion];
    NSString *appVersion=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appIdentifier=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    //NSNumber *apiVersion=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"ApiVersion"];
    NSString *appFrom = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppFrom"];
    if (!appFrom)
    {
        appFrom = @"";
    }
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    if (!deviceToken)
    {
        deviceToken = @"";
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
    if (!userId)
    {
        userId = @"0";
    }
    NSString *model=[[UIDevice currentDevice] model];
    NSString *network = @"3";
    if ([Utility checkNetWorkIsWifi])
    {
        network = @"1";
    }
    else
    {
        network = @"2";
    }
    
    NSString *postData= [NSString stringWithFormat:@"_did=%@&_dname=%@&_requesttime=%.f&_language=%@&_version=%@&_appversion=%@&_model=%@&_devicetoken=%@&_from=%@&_network=%@&_appIdentifier=%@&_apiVersion=%@&_uid=%@",[[UIDevice currentDevice] uniqueDeviceIdentifier],[[UIDevice currentDevice] name],[[NSDate date] timeIntervalSince1970],currentLanguage,systemVersion,appVersion,model,deviceToken,appFrom,network,appIdentifier,@"4.1",userId];
    // NSLog(@"postData ==== %@",postData);
    char *key = WZB_KEY;
    char *data;
    const char *postDataStr = [postData cStringUsingEncoding:NSUTF8StringEncoding];
    //int size = [postData length]*sizeof(char);

    NSUInteger size = strlen(postDataStr);
    char *buffer = (char*) malloc(size+1);
    memset(buffer, 0, size+1);
    [postData getCString:buffer maxLength:size+1 encoding:NSUTF8StringEncoding];
    _encode(buffer, &data, (unsigned char *)key);
    free(buffer);
    NSString *secStr = nil;
    if (data)
    {
        secStr = [NSString stringWithCString:data encoding:NSUTF8StringEncoding];
    }
    free(data);
    
    return secStr;
}

//判断字符串是否为空或者空格或者类型不符
+(BOOL)isBlankString:(NSString *)string
{
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([string isKindOfClass:[NSString class]])
    {
        if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
        {
            return YES;
        }
    }
    
    return NO;
}

+(NSString *)replacePersonID:(NSString *)_str
{
	/*
	 NSString *regexString       = @"@\\b(\\w+)\\b";
	 
	 NSString *replaceWithString = @"<a href=\"app:username:$1\">@$1</a>";
	 */
	NSString *regexString       = @"@\\b(\\w+)\\b[(](\\w+)[)]";
	
	NSString *replaceWithString = @"@$1";	 //$1-username, $2-userid
	
	NSString *replacedString    = NULL;
	
	replacedString = [_str stringByReplacingOccurrencesOfRegex:regexString withString:replaceWithString];
	
	return replacedString;
}

//是否已经登录
+(BOOL)isUserHasLogin
{
    BOOL b = YES;
    if ([self isBlankString:[USER_DEFAULT objectForKey:kUserName]] || [self isBlankString:[USER_DEFAULT objectForKey:kUserId]] || [self isBlankString:[USER_DEFAULT objectForKey:kAcessToken]])
    {
        b = NO;
    }
    return b;
}




//长度计算
+ (NSInteger)checkStringSize:(NSString*)string
{
    NSUInteger length=[string length];
    NSUInteger currentStringSize=0;

    for (int i=0;i<length;i++) {
        NSString *tempCh = [string substringWithRange:NSMakeRange(i, 1)];
        ////NSLog(@"tempCh%@",tempCh);
        NSData *_temp = [tempCh dataUsingEncoding:NSUTF8StringEncoding];
        ////NSLog(@"temp length === %d",[_temp length]);
        if ([_temp length] > 1)
        {
            currentStringSize+=2;
        }
        else
        {
            currentStringSize+=1;
        }
    }
    return (70 - (currentStringSize + 1)/2);
}

//年龄计算
+(NSString *)calculateAgeByDateString:(NSString *)dateStr
{
    NSLog(@"%@",dateStr);
    if ([self isBlankString:dateStr] || dateStr.length < 10)
    {
        return @"";
    }
    else
    {
        NSString *shortDateStr = [dateStr substringToIndex:10];
        NSDateFormatter *formatter=[[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *birthDate = [formatter dateFromString:shortDateStr];
        NSTimeInterval timeLenth = [birthDate timeIntervalSinceNow];
        NSTimeInterval yearLenth = 365*24*3600;
        int ageNum = (-1)*timeLenth/yearLenth;
        return [NSString stringWithFormat:@"%d",ageNum];
    }
}

//星座计算
+(NSString *)calculateAstrologicalByDateString:(NSString *)dateStr
{
    if ([self isBlankString:dateStr] || dateStr.length < 10)
    {
        return @"";
    }
    else
    {
        NSString *shortDateStr = [dateStr substringToIndex:10];
        NSDateFormatter *formatter=[[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSInteger monthNum = [[shortDateStr substringWithRange:NSMakeRange(5, 2)] integerValue];
        
        NSInteger dayNum = [[shortDateStr substringWithRange:NSMakeRange(8, 2)] integerValue];
        
        switch (monthNum)
        {
            case 1:
                if (dayNum <= 19)
                {
                    return @"摩羯座";
                }
                else
                {
                    return @"水瓶座";
                }
                break;
            case 2:
                if (dayNum <= 18)
                {
                    return @"水瓶座";
                }
                else
                {
                    return @"双鱼座";
                }
                break;
            case 3:
                if (dayNum <= 20)
                {
                    return @"双鱼座";
                }
                else
                {
                    return @"白羊座";
                }
                break;
            case 4:
                if (dayNum <= 19)
                {
                    return @"白羊座";
                }
                else
                {
                    return @"金牛座";
                }
                break;
            case 5:
                if (dayNum <= 20)
                {
                    return @"金牛座";
                }
                else
                {
                    return @"双子座";
                }

                break;
            case 6:
                if (dayNum <= 21)
                {
                    return @"双子座";
                }
                else
                {
                    return @"巨蟹座";
                }

                break;
            case 7:
                if (dayNum <= 22)
                {
                    return @"巨蟹座";
                }
                else
                {
                    return @"狮子座";
                }

                break;
            case 8:
                if (dayNum <= 22)
                {
                    return @"狮子座";
                }
                else
                {
                    return @"处女座";
                }

                break;
            case 9:
                if (dayNum <= 22)
                {
                    return @"处女座";
                }
                else
                {
                    return @"天秤座";
                }

                break;
            case 10:
                if (dayNum <= 23)
                {
                    return @"天秤座";
                }
                else
                {
                    return @"天蝎座";
                }

                break;
            case 11:
                if (dayNum <= 22)
                {
                    return @"天蝎座";
                }
                else
                {
                    return @"射手座";
                }

                break;
            case 12:
                if (dayNum <= 21)
                {
                    return @"射手座";
                }
                else
                {
                    return @"摩羯座";
                }

                break;
            default:
                return @"";
                break;
        }
    }
}

//根据用户id获取用户资料
+(NSDictionary *)getUserInfoFromListByID:(NSString *)userId
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
   // NSLog(@"~~~~~~%@",fileDirectory);
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray = [NSMutableArray arrayWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
            //NSLog(@"%@",[uDict description]);
			if ([[uDict objectForKey:@"userid"] isEqualToString:userId])
            {
                return uDict;
			}
		}
        return nil;
    }
    else
    {
        //NSLog(@"本地存储有错误");
        return nil;
    }
}

//根据第三方userId寻找第三方登录的用户
+(NSDictionary *)getUserInfoFromListByThirdID:(NSString *)userId
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    // NSLog(@"~~~~~~%@",fileDirectory);
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray = [NSMutableArray arrayWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
            //NSLog(@"%@",[uDict description]);
			if ([[uDict objectForKey:@"thirdId"] isEqualToString:userId])
            {
                return uDict;
			}
		}
        return nil;
    }
    else
    {
        //NSLog(@"本地存储有错误");
        return nil;
    }
}

+(NSString*)backgroundImgIndex
{
    NSString *nImgNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"PersonViewBackgroundUI"];
    if (nImgNumber == nil || [nImgNumber isEqualToString:@""] || [nImgNumber isEqualToString:@"0"])
    {
        nImgNumber = @"1";
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"PersonViewBackgroundUI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return nImgNumber;
}



+(Person *)parsePersoninfo:(NSDictionary *)personDic
{
    //NSLog(@"%@",[personDic objectForKey:@"province"]);
    Person *personInfo = [[Person alloc] init];
    personInfo.userid = [personDic objectForKey:@"userid"];
    personInfo.username = [personDic objectForKey:@"username"];
    personInfo.userCert = [personDic objectForKey:@"usercert"];
    personInfo.userimageURL = [personDic objectForKey:@"userimageURL"];
    return [personInfo autorelease];
}

//截取图像中的部分图像
+(UIImage*)getSubImage:(UIImage *)image mCGRect:(CGRect)mCGRect centerBool:(BOOL)centerBool
{
    /*如若centerBool为Yes则是由中心点取mCGRect范围的图片*/
    float imgwidth = image.size.width;
    float imgheight = image.size.height;
    float viewwidth = mCGRect.size.width;
    float viewheight = mCGRect.size.height;
    CGRect rect;
    if(centerBool)
        rect = CGRectMake((imgwidth-viewwidth)/2, (imgheight-viewheight)/2, viewwidth, viewheight);
    else{
        if (viewheight < viewwidth) {
            if (imgwidth <= imgheight) {
                rect = CGRectMake(0, 0, imgwidth, imgwidth*viewheight/viewwidth);
            }else {
                float width = viewwidth*imgheight/viewheight;
                float x = (imgwidth - width)/2 ;
                if (x > 0) {
                    rect = CGRectMake(x, 0, width, imgheight);
                }else {
                    rect = CGRectMake(0, 0, imgwidth, imgwidth*viewheight/viewwidth);
                }
            }
        }else {
            if (imgwidth <= imgheight) {
                float height = viewheight*imgwidth/viewwidth;
                if (height < imgheight) {
                    rect = CGRectMake(0, 0, imgwidth, height);
                }else {
                    rect = CGRectMake(0, 0, viewwidth*imgheight/viewheight, imgheight);
                }
            }else {
                float width = viewwidth*imgheight/viewheight;
                if (width < imgwidth) {
                    float x = (imgwidth - width)/2;
                    rect = CGRectMake(x, 0, width, imgheight);
                }else {
                    rect = CGRectMake(0, 0, imgwidth, imgheight);
                }
            }
        }
    }
    
    //    CGFloat w = rect.size.width;
    //    rect.size.width = rect.size.height;
    //    rect.size.height = w;
    //    rect.origin.x = (image.size.width *55)/Screen_height;
    //    rect.origin.y =  (image.size.height *10)/Screen_width;
    //
    //    //NSLog(@"%f===%f",Screen_width,Screen_height);
    //
    //    CGFloat hNew = imgwidth * ((Screen_width - 20)/Screen_width);
    //    CGFloat wNew = (hNew*9)/16.0;
    //    rect.size.width = wNew;
    //    rect.size.height = hNew;
    //    rect.origin.x = (55 * imgheight)/Screen_height;
    //    rect.origin.y =  (imgwidth *10)/Screen_width;
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    
    UIGraphicsBeginImageContext(smallBounds.size); //问题
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    
    
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    return smallImage;
}

#pragma mark - 用户信相关操作
//组织当前存在的新信息,删除老的信息,把新的信息添加至栈顶
+(void)updateUserPlistByUserId:(NSString *)userId userInfo:(Person *)userInfo
{
    //组织新的数据,然后删除成功后就加入
    //存取新的数据
    NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"AccessToken"],@"AccessToken",
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"RefreshToken"],@"RefreshToken",
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"password"],@"password",
                              
                              userInfo.userid,@"userid",
                              userInfo.username,@"username",
                              userInfo.userimageURL,@"userimageURL",
                              
                              [NSString stringWithFormat:@"%ld",userInfo.microBlogCount], @"UserBlogCount",
                              [NSString stringWithFormat:@"%ld",userInfo.followerCount],@"FollowerCount",
                              [NSString stringWithFormat:@"%ld",userInfo.fansCount],@"FansCount",
                              [NSString stringWithFormat:@"%ld",userInfo.favCount], @"FavCount",
                              [NSString stringWithFormat:@"%ld",userInfo.liveCount] ,@"LiveCount",
                              [NSString stringWithFormat:@"%ld",userInfo.picCount], @"PicCount",
                              [NSString stringWithFormat:@"%ld",userInfo.doodleCount],@"DoodleCount",
                              [NSString stringWithFormat:@"%ld",userInfo.topicCount],@"TopicCount",
                              [NSString stringWithFormat:@"%ld",userInfo.videoCount],@"VideoCount",
                              [NSString stringWithFormat:@"%ld",userInfo.paiCount],@"ShortVideoCount",
                              
                              userInfo.userCert,@"usercert",
                              userInfo.email,@"Email",
                              userInfo.emailIsValidateString,@"emailIsValidate",
                              userInfo.province,@"Province",
                              userInfo.city,@"City",
                              userInfo.school,@"school",
                              userInfo.gender,@"Gender",
                              userInfo.introduction,@"Introduction",
                              userInfo.validateIntroduction,@"ValidateIntroduction",
                              userInfo.mobileIsValidateString,@"MobileIsValidate",
                              userInfo.mobileString,@"MobileString",
                              userInfo.workString,@"WorkString",
                              userInfo.backgroundImageURL,@"background",
                              
                              userInfo.tagStr,@"TagStr",
                              userInfo.birthDate,@"BirthDate",
                              userInfo.schoolStartTime,@"SchoolStartTime",
                              userInfo.schoolDepartment,@"SchoolDepartment",
                              
                             [Utility backgroundImgIndex],@"PersonViewBackgroundUI",
                             [[NSUserDefaults standardUserDefaults] objectForKey:@"showLiveICO"],@"showLiveICO",
                              nil];
    
    //查找已存在的信息
    //读取用户数据
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
            //NSLog(@"~~~~~~%@",userId);
			if ([[uDict objectForKey:@"userid"] isEqualToString:userId])
            {
                NSInteger indexNum = [usersArray indexOfObject:uDict];
                [usersArray removeObjectAtIndex:indexNum];
                [usersArray insertObject:userDict atIndex:0];
                [usersArray writeToFile:fileDirectory atomically:YES];
                
                break;
                //BOOL saveSuc = [usersArray writeToFile:fileDirectory atomically:YES];
                //return saveSuc;
			}
		}
        [usersArray release];
    }
    [userDict release];
    
    //同时更新本地userDefault信息
    //其他
    //用户信息
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userid forKey:@"userid"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.username forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userimageURL forKey:@"userimageURL"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.microBlogCount] forKey:@"UserBlogCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.followerCount] forKey:@"FollowerCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.fansCount] forKey:@"FansCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.favCount] forKey:@"FavCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.liveCount] forKey:@"LiveCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.picCount] forKey:@"PicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.doodleCount] forKey:@"DoodleCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.topicCount] forKey:@"TopicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.videoCount] forKey:@"VideoCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)userInfo.paiCount] forKey:@"ShortVideoCount"];
    
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userCert forKey:@"usercert"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.email forKey:@"Email"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.emailIsValidateString forKey:@"emailIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.province forKey:@"Province"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.city forKey:@"City"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.school forKey:@"school"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.gender forKey:@"Gender"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.introduction forKey:@"Introduction"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.validateIntroduction forKey:@"ValidateIntroduction"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.mobileIsValidateString forKey:@"MobileIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.mobileString forKey:@"MobileString"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.workString forKey:@"WorkString"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.backgroundImageURL forKey:@"background"];
    
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.tagStr forKey:@"TagStr"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.birthDate forKey:@"BirthDate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.schoolStartTime forKey:@"SchoolStartTime"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.schoolDepartment forKey:@"SchoolDepartment"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)updateUserPlistByUserId2:(NSString *)userId userInfo:(Person *)userInfo withThirdId:(NSString *)thirdId withSinaDic:(NSDictionary *)sinaDic withSinaName:(NSString *)sinaName thirdPlatFlag:(NSString *)platFlag
{
    //组织新的数据,然后删除成功后就加入
    //存取新的数据
    NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"AccessToken"],@"AccessToken",
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"RefreshToken"],@"RefreshToken",
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"password"],@"password",
                              
                              userInfo.userid,@"userid",
                              userInfo.username,@"username",
                              userInfo.userimageURL,@"userimageURL",
                              
                              [NSString stringWithFormat:@"%ld",userInfo.microBlogCount], @"UserBlogCount",
                              [NSString stringWithFormat:@"%ld",userInfo.followerCount],@"FollowerCount",
                              [NSString stringWithFormat:@"%ld",userInfo.fansCount],@"FansCount",
                              [NSString stringWithFormat:@"%ld",userInfo.favCount], @"FavCount",
                              [NSString stringWithFormat:@"%ld",userInfo.liveCount] ,@"LiveCount",
                              [NSString stringWithFormat:@"%ld",userInfo.picCount], @"PicCount",
                              [NSString stringWithFormat:@"%ld",userInfo.doodleCount],@"DoodleCount",
                              [NSString stringWithFormat:@"%ld",userInfo.topicCount],@"TopicCount",
                              [NSString stringWithFormat:@"%ld",userInfo.videoCount],@"VideoCount",
                              [NSString stringWithFormat:@"%ld",userInfo.paiCount],@"ShortVideoCount",
                              
                              userInfo.userCert,@"usercert",
                              userInfo.email,@"Email",
                              userInfo.emailIsValidateString,@"emailIsValidate",
                              userInfo.province,@"Province",
                              userInfo.city,@"City",
                              userInfo.school,@"school",
                              userInfo.gender,@"Gender",
                              userInfo.introduction,@"Introduction",
                              userInfo.validateIntroduction,@"ValidateIntroduction",
                              userInfo.mobileIsValidateString,@"MobileIsValidate",
                              userInfo.mobileString,@"MobileString",
                              userInfo.workString,@"WorkString",
                              userInfo.backgroundImageURL,@"background",
                              
                              userInfo.tagStr,@"TagStr",
                              userInfo.birthDate,@"BirthDate",
                              userInfo.schoolStartTime,@"SchoolStartTime",
                              userInfo.schoolDepartment,@"SchoolDepartment",
                              
                              [Utility backgroundImgIndex],@"PersonViewBackgroundUI",
                              [[NSUserDefaults standardUserDefaults] objectForKey:@"showLiveICO"],@"showLiveICO",
                              
                              platFlag,@"ThirdPlatFlag",
                              sinaName,@"sinaName",
                              
                              thirdId,@"thirdId",
                              sinaDic,@"sinaDic",
                              nil];
    
    //查找已存在的信息
    //读取用户数据
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
            //NSLog(@"~~~~~~%@",userId);
			if ([[uDict objectForKey:@"userid"] isEqualToString:userId])
            {
                NSInteger indexNum = [usersArray indexOfObject:uDict];
                [usersArray removeObjectAtIndex:indexNum];
                [usersArray insertObject:userDict atIndex:0];
                [usersArray writeToFile:fileDirectory atomically:YES];
                
                break;
                //BOOL saveSuc = [usersArray writeToFile:fileDirectory atomically:YES];
                //return saveSuc;
			}
		}
        [usersArray release];
    }
    [userDict release];
    
    //同时更新本地userDefault信息
    //其他
    //用户信息
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userid forKey:@"userid"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.username forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userimageURL forKey:@"userimageURL"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.microBlogCount] forKey:@"UserBlogCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.followerCount] forKey:@"FollowerCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.fansCount] forKey:@"FansCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.favCount] forKey:@"FavCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.liveCount] forKey:@"LiveCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.picCount] forKey:@"PicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.doodleCount] forKey:@"DoodleCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.topicCount] forKey:@"TopicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.videoCount] forKey:@"VideoCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",userInfo.paiCount] forKey:@"ShortVideoCount"];
    
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.userCert forKey:@"usercert"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.email forKey:@"Email"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.emailIsValidateString forKey:@"emailIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.province forKey:@"Province"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.city forKey:@"City"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.school forKey:@"school"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.gender forKey:@"Gender"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.introduction forKey:@"Introduction"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.validateIntroduction forKey:@"ValidateIntroduction"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.mobileIsValidateString forKey:@"MobileIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.mobileString forKey:@"MobileString"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.workString forKey:@"WorkString"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.backgroundImageURL forKey:@"background"];
    
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.tagStr forKey:@"TagStr"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.birthDate forKey:@"BirthDate"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.schoolStartTime forKey:@"SchoolStartTime"];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo.schoolDepartment forKey:@"SchoolDepartment"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}



//添加帐号使用,记录入userdefault以及plist
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr
{
    if (loginInfo != nil)
    {
        Person *thePerson = loginInfo.userInfo;
        //~~~~~~~~~~~存入userdefault
        //其他
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.AccessToken forKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.RefreshToken forKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] setObject:passwordStr forKey:@"password"];
        //用户信息
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userid forKey:@"userid"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.username forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userimageURL forKey:@"userimageURL"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.microBlogCount] forKey:@"UserBlogCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.followerCount] forKey:@"FollowerCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.fansCount] forKey:@"FansCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.favCount] forKey:@"FavCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.liveCount] forKey:@"LiveCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.picCount] forKey:@"PicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.doodleCount] forKey:@"DoodleCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.topicCount] forKey:@"TopicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.videoCount] forKey:@"VideoCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.paiCount] forKey:@"ShortVideoCount"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userCert forKey:@"usercert"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.email forKey:@"Email"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.emailIsValidateString forKey:@"emailIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.province forKey:@"Province"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.city forKey:@"City"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.school forKey:@"school"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.gender forKey:@"Gender"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.introduction forKey:@"Introduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.validateIntroduction forKey:@"ValidateIntroduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileIsValidateString forKey:@"MobileIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileString forKey:@"MobileString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.workString forKey:@"WorkString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.backgroundImageURL forKey:@"background"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.tagStr forKey:@"TagStr"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.birthDate forKey:@"BirthDate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolStartTime forKey:@"SchoolStartTime"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolDepartment forKey:@"SchoolDepartment"];
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"PersonViewBackgroundUI"];
        //如果字段值为空,则为0,否则需要设置
        //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"showLiveICO"]);
//        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"showLiveICO"] isEqual:@"1"])
//        {
//             [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
//        }
//        else
//        {
//             [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
//        }
        NSString *showLiveICO = @"0";
        [[NSUserDefaults standardUserDefaults] setObject:showLiveICO forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
        [[NSUserDefaults standardUserDefaults] setObject:[Utility backgroundImgIndex] forKey:@"PersonViewBackgroundUI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  loginInfo.AccessToken,@"AccessToken",
                                  loginInfo.RefreshToken,@"RefreshToken",
                                  passwordStr,@"password",
                                  
                                  thePerson.userid,@"userid",
                                  thePerson.username,@"username",
                                  thePerson.userimageURL,@"userimageURL",
                                  
                                  [NSString stringWithFormat:@"%ld",thePerson.microBlogCount], @"UserBlogCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.followerCount],@"FollowerCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.fansCount],@"FansCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.favCount], @"FavCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.liveCount] ,@"LiveCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.picCount], @"PicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.doodleCount],@"DoodleCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.topicCount],@"TopicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.videoCount],@"VideoCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.paiCount],@"ShortVideoCount",
                                  
                                  thePerson.userCert,@"usercert",
                                  thePerson.email,@"Email",
                                  thePerson.emailIsValidateString,@"emailIsValidate",
                                  thePerson.province,@"Province",
                                  thePerson.city,@"City",
                                  thePerson.school,@"school",
                                  thePerson.gender,@"Gender",
                                  thePerson.introduction,@"Introduction",
                                  thePerson.validateIntroduction,@"ValidateIntroduction",
                                  thePerson.mobileIsValidateString,@"MobileIsValidate",
                                  thePerson.mobileString,@"MobileString",
                                  thePerson.workString,@"WorkString",
                                  thePerson.backgroundImageURL,@"background",
                                  
                                  thePerson.tagStr,@"TagStr",
                                  thePerson.birthDate,@"BirthDate",
                                  thePerson.schoolStartTime,@"SchoolStartTime",
                                  thePerson.schoolDepartment,@"SchoolDepartment",
                                  
                                  showLiveICO,@"showLiveICO",
                                  @"1",@"PersonViewBackgroundUI",
                                  nil];
        
        //~~~~~~~~~~~存入userdefault
        //存入plist
        [self saveUserAccount:userDict];
        [userDict release];
    }
    else
    {
        //如果信息为空,则不进行存储
        NSLog(@"登录信息存储错误");
    }
}


+(void)saveLoginInfo:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict
{
    [self saveLoginInfo:loginInfo  password:[theDict objectForKey:@"password"]  withLiveIco:[theDict objectForKey:@"showLiveICO"] backgroundImgIndex:[theDict objectForKey:@"PersonViewBackgroundUI"]];
}
/*
 仅供函数内部使用
 对外代替函数:+(void)saveLoginInfo:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict
 */
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr withLiveIco:(NSString *)liveIcoStr backgroundImgIndex:(NSString*)indexStr
{
    if([Utility isBlankString:indexStr])
    {
        indexStr = @"";
    }
    
    if (loginInfo != nil)
    {
        Person *thePerson = loginInfo.userInfo;
        //~~~~~~~~~~~存入userdefault
        //其他
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.AccessToken forKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.RefreshToken forKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] setObject:passwordStr forKey:@"password"];
        //用户信息
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userid forKey:@"userid"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.username forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userimageURL forKey:@"userimageURL"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.microBlogCount] forKey:@"UserBlogCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.followerCount] forKey:@"FollowerCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.fansCount] forKey:@"FansCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.favCount] forKey:@"FavCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.liveCount] forKey:@"LiveCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.picCount] forKey:@"PicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.doodleCount] forKey:@"DoodleCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.topicCount] forKey:@"TopicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.videoCount] forKey:@"VideoCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.paiCount] forKey:@"ShortVideoCount"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userCert forKey:@"usercert"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.email forKey:@"Email"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.emailIsValidateString forKey:@"emailIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.province forKey:@"Province"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.city forKey:@"City"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.school forKey:@"school"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.gender forKey:@"Gender"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.introduction forKey:@"Introduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.validateIntroduction forKey:@"ValidateIntroduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileIsValidateString forKey:@"MobileIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileString forKey:@"MobileString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.workString forKey:@"WorkString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.backgroundImageURL forKey:@"background"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.tagStr forKey:@"TagStr"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.birthDate forKey:@"BirthDate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolStartTime forKey:@"SchoolStartTime"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolDepartment forKey:@"SchoolDepartment"];
        
        [[NSUserDefaults standardUserDefaults] setObject:liveIcoStr forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
        [[NSUserDefaults standardUserDefaults] setObject:indexStr forKey:@"PersonViewBackgroundUI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  loginInfo.AccessToken,@"AccessToken",
                                  loginInfo.RefreshToken,@"RefreshToken",
                                  passwordStr,@"password",
                                  
                                  thePerson.userid,@"userid",
                                  thePerson.username,@"username",
                                  thePerson.userimageURL,@"userimageURL",
                                  
                                  [NSString stringWithFormat:@"%ld",thePerson.microBlogCount], @"UserBlogCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.followerCount],@"FollowerCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.fansCount],@"FansCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.favCount], @"FavCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.liveCount] ,@"LiveCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.picCount], @"PicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.doodleCount],@"DoodleCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.topicCount],@"TopicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.videoCount],@"VideoCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.paiCount],@"ShortVideoCount",
                                  
                                  thePerson.userCert,@"usercert",
                                  thePerson.email,@"Email",
                                  thePerson.emailIsValidateString,@"emailIsValidate",
                                  thePerson.province,@"Province",
                                  thePerson.city,@"City",
                                  thePerson.school,@"school",
                                  thePerson.gender,@"Gender",
                                  thePerson.introduction,@"Introduction",
                                  thePerson.validateIntroduction,@"ValidateIntroduction",
                                  thePerson.mobileIsValidateString,@"MobileIsValidate",
                                  thePerson.mobileString,@"MobileString",
                                  thePerson.workString,@"WorkString",
                                  thePerson.backgroundImageURL,@"background",
                                  
                                  thePerson.tagStr,@"TagStr",
                                  thePerson.birthDate,@"BirthDate",
                                  thePerson.schoolStartTime,@"SchoolStartTime",
                                  thePerson.schoolDepartment,@"SchoolDepartment",
                                  
                                  liveIcoStr,@"showLiveICO",
                                  indexStr,@"PersonViewBackgroundUI",
                                  nil];
        
        //~~~~~~~~~~~存入userdefault
        //存入plist
        [self saveUserAccount:userDict];
        [userDict release];
    }
    else
    {
        //如果信息为空,则不进行存储
        NSLog(@"登录信息存储错误");
    }
}

//第三方绑定的时候调用
+(void)saveLoginInfo2:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict
{
    [Utility saveLoginInfo2:loginInfo password:@"" withLiveIco:[theDict objectForKey:@"showLiveICO"] withThirdId:[theDict objectForKey:@"thirdId"] withSinaDic:[theDict objectForKey:@"sinaDic"] withSinaName:[theDict objectForKey:@"sinaName"] thirdPlatFlag:[theDict objectForKey:@"ThirdPlatFlag"] backgroundImgIndex:[theDict objectForKey:@"PersonViewBackgroundUI"]];
}
/*第三方绑定的时候调用
 仅供函数内部使用
 对外代替函数:+(void)saveLoginInfo2:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict
 */
+(void)saveLoginInfo2:(LoginInfo *)loginInfo password:(NSString *)passwordStr withLiveIco:(NSString *)liveIcoStr withThirdId:(NSString *)thirdId withSinaDic:(NSDictionary *)sinaDic withSinaName:(NSString *)sinaName thirdPlatFlag:(NSString *)platFlag backgroundImgIndex:(NSString*)indexStr
{
    if([Utility isBlankString:indexStr])
    {
        indexStr = @"";
    }
    if (loginInfo != nil)
    {
        Person *thePerson = loginInfo.userInfo;
        //~~~~~~~~~~~存入userdefault
        //其他
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.AccessToken forKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.RefreshToken forKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] setObject:passwordStr forKey:@"password"];
        //用户信息
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userid forKey:@"userid"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.username forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userimageURL forKey:@"userimageURL"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.microBlogCount] forKey:@"UserBlogCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.followerCount] forKey:@"FollowerCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.fansCount] forKey:@"FansCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.favCount] forKey:@"FavCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.liveCount] forKey:@"LiveCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.picCount] forKey:@"PicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.doodleCount] forKey:@"DoodleCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.topicCount] forKey:@"TopicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.videoCount] forKey:@"VideoCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.paiCount] forKey:@"ShortVideoCount"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userCert forKey:@"usercert"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.email forKey:@"Email"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.emailIsValidateString forKey:@"emailIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.province forKey:@"Province"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.city forKey:@"City"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.school forKey:@"school"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.gender forKey:@"Gender"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.introduction forKey:@"Introduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.validateIntroduction forKey:@"ValidateIntroduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileIsValidateString forKey:@"MobileIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileString forKey:@"MobileString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.workString forKey:@"WorkString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.backgroundImageURL forKey:@"background"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.tagStr forKey:@"TagStr"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.birthDate forKey:@"BirthDate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolStartTime forKey:@"SchoolStartTime"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolDepartment forKey:@"SchoolDepartment"];
        
        [[NSUserDefaults standardUserDefaults] setObject:liveIcoStr forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
        [[NSUserDefaults standardUserDefaults] setObject:indexStr forKey:@"PersonViewBackgroundUI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  loginInfo.AccessToken,@"AccessToken",
                                  loginInfo.RefreshToken,@"RefreshToken",
                                  passwordStr,@"password",
                                  
                                  thePerson.userid,@"userid",
                                  thePerson.username,@"username",
                                  thePerson.userimageURL,@"userimageURL",
                                  
                                  [NSString stringWithFormat:@"%ld",thePerson.microBlogCount], @"UserBlogCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.followerCount],@"FollowerCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.fansCount],@"FansCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.favCount], @"FavCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.liveCount],@"LiveCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.picCount], @"PicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.doodleCount],@"DoodleCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.topicCount],@"TopicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.videoCount],@"VideoCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.paiCount],@"ShortVideoCount",
                                  
                                  thePerson.userCert,@"usercert",
                                  thePerson.email,@"Email",
                                  thePerson.emailIsValidateString,@"emailIsValidate",
                                  thePerson.province,@"Province",
                                  thePerson.city,@"City",
                                  thePerson.school,@"school",
                                  thePerson.gender,@"Gender",
                                  thePerson.introduction,@"Introduction",
                                  thePerson.validateIntroduction,@"ValidateIntroduction",
                                  thePerson.mobileIsValidateString,@"MobileIsValidate",
                                  thePerson.mobileString,@"MobileString",
                                  thePerson.workString,@"WorkString",
                                    platFlag,@"ThirdPlatFlag",
                                  thePerson.tagStr,@"TagStr",
                                  thePerson.birthDate,@"BirthDate",
                                  thePerson.schoolStartTime,@"SchoolStartTime",
                                  thePerson.schoolDepartment,@"SchoolDepartment",
                                  platFlag,@"ThirdPlatFlag",
                                  sinaName,@"sinaName",
                                  
                                  liveIcoStr,@"showLiveICO",
                                  thirdId,@"thirdId",
                                  sinaDic,@"sinaDic",
                                  
                                  indexStr,@"PersonViewBackgroundUI",
                                  thePerson.backgroundImageURL,@"background",
                                  nil];
        
        
        //~~~~~~~~~~~存入userdefault
        //存入plist
        [self saveUserAccount:userDict];
        [userDict release];
    }
    else
    {
        //如果信息为空,则不进行存储
        NSLog(@"登录信息存储错误");
    }
}


//仅限第三方帐号登录使用
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr withThirdUserId:(NSString *)useId withSinaDic:(NSDictionary *)dic
{
    if (loginInfo != nil)
    {
        Person *thePerson = loginInfo.userInfo;
        //~~~~~~~~~~~存入userdefault
        //其他
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.AccessToken forKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:loginInfo.RefreshToken forKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] setObject:passwordStr forKey:@"password"];
        
        //用户信息
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userid forKey:@"userid"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.username forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userimageURL forKey:@"userimageURL"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.microBlogCount] forKey:@"UserBlogCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.followerCount] forKey:@"FollowerCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.fansCount] forKey:@"FansCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.favCount] forKey:@"FavCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.liveCount] forKey:@"LiveCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.picCount] forKey:@"PicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.doodleCount] forKey:@"DoodleCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.topicCount] forKey:@"TopicCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.videoCount] forKey:@"VideoCount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",thePerson.paiCount] forKey:@"ShortVideoCount"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.userCert forKey:@"usercert"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.email forKey:@"Email"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.emailIsValidateString forKey:@"emailIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.province forKey:@"Province"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.city forKey:@"City"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.school forKey:@"school"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.gender forKey:@"Gender"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.introduction forKey:@"Introduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.validateIntroduction forKey:@"ValidateIntroduction"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileIsValidateString forKey:@"MobileIsValidate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.mobileString forKey:@"MobileString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.workString forKey:@"WorkString"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.backgroundImageURL forKey:@"background"];
        
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.tagStr forKey:@"TagStr"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.birthDate forKey:@"BirthDate"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolStartTime forKey:@"SchoolStartTime"];
        [[NSUserDefaults standardUserDefaults] setObject:thePerson.schoolDepartment forKey:@"SchoolDepartment"];
        
        NSString *showLiveICO = @"0";
        [[NSUserDefaults standardUserDefaults] setObject:showLiveICO forKey:@"showLiveICO"]; //工具栏是否有微直播按钮
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"PersonViewBackgroundUI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSDictionary *userDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  loginInfo.AccessToken,@"AccessToken",
                                  loginInfo.RefreshToken,@"RefreshToken",
                                  passwordStr,@"password",
                                  
                                  thePerson.userid,@"userid",
                                  thePerson.username,@"username",
                                  thePerson.userimageURL,@"userimageURL",
                                  
                                  [NSString stringWithFormat:@"%ld",thePerson.microBlogCount], @"UserBlogCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.followerCount],@"FollowerCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.fansCount],@"FansCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.favCount], @"FavCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.liveCount] ,@"LiveCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.picCount], @"PicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.doodleCount],@"DoodleCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.topicCount],@"TopicCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.videoCount],@"VideoCount",
                                  [NSString stringWithFormat:@"%ld",thePerson.paiCount],@"ShortVideoCount",
                                  
                                  thePerson.userCert,@"usercert",
                                  thePerson.email,@"Email",
                                  thePerson.emailIsValidateString,@"emailIsValidate",
                                  thePerson.province,@"Province",
                                  thePerson.city,@"City",
                                  thePerson.school,@"school",
                                  thePerson.gender,@"Gender",
                                  thePerson.introduction,@"Introduction",
                                  thePerson.validateIntroduction,@"ValidateIntroduction",
                                  thePerson.mobileIsValidateString,@"MobileIsValidate",
                                  thePerson.mobileString,@"MobileString",
                                  thePerson.workString,@"WorkString",
                                  thePerson.backgroundImageURL,@"background",
                                  
                                  thePerson.tagStr,@"TagStr",
                                  thePerson.birthDate,@"BirthDate",
                                  thePerson.schoolStartTime,@"SchoolStartTime",
                                  thePerson.schoolDepartment,@"SchoolDepartment",
                                  
                                  showLiveICO,@"showLiveICO",
                                  useId,@"thirdId",
                                  dic,@"sinaDic",
                                  @"",@"sinaName",
                                  @"1",@"PersonViewBackgroundUI",
                                  nil];
        
        //~~~~~~~~~~~存入userdefault
        //存入plist
        [self saveUserAccount:userDict];
        [userDict release];
    }
    else
    {
        //如果信息为空,则不进行存储
        NSLog(@"登录信息存储错误");
    }
}

//将用户信息记录入plist
+(void)saveUserAccount:(NSDictionary*)userDict
{
	NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    //NSLog(@"%@",fileDirectory);
	if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
		BOOL isExist=NO;
        NSString *userDictString = [userDict objectForKey:@"userid"];
        //NSString *userNametString = [userDict objectForKey:@"username"];
        for (int i=0; i<[usersArray count]; i++)
        {
            NSDictionary *uDict = [usersArray objectAtIndex:i];
            NSString *uDictString = [uDict objectForKey:@"userid"];
            //NSString *nameString = [uDict objectForKey:@"username"];
            
            if (userDictString  && [userDictString length] > 2 && [uDictString isEqualToString:userDictString])
            {
				isExist=YES;
                //只要ID一样就可以，用户名可以变化
//                NSString *uDictNameString = [uDict objectForKey:@"username"];
//                NSString *userDictNameString = [userDict objectForKey:@"username"];
//                if ([uDictNameString isEqualToString:userDictNameString])
                {
                    NSUInteger _replaceIndex = [usersArray indexOfObject:uDict];
                    [usersArray removeObjectAtIndex:_replaceIndex];
                    [usersArray insertObject:userDict atIndex:0];
                    [usersArray writeToFile:fileDirectory atomically:YES];
                }
				break;
			}
        }
		
        if (isExist ==  NO &&  userDictString && [userDictString length] > 2)//不存在就add
        {
			[usersArray addObject:userDict];
			[usersArray writeToFile:fileDirectory atomically:YES];
		}
        
        [usersArray writeToFile:fileDirectory atomically:YES];
		[usersArray release];
	}
	else
    {
		NSArray *usersArray=[[NSArray alloc] initWithObjects:userDict,nil];
		NSString *userDictString = [userDict objectForKey:@"userid"];
        if (userDictString && [userDictString length] > 2)
        {
            [usersArray writeToFile:fileDirectory atomically:YES];
        }
        else
        {
            NSLog(@"saveUserAccount error~~!!!");
        }
        //[usersArray writeToFile:fileDirectory atomically:YES];
		[usersArray release];
	}
}

//设置当前帐号,userdict是从plist中拿出来的
+(void)setCurrentAccount:(NSDictionary*)userDict
{
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"AccessToken"] forKey:@"AccessToken"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"RefreshToken"] forKey:@"RefreshToken"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"password"] forKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"userid"] forKey:@"userid"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"username"] forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"userimageURL"] forKey:@"userimageURL"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"UserBlogCount"] forKey:@"UserBlogCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"FollowerCount"] forKey:@"FollowerCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"FansCount"] forKey:@"FansCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"FavCount"] forKey:@"FavCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"LiveCount"] forKey:@"LiveCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"PicCount"] forKey:@"PicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"DoodleCount"] forKey:@"DoodleCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"TopicCount"] forKey:@"TopicCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"VideoCount"] forKey:@"VideoCount"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"ShortVideoCount"] forKey:@"ShortVideoCount"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"usercert"] forKey:@"usercert"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"Email"] forKey:@"Email"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"emailIsValidate"] forKey:@"emailIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"Province"] forKey:@"Province"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"City"] forKey:@"City"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"school"] forKey:@"school"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"Gender"] forKey:@"Gender"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"Introduction"] forKey:@"Introduction"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"ValidateIntroduction"] forKey:@"ValidateIntroduction"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"MobileIsValidate"] forKey:@"MobileIsValidate"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"MobileString"] forKey:@"MobileString"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"WorkString"] forKey:@"WorkString"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"background"] forKey:@"background"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"TagStr"] forKey:@"TagStr"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"BirthDate"] forKey:@"BirthDate"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"SchoolStartTime"] forKey:@"SchoolStartTime"];
    [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"SchoolDepartment"] forKey:@"SchoolDepartment"];

    
   [[NSUserDefaults standardUserDefaults] setObject:[userDict objectForKey:@"PersonViewBackgroundUI"] forKey:@"PersonViewBackgroundUI"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//更改是否有微直播图标那个属性
+(void)updateUserPlistLiveICO
{
    //拿出dic,然后修改之,存储起来
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
        for(NSMutableDictionary *uDict in usersArray)
		{
			if ([[uDict objectForKey:@"userid"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"userid"]])
            {
                //改变属性
                [uDict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"showLiveICO"] forKey:@"showLiveICO"];
                [usersArray writeToFile:fileDirectory atomically:YES];
                break;
			}
		}
        [usersArray release];
    }
}

//有多少个用户
+(NSInteger)userListNum
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
    {
        NSMutableArray *usersArray = [NSMutableArray arrayWithContentsOfFile:fileDirectory];
        
        return usersArray.count;
    }
    else
    {
        return 0;
    }
}

//得到某个用户的信息
+(Person *)getPersonInfoByUserId:(NSString *)userIdStr
{
    //先根据用户id得到userDic
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"user.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
        Person *userInfo = nil;
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
        for(NSMutableDictionary *uDict in usersArray)
		{
			if ([[uDict objectForKey:@"userid"] isEqualToString:userIdStr])
            {
                userInfo = [[Person alloc] init];
                userInfo.userid = [uDict objectForKey:@"userid"];
                userInfo.username = [uDict objectForKey:@"username"];
                userInfo.userimageURL = [uDict objectForKey:@"userimageURL"];
                
                userInfo.microBlogCount = [[uDict objectForKey:@"UserBlogCount"] integerValue];
                userInfo.followerCount = [[uDict objectForKey:@"FollowerCount"] integerValue];
                userInfo.fansCount = [[uDict objectForKey:@"FansCount"] integerValue];
                userInfo.favCount = [[uDict objectForKey:@"FavCount"] integerValue];
                userInfo.liveCount = [[uDict objectForKey:@"LiveCount"] integerValue];
                userInfo.picCount = [[uDict objectForKey:@"PicCount"] integerValue];
                userInfo.doodleCount = [[uDict objectForKey:@"DoodleCount"] integerValue];
                userInfo.topicCount = [[uDict objectForKey:@"TopicCount"] integerValue];
                userInfo.videoCount = [[uDict objectForKey:@"VideoCount"] integerValue];
                userInfo.paiCount = [[uDict objectForKey:@"ShortVideoCount"] integerValue];
                
                userInfo.userCert = [uDict objectForKey:@"usercert"];
                userInfo.email = [uDict objectForKey:@"Email"];
                userInfo.emailIsValidateString = [uDict objectForKey:@"emailIsValidate"];
                userInfo.province = [uDict objectForKey:@"Province"];
                userInfo.city = [uDict objectForKey:@"City"];
                userInfo.school = [uDict objectForKey:@"school"];
                userInfo.workString = [uDict objectForKey:@"WorkString"];
                userInfo.gender = [uDict objectForKey:@"Gender"];
                userInfo.introduction = [uDict objectForKey:@"Introduction"];
                
                userInfo.validateIntroduction = [uDict objectForKey:@"ValidateIntroduction"];
                userInfo.mobileIsValidateString = [uDict objectForKey:@"MobileIsValidate"];
                userInfo.mobileString = [uDict objectForKey:@"MobileString"];
                userInfo.workString = [uDict objectForKey:@"WorkString"];
                userInfo.backgroundImageURL = [uDict objectForKey:@"background"];
                
                
                userInfo.tagStr = [uDict objectForKey:@"TagStr"];
                userInfo.birthDate = [uDict objectForKey:@"BirthDate"];
                userInfo.schoolStartTime = [uDict objectForKey:@"SchoolStartTime"];
                userInfo.schoolDepartment = [uDict objectForKey:@"SchoolDepartment"];
                break;
			}
		}
        [usersArray release];
        return userInfo;
    }
    else
    {
        return nil;
    }
}

#pragma mark - 微博列表标签点击,转换为表情标签
+(NSString *)transformToEmojiString:(NSString *)originalStr
{
    NSString *emojiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.plist"];
    NSMutableDictionary *emojiDic = [[NSMutableDictionary alloc] initWithContentsOfFile:emojiFilePath];
    
    NSString *emojialiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"aliInfo.plist"];
    NSDictionary *emojialiDic = [[NSDictionary alloc] initWithContentsOfFile:emojialiFilePath];
    [emojiDic addEntriesFromDictionary:emojialiDic];
    [emojialiDic release];
    NSString *text = originalStr;
    NSString *regex_emoji = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
    NSArray *array_emoji = [text componentsMatchedByRegex:regex_emoji];
    if ([array_emoji count]) {
        for (NSString *str in array_emoji)
        {
            NSRange range = [text rangeOfString:str];
            NSArray *keyArray = [emojiDic allKeysForObject:str];
            
            if (keyArray.count == 0)
            {
                
            }
            else
            {
                NSString *i_transCharacter = [keyArray objectAtIndex:0];
                if (i_transCharacter)
                {
                    NSString *imageHtml = [NSString stringWithFormat:@"<Gyb_img src=\"%@.png\" width=\"16\" height=\"16\">",i_transCharacter];
                    text = [text stringByReplacingCharactersInRange:NSMakeRange(range.location, [str length]) withString:imageHtml];
                }
            }
        }
    }
    
    [emojiDic release],emojiDic = nil;
    if ([[self transformEmojiStringBlank:originalStr] isEqualToString:@"  "])
    {
        return [NSString stringWithFormat:@"%@ ",text];
    }
    
    if ([[[self transformEmojiStringBlank:originalStr] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
    {
        return [NSString stringWithFormat:@"%@ ",text];
    }
    
    //返回转义后的字符串
    return text;
}

#pragma mark - 微博列表标签点击,表情转换为空字串
+(NSString *)transformEmojiStringBlank:(NSString *)originalStr
{
    NSString *emojiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"face.plist"];
    NSMutableDictionary *emojiDic = [[NSMutableDictionary alloc] initWithContentsOfFile:emojiFilePath];
    
    NSString *emojialiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"aliInfo.plist"];
    NSDictionary *emojialiDic = [[NSDictionary alloc] initWithContentsOfFile:emojialiFilePath];
    [emojiDic addEntriesFromDictionary:emojialiDic];
    [emojialiDic release];
    NSString *text = originalStr;
    NSString *regex_emoji = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
    NSArray *array_emoji = [text componentsMatchedByRegex:regex_emoji];
    if ([array_emoji count]) {
        for (NSString *str in array_emoji) {
            NSRange range = [text rangeOfString:str];
            NSArray *keyArray = [emojiDic allKeysForObject:str];
            
            //如果没找到这个表情
            if (keyArray.count == 0)
            {
                
            }
            else
            {
                NSString *i_transCharacter = [keyArray objectAtIndex:0];
                if (i_transCharacter)
                {
                    NSString *imageHtml = [NSString stringWithFormat:@" "];
                    text = [text stringByReplacingCharactersInRange:NSMakeRange(range.location, [str length]) withString:imageHtml];
                }
            }
        }
    }
    
    [emojiDic release],emojiDic = nil;
    //返回转义后的字符串
    if ([text isEqualToString:@" "])
    {
        text = @"  ";
    }
    
    return text;
}

#pragma mark - 微博列表标签点击,转换为位置信息字符串
+(NSString *)transformToLocationStr:(NSString *)str
{
    NSString *lastStr = [str substringWithRange:NSMakeRange(str.length - 1, 1)];
    
    NSString *biaoDian = @"!;:\"\',.?！、；‘：“？，。、";
    
    NSString *locationStr;
    
    if ([biaoDian rangeOfString:lastStr].length > 0)
    {
         locationStr = [[NSString alloc] initWithFormat:@"%@我在这里:<Gyb_location>",str];
    }
    else
    {
         locationStr = [[NSString alloc] initWithFormat:@"%@,我在这里:<Gyb_location>",str];
    }

    return [locationStr autorelease];
}

#pragma mark - 微博列表标签点击,添加一个【观看直播】的按钮
+(NSString *)transformToLiveBtn:(NSString *)str
{
    NSString *locationStr = [[NSString alloc] initWithFormat:@"%@ [观看直播] ",str];
    return [locationStr autorelease];
}


+ (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string  WidthValue:(int)width
{
    if (string.length == 0)
    {
        return 20.0f;
    }

    int total_height = 0;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);    //string 为要计算高度的NSAttributedString
    CGRect drawingRect = CGRectMake(0, 0, width, 1000);  //这里的高要设置足够大
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    NSArray *linesArray = (NSArray *) CTFrameGetLines(textFrame);
    
    CGPoint origins[[linesArray count]];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    
    int line_y = (int) origins[[linesArray count] -1].y;  //最后一行line的原点y坐标
    
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    
    CTLineRef line = (CTLineRef) [linesArray objectAtIndex:[linesArray count]-1];
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    
    total_height = 1000 - line_y + (int) descent +1;    //+1为了纠正descent转换成int小数点后舍去的值
    
    CFRelease(textFrame);
    
    return total_height;
}

+(void)NSLogNowDate:(NSString*)theKey
{
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    
    NSInteger interval = [zone secondsFromGMTForDate: date];
    
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    if (theKey)
    {
        NSLog(@"%@ %@",localeDate,theKey);
    }

}

//根据用户id获取第三方授权
+(NSDictionary *)getAuthorInfoListFromByID:(NSString *)userId andThirdType:(NSString *)thirdType
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"authorInformation.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray = [NSMutableArray arrayWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
			if ([[uDict objectForKey:@"userid"] isEqualToString:userId] && [thirdType isEqualToString:[uDict objectForKey:kThirdPlatformType]])
            {
                return uDict;
			}
		}
        return nil;
    }
    else
    {
        //NSLOG(@"本地存储有错误");
        return nil;
    }
}


//保存用户得push信息
+(void)saveOrUpdateUserPushInfo:(NSDictionary*)userPushDict
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"push.plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray=[[NSMutableArray alloc] initWithContentsOfFile:fileDirectory];
		BOOL isExist=NO;
        
        NSString *userDictOfUserId = [userPushDict objectForKey:@"userid"];
        NSString *pushStatus = [userPushDict objectForKey:kPushStatus];
		for(NSDictionary *uDict in usersArray)
		{
            NSString *uDictOfUserId = [uDict objectForKey:@"userid"];
			if (userDictOfUserId  && [userDictOfUserId length] > 2 && [uDictOfUserId isEqualToString:userDictOfUserId])
            {
				isExist=YES;
                //存在就覆盖数据
                NSUInteger _replaceIndex = [usersArray indexOfObject:uDict];
                [usersArray replaceObjectAtIndex:_replaceIndex withObject:userPushDict];
                [usersArray writeToFile:fileDirectory atomically:YES];
				break;
			}
		}
		
		if (isExist ==  NO &&  userDictOfUserId && [userDictOfUserId length] > 2 && pushStatus)//不存在就add
        {
			[usersArray addObject:userPushDict];
			[usersArray writeToFile:fileDirectory atomically:YES];
		}
		[usersArray release];
	}
	else
    {
		NSArray *authorInfArray=[[NSArray alloc] initWithObjects:userPushDict,nil];
        NSString *userDictString = [userPushDict objectForKey:@"userid"];
        if (userDictString && [userDictString length] > 2)
        {
            [authorInfArray writeToFile:fileDirectory atomically:YES];
        }
        else
        {
            NSLog(@"saveAuthorInfo error.");
        }
		
		[authorInfArray release];
	}
}

//根据用户id获取push信息
+(NSDictionary *)getUserPushInfoListFromByID:(NSString *)userId
{
    NSArray *pathArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory=[pathArray objectAtIndex:0];
	NSString *fileDirectory=[documentDirectory stringByAppendingPathComponent:@"push.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
	{
		NSMutableArray *usersArray = [NSMutableArray arrayWithContentsOfFile:fileDirectory];
        for(NSDictionary *uDict in usersArray)
		{
			if ([[uDict objectForKey:@"userid"] isEqualToString:userId])
            {
                return uDict;
			}
		}
        return nil;
    }
    else
    {
        //NSLOG(@"本地存储有错误");
        return nil;
    }
}



+(NSString*)getDeviceToken
{
	NSString* token = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"];
	if (token && [token length])
	{
		return [NSString stringWithFormat:@"%@", token];
	}
	return nil;
}

+(void)setDeviceToken:(NSString *)deviceToken
{
    if (![self isBlankString:deviceToken])
	{
		NSString* savedToken = [Utility getDeviceToken];
		//没有或者不同
		if (savedToken == nil || (![savedToken isEqualToString:deviceToken]))
		{
			NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
			[userDefaults setObject:deviceToken forKey:kDeviceToken];
			[userDefaults synchronize];
		}
	}
}

//验证邮箱的合法性 
+(BOOL)isValidateEmail:(NSString *)email
{
    if (email == nil || [email length] == 0)
    {
        return NO;
    }
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
    
}
+(BOOL)isAudioFileExistsAtPath:(NSString*)audioString
{
    if (audioString  == nil ||  [audioString length] == 0)
    {
        return NO;
    }
    NSString *mainFilePath = [FileOperation getAudioPath:audioString];
    if (mainFilePath && [[NSFileManager defaultManager] fileExistsAtPath:mainFilePath])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (UILabel*)getTitleLabel
{
	UILabel *lbTitle = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 44)] autorelease];
	lbTitle.backgroundColor = [UIColor clearColor];
	lbTitle.font = [UIFont boldSystemFontOfSize:18];
	lbTitle.textAlignment = NSTextAlignmentCenter;
    lbTitle.textColor = ColorWithRGB(74, 74, 74);
    lbTitle.lineBreakMode = NSLineBreakByTruncatingTail;
	return lbTitle;
}


+ (NSInteger )stringContainsEmoji:(NSString *)string
{
    __block NSInteger returnValue = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs && hs <= 0xdbff) {
             if (substring.length > 1) {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc && uc <= 0x1f77f) {
                     returnValue = 2;
                 }
             }
         } else if (substring.length > 1) {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3) {
                 returnValue = 2;
             }
             
         } else {
             // non surrogate
             if (0x2100 <= hs && hs <= 0x27ff) {
                 returnValue = 1;
             } else if (0x2B05 <= hs && hs <= 0x2b07) {
                 returnValue = 1;
             } else if (0x2934 <= hs && hs <= 0x2935) {
                 returnValue = 1;
             } else if (0x3297 <= hs && hs <= 0x3299) {
                 returnValue = 1;
             } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                 returnValue = 1;
             }
         }
     }];
    
    return returnValue;
}


//根据当前时间获取一个数字
+(long long)getDateNumByCurrentDate
{
    NSDate *date = [NSDate date];
    
    NSTimeInterval interval = [date timeIntervalSince1970];
    
    NSLog(@"%.0f", interval*1000);
    return interval*1000;
}

//发送队列图片保存
+(NSString *)saveImageToQueueFile:(UIImage *)image
{
    NSString *filePath = [Utility getFilePathInOutboxWithExt:@"jpg"];
    
    NSData *imageData = UIImageJPEGRepresentation([Utility changeImageSizeWithOriginalImage:image percent:0.99], 0.4f);
    BOOL flag = [imageData writeToFile:filePath atomically:YES];
    if (flag)
    {
        return filePath;
    }
    else
    {
        return nil;
    }
}

//用于读取系统的图片文件
+(UIImage *)imageNamedWithFileName:(NSString *)fileName
{
    NSString *fileHead;
    NSString *fileType;
    if (![self isBlankString:fileName] && fileName.length >= 4)
    {
        fileHead = [fileName substringToIndex:fileName.length-4];
        fileType = [fileName substringFromIndex:fileName.length-3];
        NSString *newPath = [[NSBundle mainBundle] pathForResource:fileHead ofType:fileType];
        return [UIImage imageWithContentsOfFile:newPath];
    }
    else
    {
        return nil;
    }
}

//ios 8以后每次编译,文件路径会发生变化,为了简化获取路径,仅限NSDocumentDirectory路径，目前已经支持Library了
+(NSString *)handlePathOfLoacalFile:(NSString *)oldPath
{
    NSRange range = [oldPath rangeOfString:@"Documents"];
    
    NSRange rangeLibrary = [oldPath rangeOfString:@"Library"];

  //  NSRange rangeTemp = [oldPath rangeOfString:@"tmp"];
    
    if (range.length > 0)
    {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *newPath = [NSString stringWithFormat:@"%@%@",path,[oldPath substringFromIndex:range.location + range.length]];
        
        return newPath;
    }
    else
        if (rangeLibrary.length > 0)
        {
            NSString *path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
            NSString *newPath = [NSString stringWithFormat:@"%@%@",path,[oldPath substringFromIndex:rangeLibrary.location + rangeLibrary.length]];
            return newPath;
        }
        else
        {
            return oldPath;
        }
}


+(NSString *)retJsonFormatStr:(NSArray *)aImageUrlArray
{
    NSMutableString *imageUrls = [[NSMutableString alloc] initWithCapacity:0];
    for (int i = 0; i < aImageUrlArray.count; i++)
    {
        //push to json
        NSString *url = [aImageUrlArray objectAtIndex:i];
        NSString *str = [NSString stringWithFormat:@"{\"w\":\"0\",\"h\":\"0\",\"url\":\"%@\"}",url];
        if (imageUrls.length < 1)
        {
            [imageUrls appendString:str];
        }
        else
        {
            [imageUrls appendString:@","];
            [imageUrls appendString:str];
        }
    }
    return [NSString stringWithFormat:@"[%@]",(NSString *)imageUrls];
}

//携带分辨率的上个函数版本
+(NSString *)retJsonFormatStr:(NSArray *)aImageUrlArray withSizeArray:(NSMutableArray *)sizeArray
{
    NSMutableString *imageUrls = [[NSMutableString alloc] initWithCapacity:0];
    for (int i = 0; i < aImageUrlArray.count; i++)
    {
        //push to json
        NSString *url = [aImageUrlArray objectAtIndex:i];
        CGFloat width = [[sizeArray objectAtIndex:i*2] floatValue];
         CGFloat height = [[sizeArray objectAtIndex:i*2 + 1] floatValue];
        
        NSString *str = [NSString stringWithFormat:@"{\"w\":\"%f\",\"h\":\"%f\",\"url\":\"%@\"}",width,height,url];
        if (imageUrls.length < 1)
        {
            [imageUrls appendString:str];
        }
        else
        {
            [imageUrls appendString:@","];
            [imageUrls appendString:str];
        }
    }
    return [NSString stringWithFormat:@"[%@]",(NSString *)imageUrls];
}

#pragma mark - 获取Asset的地址
+(NSString *)getAssetPicUrlString:(ALAsset *)asset
{
    NSString *currentAssetUrl;
    NSDictionary *currentAssetDic = [asset valueForProperty:ALAssetPropertyURLs];
    
    if ([currentAssetDic allKeys].count > 0)
    {
        currentAssetUrl = [[currentAssetDic objectForKey:[[currentAssetDic allKeys] firstObject]] absoluteString];
    }
    else
    {
        currentAssetUrl = @"";
    }
    
    
//    if ([[currentAssetDic allKeys] containsObject:@"public.jpeg"])
//    {
//        currentAssetUrl = [[currentAssetDic objectForKey:@"public.jpeg"] absoluteString];
//    }
//    else
//    {
//        currentAssetUrl = [[currentAssetDic objectForKey:@"public.png"] absoluteString];
//    }
    
    return currentAssetUrl;
}


#pragma mark - 用于统计请求快慢的方法  
+(void)writeReqestTimeInfo:(NSDate *)beginTime endDate:(NSDate *)endDate fileSize:(NSInteger)fileSize urlStr:(NSString *)urlStr type:(NSString *)typeStr viewName:(NSString *)viewName
{
    //开始时间
    NSTimeInterval beginInterval = [beginTime timeIntervalSince1970];
    //结束时间
    NSTimeInterval endInterval = [endDate timeIntervalSince1970];
    //时间差
    //NSTimeInterval interval = [endDate timeIntervalSinceDate:beginTime];
    
//    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentDirectory = [pathArray objectAtIndex:0];
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *fileDirectory = [tmpDir stringByAppendingPathComponent:@"RequestTimeLog"];
    //用于写入的data
    NSMutableData *writerData = [[NSMutableData alloc] init];
    //用于记录旧的data
    NSData *readeData;
    //检查文件是否存在
    if([[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
    {
        readeData = [NSData dataWithContentsOfFile:fileDirectory];
        [writerData appendData:readeData];
    }
    
   // NSString *uniqueIdentifier = [[UIDevice currentDevice] timeUrlAndMacaddress:endInterval urlStr:urlStr];
    //界面名称,动作名称,开始时间,结束时间,文件大小,文件地址
//圈子,d,1448333897663,1448333911736,1024,http://api.cuctv.com/friendships/show.json?api_key=d586b060773e41
//圈子,d,1448444296.270756,1448444296.455535,6892,http://test.api.cuctv.com/netlive/4/1/getnetlivelistbytype.json?
    
    NSString *requestInfoStr = [NSString stringWithFormat:@"%@,%@,%ld,%ld,%ld,%@\n",viewName,typeStr,(NSInteger)beginInterval,(NSInteger)endInterval,fileSize,urlStr,nil];
    //NSLog(@"========%@",requestInfoStr);
    //NSLog(@"请求时间========%f",endInterval - beginInterval);
    [writerData appendData:[requestInfoStr dataUsingEncoding:NSUTF8StringEncoding]];
    [writerData writeToFile:fileDirectory atomically:YES];
    [writerData release];
}

#pragma mark - 计算字数的
+(NSInteger)checkStringSize:(NSString*)aString withTotleNum:(NSInteger)num
{
    NSString *string=[aString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string=[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSInteger currentStringSize = 0;
    currentStringSize = [self getStringLength:string];
    return (num - (NSInteger)currentStringSize);
}

+(NSUInteger)getStringLength:(NSString*)string
{
    NSUInteger asciiLength = 0;
    for (NSUInteger i = 0; i < string.length; i++) {
        unichar uc = [string characterAtIndex: i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    NSUInteger unicodeLength = asciiLength / 2;
    
    if(asciiLength % 2) {
        unicodeLength++;
    }
    return unicodeLength;
}

#pragma mark - 取得用户默认存储数据(字符串类型)
+(NSString *)getUserDefaultStringValueWithKey:(NSString *)keyStr
{
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:keyStr];
}

#pragma mark - 获取视频的截图
+(UIImage *)getVideoThumbnail:(NSURL *)videoURL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    //generator.maximumSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height);
    CMTime time = CMTimeMakeWithSeconds(1.0, 600);
    NSError *error2 = nil;
    CMTime actualTime;
    
    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error2];
    if (error2)
    {
        CGImageRelease(image);
        
        NSLog(@"图片截图出问题了");
        
        return nil;
    }
    UIImage *thumb = [[[UIImage alloc] initWithCGImage:image] autorelease];
    CGImageRelease(image);
    return thumb;
}

//获取视频截图2
+ (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[[AVURLAsset alloc] initWithURL:videoURL options:nil] autorelease];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[[AVAssetImageGenerator alloc] initWithAsset:asset] autorelease];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[[UIImage alloc] initWithCGImage:thumbnailImageRef] autorelease] : nil;
    
    return thumbnailImage;
}


+ (UIImage *)thumbnailFromVideoAtURL:(NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    //  Get thumbnail at the very start of the video
    CMTime thumbnailTime = [asset duration];
    thumbnailTime.value = 0;
    
    //  Get image from the video at the given time
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
     NSError *thumbnailImageGenerationError = nil;
    
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:thumbnailTime actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!imageRef)
    {
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return thumbnail;
}


+ (CGFloat)measureHeight:(UITextView *)textView
{
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
//    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
//    {
//        CGRect frame = textView.bounds;
//        CGSize fudgeFactor;
//        // The padding added around the text on iOS6 and iOS7 is different.
//        fudgeFactor = CGSizeMake(10.0, 16.0);
//        
//        frame.size.height -= fudgeFactor.height;
//        frame.size.width -= fudgeFactor.width;
//        
//        NSMutableAttributedString* textToMeasure;
//        if(textView.attributedText && textView.attributedText.length > 0){
//            textToMeasure = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
//        }
//        else
//        {
//            textToMeasure = [[NSMutableAttributedString alloc] initWithString:textView.text];
//            [textToMeasure addAttribute:NSFontAttributeName value:textView.font range:NSMakeRange(0, textToMeasure.length)];
//        }
//        
//        if ([textToMeasure.string hasSuffix:@"\n"])
//        {
//            [textToMeasure appendAttributedString:[[NSAttributedString alloc] initWithString:@"-" attributes:@{NSFontAttributeName: textView.font}]];
//        }
//        
//        // NSAttributedString class method: boundingRectWithSize:options:context is
//        // available only on ios7.0 sdk.
//        CGRect size = [textToMeasure boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
//                                                  options:NSStringDrawingUsesLineFragmentOrigin
//                                                  context:nil];
//        
//        return CGRectGetHeight(size) + fudgeFactor.height;
//    }
//    else
//    {
//        return textView.contentSize.height;
//    }
//#else
    return textView.contentSize.height;
//#endif
}


#define MAKE_Q(x) @#x
#define MAKE_EM(x,y) MAKE_Q(x##y)
#define MAKE_EMOJI(x) MAKE_EM(\U000,x)
#define EMOJI_METHOD(x,y) + (NSString *)x { return MAKE_EMOJI(y); } //method implementions at .m file
#define EMOJI_HMETHOD(x) + (NSString *)x;   //method define at .h file
#define EMOJI_CODE_TO_SYMBOL(x) ((((0x808080F0 | (x & 0x3F000) >> 4) | (x & 0xFC0) << 10) | (x & 0x1C0000) << 18) | (x & 0x3F) << 24);


//遍历拿到所有的表情
+(NSMutableArray *)getAllEmoji
{
    //列出所有的emoji
    NSMutableArray *aa = [NSMutableArray arrayWithCapacity:0];
    
    for (int i=0x1F600; i<=0x1F64F; i++)
    {
        if (i < 0x1F641 || i > 0x1F644)
        {
            [aa addObject:[self emojiWithCode:i]];
        }
    }
    
    for (int i=0x1F6A5; i<=0x1F6C5; i++)
    {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F300; i<=0x1F320; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F330; i<=0x1F335; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F337; i<=0x1F37C; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F380; i<=0x1F393; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F3A0; i<=0x1F3C4; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F3C6; i<=0x1F3CA; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F3E0; i<=0x1F3F0; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F400; i<=0x1F4FC; i++) {
        if (i==0x1F441 || i==0x1F43F || i==0x1F4F8) {
            continue;
        }
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F500; i<=0x1F53D; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F540; i<=0x1F543; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F550; i<=0x1F567; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F5FB; i<=0x1F5FF; i++) {
        [aa addObject:[self emojiWithCode:i]];
    }
    
    for (int i=0x1F680; i<=0x1F6A4; i++)
    {
        [aa addObject:[self emojiWithCode:i]];
    }
    return aa;
}

+ (NSString *)emojiWithCode:(int)code
{
    int sym = EMOJI_CODE_TO_SYMBOL(code);
    return [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
}


+ (NSString*)deviceModel
{
    NSString *model = [[UIDevice currentDevice] model];
    if ([model isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([model isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([model isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([model isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([model isEqualToString:@"iPhone3,3"])    return @"iPhone 4";
    if ([model isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([model isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([model isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([model isEqualToString:@"iPhone5,3"])    return @"iPhone 5c";
    if ([model isEqualToString:@"iPhone5,4"])    return @"iPhone 5c";
    if ([model isEqualToString:@"iPhone6,1"])    return @"iPhone 5s";
    if ([model isEqualToString:@"iPhone6,2"])    return @"iPhone 5s";
    if ([model isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([model isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([model isEqualToString:@"iPhone8,1"])    return @"iPhone 6s Plus";
    if ([model isEqualToString:@"iPhone8,2"])    return @"iPhone 6s";
    if ([model isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([model isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([model isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([model isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([model isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([model isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([model isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([model isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([model isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([model isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([model isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([model isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([model isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([model isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([model isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([model isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([model isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([model isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([model isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([model isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([model isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([model isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([model isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([model isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([model isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([model isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (Cellular)";
    if ([model isEqualToString:@"iPad6,8"])      return @"iPad Pro";
    if ([model isEqualToString:@"i386"])         return @"Simulator";
    if ([model isEqualToString:@"x86_64"])       return @"Simulator";
    return model;
}


//退出的时候清空cookie
+(void)cleanCookie
{
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *_tmpArray = [NSArray arrayWithArray:[cookieStorage cookies]];
    for (id obj in _tmpArray)
    {
        [cookieStorage deleteCookie:obj];
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_auth"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_headface"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_login_info"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_login_name"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_login_pwd"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"system_login_uid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//每次打开url的时候更新,获取cookie然后更新
+(void)updateCookie:(NSDictionary *)cookieDic withUrl:(NSString *)urlStr
{
    NSArray *allKeys = cookieDic.allKeys;
    
    NSNumber *sessionOnly = [NSNumber numberWithBool:NO];
    NSNumber *isSecure = [NSNumber numberWithBool:NO];
    
    if ([allKeys containsObject:@"system_headface"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_headface", [cookieDic objectForKey:@"system_headface"], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_headface"];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];

    }
    
    if ([allKeys containsObject:@"system_auth"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_auth", [[cookieDic objectForKey:@"system_auth"] stringValue], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_auth"];
        
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];
        
    }

    
    if ([allKeys containsObject:@"system_login_info"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_login_info", [cookieDic objectForKey:@"system_login_info"], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_login_info"];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];
    }
    
    if ([allKeys containsObject:@"system_login_name"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_login_name", [[cookieDic objectForKey:@"system_login_name"] stringByURLEncode], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_login_name"];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];

    }
    
    if ([allKeys containsObject:@"system_login_pwd"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_login_pwd", [cookieDic objectForKey:@"system_login_pwd"], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_login_pwd"];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];

    }
    
    if ([allKeys containsObject:@"system_login_uid"])
    {
        NSArray *cookies = [NSArray arrayWithObjects:@"system_login_uid", [cookieDic objectForKey:@"system_login_uid"], sessionOnly, @".cuctv.com", @"/", isSecure, nil];
        [[NSUserDefaults standardUserDefaults] setObject:cookies forKey:@"system_login_uid"];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        
        [cookieProperties setObject:[cookies objectAtIndex:0] forKey:NSHTTPCookieName];
        [cookieProperties setObject:[cookies objectAtIndex:1] forKey:NSHTTPCookieValue];
        [cookieProperties setObject:[cookies objectAtIndex:3] forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:urlStr forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:@"2117-12-01" forKey:NSHTTPCookieExpires];
        
        NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]  setCookie:cookieuser];

    }
}



@end


@implementation UIColor(myselfColor)

+(UIColor *)defaultBackgroundColor
{
    return [UIColor colorWithRed:kRED green:kGREEN blue:kBLUE alpha:kALPHA];
}
+(UIColor *)NavBarTitleColor
{
    return [UIColor colorWithRed:82.0/255.0 green:82.0/255.0 blue:82.0/255.0 alpha:1];
}
+(UIColor *)NavBarButtonColor
{
    return [UIColor whiteColor];
}
+(UIColor *)popViewTextNormalColor
{
    return [UIColor colorWithRed:102.0f/255.0f green:102.0f/255.0f blue:102.0f/255.0f alpha:1];
}
+(UIColor *)popViewTextSelectedColor
{
    return [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1];
}
+(UIColor *)popViewBackgroundColor
{
    return [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1];
}
+(UIColor *)popViewBackgroundColor1
{
    return [UIColor colorWithRed:187.0f/255.0f green:187.0f/255.0f blue:187.f/255.0f alpha:1];
}
+(UIColor *)messageSelectedColor
{
    return [UIColor colorWithRed:213.f/255.0f green:213.f/255.0f blue:213.f/255.0f alpha:1];
}
+(UIColor *)findFirendsBgColor
{
    return [UIColor colorWithRed:199.f/255.0f green:205.f/255.0f blue:208.f/255.0f alpha:1];
}
+(UIColor *)squareSearchBgColor
{
    return  [UIColor colorWithRed:222.0f/255.0f green:213.0f/255.0f blue:200.0f/255.0f alpha:1.0f];
}
//忘记密码字体颜色
+(UIColor *)forgetTextColor
{
    return  [UIColor colorWithRed:93.0f/255.0f green:93.0f/255.0f blue:93.0f/255.0f alpha:1.0f];
}
//默认背景色-土灰色
+(UIColor *)squareBgColor
{
    return [UIColor colorWithRed:247.0f/255.0f green:246.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
}

//213 207 203
+(UIColor *)upBgColor
{
    return [UIColor colorWithRed:213.0f/255.0f green:207.0f/255.0f blue:203.0f/255.0f alpha:1.0f];
}
//酒红色
+(UIColor *)redWineColor
{
    return  [UIColor colorWithRed:183.0f/255.0f green:47.0f/255.0f blue:37.0f/255.0f alpha:1.0f];
}
//灰色
+(UIColor *)defaultGrayColor
{
    return  [UIColor colorWithRed:102.0f/255.0f green:102.0f/255.0f blue:102.0f/255.0f alpha:1.0f];
}
//黑色
+(UIColor *)defaultBlackColor
{
    return  [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
}
//白色
+(UIColor *)defaultWhiteColor
{
    return  [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
}
//光标颜色
+(UIColor *)cursorColor
{
    return [UIColor colorWithRed:51.0f/255.0f green:80.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
}
//弹出分组未选文字颜色
+(UIColor *)popNoSelectColor
{
    return [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
}
//下拉刷新文字颜色
+(UIColor *)updateTextColor
{
    return [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
}
//未登录tab切换未选择文本颜色
+(UIColor *)nologinNormalTextColor
{
    return [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
}
+(UIColor *)tipsBackgroundColor
{
     return  [UIColor colorWithRed:218.0f/255.0f green:36.0f/255.0f blue:36.0f/255.0f alpha:0.6f];
}

+(UIColor *)backgroundGrayColor
{
    return  [UIColor colorWithRed:239.0f/255.0f green:236.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
}
//搜索活动界面laber背景色
+(UIColor *)searchbackgroundColor
{
    return  [UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
}
//发现页面cell线条颜色
+(UIColor *)discoveyCellLineColor
{
    return  [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0f];
}

//搜索页面分割线条颜色
+(UIColor *)seachSperatColor
{
    return  [UIColor colorWithRed:207.0f/255.0f green:207.0f/255.0f blue:207.0f/255.0f alpha:1.0f];
}

//发现页面字体颜色
+(UIColor *)discoveyfontColor
{
    return  [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
}

//发现页面话题字体颜色
+(UIColor *)discoveytopicColor
{
    return  [UIColor colorWithRed:122.0f/255.0f green:122.0f/255.0f blue:122.0f/255.0f alpha:1.0f];
}

//发现页面活动描述字体颜色
+(UIColor *)discoveyactivityDescColor
{
    return  [UIColor colorWithRed:102.0f/255.0f green:102.0f/255.0f blue:102.0f/255.0f alpha:1.0f];
}

+(UIColor *)actBackgroundColor
{
    return  [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f];
}
//搜索页面老红色字体颜色
+(UIColor *)discoverySearchRedColor
{
    return  [UIColor colorWithRed:186.0f/255.0f green:52.0f/255.0f blue:43.0f/255.0f alpha:1.0f];
}
//直播播放器工具条背景
+(UIColor *)liveVideoToolColor
{
    return  [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.8f];
}

//直播
+(UIColor *)liveVideoSelectBkColor
{
    return  [UIColor colorWithRed:239.0f/255.0f green:114.0f/255.0f blue:31.0f/255.0f alpha:1.0f];
}

//直播
+(UIColor *)liveVideolivingStatusColor
{
    return  [UIColor colorWithRed:250.0f/255.0f green:64.0f/255.0f blue:95.0f/255.0f alpha:1.0f];
}

//预告
+(UIColor *)liveVideofrontStatusColor
{
    return  [UIColor colorWithRed:251.0f/255.0f green:122.0f/255.0f blue:13.0f/255.0f alpha:1.0f];
}


@end



@implementation UIImage (Rotate_Flip)

+(UIImage *)rotateImage:(UIImage *)aImage with:(UIImageOrientation)theorient
{
    CGImageRef imgRef = aImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    UIImageOrientation orient = theorient;//aImage.imageOrientation;
    switch(orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}

+(UIImage *)fixOrientation:(UIImage *)aImage
{
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp){
        return aImage;
        
    }
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end




