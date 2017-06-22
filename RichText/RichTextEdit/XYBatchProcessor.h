//
//  XYBatchProcessor.h
//  RichText
//
//  Created by xyzhenu on 2017/6/22.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString* const keyNotificationXYBatchProcesserReturn;
@protocol XYBatchProcessorCancelable <NSObject>
-(void)cancel;
@end
@interface XYBatchProcessor : NSObject
+(instancetype)instance;
-(NSString*)batchProcessObjects:(NSArray*)objects;

-(void)suspend:(NSString*)identifier;
-(void)cancel:(NSString*)identifier;


-(void)convertObject:(id)obj complete:(void(^)(id obj))complete;

-(void)saveObject:(id)object complete:(void(^)(NSString* retriveid))complete;
-(void)retriveObjectforId:(NSString*)retriveid complete:(void(^)(id retriveObj))complete;

-(id<XYBatchProcessorCancelable>)processObject:(id)object complete:(void(^)(id msg))complete;

-(void)processCompleteId:(NSString*)identifier result:(NSArray*)result;
@end

@class XYRichTextImage;
@interface XYImageUploader : XYBatchProcessor
-(NSString*)batchProcessObjects:(NSArray<XYRichTextImage*>*)objects;



-(void)convertObject:(XYRichTextImage*)obj complete:(void(^)(NSData* obj))complete;
-(void)saveObject:(id)object complete:(void(^)(NSString* retriveid))complete;
-(void)retriveObjectforId:(NSString*)retriveid complete:(void(^)(id retriveObj))complete;
-(id<XYBatchProcessorCancelable>)processObject:(id)object complete:(void(^)(id msg))complete;

-(void)processCompleteId:(NSString*)identifier result:(NSArray*)result;
@end
