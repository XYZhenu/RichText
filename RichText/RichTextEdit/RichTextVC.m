//
//  RichTextVC.m
//  RichText
//
//  Created by xyzhenu on 2017/6/26.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "RichTextVC.h"
#import <TZImagePickerController/TZImageManager.h>
#import <YYKit/YYKit.h>
@interface RichTextVC ()
@property (nonatomic,strong)NSMutableString* contents;
@property (nonatomic,strong)NSMutableDictionary<NSString *,XYRichTextImage *>* imagesDic;
@property (nonatomic,assign)BOOL iscomplete;
@end
@implementation RichTextVC
-(void)viewDidLoad{
    [super viewDidLoad];
    self.iscomplete = NO;
}

-(void)start:(XYRichTextImage*)image{
    [self saveImage:image];
    
    if (!image.asset) {
        [self uploadImageData:image.image.imageDataRepresentation complete:^(NSString *imageurl) {
            image.uploadedUrl = imageurl;
            [self changeImage:image saveKey:imageurl];
            [self checkIsFinish];
        }];
    }else if ([[image.asset valueForKey:@"filename"] hasSuffix:@"GIF"]){
        [[TZImageManager manager] getOriginalPhotoDataWithAsset:image.asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
            if (isDegraded) return;
            [self uploadImageData:data complete:^(NSString *imageurl) {
                image.uploadedUrl = imageurl;
                [self changeImage:image saveKey:imageurl];
                [self checkIsFinish];
            }];
        }];
    }else{
        [[TZImageManager manager] getPhotoWithAsset:image.asset photoWidth:1024 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            [self uploadImageData:UIImageJPEGRepresentation(photo, 0.7) complete:^(NSString *imageurl) {
                image.uploadedUrl = imageurl;
                [self changeImage:image saveKey:imageurl];
                [self checkIsFinish];
            }];
        }];
    }
}

-(void)cancel:(XYRichTextImage*)image{
    [image.operation cancel];
    [self removeImage:image];
}

-(void)removeImage:(XYRichTextImage*)image{
    
}
-(void)saveImage:(XYRichTextImage*)image{
    
}
-(void)changeImage:(XYRichTextImage*)image saveKey:(NSString*)key{
    
}
-(void)saveText:(NSString*)text name:(NSString*)name{
    
}

-(NSOperation*)uploadImageData:(NSData*)data complete:(void(^)(NSString* imageurl))complete{
    return nil;
}
-(void)uploadContent:(NSString*)content complete:(void(^)())complete{
    
}

-(void)onSaveWithText:(NSString *)content images:(NSDictionary<NSString *,XYRichTextImage *> *)images complete:(BOOL)complete {
    self.iscomplete = complete;
    //remove old
    NSSet<NSString*>* current = [NSSet setWithArray:self.imagesDic.allKeys];
    NSSet<NSString*>* discard = [current objectsPassingTest:^BOOL(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        return nil == images[obj];
    }];
    [discard enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self cancel:self.imagesDic[obj]];
        [self.imagesDic removeObjectForKey:obj];
    }];
    
    //add new
    NSSet<NSString*>* new = [NSSet setWithArray:images.allKeys];
    NSSet<NSString*>* added = [new objectsPassingTest:^BOOL(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        return nil == self.imagesDic[obj];
    }];
    [added enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self start:images[obj]];
        [self.imagesDic setValue:images[obj] forKey:obj];
    }];
    
    //set content
    self.contents = [NSMutableString stringWithString:content];

    [self checkIsFinish];
}
-(void)checkIsFinish{
    [self.imagesDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, XYRichTextImage * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.uploadedUrl) {
            [self.contents replaceOccurrencesOfString:key withString:obj.uploadedUrl options:NSLiteralSearch range:NSMakeRange(0, self.contents.length)];
        }
    }];
    [self saveText:self.contents name:@"richtext_circleid"];
    if (!self.iscomplete) return;
    for (XYRichTextImage* image in self.imagesDic) { if (!image.uploadedUrl) return; }
    //TODO: complete upload
    [self uploadContent:self.contents complete:^{
        
    }];
}
@end
