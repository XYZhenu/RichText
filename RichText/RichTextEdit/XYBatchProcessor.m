//
//  XYBatchProcessor.m
//  RichText
//
//  Created by xyzhenu on 2017/6/22.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "XYBatchProcessor.h"
NSString* const keyNotificationXYBatchProcessorReturn = @"keyNotificationXYBatchProcessorReturn";
@interface XYBatchProcessor ()
@property(nonatomic,strong)NSMutableDictionary* processDic;
@property(nonatomic,strong)NSOperationQueue* processQueue;
@end
@implementation XYBatchProcessor
static XYBatchProcessor* processor = nil;
+(instancetype)instance{
    @synchronized(self) {
        if (!processor) {
            processor = [XYBatchProcessor new];
        }
    }
    return processor;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.processDic = [NSMutableDictionary dictionary];
        self.processQueue = [NSOperationQueue new];
    }
    return self;
}

-(NSString*)getUniqueId{
    return @"";
}
-(NSString*)batchProcessObjects:(NSArray*)objects convertor:(id(^)(id obj))convertor{
    NSString* identifier = [self getUniqueId];
    NSMutableArray *infoArr = [NSMutableArray array];
    for (NSInteger i = 0; i < objects.count; i++) { [infoArr addObject:@1]; }
    self.processDic[identifier] = objects;
    for (NSInteger i = 0; i < objects.count; i++) {
        [self.processQueue addOperationWithBlock:^{
            [self processObject:convertor(objects[i]) complete:^(id msg) {
                [infoArr replaceObjectAtIndex:i withObject:msg];
                for (id item in infoArr) { if ([item isKindOfClass:[NSNumber class]]) return; }
                [self processCompleteId:identifier result:infoArr];
            }];
        }];
    }
    return identifier;
}
-(void)saveObject:(id)object complete:(void(^)(NSString* retriveid))complete{
    
}
-(void)retriveObjectforId:(NSString*)retriveid complete:(void(^)(id retriveObj))complete{
    
}
-(id<XYBatchProcessorCancelable>)processObject:(id)object complete:(void(^)(id msg))complete{
    return nil;
}

-(void)processCompleteId:(NSString*)identifier result:(NSArray*)result {
    
}
@end
