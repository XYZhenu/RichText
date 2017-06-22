//
//  XYRichTextVC.m
//  RichText
//
//  Created by xieyan on 2017/6/21.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "XYRichTextVC.h"
@import YYKit;
@import TZImagePickerController;
@import Photos;

static NSString* const keyRichTextImage = @"keyRichTextImage";

@interface YYTextView (InsertImage)
- (void)insertImage:(id)sender;
@end

@implementation XYRichTextImage

@end
@interface XYRichTextVC ()<YYTextViewDelegate, YYTextKeyboardObserver>
@property (nonatomic, assign) YYTextView *textView;
@property (nonatomic, assign) NSUInteger imageCount;
@end

@implementation XYRichTextVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.picSymbolPrefix = @"[";
    self.picSymbolSuffix = @"]";
    self.imageCount = 0;
    self.saveType = XYRichTextImageSaveTypeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIBarButtonItem *buttonItemSave = [[UIBarButtonItem alloc] initWithTitle:@"存草稿" style:UIBarButtonItemStylePlain target:self action:@selector(saveClick:)];
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(saveClick:)];
    self.navigationItem.rightBarButtonItems = @[buttonItemSave,buttonItemDone];
    
    
    UIView *toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    toolbar.size = CGSizeMake(kScreenWidth, 40);
    toolbar.top = kiOS7Later ? 64 : 0;
    [self.view addSubview:toolbar];
    

    UIButton* alubmBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    alubmBtn.size = CGSizeMake(44, 40);
    [alubmBtn addTarget:self action:@selector(addImageClick) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:alubmBtn];
    alubmBtn.right = toolbar.width;
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the season of light, it was the season of darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us. We were all going direct to heaven, we were all going direct the other way.\n\n这是最好的时代，这是最坏的时代；这是智慧的时代，这是愚蠢的时代；这是信仰的时期，这是怀疑的时期；这是光明的季节，这是黑暗的季节；这是希望之春，这是失望之冬；人们面前有着各样事物，人们面前一无所有；人们正在直登天堂，人们正在直下地狱。"];
    text.font = [UIFont systemFontOfSize:20];
    text.lineSpacing = 4;
    text.firstLineHeadIndent = 0;
    
    YYTextView *textView = [YYTextView new];
    textView.attributedText = text;
    textView.size = self.view.size;
    textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    textView.delegate = self;
    textView.allowsPasteImage = YES; /// Pasts image
    textView.allowsPasteAttributedString = YES; /// Paste attributed string
    if (kiOS7Later) {
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    } else {
        textView.height -= 64;
    }
    textView.contentInset = UIEdgeInsetsMake(toolbar.bottom, 0, 0, 0);
    textView.scrollIndicatorInsets = textView.contentInset;
    textView.selectedRange = NSMakeRange(text.length, 0);
    [self.view insertSubview:textView belowSubview:toolbar];
    self.textView = textView;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textView becomeFirstResponder];
    });
    
    [[YYTextKeyboardManager defaultManager] addObserver:self];
}

- (void)dealloc {
    [[YYTextKeyboardManager defaultManager] removeObserver:self];
}

- (void)saveClick:(UIBarButtonItem *)item {
    [self saveComplete:NO];
}
- (void)doneClick:(UIBarButtonItem *)item {
    [self.textView resignFirstResponder];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"确认发布此贴？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"存草稿" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self saveComplete:NO];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"发布" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self saveComplete:YES];
    }]];
}

#pragma mark - keyboard

- (void)keyboardChangedWithTransition:(YYTextKeyboardTransition)transition {
    BOOL clipped = NO;
    if (self.textView.isVerticalForm && transition.toVisible) {
        CGRect rect = [[YYTextKeyboardManager defaultManager] convertRect:transition.toFrame toView:self.view];
        if (CGRectGetMaxY(rect) == self.view.height) {
            CGRect textFrame = self.view.bounds;
            textFrame.size.height -= rect.size.height;
            self.textView.frame = textFrame;
            clipped = YES;
        }
    }
    
    if (!clipped) {
        self.textView.frame = self.view.bounds;
    }
}

#pragma mark - pick image

- (void)addImageClick {
    [self pickImage:^(NSArray<PHAsset *> * _Nonnull assets, NSArray<UIImage *> * _Nonnull images,NSArray<NSDictionary *> *infos) {
        for (int i = 0; i < assets.count; i++) {
            XYRichTextImage* image = [XYRichTextImage new];
            image.asset = assets[i];
            image.image = images[i];
            image.info = infos[i];
            image.url = image.info[@"PHImageFileURLKey"];
            [self.textView insertImage:image];
        }
    }];
}
- (void)pickImage:(void(^)(NSArray<PHAsset*>* assets, NSArray<UIImage*>*images,NSArray<NSDictionary *> *infos))complete {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:3 delegate:nil];
    imagePickerVc.photoWidth = (self.textView.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right);
    imagePickerVc.allowPickingGif = YES;
    [imagePickerVc setDidFinishPickingPhotosWithInfosHandle:^(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos){
        complete(assets,photos,infos);
    }];
    [imagePickerVc setDidFinishPickingGifImageHandle:^(UIImage *animatedImage,id sourceAssets){
        complete(@[sourceAssets],@[animatedImage],@[@{}]);
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - save image
- (NSString*)generateId{
    self.imageCount ++;
    return [NSString stringWithFormat:@"%ld",(unsigned long)self.imageCount];
}

- (NSArray *)rangesOfString:(NSString *)searchString inString:(NSString *)str {
    NSMutableArray *results = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;
    while ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {
        
        [results addObject:[NSValue valueWithRange:range]];
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
    }
    return results;
}

-(void)saveComplete:(BOOL)isComplete{
    NSAttributedString* allstr = self.textView.attributedText;
    NSMutableDictionary* imagesDic = [NSMutableDictionary dictionary];
    
    NSMutableString* plainText = allstr.string.mutableCopy;
    NSRange searchRange = NSMakeRange(0, [plainText length]);
    NSRange range;
    while ((range = [plainText rangeOfString:YYTextAttachmentToken options:NSBackwardsSearch range:searchRange]).location != NSNotFound) {
        searchRange = NSMakeRange(0, range.location);
        
        XYRichTextImage* RTimage = [allstr attribute:keyRichTextImage atIndex:range.location];
        if (!RTimage) {
            YYTextAttachment* content = [allstr attribute:YYTextAttachmentAttributeName atIndex:range.location];
            UIImage* image = nil;
            if ([content.content isKindOfClass:[UIImage class]]) {
                image = content.content;
            }else if ([content.content isKindOfClass:[UIImageView class]]) {
                image = ((UIImageView*)content.content).image;
            }
            if (image) {
                RTimage = [XYRichTextImage new];
                RTimage.image = image;
            }
        }
        if (RTimage && RTimage.image) {
            if (!RTimage.identifier) {
                if (RTimage.url) RTimage.identifier = RTimage.url.absoluteString;
                else RTimage.identifier = [self generateId];
            }
            [imagesDic setValue:RTimage forKey:RTimage.identifier];
            [plainText replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%@%@%@",self.picSymbolPrefix,RTimage.identifier,self.picSymbolSuffix]];
        }else{
            [plainText replaceCharactersInRange:range withString:@""];
        }
    }
    [self onSaveWithText:plainText images:imagesDic complete:isComplete];
}
- (void)onSaveWithText:(NSString*)content images:(NSDictionary<NSString*,XYRichTextImage*>*)images complete:(BOOL)complete; {
    
}
@end

@implementation YYTextView (InsertImage)

- (void)insertImage:(XYRichTextImage*)sender {
    UIImage *img = sender.image;
    if (img && img.size.width > 1 && img.size.height > 1) {
        id content = img;
        if ([img conformsToProtocol:@protocol(YYAnimatedImage)]) {
            id<YYAnimatedImage> ani = (id)img;
            if (ani.animatedImageFrameCount > 1) {
                YYAnimatedImageView *aniView = [[YYAnimatedImageView alloc] initWithImage:img];
                if (aniView) {
                    content = aniView;
                }
            }
        }
        
        if ([content isKindOfClass:[UIImage class]] && img.images.count > 1) {
            UIImageView *imgView = [UIImageView new];
            imgView.image = img;
            imgView.frame = CGRectMake(0, 0, img.size.width, img.size.height);
            if (imgView) {
                content = imgView;
            }
        }
        
        NSMutableAttributedString *attText = [NSAttributedString attachmentStringWithContent:content contentMode:UIViewContentModeScaleToFill width:img.size.width ascent:img.size.height descent:0];
        [attText addAttribute:keyRichTextImage value:sender range:attText.rangeOfAll];
        
        NSDictionary *attrs = self.attributedText.attributes;
        if (attrs) [attText addAttributes:attrs range:NSMakeRange(0, attText.length)];
        
        NSUInteger endPosition = self.selectedRange.location + attText.length;
        NSMutableAttributedString *text = self.attributedText.mutableCopy;
        [text replaceCharactersInRange:self.selectedRange withAttributedString:attText];
        self.attributedText = text;
        self.selectedRange = NSMakeRange(endPosition, 0);
    }
}

@end
