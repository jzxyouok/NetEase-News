//
//  FRSlideMenuController.m
//  NetEase News
//
//  Created by 1860 on 16/6/15.
//  Copyright © 2016年 FanrongQu. All rights reserved.
//

#import "FRSlideMenuController.h"
#import "FRSlideMenuTitleLabel.h"
#import "FRHorizontalLayout.h"
// 导航条高度
static CGFloat const FRNavBarH = 64;

// 标题滚动视图的高度
static CGFloat const FRTitleScrollViewH = 44;

// 标题缩放比例
static CGFloat const FRTitleTransformScale = 1.3;

// 下划线默认高度
static CGFloat const FRUnderLineH = 2;

// 默认标题字体
static CGFloat const TitleFontSize = 15;

// 默认标题间距
static CGFloat const margin = 20;

static NSString * const ID = @"FRSlideMenuCollectionCell";

// 标题被点击或者滚动切换分类后，会发出这个通知。监听这个通知，加载数据
static NSString * const FRSlideMenuClickOrScrollDidFinshNote = @"FRSlideMenuClickOrScrollDidFinshNote";

// 重复点击通知
static NSString * const FRSlideMenuRepeatClickTitleNote = @"FRSlideMenuRepeatClickTitleNote";


@interface FRSlideMenuController ()<UICollectionViewDataSource,UICollectionViewDelegate>

/** 整体内容View 包含标题好内容滚动视图 */
@property (nonatomic, weak) UIView *contentView;

/** 标题滚动视图 */
@property (nonatomic, weak) UIScrollView *titleScrollView;

/** 内容滚动视图 */
@property (nonatomic, weak) UICollectionView *contentScrollView;

/** 所有标题数组 */
@property (nonatomic, strong) NSMutableArray *titleLabels;

/** 所有标题宽度数组 */
@property (nonatomic, strong) NSMutableArray *titleWidths;

/** 下标视图 */
@property (nonatomic, weak) UIView *underLine;

/** 标题遮盖视图 */
@property (nonatomic, weak) UIView *coverView;

/** 记录上一次内容滚动视图偏移量 */
@property (nonatomic, assign) CGFloat lastOffsetX;

/** 记录是否点击 */
@property (nonatomic, assign) BOOL isClickTitle;

/** 记录是否在动画 */
@property (nonatomic, assign) BOOL isAnimationing;

/* 是否初始化 */
@property (nonatomic, assign) BOOL isInitial;

/** 标题间距 */
@property (nonatomic, assign) CGFloat titleMargin;

/** 计算上一次选中角标 */
@property (nonatomic, assign) NSInteger selIndex;

@property (nonatomic, weak) UIButton *addMenuView;

@end

@implementation FRSlideMenuController

#pragma mark - 初始化数据
- (instancetype)init {
    if (self = [super init]) {
        [self initial];
    }
    return self;
}

- (void)awakeFromNib {
    [self initial];
}

- (void)initial {
    
    //初始化标题栏高度
    _titleHeight = FRTitleScrollViewH;
    //automaticallyAdjustsScrollViewInsets根据按所在界面的status bar，navigationbar，与tabbar的高度，自动调整scrollview的 inset
    //这里设置为no，不让viewController调整，我们自己修改布局
    self.automaticallyAdjustsScrollViewInsets = NO;
}

#pragma mark - 控件懒加载
- (UIFont *)titleFont {
    if (!_titleFont) {
        _titleFont = [UIFont systemFontOfSize:TitleFontSize];
    }
    return _titleFont;
}

- (NSMutableArray *)titleWidths {
    if (!_titleWidths) {
        _titleWidths = [NSMutableArray array];
    }
    return _titleWidths;
}

- (UIColor *)norColor
{
    if (_isShowTitleGradient && _titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
        _norColor = [UIColor colorWithRed:_startR green:_startG blue:_startB alpha:1];
    }
    
    if (_norColor == nil){
        _norColor = [UIColor blackColor];
    }
    
    
    return _norColor;
}

- (UIColor *)selColor
{
    if (_isShowTitleGradient && _titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
        _selColor = [UIColor colorWithRed:_endR green:_endG blue:_endB alpha:1];
    }
    
    if (_selColor == nil) _selColor = [UIColor redColor];
    
    return _selColor;
}

- (UIView *)coverView
{
    if (_coverView == nil) {
        UIView *coverView = [[UIView alloc] init];
        
        coverView.backgroundColor = _coverColor?_coverColor:[UIColor lightGrayColor];
        
        coverView.layer.cornerRadius = _coverCornerRadius;
        
        [self.titleScrollView insertSubview:coverView atIndex:0];
        
        _coverView = coverView;
    }
    return _isShowTitleCover?_coverView:nil;
}

- (UIView *)underLine
{
    if (_underLine == nil) {
        
        UIView *underLineView = [[UIView alloc] init];
        
        underLineView.backgroundColor = _underLineColor?_underLineColor:[UIColor redColor];
        
        [self.titleScrollView addSubview:underLineView];
        
        _underLine = underLineView;
        
    }
    return _isShowUnderLine?_underLine : nil;
}

- (NSMutableArray *)titleLabels
{
    if (_titleLabels == nil) {
        _titleLabels = [NSMutableArray array];
    }
    return _titleLabels;
}

// 懒加载标题滚动视图
- (UIScrollView *)titleScrollView
{
    if (_titleScrollView == nil) {
        
        UIScrollView *titleScrollView = [[UIScrollView alloc] init];
        
        titleScrollView.backgroundColor = _titleScrollViewColor?_titleScrollViewColor:[UIColor colorWithWhite:1 alpha:0.7];
        
        [self.contentView addSubview:titleScrollView];
        
        _titleScrollView = titleScrollView;
        
    }
    return _titleScrollView;
}

// 懒加载内容滚动视图
- (UIScrollView *)contentScrollView
{
    if (_contentScrollView == nil) {
        
        // 创建并设置布局属性
        FRHorizontalLayout *layout = [[FRHorizontalLayout alloc] init];
      
        UICollectionView *contentScrollView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _contentScrollView = contentScrollView;
        // 设置内容滚动视图
        _contentScrollView.pagingEnabled = YES;
        _contentScrollView.showsHorizontalScrollIndicator = NO;
        _contentScrollView.bounces = NO;
        _contentScrollView.delegate = self;
        _contentScrollView.dataSource = self;
        [self.contentView insertSubview:contentScrollView belowSubview:self.titleScrollView];
    }
    return _contentScrollView;
}

- (UIView *)contentView {
    if (!_contentView) {
        UIView *contentView = [[UIView alloc]init];
        _contentView = contentView;
        [self.view addSubview:contentView];
    }
    return _contentView;
}

#pragma mark - 属性setter方法

- (void)setIsShowTitleScale:(BOOL)isShowTitleScale
{
    if (_isShowUnderLine) {
        // 抛异常
        NSException *excp = [NSException exceptionWithName:@"FRSlideMenuControllerException" reason:@"字体放大效果和角标不能同时使用。" userInfo:nil];
        [excp raise];
    }
    
    _isShowTitleScale = isShowTitleScale;
}

- (void)setIsShowUnderLine:(BOOL)isShowUnderLine
{
    if (_isShowTitleScale) {
        // 抛异常
        NSException *excp = [NSException exceptionWithName:@"FRSlideMenuControllerException" reason:@"字体放大效果和角标不能同时使用。" userInfo:nil];
        [excp raise];
    }
    
    _isShowUnderLine = isShowUnderLine;
}

- (void)setTitleScrollViewColor:(UIColor *)titleScrollViewColor
{
    _titleScrollViewColor = titleScrollViewColor;
    
    self.titleScrollView.backgroundColor = titleScrollViewColor;
}

- (void)setIsfullScreen:(BOOL)isfullScreen
{
    _isfullScreen = isfullScreen;
    CGSize size = [UIScreen mainScreen].bounds.size;
    self.contentView.frame = CGRectMake(0, 0, size.width, size.height);
    
}

// 设置整体内容的尺寸
- (void)setUpContentViewFrame:(void (^)(UIView *))contentBlock
{
    if (contentBlock) {
        contentBlock(self.contentView);
    }
}

// 一次性设置所有颜色渐变属性
- (void)setUpTitleGradient:(void (^)(BOOL *, FRTitleColorGradientStyle *, CGFloat *, CGFloat *, CGFloat *, CGFloat *, CGFloat *, CGFloat *))titleGradientBlock
{
    if (titleGradientBlock) {
        titleGradientBlock(&_isShowTitleGradient,&_titleColorGradientStyle,&_startR,&_startG,&_startB,&_endR,&_endG,&_endB);
    }
}

// 一次性设置所有遮盖属性
- (void)setUpCoverEffect:(void (^)(BOOL *, UIColor **, CGFloat *))coverEffectBlock
{
    UIColor *color;
    
    if (coverEffectBlock) {
        
        coverEffectBlock(&_isShowTitleCover,&color,&_coverCornerRadius);
        
        if (color) {
            _coverColor = color;
        }
        
    }
}

// 一次性设置所有字体缩放属性
- (void)setUpTitleScale:(void(^)(BOOL *isShowTitleScale,CGFloat *titleScale))titleScaleBlock
{
    if (titleScaleBlock) {
        titleScaleBlock(&_isShowTitleScale,&_titleScale);
    }
}

// 一次性设置所有下标属性
- (void)setUpUnderLineEffect:(void(^)(BOOL *isShowUnderLine,BOOL *isDelayScroll,CGFloat *underLineH,UIColor **underLineColor))underLineBlock
{
    UIColor *underLineColor;
    
    if (underLineBlock) {
        underLineBlock(&_isShowUnderLine,&_isDelayScroll,&_underLineH,&underLineColor);
        
        _underLineColor = underLineColor;
    }
    
}

// 一次性设置所有标题属性
- (void)setUpTitleEffect:(void(^)(UIColor **titleScrollViewColor,UIColor **norColor,UIColor **selColor,UIFont **titleFont,CGFloat *titleHeight))titleEffectBlock{
    UIColor *titleScrollViewColor;
    UIColor *norColor;
    UIColor *selColor;
    UIFont *titleFont;
    if (titleEffectBlock) {
        titleEffectBlock(&titleScrollViewColor,&norColor,&selColor,&titleFont,&_titleHeight);
        _norColor = norColor;
        _selColor = selColor;
        _titleScrollViewColor = titleScrollViewColor;
        _titleFont = titleFont;
    }
}



#pragma mark - 控制器的生命周期
//layoutSubviews在以下情况下会被调用：
//1、init初始化不会触发layoutSubviews
//2、addSubview会触发layoutSubviews
//3、设置view的Frame会触发layoutSubviews，当然前提是frame的值设置前后发生了变化
//4、滚动一个UIScrollView会触发layoutSubviews
//5、旋转Screen会触发父UIView上的layoutSubviews事件
//6、改变一个UIView大小的时候也会触发父UIView上的layoutSubviews事件
//在这里设置整体视图、标题、内容滚动视图的尺寸可以解决操作过程中横屏时页面展示适配问题
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    //设置视图内容大小
    CGFloat contentX = 0;
    CGFloat contentY = self.navigationController?FRNavBarH : [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat contentW = [UIScreen mainScreen].bounds.size.width - 2 * contentX;
    CGFloat contentH = [UIScreen mainScreen].bounds.size.height - contentY;
    // 设置整个内容的尺寸
    if (self.contentView.bounds.size.height == 0) {
        // 没有设置内容尺寸，才需要设置内容尺寸
        self.contentView.frame = CGRectMake(0, contentY, contentW, contentH);
    }
    // 设置标题滚动视图frame
    // 计算尺寸
    CGFloat titleH = _titleHeight?_titleHeight:FRTitleScrollViewH;
    CGFloat titleY = _isfullScreen?contentY:0;
    self.titleScrollView.frame = CGRectMake(contentX, titleY, contentW, titleH);
    
    // 设置内容滚动视图frame
    CGFloat contentScrollY = CGRectGetMaxY(self.titleScrollView.frame);
    self.contentScrollView.frame = _isfullScreen?CGRectMake(0, 0, contentW, [UIScreen mainScreen].bounds.size.height) :CGRectMake(0, contentScrollY, contentW, self.contentView.bounds.size.height - contentScrollY);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_isInitial == NO) {
        
        _isInitial = YES;
        
        // 注册cell
        [self.contentScrollView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:ID];
        self.contentScrollView.backgroundColor = self.view.backgroundColor;
        
        // 初始化文字渐变颜色
        if (_isShowTitleGradient && _titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
            // 初始化颜色渐变
            if (_endR == 0 && _endG == 0 && _endB == 0) {
                _endR = 1;
            }
        }
        
        // 没有子控制器，不需要设置标题
        if (self.childViewControllers.count == 0) return;
        
        [self setUpTitleWidth];
        
        [self setUpAllTitle];
        
    }
}
#pragma mark - 设置标题
- (void)setUpTitleWidth {
    //获取需要显示的子控制器个数
    NSInteger count = self.childViewControllers.count;
    //取出子控制器的标题
    NSArray *titles = [self.childViewControllers valueForKeyPath:@"title"];
    
    CGFloat totalWidth = 0;
    for (NSString *title in titles) {
        //判断title是否为nil
        if ([title isKindOfClass:[NSNull class]]) {
            //如果控制器没有设置title，抛出异常
            NSException *excp = [NSException exceptionWithName:@"YZDisplayViewControllerException" reason:@"没有设置Controller.title属性，应该把子标题保存到对应子控制器中" userInfo:nil];
            [excp raise];
        }
        //根据文字内容和字体大小获取文字占据的bounds
        CGRect titleBounds = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.titleFont} context:nil];
        
        CGFloat width = titleBounds.size.width;
        [self.titleWidths addObject:@(width)];
        
        totalWidth += width;
    }
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    //判断所有子控制器的title的长度之和能否占据整个屏幕
    CGFloat titleWidth = totalWidth + (count + 1) * margin;
    if (titleWidth > screenWidth) {
        _titleMargin = margin;
        //为最后一个title增加右侧滚动距离
        self.titleScrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, _titleMargin);
        return;
    }
    
    CGFloat titleMargin = (screenWidth - totalWidth) / (count + 1);
    
    _titleMargin = titleMargin < margin? margin: titleMargin;
    
    self.titleScrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, _titleMargin);
}

- (void)setUpAllTitle {
    //获取需要显示的子控制器个数
    NSInteger count = self.childViewControllers.count;
    //添加标题
    CGFloat labelW = 0;
    CGFloat labelH = self.titleHeight;
    CGFloat labelX = 0;
    CGFloat labelY = 0;
    
    for (int i = 0; i < count; i++) {
        
        UIViewController *vc = self.childViewControllers[i];
        
        UILabel *label = [[FRSlideMenuTitleLabel alloc] init];
        
        label.tag = i;
        
        // 设置按钮的文字颜色
        label.textColor = self.norColor;
        label.font = self.titleFont;
        
        // 设置按钮标题
        label.text = vc.title;
        
        labelW = [self.titleWidths[i] floatValue];
        
        // 设置按钮位置
        UILabel *lastLabel = [self.titleLabels lastObject];
        labelX = _titleMargin + CGRectGetMaxX(lastLabel.frame);
        label.frame = CGRectMake(labelX, labelY, labelW, labelH);
        
        // 监听标题的点击
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleClick:)];
        [label addGestureRecognizer:tap];
        
        // 保存到数组
        [self.titleLabels addObject:label];
        
        [_titleScrollView addSubview:label];
        
        if (i == _selectIndex) {
            [self titleClick:tap];
        }
    }
    // 设置标题滚动视图的内容范围
    UILabel *lastLabel = self.titleLabels.lastObject;
    _titleScrollView.contentSize = CGSizeMake(CGRectGetMaxX(lastLabel.frame), 0);
    _titleScrollView.showsHorizontalScrollIndicator = NO;
    _contentScrollView.contentSize = CGSizeMake(count * [UIScreen mainScreen].bounds.size.width, 0);
}

#pragma mark - 标题点击处理
- (void)setSelectIndex:(NSInteger)selectIndex
{
    _selectIndex = selectIndex;
    if (self.titleLabels.count) {
        
        UILabel *label = self.titleLabels[selectIndex];
        
        [self titleClick:[label.gestureRecognizers lastObject]];
    }
}

// 标题按钮点击
- (void)titleClick:(UITapGestureRecognizer *)tap
{
    // 记录是否点击标题
    _isClickTitle = YES;
    
    // 获取对应标题label
    UILabel *label = (UILabel *)tap.view;
    
    // 获取当前角标
    NSInteger i = label.tag;
    
    // 选中label
    [self selectLabel:label];
    
    // 内容滚动视图滚动到对应位置
    CGFloat offsetX = i * [UIScreen mainScreen].bounds.size.width;
    
    self.contentScrollView.contentOffset = CGPointMake(offsetX, 0);
    
    // 记录上一次偏移量,因为点击的时候不会调用scrollView代理记录，因此需要主动记录
    _lastOffsetX = offsetX;
    
    // 添加控制器
    UIViewController *vc = self.childViewControllers[i];
    
    // 判断控制器的view有没有加载，没有就加载，加载完在发送通知
    if (vc.view) {
        // 发出通知点击标题通知
        [[NSNotificationCenter defaultCenter] postNotificationName:FRSlideMenuClickOrScrollDidFinshNote  object:vc];
        
        // 发出重复点击标题通知
        if (_selIndex == i) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FRSlideMenuRepeatClickTitleNote object:vc];
        }
    }
    _selIndex = i;
    
    // 点击事件处理完成
    _isClickTitle = NO;
}

/**
 *  按钮点击后改变Label属性
 */
- (void)selectLabel:(UILabel *)label
{
    
    for (FRSlideMenuTitleLabel *labelView in self.titleLabels) {
        
        if (label == labelView) continue;
        
        if (_isShowTitleGradient && _titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
            
            labelView.transform = CGAffineTransformIdentity;
        }
        
        labelView.textColor = self.norColor;
        
        if (_isShowTitleGradient && _titleColorGradientStyle == FRTitleColorGradientStyleFill) {
            
            labelView.fillColor = self.norColor;
            
            labelView.progress = 1;
        }
    }
    
    // 标题缩放
    if (_isShowTitleScale && _titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
        
        CGFloat scaleTransform = _titleScale?_titleScale:FRTitleTransformScale;
        
        label.transform = CGAffineTransformMakeScale(scaleTransform, scaleTransform);
    }
    
    // 修改标题选中颜色
    label.textColor = self.selColor;
    
    // 设置标题居中
    [self setLabelTitleCenter:label];
    
    // 设置下标的位置
    [self setUpUnderLine:label];
    
    // 设置cover
    [self setUpCoverView:label];
    
}

// 让选中的按钮居中显示
- (void)setLabelTitleCenter:(UILabel *)label
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    // 设置标题滚动区域的偏移量
    CGFloat offsetX = label.center.x - screenWidth * 0.5;
    
    if (offsetX < 0) {
        offsetX = 0;
    }
    
    // 计算下最大的标题视图滚动区域
    CGFloat maxOffsetX = self.titleScrollView.contentSize.width - screenWidth + _titleMargin;
    
    if (maxOffsetX < 0) {
        maxOffsetX = 0;
    }
    
    if (offsetX > maxOffsetX) {
        offsetX = maxOffsetX;
    }
    // 滚动区域
    [self.titleScrollView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
}


// 设置下标的位置
- (void)setUpUnderLine:(UILabel *)label
{
    // 获取文字尺寸
    CGRect titleBounds = [label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.titleFont} context:nil];
    
    CGFloat underLineH = _underLineH?_underLineH:FRUnderLineH;
    
    CGFloat underLineX = self.underLine.frame.origin.x;
    CGFloat underLineY = label.frame.size.height - underLineH;
    CGFloat underLineW = self.underLine.frame.size.width;
    self.underLine.frame = CGRectMake(underLineX, underLineY, underLineW, underLineH);
    
    // 最开始不需要动画
    if (self.underLine.frame.origin.x == 0) {
        underLineW = titleBounds.size.width;
        underLineX = label.frame.origin.x;
        self.underLine.frame = CGRectMake(underLineX, underLineY, underLineW, underLineH);
        return;
    }
    __weak typeof(self) weakSelf = self;
    // 点击时候需要动画
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = weakSelf.underLine.frame;
        frame.origin.x = label.frame.origin.x;
        frame.size.width = titleBounds.size.width;
        weakSelf.underLine.frame = frame;
    }];
    
}


// 设置蒙版
- (void)setUpCoverView:(UILabel *)label
{
    // 获取文字尺寸
    CGRect titleBounds = [label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.titleFont} context:nil];
    
    CGFloat border = 5;
    CGFloat coverH = titleBounds.size.height + 2 * border;
    CGFloat coverW = titleBounds.size.width + 2 * border;
    
    CGRect frame = self.coverView.frame;
    frame.origin.y = (label.frame.size.height - coverH) * 0.5;
    frame.size.height = coverH;
    self.coverView.frame = frame;
    
    // 最开始不需要动画
    if (frame.origin.x == 0) {
        frame.size.width = coverW;
        frame.origin.x = label.frame.origin.x - border;
        self.coverView.frame = frame;
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 点击时候需要动画
    [UIView animateWithDuration:0.25 animations:^{
        CGRect coverframe = weakSelf.coverView.frame;
        coverframe.origin.x =  label.frame.origin.x - border;
        coverframe.size.width = coverW;
        weakSelf.coverView.frame = coverframe;
    }];
}

#pragma mark - 刷新界面方法
// 更新界面
- (void)refreshDisplay
{
    // 清空之前所有标题
    [self.titleLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.titleLabels removeAllObjects];
    
    // 刷新表格
    [self.contentScrollView reloadData];
    
    // 重新设置标题
    [self setUpTitleWidth];
    
    [self setUpAllTitle];
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.childViewControllers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    
    // 移除之前的子控件
    //    makeObjectsPerformSelector:@select（aMethod）
    //    让数组中的每个元素 都调用 aMethod方法
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // 添加控制器
    UIViewController *vc = self.childViewControllers[indexPath.row];
    
    vc.view.frame = CGRectMake(0, 0, self.contentScrollView.frame.size.width, self.contentScrollView.frame.size.height);
   
    [cell.contentView addSubview:vc.view];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

// 减速完成
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger offsetXInt = offsetX;
    NSInteger screenWInt = screenWidth;
    
    NSInteger extre = offsetXInt % screenWInt;
    if (extre > screenWidth * 0.5) {
        // 往右边移动
        offsetX = offsetX + (screenWidth - extre);
        _isAnimationing = YES;
        [self.contentScrollView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
    }else if (extre < screenWidth * 0.5 && extre > 0){
        _isAnimationing = YES;
        // 往左边移动
        offsetX =  offsetX - extre;
        [self.contentScrollView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
    }
    
    // 获取角标
    NSInteger i = offsetX / screenWidth;
    
    // 选中标题
    [self selectLabel:self.titleLabels[i]];
    
    // 取出对应控制器发出通知
    UIViewController *vc = self.childViewControllers[i];
    
    // 发出通知
    [[NSNotificationCenter defaultCenter] postNotificationName:FRSlideMenuClickOrScrollDidFinshNote object:vc];
}


// 监听滚动动画是否完成
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _isAnimationing = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    // 点击和动画的时候不需要设置
    if (_isAnimationing || self.titleLabels.count == 0) return;
    
    // 获取偏移量
    CGFloat offsetX = scrollView.contentOffset.x;
    
    // 获取左边角标
    NSInteger leftIndex = offsetX / screenWidth;
    
    // 左边按钮
    FRSlideMenuTitleLabel *leftLabel = self.titleLabels[leftIndex];
    
    // 右边角标
    NSInteger rightIndex = leftIndex + 1;
    
    // 右边按钮
    FRSlideMenuTitleLabel *rightLabel = nil;
    
    if (rightIndex < self.titleLabels.count) {
        rightLabel = self.titleLabels[rightIndex];
    }
    
    // 字体放大
    [self setUpTitleScaleWithOffset:offsetX rightLabel:rightLabel leftLabel:leftLabel];
    
    // 设置下标偏移
    if (_isDelayScroll == NO) { // 延迟滚动，不需要移动下标
        
        [self setUpUnderLineOffset:offsetX rightLabel:rightLabel leftLabel:leftLabel];
    }
    
    // 设置遮盖偏移
    [self setUpCoverOffset:offsetX rightLabel:rightLabel leftLabel:leftLabel];
    
    // 设置标题渐变
    [self setUpTitleColorGradientWithOffset:offsetX rightLabel:rightLabel leftLabel:leftLabel];
    
    // 记录上一次的偏移量
    _lastOffsetX = offsetX;
}

#pragma mark - 标题效果渐变方法
// 设置标题颜色渐变
- (void)setUpTitleColorGradientWithOffset:(CGFloat)offsetX rightLabel:(FRSlideMenuTitleLabel *)rightLabel leftLabel:(FRSlideMenuTitleLabel *)leftLabel
{
    if (_isShowTitleGradient == NO) return;
    
    // 获取右边缩放
    CGFloat rightSacle = offsetX / [UIScreen mainScreen].bounds.size.width - leftLabel.tag;
    
    // 获取左边缩放比例
    CGFloat leftScale = 1 - rightSacle;
    
    // RGB渐变
    if (_titleColorGradientStyle == FRTitleColorGradientStyleRGB) {
        
        CGFloat r = _endR - _startR;
        CGFloat g = _endG - _startG;
        CGFloat b = _endB - _startB;
        
        // rightColor
        // 1 0 0
        UIColor *rightColor = [UIColor colorWithRed:_startR + r * rightSacle green:_startG + g * rightSacle blue:_startB + b * rightSacle alpha:1];
        
        // 0.3 0 0
        // 1 -> 0.3
        // leftColor
        UIColor *leftColor = [UIColor colorWithRed:_startR +  r * leftScale  green:_startG +  g * leftScale  blue:_startB +  b * leftScale alpha:1];
        
        // 右边颜色
        rightLabel.textColor = rightColor;
        
        // 左边颜色
        leftLabel.textColor = leftColor;
        
        return;
    }
    
    // 填充渐变
    if (_titleColorGradientStyle == FRTitleColorGradientStyleFill) {
        
        // 获取移动距离
        CGFloat offsetDelta = offsetX - _lastOffsetX;
        
        if (offsetDelta > 0) { // 往右边
            
            
            rightLabel.fillColor = self.selColor;
            rightLabel.progress = rightSacle;
            
            leftLabel.fillColor = self.norColor;
            leftLabel.progress = rightSacle;
            
        } else if(offsetDelta < 0){ // 往左边
            
            rightLabel.textColor = self.norColor;
            rightLabel.fillColor = self.selColor;
            rightLabel.progress = rightSacle;
            
            leftLabel.textColor = self.selColor;
            leftLabel.fillColor = self.norColor;
            leftLabel.progress = rightSacle;
            
        }
    }
}

// 标题缩放
- (void)setUpTitleScaleWithOffset:(CGFloat)offsetX rightLabel:(UILabel *)rightLabel leftLabel:(UILabel *)leftLabel
{
    if (_isShowTitleScale == NO) return;
    
    // 获取右边缩放
    CGFloat rightSacle = offsetX / [UIScreen mainScreen].bounds.size.width - leftLabel.tag;
    
    CGFloat leftScale = 1 - rightSacle;
    
    CGFloat scaleTransform = _titleScale?_titleScale:FRTitleTransformScale;
    
    scaleTransform -= 1;
    
    // 缩放按钮
    leftLabel.transform = CGAffineTransformMakeScale(leftScale * scaleTransform + 1, leftScale * scaleTransform + 1);
    
    // 1 ~ 1.3
    rightLabel.transform = CGAffineTransformMakeScale(rightSacle * scaleTransform + 1, rightSacle * scaleTransform + 1);
}

// 获取两个标题按钮宽度差值
- (CGFloat)widthDeltaWithRightLabel:(UILabel *)rightLabel leftLabel:(UILabel *)leftLabel
{
    CGRect titleBoundsR = [rightLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.titleFont} context:nil];
    
    CGRect titleBoundsL = [leftLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.titleFont} context:nil];
    
    return titleBoundsR.size.width - titleBoundsL.size.width;
}

// 设置下标偏移
- (void)setUpUnderLineOffset:(CGFloat)offsetX rightLabel:(UILabel *)rightLabel leftLabel:(UILabel *)leftLabel
{
    if (_isClickTitle) return;
    
    // 获取两个标题中心点距离
    CGFloat centerDelta = rightLabel.frame.origin.x - leftLabel.frame.origin.x;
    
    // 标题宽度差值
    CGFloat widthDelta = [self widthDeltaWithRightLabel:rightLabel leftLabel:leftLabel];
    
    // 获取移动距离
    CGFloat offsetDelta = offsetX - _lastOffsetX;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    // 计算当前下划线偏移量
    CGFloat underLineTransformX = offsetDelta * centerDelta / screenWidth;
    
    // 宽度递增偏移量
    CGFloat underLineWidth = offsetDelta * widthDelta / screenWidth;
    
    CGRect frame = self.underLine.frame;
    frame.size.width += underLineWidth;
    frame.origin.x += underLineTransformX;
    self.underLine.frame = frame;
}

// 设置遮盖偏移
- (void)setUpCoverOffset:(CGFloat)offsetX rightLabel:(UILabel *)rightLabel leftLabel:(UILabel *)leftLabel
{
    if (_isClickTitle) return;
    
    // 获取两个标题中心点距离
    CGFloat centerDelta = rightLabel.frame.origin.x - leftLabel.frame.origin.x;
    
    // 标题宽度差值
    CGFloat widthDelta = [self widthDeltaWithRightLabel:rightLabel leftLabel:leftLabel];
    
    // 获取移动距离
    CGFloat offsetDelta = offsetX - _lastOffsetX;
    
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // 计算当前下划线偏移量
    CGFloat coverTransformX = offsetDelta * centerDelta / screenWidth;
    
    // 宽度递增偏移量
    CGFloat coverWidth = offsetDelta * widthDelta / screenWidth;
    
    CGRect frame = self.coverView.frame;
    frame.size.width += coverWidth;
    frame.origin.x += coverTransformX;
    self.coverView.frame = frame;
}



@end
