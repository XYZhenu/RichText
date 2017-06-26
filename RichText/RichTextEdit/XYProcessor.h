//
//  XYProcessor.h
//  RichText
//
//  Created by xyzhenu on 2017/6/23.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface XYProcessor : NSObject
@property (nonatomic,strong)NSString* group;
@property (nonatomic,strong)NSString* identifier;

@property (nonatomic,strong)id msg;

-(void)start;
-(void)suspend;
-(void)cancel;

-(void)convertComplete:(void(^)(id newMsg))complete;


@property(nonatomic,strong)NSString* saveKey;
-(NSString*)save;
-(void)changeMsgKey:(NSString*)oldKey newKey:(NSString*)newKey;

-(void)processComplete:(void(^)(NSString* completeKey))complete;
@end



@class XYRichTextImage;
@interface ImageUploader : XYProcessor
@property (nonatomic,strong)XYRichTextImage* msg;
@end

NS_ASSUME_NONNULL_END
