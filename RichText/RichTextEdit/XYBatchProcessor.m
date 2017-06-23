//
//  XYBatchProcessor.m
//  RichText
//
//  Created by xyzhenu on 2017/6/22.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "XYBatchProcessor.h"
#import "XYCache.h"

NSString* const keyNotificationXYBatchProcessorReturn = @"keyNotificationXYBatchProcessorReturn";

typedef NS_ENUM(NSUInteger,_XYProcessStatus) {
    _XYProcessStatusRunning,
    _XYProcessStatusCanceled,
    _XYProcessStatusSuspended,
    _XYProcessStatusDone,
};

@interface _XYBatchProcessorModel : NSObject

@property(nonatomic,strong)NSString* batchIdentifier;

@property(nonatomic,assign)_XYProcessStatus status;

@property(nonatomic,strong)NSString* retriveId;
@property(nonatomic,strong)NSString* processedId;
@property(nonatomic,strong)id msg;

@property(nonatomic,weak)id<XYBatchProcessorCancelable>processOperation;
-(NSDictionary*)descriptionDic;
-(void)setDescriptionDic:(NSDictionary*)dic;
@end

@implementation _XYBatchProcessorModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = _XYProcessStatusRunning;
    }
    return self;
}
-(NSDictionary*)descriptionDic{
    return @{
             @"retriveid":(self.retriveId?self.retriveId:@""),
             @"processedid":(self.processedId?self.processedId:@""),
             };
}
-(void)setDescriptionDic:(NSDictionary*)dic{
    self.processedId = ((NSString*)dic[@"processedid"]).length > 0 ? dic[@"processedid"] : nil;
    self.retriveId = ((NSString*)dic[@"retriveid"]).length > 0 ? dic[@"retriveid"] : nil;
}
@end


@interface XYBatchProcessor ()
@property(nonatomic,strong)NSMutableDictionary<NSString*,NSMutableArray<_XYBatchProcessorModel*>*>* processDic;
@property(nonatomic,strong)NSMutableDictionary*saveCompleteHandlers;
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
        self.saveCompleteHandlers = [NSMutableDictionary dictionary];
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
    NSMutableArray *modelArray = [NSMutableArray arrayWithCapacity:objects.count];
    self.processDic[identifier] = modelArray;
    for (NSInteger i = 0; i < objects.count; i++) {
        _XYBatchProcessorModel* model = [_XYBatchProcessorModel new];
        model.batchIdentifier = identifier;
        model.msg = objects[i];
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ConvertModel:) object:model];
        [self.processQueue addOperation:oper];
        [modelArray addObject:model];
    }
    return identifier;
}

#pragma mark -- operation control
-(void)suspend:(NSString*)identifier{
    NSArray* array = self.processDic[identifier];
    for (_XYBatchProcessorModel*model in array) {
        if (model.status != _XYProcessStatusDone) model.status = _XYProcessStatusSuspended;
    }
    [self saveSatus:identifier];
}
-(void)deleteId:(NSString*)identifier{
    NSArray* array = self.processDic[identifier];
    for (_XYBatchProcessorModel*model in array) {
        if (model.retriveId) [self removeObjectForId:model.retriveId];
    }
    [self cleanIdentifier:identifier];
}
-(void)saveSatus:(NSString*)identifier{
    if ([self isSavedOf:identifier]) {
        [self saveStatusToDisk:identifier];
    }else{
        __weak typeof(self) weakself = self;
        [self.saveCompleteHandlers setValue:^void(){ [weakself saveStatusToDisk:identifier]; } forKey:identifier];
    }
}
-(void)saveStatusToDisk:(NSString*)identifier{
    NSArray<_XYBatchProcessorModel*>* processArray = self.processDic[identifier];
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:processArray.count];
    
    for (int i=0; i<processArray.count; i++) {
        [array addObject:[processArray[i] descriptionDic]];
    }
    
    [XYCache saveArray:array key:identifier group:@"batchProcesser"];
}
-(BOOL)isSavedOf:(NSString*)identifier{
    NSArray* array = self.processDic[identifier];
    for (_XYBatchProcessorModel*model in array) {
        if (!model.retriveId) return NO;
    }
    return YES;
}

-(void)resume:(NSString*)identifier{
    NSArray<_XYBatchProcessorModel*>*models = self.processDic[identifier];
    if (models) {
        BOOL iscomplete = YES;
        for (_XYBatchProcessorModel*model in models) {
            if (model.status == _XYProcessStatusDone) continue;
            model.status = _XYProcessStatusRunning;
            if (!model.processOperation && !model.processedId) {
                [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessModel:) object:model]];
            }
            iscomplete = NO;
        }
        for (_XYBatchProcessorModel* item in models) { if (!item.processedId) return; }
        for (_XYBatchProcessorModel* item in models) {
            if (!item.retriveId) {
                __weak typeof(self) weakself = self;
                [self.saveCompleteHandlers setValue:^void(){ [weakself _ProcessComplete:identifier]; } forKey:identifier];
                return;
            }
        }
        [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessComplete:) object:identifier]];
    }else{
        NSArray* operationarray = [XYCache arrayForKey:identifier group:@"batchProcesser"];
        if (operationarray) {
            NSMutableArray *modelArray = [NSMutableArray arrayWithCapacity:operationarray.count];
            self.processDic[identifier] = modelArray;
            for (NSInteger i = 0; i < operationarray.count; i++) {
                _XYBatchProcessorModel* model = [_XYBatchProcessorModel new];
                model.batchIdentifier = identifier;
                [model setDescriptionDic:operationarray[i]];
                
                NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_RetriveModel:) object:model];
                [self.processQueue addOperation:oper];
                [modelArray addObject:model];
            }
        }
    }
}

-(void)cleanIdentifier:(NSString*)identifier{
    NSArray* operationarray = self.processQueue.operations;
    for (NSOperation*oper in operationarray) {
        if ([oper.name hasPrefix:identifier]) {
            [oper cancel];
        }
    }
    NSArray* array = self.processDic[identifier];
    for (_XYBatchProcessorModel*model in array) {
        [model.processOperation cancel];
    }
    [self.processDic removeObjectForKey:identifier];
}

#pragma mark -- convert model
-(void)_ConvertModel:(_XYBatchProcessorModel*)model{
    [self convertObject:model.msg complete:^(id obj) {
        model.msg = obj;
        [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_SaveModel:) object:model]];
        if (model.status==_XYProcessStatusSuspended) return;
        [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessModel:) object:model]];
    }];
}
-(void)convertObject:(id)obj complete:(void (^)(id))complete{
    
}



#pragma mark -- save retrive delete locally
-(void)_SaveModel:(_XYBatchProcessorModel*)model{
    [self saveObject:model.msg complete:^(NSString *retriveid) {
        model.retriveId = retriveid;
        NSArray* models = self.processDic[model.batchIdentifier];
        
        for (_XYBatchProcessorModel* item in models) { if (!item.retriveId) return; }
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveComplete:) object:model.batchIdentifier];
        [self.processQueue addOperation:oper];
        
        for (_XYBatchProcessorModel* item in models) { if (!item.processedId) return; }
        NSInvocationOperation * oper1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessComplete:) object:self.processDic[model.batchIdentifier]];
        [self.processQueue addOperation:oper1];
        
    }];
}
-(void)saveObject:(id)object complete:(void(^)(NSString* retriveid))complete{
    
}
-(void)saveComplete:(NSString*)identifier{
    if (self.saveCompleteHandlers[identifier]) {
        ((void(^)())self.saveCompleteHandlers[identifier])();
        [self.saveCompleteHandlers removeObjectForKey:identifier];
    }
}



-(void)_RetriveModel:(_XYBatchProcessorModel*)model{
    [self retriveObjectforId:model.retriveId complete:^(id retriveObj) {
        model.msg = retriveObj;
        [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessModel:) object:model]];
    }];
}
-(void)retriveObjectforId:(NSString*)retriveid complete:(void(^)(id retriveObj))complete{
    
}

-(void)removeObjectForId:(NSString*)retriveid{
    
}


#pragma mark -- process model
-(void)_ProcessModel:(_XYBatchProcessorModel*)model {
    if (model.status!=_XYProcessStatusRunning) return;
    model.processOperation = [self processObject:model.msg complete:^(id msg) {
        model.processedId = msg;
        model.status = _XYProcessStatusDone;
        NSArray* models = self.processDic[model.batchIdentifier];
        for (_XYBatchProcessorModel* item in models) { if (!item.processedId) return; }
        for (_XYBatchProcessorModel* item in models) { if (!item.retriveId) return; }
        NSInvocationOperation * oper = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_ProcessComplete:) object:self.processDic[model.batchIdentifier]];
        [self.processQueue addOperation:oper];
    }];
}
-(id<XYBatchProcessorCancelable>)processObject:(id)object complete:(void(^)(id msg))complete{
    return nil;
}



#pragma mark -- complete
-(void)_ProcessComplete:(NSString*)identifier{
    [self cleanIdentifier:identifier];
//    NSMutableArray* results = [NSMutableArray arrayWithCapacity:models.count];
//    for (int i=0; i<models.count; i++) {
//        [results addObject:models[i].msg];
//    }
//    [self processCompleteId:models.firstObject.batchIdentifier result:models];
}
-(void)processCompleteId:(NSString*)identifier result:(NSArray*)result {
    
}
@end
