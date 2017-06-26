//
//  XYProcessor.m
//  RichText
//
//  Created by xyzhenu on 2017/6/23.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "XYProcessor.h"
@interface XYProcessor ()
@property(nonatomic,strong)NSString* saveKey;
@end
@implementation XYProcessor
-(void)start { }
-(void)suspend { }
-(void)cancel { }

-(void)convertComplete:(void(^)(id newMsg))complete { }

-(NSString*)save {
    return @"";
}
-(void)changeMsgKey:(NSString*)oldKey newKey:(NSString*)newKey { }

-(void)processComplete:(void(^)(NSString* completeKey))complete { }
@end


@implementation ImageUploader
@dynamic msg;


-(void)start {
    [self convertComplete:^(id  _Nonnull newMsg) {
        self.saveKey = [self save];
        [self processComplete:^(NSString * _Nonnull completeKey) {
            [self changeMsgKey:self.saveKey newKey:completeKey];
            [self ];
        }];
    }];
}
-(void)suspend {
    
}
-(void)cancel {
    
}

-(void)convertComplete:(void(^)(id newMsg))complete {
    
}

-(NSString*)save {
    return @"";
}
-(void)changeMsgKey:(NSString*)oldKey newKey:(NSString*)newKey {
    
}

-(void)processComplete:(void(^)(NSString* completeKey))complete {
    
}

@end
