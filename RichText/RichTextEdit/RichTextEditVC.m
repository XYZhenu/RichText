//
//  RichTextEditVC.m
//  RichText
//
//  Created by xyzhenu on 2017/6/21.
//  Copyright © 2017年 xyzhenu. All rights reserved.
//

#import "RichTextEditVC.h"
@import YYKit;
@import TZImagePickerController;
@import Photos;

@interface RichTextEditVC ()<YYTextViewDelegate, YYTextKeyboardObserver>
@property (nonatomic, assign) YYTextView *textView;
@property (nonatomic, strong) NSMutableDictionary* imagesDic;
@property (nonatomic, assign) NSUInteger imageCount;
@end

@implementation RichTextEditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.picSymbol = @"[";
    self.saveType = RichTextImageSaveTypeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.imagesDic = [NSMutableDictionary dictionary];
    self.imageCount = 0;
    
    
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
    text.font = [UIFont fontWithName:@"Times New Roman" size:20];
    text.lineSpacing = 4;
    text.firstLineHeadIndent = 20;
    
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

- (void)edit:(UIBarButtonItem *)item {
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    } else {
        [self.textView becomeFirstResponder];
    }
}

#pragma mark text view

- (void)textViewDidBeginEditing:(YYTextView *)textView {
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = buttonItem;
}

- (void)textViewDidEndEditing:(YYTextView *)textView {
    self.navigationItem.rightBarButtonItem = nil;
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

- (NSString*)generateId{
    self.imageCount ++;
    return [NSString stringWithFormat:@"%ld",self.imageCount];
}
- (void)addImageClick {
    [self pickImage:^(NSArray<PHAsset *> * _Nonnull assets, NSArray<UIImage *> * _Nonnull images,NSArray<NSDictionary *> *infos) {
        for (int i = 0; i < assets.count; i++) {
            RichTextImage* image = [RichTextImage new];
            image.asset = assets[i];
            image.image = images[i];
            image.info = infos[i];
            self.imagesDic[[self generateId]] = image;
        }
        
    }];
}
- (void)pickImage:(void(^)(NSArray<PHAsset*>* assets, NSArray<UIImage*>*images,NSArray<NSDictionary *> *infos))complete {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    [imagePickerVc setDidFinishPickingPhotosWithInfosHandle:^(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos){
        complete(assets,photos,infos);
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}
- (void)onImageSave:(NSArray<RichTextImage*>*)images {
    
}
- (void)editCompleteWithText:(NSString*)content images:(NSDictionary<NSString*,RichTextImage*>*)images {
    
}
@end
