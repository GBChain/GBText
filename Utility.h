//
//  Utility.h
//  CuctvWeibo
//
//  Created by miti on 11-9-14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/sockio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <netdb.h>
#include <errno.h>
#include <sys/sysctl.h>
#import "Person.h"
#import "LoginInfo.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define RGB(A,B,C) [UIColor colorWithRed:A/255.0 green:B/255.0 blue:C/255.0 alpha:1.0] 

@interface Utility : NSObject {

}

+ (UIImage *) createRoundedRectImage:(UIImage*)image size:(CGSize)size roundSize:(CGSize)roundSize;
+(UIImage*) circleImage:(UIImage*) image;
+(NSString*)chineseWeekMark:(SInt8)day;

+(void)getHUDWithView:(UIView*)view target:(id)delegate info:(NSString *)Str;
+(void)getErrorHUDWithView:(UIView*)view target:(id)delegate;
+(void)ATMHudWithView:(UIView*)view target:(id)delegate wrongInfo:(NSString *)Str;
+(UIImage*)changeImageSizeWithOriginalImage:(UIImage*)image percent:(float)percent;
+(UIImage*)changeImageSizeWithOriginalImage:(UIImage*)image percentX:(float)percentX percentY:(float)percentY;
+(NSString*)getFilePathInOutboxWithExt:(NSString*)file_ext;
+(NSString*)getFilePathInOutboxWithExtAndMarked:(NSString*)file_ext andMark:(NSString *)mark;
+(NSData *)subdataWithRange:(NSRange)range filePath:(NSString*)filePath;
+(NSUInteger)getFileArrayLengthByPath:(NSArray*)filePathArray;
+(NSUInteger)getFileLengthByPath:(NSString*)filePath;
+(NSData *)getDataByPath:(NSString *)filePath;
+(float)getImageHeightByDisplayWidth:(float)width ori_width:(float)ori_width ori_height:(float)ori_height;
+(UILabel*)getTitleLabelWithText:(NSString*)text;
+(NSString*)getImageUrl:(NSString*)ori_url Width:(int)width height:(int)height;
+(NSDictionary*)getFaceDict;
+(NSDictionary*)getDefaultFaceDict;

+(NSArray*)getEmojiFaceArray;
+(CGRect)findRightRect:(UIImage*)image maxWidth:(float)mWidth maxHeight:(float)mHeight containerWidth:(float)cWidth containerHeight:(float)cHeight;

+(BOOL)checkConnection:(NSString*)url;
+(NSString *)getAppID;
+ (NSString*)IPAddress;
+(NSString *)MacAddress;
+(NSString*)getAppVersion;
+(void)showWeiPai:(id)target;
+(void)showWeiZhiBo:(id)target;
+(NSString *)clipImageToSpecifiedSize:(NSString *)ori_url Width:(int)width height:(int)height;
+(NSString *)clipImageToSpecifiedSize2:(NSString *)ori_url Width:(int)width height:(int)height;
//截取一部分图片
+ (UIImage *)clipFromImage:(UIImage *)image inRect:(CGRect)rect;
+(NSString *)changeUrlToTestUrl:(NSString *)imageUrl;
+(NSString*)getADPictureUrl:(NSString*)ori_url Width:(int)width height:(int)height;
+(NSString*)clipHeaderImageToSpecifiedSize:(NSString*)ori_url Width:(int)width height:(int)height;
+(NSString*)compressionImageToSpecifiedSize:(NSString*)ori_url withFunctionStr:(NSString *)functionStr;

+(NSString *)cancelClipImageToSpecifiedSize:(NSString *)ori_url;

+(NSString*)getImageNoSpecifiedSize:(NSString*)ori_url;
+(void)alert:(NSString*)title message:(NSString*)message delegate:(id)delegate tag:(int)tag;
+(NSString *)getDocumentPath:(NSString*)strName;
//用于合并文件地址并用,隔开
+(NSString *)retAllFilePath:(NSArray *)array;
+(NSString*)getCurrentTimeStrForDraft; //草稿箱使用
+(NSString*)getCurrentTimeStr;
+(NSString*)getFilePathWithExt:(NSString*)file_ext;
+(BOOL)deleteFile:(NSString*)file_path;
+(BOOL)saveFileToDisk:(NSData*)file_data withFilePath:(NSString*)file_path;
+(BOOL)saveFileToDisk:(NSData *)file_data withFilePath:(NSString *)file_path andWithError:(NSError **)aError;
+(void)showNoticeAlert:(NSString*)strNotice;
+(void)showNoticeAlert:(NSString*)strNotice afterDelay:(float)theTime;
+(void)dismissNoticeAlert:(UIAlertView*)noticeAlert;
+ (NSString*)URLencode:(NSString *)originalString stringEncoding:(NSStringEncoding)stringEncoding;
+ (NSString *)URLEncodedString:(NSString *)resultStr;
+(NSUInteger) unicodeLengthOfString: (NSString *) text;
+(NSInteger)checkStringCharCount:(NSString*)string;
//是否是合法的手机号,满足两个条件,11位,前三位正确
+(BOOL)checkisChinaMobile:(NSString *)mobileNumberString;
//检查是否是手机号
+ (BOOL)isMobileNumber:(NSString *)mobileNum;

+(BOOL)checkNetWorkIsWifi;
+(NSString *)getStatString;
+(BOOL)isFirstRunApp;

+(BOOL)isBlankString:(NSString *)string;

+(NSString *)replacePersonID:(NSString *)_str;

+(BOOL)isUserHasLogin;//是否已经登录

+ (NSInteger)checkStringSize:(NSString*)string;

+(NSString *)calculateAgeByDateString:(NSString *)dateStr;

+(NSString *)calculateAstrologicalByDateString:(NSString *)dateStr;
+(NSString*)getOutboxPath;

+(NSString *)get9SecVideoPath;

//根据用户id获取用户资料
+(NSDictionary *)getUserInfoFromListByID:(NSString *)userId;
//根据第三方userId寻找第三方登录的用户
+(NSDictionary *)getUserInfoFromListByThirdID:(NSString *)userId;

+(NSString*)backgroundImgIndex;
//个人信息处理
+(Person *)parsePersoninfo:(NSDictionary *)personDic;

//更新用户信息时使用
+(void)updateUserPlistByUserId:(NSString *)userId userInfo:(Person *)userInfo;
+(void)updateUserPlistByUserId2:(NSString *)userId userInfo:(Person *)userInfo withThirdId:(NSString *)thirdId withSinaDic:(NSDictionary *)sinaDic withSinaName:(NSString *)sinaName thirdPlatFlag:(NSString *)platFlag;

//添加帐号使用,包括userdefault和plist
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr;

+(void)saveLoginInfo:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict;
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr withLiveIco:(NSString *)liveIcoStr backgroundImgIndex:(NSString*)indexStr;

+(void)saveLoginInfo2:(LoginInfo *)loginInfo oldDict:(NSDictionary*)theDict;
+(void)saveLoginInfo2:(LoginInfo *)loginInfo password:(NSString *)passwordStr withLiveIco:(NSString *)liveIcoStr withThirdId:(NSString *)thirdId withSinaDic:(NSDictionary *)sinaDic withSinaName:(NSString *)sinaName  thirdPlatFlag:(NSString *)platFlag backgroundImgIndex:(NSString*)indexStr;

//第三方绑定的时候调用3
//+(void)saveLoginInfo3:(NSDictionary *)userDic password:(NSString *)passwordStr withLiveIco:(NSString *)liveIcoStr withThirdId:(NSString *)thirdId withSinaDic:(NSDictionary *)sinaDic withSinaName:(NSString *)sinaName;

//第三方帐号登录使用
+(void)saveLoginInfo:(LoginInfo *)loginInfo password:(NSString *)passwordStr withThirdUserId:(NSString *)useId withSinaDic:(NSDictionary *)dic;

//plist
+(void)saveUserAccount:(NSDictionary*)userDict;
//设置当前帐号,userdict是从plist中拿出来的
+(void)setCurrentAccount:(NSDictionary*)userDict;
//更新LiveICO属性
+(void)updateUserPlistLiveICO;
//有多少个用户
+(NSInteger)userListNum;
//得到某个用户的信息
+(Person *)getPersonInfoByUserId:(NSString *)userIdStr;

//文字处理
+(NSString *)transformToEmojiString:(NSString *)originalStr;
+(NSString *)transformEmojiStringBlank:(NSString *)originalStr;
+(NSString *)transformToLocationStr:(NSString *)str;
+(NSString *)transformToLiveBtn:(NSString *)str;

+(CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string WidthValue:(int)width;

+(void)NSLogNowDate:(NSString*)theKey;
//保存用户得推送信心
+(void)saveOrUpdateUserPushInfo:(NSDictionary*)userPushDict;
////根据用户id获取push信息
+(NSDictionary *)getUserPushInfoListFromByID:(NSString *)userId;
//第三方分享帐号管理
//+(void)saveAuthorInfo:(NSDictionary*)userDict;
//+(void)setCurrentAccountAuthorInfo;
//+(void)saveRenrenUserSessionInfo:(NSDictionary *)dic;
+(NSDictionary *)getAuthorInfoListFromByID:(NSString *)userId andThirdType:(NSString *)thirdType;

+(NSString*)getDeviceToken;
+(void)setDeviceToken:(NSString *)deviceToken;

//验证邮箱的合法性
+(BOOL)isValidateEmail:(NSString *)email;

//语音文件是否已读
+(BOOL)isAudioFileExistsAtPath:(NSString*)audioString;

//导航条标题
+ (UILabel*)getTitleLabel;

+ (NSInteger)stringContainsEmoji:(NSString *)string;

//根据当前时间获取一个数字
+(long long)getDateNumByCurrentDate;

//发送队列图片保存
+(NSString *)saveImageToQueueFile:(UIImage *)image;

//用于读取系统的图片文件
+(UIImage *)imageNamedWithFileName:(NSString *)fileName;

//ios 8以后每次编译,文件路径会发生变化,为了简化获取路径
+(NSString *)handlePathOfLoacalFile:(NSString *)oldPath;


//是否同一分钟
+(BOOL)isSameTime_min:(NSString *)lastTime currentTime:(NSString *)currentTime;

//将时间转化为当前时间对比后的时间
+(NSString *)handleDate:(NSString *)dataStr;

//将时间转化为当前时间对比后的时间
+(NSString *)handleDateInPrivateMessage:(NSString *)dataStr;


//多图的时候上传服务器转换为json字符串
+(NSString *)retJsonFormatStr:(NSArray *)aImageUrlArray;

+(NSString *)retJsonFormatStr:(NSArray *)aImageUrlArray withSizeArray:(NSMutableArray *)sizeArray;


#pragma mark - 获取Asset的地址
+(NSString *)getAssetPicUrlString:(ALAsset *)asset;

#pragma mark - 计算字数的
+(NSInteger)checkStringSize:(NSString*)aString withTotleNum:(NSInteger)num;
+(NSUInteger)getStringLength:(NSString*)string;


//取得通讯录信息到数组中
+(int)getAddressBookToArray:(NSMutableArray*)theArray;

#pragma mark - 取得用户默认存储数据(字符串类型)取得userDefault的字符串
+(NSString *)getUserDefaultStringValueWithKey:(NSString *)keyStr;

#pragma mark - 获取视频的截图
+(UIImage *)getVideoThumbnail:(NSURL *)videoURL;
//获取视频截图2
+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

+ (UIImage *)thumbnailFromVideoAtURL:(NSURL *)url;

//用来计算uitextview的高度
+ (CGFloat)measureHeight:(UITextView *)textView;


//遍历拿到所有的表情
+(NSMutableArray *)getAllEmoji;

+(void)writeReqestTimeInfo:(NSDate *)beginTime endDate:(NSDate *)endDate fileSize:(NSInteger)fileSize urlStr:(NSString *)urlStr type:(NSString *)typeStr viewName:(NSString *)viewName;

+(UIImage*)getSubImage:(UIImage *)image mCGRect:(CGRect)mCGRect centerBool:(BOOL)centerBool;


+(NSString*)deviceModel;

+(NSDictionary *)addExtraInfoToRequest:(NSInteger)netType;


//退出的时候清空cookie
+(void)cleanCookie;
//每次打开url的时候更新,获取cookie然后更新
+(void)updateCookie:(NSDictionary *)cookieDic withUrl:(NSString *)urlStr;

@end
#pragma mark - 
#pragma mark -

@interface UIColor(myselfColor)
+(UIColor *)defaultBackgroundColor;
+(UIColor *)NavBarTitleColor;
+(UIColor *)NavBarButtonColor;
+(UIColor *)popViewTextNormalColor;
+(UIColor *)popViewTextSelectedColor;
+(UIColor *)popViewBackgroundColor;
+(UIColor *)popViewBackgroundColor1;
+(UIColor *)messageSelectedColor;
+(UIColor *)findFirendsBgColor;
+(UIColor *)squareSearchBgColor;
+(UIColor *)forgetTextColor;
+(UIColor *)squareBgColor;
+(UIColor *)upBgColor;
+(UIColor *)redWineColor;
+(UIColor *)defaultGrayColor;
+(UIColor *)defaultBlackColor;
+(UIColor *)defaultWhiteColor;
+(UIColor *)cursorColor;
+(UIColor *)popNoSelectColor;
+(UIColor *)updateTextColor;
+(UIColor *)nologinNormalTextColor;
+(UIColor *)tipsBackgroundColor;
+(UIColor *)backgroundGrayColor;
+(UIColor *)searchbackgroundColor;
+(UIColor *)discoveyCellLineColor;
+(UIColor *)actBackgroundColor;
+(UIColor *)discoveyfontColor;
+(UIColor *)discoveytopicColor;
+(UIColor *)discoveyactivityDescColor;
+(UIColor *)discoverySearchRedColor;
+(UIColor *)seachSperatColor;
+(UIColor *)liveVideoToolColor;
+(UIColor *)liveVideoSelectBkColor;
+(UIColor *)liveVideolivingStatusColor;
+(UIColor *)liveVideofrontStatusColor;

@end

@interface UIImage (Rotate_Flip)

+(UIImage *)rotateImage:(UIImage *)aImage with:(UIImageOrientation)theorient;
+(UIImage *)fixOrientation:(UIImage *)aImage;
@end

