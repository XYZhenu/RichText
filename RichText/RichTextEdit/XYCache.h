//
//  XYCache.h
//  RichText
//
//  Created by xyzhenu on 2017/6/22.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface XYCache : NSObject

+(void)saveArray:(NSArray*)array key:(NSString*)key group:(NSString*)group;
+(void)saveDictionary:(NSDictionary*)dic key:(NSString*)key group:(NSString*)group;
+(void)saveString:(NSString*)string key:(NSString*)key group:(NSString*)group;
+(void)saveData:(NSData*)data    key:(NSString*)key group:(NSString*)group;
+(void)saveImage:(UIImage*)image key:(NSString*)key group:(NSString*)group;
+(void)saveAsset:(PHAsset*)asset key:(NSString*)key group:(NSString*)group;

+(NSArray*)arrayForKey:(NSString*)key group:(NSString*)group;
+(NSDictionary*)dicForKey:(NSString*)key group:(NSString*)group;
+(NSString*)stringForKey:(NSString*)key group:(NSString*)group;
+(NSData*)dataForKey:(NSString*)key group:(NSString*)group;
+(UIImage*)imageForKey:(NSString*)key group:(NSString*)group;

+(void)deleteKey:(NSString*)key group:(NSString*)group;

@end
