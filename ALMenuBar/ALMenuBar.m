//
//  ALMenuBar.m
//  UIMenuBarTest
//
//  Created by Arien Lau on 14-4-2.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "ALMenuBar.h"

static CGFloat kDefaultHeight = 240.0f;
static CGFloat kDefaultHalfHeight = 130;
static CGFloat kTitleLabelHeight = 40.0f;
static NSInteger kDefaultItemsNumberInOnePage = 6;
static CGFloat kDefaultPageControlHeight = 20.0;
static CGFloat kDefaultItemSize = 90.0f;
static CGFloat kDefaultTitleFontSize = 16.0f;
static CGFloat kDefaultAnimationDuration = 0.3f;

#if !__has_feature(objc_arc)
    #ifndef ALRelease
        #define ALRelease(_v) ([(_v) release]);
    #endif

    #ifndef ALAutoRelease
        #define ALAutoRelease(_v) ([(_v) autorelease]);
    #endif

    #ifndef ALRetain
        #define ALRetain(_v) ([(_v) retain]);
    #endif

    #ifndef ALReleaseSave
        #define ALReleaseSave(_v) if (_v) {[(_v) release]; (_v) = nil;}
    #endif
#else
    #ifndef ALRelease
        #define ALRelease(_v)
    #endif

    #ifndef ALAutoRelease
        #define ALAutoRelease(_v)
    #endif

    #ifndef ALRetain
        #define ALRetain(_v)
    #endif

    #ifndef ALReleaseSave
        #define ALReleaseSave(_v) if (_v) {(_v) = nil;}
    #endif

    #ifndef ALARC
        #define ALARC YES
    #endif
#endif

@interface ALMenuBar () <UIScrollViewDelegate>
@property (nonatomic, retain) NSMutableArray *menuBarItems;
@property (nonatomic, retain) UIScrollView   *contentView;
@property (nonatomic, retain) UILabel        *titleLabel;
@property (nonatomic, retain) UIPageControl  *pageControl;
@property (nonatomic, retain) UIView         *coverView;
@end

@implementation ALMenuBar

- (void)dealloc
{
    for (ALMenuBarItem* item in _menuBarItems) {
        [item removeFromSuperview];
    }
    ALReleaseSave(_menuBarItems);
    ALReleaseSave(_contentView);
    ALReleaseSave(_titleLabel);
    ALReleaseSave(_pageControl);
    ALReleaseSave(_coverView);
#ifndef ALARC
    [super dealloc];
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setSelfProperty];
        _menuBarItems = [[NSMutableArray alloc] init];
        [self initTitleLabelWithTitle:@""];
        [self initCommonUI];
        [self resetSubviewLayout];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setSelfProperty];
        _menuBarItems = [[NSMutableArray alloc] init];
        [self initTitleLabelWithTitle:@""];
        [self initCommonUI];
        [self resetSubviewLayout];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title items:(NSArray *)items
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setSelfProperty];
        _menuBarItems = [[NSMutableArray alloc] initWithArray:items];
        [self initTitleLabelWithTitle:title];
        [self initCommonUI];
        [self resetSubviewLayout];
    }
    return self;
}

- (void)setSelfProperty
{
//    self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0, -2);
    self.layer.shadowRadius = 5.0;
    self.layer.shadowOpacity = 0.8;
    CGRect frame = [UIScreen mainScreen].bounds;
    self.frame = CGRectMake(0, 0, frame.size.width, kDefaultHeight);
    
    UIImageView *backGroundView = [[UIImageView alloc] init];
    backGroundView.frame = self.bounds;
    backGroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    backGroundView.image = [UIImage imageNamed:@"ALMenuBackgroud.png"];
    [self addSubview:backGroundView];
    ALRelease(backGroundView);
}

- (void)initTitleLabelWithTitle:(NSString *)title
{
    CGFloat _borderWidth = (([UIScreen mainScreen].scale >= 2.0) ? 0.5f : 1.0f);
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-_borderWidth, 0, self.frame.size.width + 2 * _borderWidth, kTitleLabelHeight)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.text = title;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:kDefaultTitleFontSize];
    _titleLabel.layer.borderColor = [UIColor grayColor].CGColor;
    _titleLabel.layer.borderWidth = _borderWidth;
    [self addSubview:_titleLabel];
}

- (void)setTitle:(NSString *)title
{
    if (!_titleLabel) {
        [self initTitleLabelWithTitle:title];
    } else {
        _titleLabel.text = title ? title : @"";
    }
}

- (void)setItems:(NSMutableArray *)items
{
    if (![_menuBarItems isEqualToArray:items]) {
        ALRelease(_menuBarItems);
        _menuBarItems = items;
        ALRetain(_menuBarItems);
        
        [self setScrollEnabledForContentViewIfNeed];
        [self initPageControl];
        [self resetSubviewLayout];
    }
}

- (void)initCommonUI
{
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kTitleLabelHeight, CGRectGetWidth(self.frame), CGRectGetHeight(self.bounds) - kDefaultPageControlHeight - kTitleLabelHeight)];
    
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self setScrollEnabledForContentViewIfNeed];
    _contentView.pagingEnabled = YES;
    _contentView.delegate = self;
    _contentView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_contentView];
    
    [self initPageControl];
}

- (void)setScrollEnabledForContentViewIfNeed
{
    _contentView.scrollEnabled = ([self totalPages] > 1);
}

- (void)initPageControl
{
    if ([self totalPages] > 1) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.frame = CGRectMake(0, CGRectGetHeight(self.frame) - kDefaultPageControlHeight, CGRectGetWidth(self.frame), kDefaultPageControlHeight);
        _pageControl.currentPage = 0;
        _pageControl.numberOfPages = [self totalPages];
        [_pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_pageControl];
    }
}

- (void)changePage:(UIPageControl *)pageControl
{
    NSInteger page = pageControl.currentPage;
    [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
        self.contentView.contentOffset = CGPointMake(page * CGRectGetWidth(self.contentView.frame), 0);
    }];
}

- (void)resetSubviewLayout
{
    if (_menuBarItems.count == 0) {
        return;
    }
    if (_pageControl) {
        _pageControl.numberOfPages = [self totalPages];
        _pageControl.currentPage = 0;
    }
   
    [self resetScrollViewLayout];
    
    if (_menuBarItems.count == 1) {
        [self setSingalItemFrame];
    } else if (_menuBarItems.count == 2) {
        [self setDoubleItemFrame];
    } else {
        [self setItemsFrame];
    }
}

- (void)addTapGestureToMenuBar:(ALMenuBarItem *)item
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ALMenuBarDidTaped:)];
    [item addGestureRecognizer:tap];
    ALRelease(tap);
}

- (void)setSingalItemFrame
{
    ALMenuBarItem *menuBarItem = [_menuBarItems objectAtIndex:0];
    menuBarItem.index = 0;
    [self addTapGestureToMenuBar:menuBarItem];
    menuBarItem.frame = CGRectMake((_contentView.frame.size.width - kDefaultItemSize) / 2.0, 0, kDefaultItemSize, kDefaultItemSize);
    [_contentView addSubview:menuBarItem];
}

- (void)setDoubleItemFrame
{
    CGFloat totalMargin = _contentView.frame.size.width - 2 * kDefaultItemSize;
    CGFloat margin = totalMargin / 4.0;
    for (int num = 0; num < _menuBarItems.count; num++) {
        ALMenuBarItem *menuBarItem = _menuBarItems[num];
        menuBarItem.index = num;
        [self addTapGestureToMenuBar:menuBarItem];
        menuBarItem.frame = CGRectMake(margin + num * (kDefaultItemSize + margin * 2) , 0, kDefaultItemSize, kDefaultItemSize);
        [_contentView addSubview:menuBarItem];
    }
}

- (void)setItemsFrame
{
    for (int page = 0; page < [self totalPages]; page++) {
        for (NSInteger index = (page * kDefaultItemsNumberInOnePage); index < (page * kDefaultItemsNumberInOnePage + kDefaultItemsNumberInOnePage); index++) {
            if (index == _menuBarItems.count) {
                break;
            }
            ALMenuBarItem *menuBarItem = _menuBarItems[index];
            menuBarItem.index= index;
            [self addTapGestureToMenuBar:menuBarItem];
            NSInteger relativeIndex = index - (page * kDefaultItemsNumberInOnePage);  /**< 在本页面的相对位置*/
            int row = (relativeIndex / 3 < 1) ? 0 : 1; /**< 行数*/
            int coloumn = (relativeIndex % 3); /**< 列数*/
            
            int totalInterval = CGRectGetWidth(self.frame) - 3 * kDefaultItemSize;
            menuBarItem.frame = CGRectMake(coloumn * (kDefaultItemSize + totalInterval / 2) + page * CGRectGetWidth(_contentView.frame), row * kDefaultItemSize, kDefaultItemSize, kDefaultItemSize);
            [_contentView addSubview:menuBarItem];
        }
    }
}

- (void)resetScrollViewLayout
{
    if (_menuBarItems.count <= 3) {
        
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                CGRectGetWidth(self.bounds),
                                kDefaultHalfHeight);
    } else {
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                CGRectGetWidth(self.bounds),
                                kDefaultHeight);
    }
    
    if ([self totalPages] > 1) {
        _contentView.frame = CGRectMake(0,
                                       kTitleLabelHeight,
                                       CGRectGetWidth(self.bounds),
                                       CGRectGetHeight(self.bounds) - kDefaultPageControlHeight - kTitleLabelHeight);
    } else {
        _contentView.frame = CGRectMake(0,
                                          kTitleLabelHeight,
                                          CGRectGetWidth(self.bounds),
                                          CGRectGetHeight(self.bounds) - kTitleLabelHeight);
    }
    
    _contentView.contentSize = CGSizeMake([self totalPages] * CGRectGetWidth(_contentView.bounds),
                                            CGRectGetHeight(_contentView.bounds));
}

- (void)layoutSubviews
{
    [self resetScrollViewLayout];
}

- (NSInteger)totalPages
{
    return ((_menuBarItems.count / kDefaultItemsNumberInOnePage) + 1);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_pageControl) {
        CGPoint offset = scrollView.contentOffset;
        _pageControl.currentPage = offset.x / _contentView.bounds.size.width;
    }
}

- (void)ALMenuBarDidTaped:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded && [gesture.view isKindOfClass:[ALMenuBarItem class]]) {
        ALMenuBarItem *item = (ALMenuBarItem *)gesture.view;
        if (item.target && item.action && [item.target respondsToSelector:item.action]) {
            [item.target performSelector:item.action withObject:item afterDelay:0];
        }
        
        if ([_delegate respondsToSelector:@selector(ALMenuBar:didSelectItemAtIndex:)]) {
            [_delegate ALMenuBar:self didSelectItemAtIndex:item.index];
        }
    }
}

- (void)ALMenuBarShow
{
    UIWindow *keywindow = [[UIApplication sharedApplication] keyWindow];
    if (![keywindow.subviews containsObject:self]) {
        // Calulate all frames
        CGRect showFrame = CGRectMake(0, CGRectGetHeight(keywindow.frame) - CGRectGetHeight(self.frame), CGRectGetWidth(keywindow.frame), CGRectGetHeight(self.frame));
        CGRect leftFrame = CGRectMake(0, 0, CGRectGetWidth(keywindow.frame), CGRectGetHeight(keywindow.frame) - CGRectGetHeight(self.frame));
        
        if (!_coverView) {
            _coverView = [[UIView alloc] initWithFrame:keywindow.bounds];
            _coverView.backgroundColor = [UIColor colorWithRed:.16 green:.17 blue:.21 alpha:.6];
        }
        [keywindow addSubview:_coverView];
        
        UIControl *dismissButton = [[UIControl alloc] initWithFrame:leftFrame];
        [dismissButton addTarget:self action:@selector(ALMenuBarDismiss) forControlEvents:UIControlEventTouchUpInside];
        dismissButton.backgroundColor = [UIColor clearColor];
        [_coverView addSubview:dismissButton];
        ALRelease(dismissButton);
        
        // Present view animated
        self.frame = CGRectMake(0, CGRectGetHeight(keywindow.frame), CGRectGetWidth(keywindow.frame), CGRectGetHeight(self.frame));
        [keywindow addSubview:self];
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            self.frame = showFrame;
        } completion:^(BOOL finished) {
            if (_delegate && [_delegate respondsToSelector:@selector(ALMenuBarDidShown:)]) {
                [_delegate ALMenuBarDidShown:self];
            }
        }];
    }
}

- (void)ALMenuBarDismiss
{
    UIWindow *keywindow = [[UIApplication sharedApplication] keyWindow];
    CGRect dismissFrame = CGRectMake(0, CGRectGetHeight(keywindow.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    if (!CGRectEqualToRect(self.frame, dismissFrame)) {
        if ([_delegate respondsToSelector:@selector(ALMenuBarWillDismiss:)]) {
            [_delegate ALMenuBarWillDismiss:self];
        }
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            self.frame = dismissFrame;
        } completion:^(BOOL finished) {
            [self.coverView removeFromSuperview];
            [self removeFromSuperview];
            if ([_delegate respondsToSelector:@selector(ALMenuBarDidDismiss:)]) {
                [_delegate ALMenuBarDidDismiss:self];
            }
        }];
    }
}

@end

static CGFloat kItemTitleLabelHeight = 25.0f;
static CGFloat kBottomMargin = 10.0f;

@interface ALMenuBarItem ()

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *titleLabel;

@end

@implementation ALMenuBarItem

- (void)dealloc
{
    ALReleaseSave(_imageView);
    ALReleaseSave(_titleLabel);
#ifndef ALARC
    [super dealloc];
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithTitle:(NSString *)title image:(UIImage *)image target:(id)target action:(SEL)action
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _target = target;
        _action = action;
        
        _imageView = [[UIImageView alloc] init];
        _imageView.image = image;
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = title;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    CGSize size = _imageView.image.size;
    _imageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - size.width) / 2.0, (CGRectGetHeight(self.frame) - size.height - kItemTitleLabelHeight) / 2.0, size.width, size.height);
    _titleLabel.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - kItemTitleLabelHeight - kBottomMargin, CGRectGetWidth(self.frame), kItemTitleLabelHeight);
}

@end
