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
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isSelectOriginalPhoto = NO;
    }
    return self;
}
@end
@interface XYRichTextVC ()<YYTextViewDelegate>
@property (nonatomic, assign) YYTextView *textView;
@property (nonatomic, assign) NSUInteger imageCount;
@property (nonatomic, strong) NSLayoutConstraint* toolBarBottom;
@end

@implementation XYRichTextVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.picSymbolPrefix = @"[";
    self.picSymbolSuffix = @"]";
    self.imageCount = 0;
    self.saveType = XYRichTextImageSaveTypeOnSaveClick;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIBarButtonItem *buttonItemSave = [[UIBarButtonItem alloc] initWithTitle:@"存草稿" style:UIBarButtonItemStylePlain target:self action:@selector(saveClick:)];
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(doneClick:)];
    self.navigationItem.rightBarButtonItems = @[buttonItemSave,buttonItemDone];
    
    
    UIView *toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    [self.view addSubview:toolbar];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[toolbar]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(toolbar)]];
    [toolbar addConstraint:[NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    self.toolBarBottom = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:toolbar attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self.view addConstraint:self.toolBarBottom];

    UIButton* alubmBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    alubmBtn.size = CGSizeMake(44, 40);
    [alubmBtn addTarget:self action:@selector(addImageClick) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:alubmBtn];
    alubmBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [toolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[alubmBtn(40)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(alubmBtn)]];
    [toolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[alubmBtn]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(alubmBtn)]];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
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
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[textView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView)]];
    id toplayout = self.topLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toplayout]-0-[textView]-0-[toolbar]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView,toolbar,toplayout)]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textView becomeFirstResponder];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIKeyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - keyboard

- (void)UIKeyboardWillChangeFrameNotification:(NSNotification*)transition {
    CGRect frame = [transition.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval time = [transition.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:time animations:^{
        self.textView.frame = CGRectMake(self.textView.origin.x, self.textView.origin.y, self.textView.size.width, self.view.height-self.textView.origin.y-frame.size.height);
    } completion:^(BOOL finished) {
        if (finished) {
            self.toolBarBottom.constant = frame.origin.y >= self.view.frame.size.height ? 0 : frame.size.height;
        }
    }];
}

#pragma mark - pick image

- (void)addImageClick {
    [self pickImage:^(NSArray<PHAsset *> * _Nonnull assets, NSArray<UIImage *> * _Nonnull images,NSArray<NSDictionary *> *infos,BOOL isSelectOriginalPhoto) {
        for (int i = 0; i < assets.count; i++) {
            XYRichTextImage* image = [XYRichTextImage new];
            image.asset = assets[i];
            image.image = images[i];
            image.info = infos[i];
            image.url = image.info[@"PHImageFileURLKey"];
            image.isSelectOriginalPhoto = isSelectOriginalPhoto;
            [self.textView insertImage:image];
        }
        if (self.saveType & XYRichTextImageSaveTypeOnInsert) {
            [self saveComplete:NO];
        }
    }];
}
- (void)pickImage:(void(^)(NSArray<PHAsset*>* assets, NSArray<UIImage*>*images,NSArray<NSDictionary *> *infos,BOOL isSelectOriginalPhoto))complete {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:3 delegate:nil];
    imagePickerVc.photoWidth = (self.textView.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right);
    imagePickerVc.allowPickingGif = YES;
    [imagePickerVc setDidFinishPickingPhotosWithInfosHandle:^(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos){
        complete(assets,photos,infos,isSelectOriginalPhoto);
    }];
    [imagePickerVc setDidFinishPickingGifImageHandle:^(UIImage *animatedImage,id sourceAssets){
        complete(@[sourceAssets],@[animatedImage],@[@{}],YES);
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - save image
- (NSString*)generateId{
    self.imageCount ++;
    return [NSString stringWithFormat:@"XYRichText_%ld",(unsigned long)self.imageCount];
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
- (void)onSaveWithText:(NSString*)content images:(NSDictionary<NSString*,XYRichTextImage*>*)images complete:(BOOL)complete {
    
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
