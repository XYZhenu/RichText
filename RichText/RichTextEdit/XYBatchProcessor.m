//
//  XYBatchProcessor.m
//  RichText
//
//  Created by xyzhenu on 2017/6/22.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "XYBatchProcessor.h"
NSString* const keyNotificationXYBatchProcessorReturn = @"keyNotificationXYBatchProcessorReturn";
typedef NS_ENUM(NSUInteger,_XYProcessStatus) {
    _XYProcessStatusRunning,
    _XYProcessStatusCanceled,
    _XYProcessStatusSuspended,
    _XYProcessStatusDone,
};
@interface _XYBatchProcessorModel : NSObject
@property(nonatomic,assign)_XYProcessStatus status;

@property(nonatomic,strong)NSMutableArray* batchResults;
@property(nonatomic,strong)NSMutableArray* batchCaches;
@property(nonatomic,strong)NSString* batchIdentifier;

@property(nonatomic,assign)NSInteger index;
@property(nonatomic,strong)id msg;
+(instancetype)model:(NSMutableArray*)results caches:(NSMutableArray*)caches ident:(NSString*)ident msg:(id)msg  index:(NSInteger)index;
@end
@implementation _XYBatchProcessorModel
+(instancetype)model:(NSMutableArray*)results caches:(NSMutableArray*)caches ident:(NSString*)ident msg:(id)msg  index:(NSInteger)index{
    _XYBatchProcessorModel* model = [_XYBatchProcessorModel new];
    model.batchResults = results;
    model.batchCaches = caches;
    model.batchIdentifier = ident;
    model.msg = msg;
    model.index = index;
    model.status = _XYProcessStatusRunning;
    return model;
}
@end
@interface XYBatchProcessor ()
@property(nonatomic,strong)NSMutableDictionary<NSString*,NSMutableArray<_XYBatchProcessorModel*>*>* processDic;
@property(nonatomic,strong)NSOperationQueue* processQueue;
@property (nonatomic, assign) NSUInteger objCount;
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
        self.objCount = 0;
    }
    return self;
}

-(NSString*)getUniqueId{
    self.objCount ++;
    return [NSString stringWithFormat:@"XYBatchProcess_%ld",(unsigned long)self.objCount];
}
-(NSString*)batchProcessObjects:(NSArray*)objects{
    NSString* identifier = [self getUniqueId];
    NSMutableArray *infoArr = [NSMutableArray array];
    for (NSInteger i = 0; i < objects.count; i++) { [infoArr addObject:@1]; }
    NSMutableArray *cacheArray = infoArr.mutableCopy;
    NSMutableArray *modelArray = [NSMutableArray arrayWithCapacity:objects.count];
    for (NSInteger i = 0; i < objects.count; i++) {
        _XYBatchProcessorModel* model = [_XYBatchProcessorModel model:infoArr caches:cacheArray ident:identifier msg:objects[i] index:i];
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ConvertModel:) object:model];
        [self.processQueue addOperation:oper];
        [modelArray addObject:model];
    }
    self.processDic[identifier] = modelArray;
    return identifier;
}

-(void)suspend:(NSString*)identifier{
    [self.processQueue setSuspended:YES];
    
}
-(void)cancel:(NSString*)identifier{
    
}
-(void)saveSatus:(NSString*)identifier{
    
}

-(void)_ConvertModel:(_XYBatchProcessorModel*)model{
    [self convertObject:model.msg complete:^(id obj) {
        model.msg = obj;
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessModel:) object:model];
        [self.processQueue addOperation:oper];
        NSInvocationOperation * oper1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_SaveModel:) object:model];
        [self.processQueue addOperation:oper1];
    }];
}
-(void)convertObject:(id)obj complete:(void (^)(id))complete{
    
}

-(void)_SaveModel:(_XYBatchProcessorModel*)model{
    [self saveObject:model.msg complete:^(NSString *retriveid) {
        [model.batchCaches replaceObjectAtIndex:model.index withObject:retriveid];
        for (id item in model.batchCaches) { if ([item isKindOfClass:[NSNumber class]]) return; }
        
    }];
}
-(void)saveObject:(id)object complete:(void(^)(NSString* retriveid))complete{
    
}


-(void)retriveObjectforId:(NSString*)retriveid complete:(void(^)(id retriveObj))complete{
    
}


-(void)_ProcessModel:(_XYBatchProcessorModel*)model {
    [self processObject:model.msg complete:^(id msg) {
        [model.batchResults replaceObjectAtIndex:model.index withObject:msg];
        model.status = _XYProcessStatusDone;
        for (id item in model.batchResults) { if ([item isKindOfClass:[NSNumber class]]) return; }
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessComplete:) object:model];
        [self.processQueue addOperation:oper];
    }];
}
-(id<XYBatchProcessorCancelable>)processObject:(id)object complete:(void(^)(id msg))complete{
    return nil;
}


-(void)_ProcessComplete:(_XYBatchProcessorModel*)model{
    [self processCompleteId:model.batchIdentifier result:model.batchResults];
    
}
-(void)processCompleteId:(NSString*)identifier result:(NSArray*)result {
    
}
@end
