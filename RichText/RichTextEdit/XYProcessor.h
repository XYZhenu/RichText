//
//  XYProcessor.h
//  RichText
//
//  Created by xyzhenu on 2017/6/23.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYProcessor : NSObject
-(void)process:(id)obj identifier:(NSString*)identifier;
-(void)completeWithIdentifier:(NSString*)identifier;


@end
