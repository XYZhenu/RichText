//
//  XYRichTextVC.h
//  RichText
//
//  Created by xieyan on 2017/6/21.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger,XYRichTextImageSaveType) {
    XYRichTextImageSaveTypeNone = 1,
    XYRichTextImageSaveTypeOnInsert = 1<<1,
    XYRichTextImageSaveTypeOnSaveClick = 1<<2,
};
@interface XYRichTextImage : NSObject
@property (nonatomic,strong,nullable)PHAsset* asset;
@property (nonatomic,strong,nullable)UIImage* image;
@property (nonatomic,strong,nullable)NSDictionary* info;
@property (nonatomic,strong,nullable)NSURL* url;
@end
@interface XYRichTextVC : UIViewController
@property (nonatomic,strong)NSString* picSymbol;//default [
- (void)pickImage:(void(^)(NSArray<PHAsset*>* assets, NSArray<UIImage*>*images,NSArray<NSDictionary *> *infos))complete;
@property(nonatomic,assign)XYRichTextImageSaveType saveType;
- (void)onImageSave:(NSArray<XYRichTextImage*>*)images;
- (void)editCompleteWithText:(NSString*)content images:(NSDictionary<NSString*,XYRichTextImage*>*)images;
@end
NS_ASSUME_NONNULL_END
