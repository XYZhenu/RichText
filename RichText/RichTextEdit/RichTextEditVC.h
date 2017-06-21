//
//  RichTextEditVC.h
//  RichText
//
//  Created by xyzhenu on 2017/6/21.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger,RichTextImageSaveType) {
    RichTextImageSaveTypeNone = 1,
    RichTextImageSaveTypeOnInsert = 1<<1,
    RichTextImageSaveTypeOnSaveClick = 1<<2,
};
@interface RichTextImage : NSObject
@property (nonatomic,strong,nullable)PHAsset* asset;
@property (nonatomic,strong,nullable)UIImage* image;
@property (nonatomic,strong,nullable)NSDictionary* info;
@property (nonatomic,strong,nullable)NSURL* url;
@end
@interface RichTextEditVC : UIViewController
@property (nonatomic,strong)NSString* picSymbol;//default [
- (void)pickImage:(void(^)(NSArray<PHAsset*>* assets, NSArray<UIImage*>*images,NSArray<NSDictionary *> *infos))complete;
@property(nonatomic,assign)RichTextImageSaveType saveType;
- (void)onImageSave:(NSArray<RichTextImage*>*)images;
- (void)editCompleteWithText:(NSString*)content images:(NSDictionary<NSString*,RichTextImage*>*)images;
@end
NS_ASSUME_NONNULL_END
