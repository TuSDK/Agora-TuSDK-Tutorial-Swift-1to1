/********************************************************
 * @file    : TuSDKManager.m
 * @author  : Copyright © http://tutucloud.com/
 * @date    : 2020-08-01
 * @brief   :
*********************************************************/

#import "TuSDKManager.h"

#import "TuFilterPanelView.h"
#import "TuBeautyPanelView.h"
#import "TuStickerPanelView.h"

#import <TuSDKPulse/TUPDispatchQueue.h>
#import <TuSDKPulseFilter/TuSDKPulseFilter.h>

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

@interface TuSDKManager()<TuFilterPanelViewDelegate, TuStickerPanelViewDelegate, TuBeautyPanelViewDelegate, SelesParametersListener>
{
    UIView *_superView;
    UIButton *_filterButton;   /**滤镜按钮*/
    UIButton *_stickerButton;  /**贴纸按钮*/
    UIButton *_beautyButton;   /**美肤按钮*/
    
    TuFilterPanelView *_filterPanelView;
    TuBeautyPanelView *_beautyPanelView;
    TuStickerPanelView *_stickerPanelView;
    
    TUPFPImage_CMSampleBufferCvt *_imgcvt;
    TUPFilterPipe *_pipeline;
    
    TUPFPImage* _pipeInImage;
    TUPFPImage* _pipeOutImage;
    
    TUPDispatchQueue *_pipeOprationQueue;
    NSLock *_pipeOutLock;
    
    NSMutableArray<NSNumber *> *_filterChain; // 滤镜链[滤镜执行的先后顺序, 顺序改变会影响最终的效果。建议不要更改]
    NSMutableDictionary<NSNumber*, NSObject*> *_filterPropertys;
    
}


@end

@implementation TuSDKManager

#pragma mark - init
- (instancetype)init
{
    if (self = [super init]) {
        _enableLiveSticker = YES;
        _enableLiveBeauty = YES;
    }
    return self;
}

+ (instancetype)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TuSDKManager alloc] init];
    });
    return instance;
}

- (void)initSdkWithAppKey:(NSString *)appKey
{
    [TUCCore initSdkWithAppKey:appKey];
    [TUCCore setLogLevel:TuLogLevelDEBUG];
    _isInitedTuSDK = YES;
}

#pragma mark - dealloc
- (void)destoryTuSDKView
{
    [_filterButton removeFromSuperview];
    [_stickerButton removeFromSuperview];
    [_beautyButton removeFromSuperview];
    
    [_filterPanelView removeFromSuperview];
    [_stickerPanelView removeFromSuperview];
    [_beautyPanelView removeFromSuperview];
    
    _filterButton = nil;
    _stickerButton = nil;
    _beautyButton = nil;
    
    _filterPanelView = nil;
    _stickerPanelView = nil;
    _beautyPanelView = nil;
}

#pragma mark - TuSDKFilter
- (void)configTuSDKViewWithSuperView:(UIView*)superView
{
    [self destoryTuSDKView];
    _superView = superView;
    
    [self initModuleBtn];
    
    {
        //滤镜面板
        UIView *filterView = [self configFilterPanelView];
        [superView addSubview:filterView];
    }
    if (_enableLiveSticker)
    {
        //贴纸面板
        UIView *stickerView = [self configStickerPanelView];
        [superView addSubview:stickerView];
    }
    if (_enableLiveBeauty)
    {
        //美肤面板
        UIView *beautyView = [self configBeautyPanelView];
        [superView addSubview:beautyView];
    }
    
    _pipeOprationQueue = [[TUPDispatchQueue alloc] initWithName:@"pipeOprationQueue"];

    _filterChain = [[NSMutableArray alloc] init];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_None]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_ReshapeFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_CosmeticFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_MonsterFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_PlasticFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_SkinFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_StickerFace]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_Filter]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_Comic]];
    [_filterChain addObject:[NSNumber numberWithInteger:TuFilterModel_Ratio]];
    
    _filterPropertys = [NSMutableDictionary dictionary];
    
    _pipeOutLock = [[NSLock alloc] init];
    
    [_pipeOprationQueue runSync:^{
        
        self->_imgcvt = [[TUPFPImage_CMSampleBufferCvt alloc] init];
        self->_pipeline = [[TUPFilterPipe alloc] init];
        TUPConfig *config = [[TUPConfig alloc] init];
        [config setIntNumber:1 forKey:@"pbout"];
        [self->_pipeline setConfig:config];
        [self->_pipeline open];
    }];
    
    _isInitFilterPipeline = YES;
}


#pragma mark - TuSDK init
- (void)initModuleBtn
{
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    UIColor *btnBGColor = lsqRGB(255, 102, 51);
    
    //滤镜按钮
    if (!_filterButton)
    {
        _filterButton = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth - 70, 80, 46, 46)];
        _filterButton.layer.cornerRadius = 16;
        _filterButton.backgroundColor = btnBGColor;
        [_filterButton setTitle:@"滤镜" forState:UIControlStateNormal];
        _filterButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_filterButton addTarget:self action:@selector(clickFilterBtn) forControlEvents:UIControlEventTouchUpInside];
        [_superView addSubview:_filterButton];
    }
    
    //贴纸按钮
    if (_enableLiveSticker)
    {
        if (!_stickerButton)
        {
            _stickerButton = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth - 70, 140, 46, 46)];
            _stickerButton.layer.cornerRadius = 16;
            _stickerButton.backgroundColor = btnBGColor;
            [_stickerButton setTitle:@"贴纸" forState:UIControlStateNormal];
            _stickerButton.titleLabel.font = [UIFont systemFontOfSize:13];
            [_stickerButton addTarget:self action:@selector(clickStickerBtn) forControlEvents:UIControlEventTouchUpInside];
            [_superView addSubview:_stickerButton];
        }
    }
    //美肤按钮
    if (_enableLiveBeauty)
    {
        if (!_beautyButton)
        {
            _beautyButton = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth - 70, 200, 46, 46)];
            _beautyButton.layer.cornerRadius = 16;
            _beautyButton.backgroundColor = btnBGColor;
            [_beautyButton setTitle:@"微整形" forState:UIControlStateNormal];
            _beautyButton.titleLabel.font = [UIFont systemFontOfSize:13];
            [_beautyButton addTarget:self action:@selector(clickBeautyBtn) forControlEvents:UIControlEventTouchUpInside];
            [_superView addSubview:_beautyButton];
        }
    }
}

- (void)clickFilterBtn
{
    _filterPanelView.hidden = !_filterPanelView.hidden;
    _beautyPanelView.hidden = _stickerPanelView.hidden = YES;
}

- (void)clickStickerBtn
{
    _stickerPanelView.hidden = !_stickerPanelView.hidden;
    _beautyPanelView.hidden = _filterPanelView.hidden = YES;
}

- (void)clickBeautyBtn
{
    _beautyPanelView.hidden = !_beautyPanelView.hidden;
    _stickerPanelView.hidden = _filterPanelView.hidden = YES;
}

/**
 *  配置滤镜面板
 *  @return 滤镜面板
 */
- (UIView *)configFilterPanelView
{
    [_filterPanelView removeFromSuperview];
    _filterPanelView = nil;
        
    _filterPanelView = [[TuFilterPanelView alloc] initWithFrame:CGRectMake(0, KScreenHeight - 246, KScreenWidth, 246)];
    _filterPanelView.delegate = self;
    _filterPanelView.hidden = YES;
    [_superView addSubview:_filterPanelView];
    return _filterPanelView;
}

/**
 *  贴纸面板
 *  @return 贴纸面板
 */
- (UIView *)configStickerPanelView
{
    [_stickerPanelView removeFromSuperview];
    _stickerPanelView = nil;
        
    _stickerPanelView = [[TuStickerPanelView alloc] initWithFrame:CGRectMake(0, KScreenHeight - 200, KScreenWidth, 200)];
    _stickerPanelView.hidden = YES;
    _stickerPanelView.delegate = self;
    [_superView addSubview:_stickerPanelView];
    return _stickerPanelView;
}

/**
 *  配置美肤面板
 *  @return 美肤面板
 */
- (UIView *)configBeautyPanelView
{
    [_beautyPanelView removeFromSuperview];
    _beautyPanelView = nil;
    
    _beautyPanelView = [[TuBeautyPanelView alloc] initWithFrame:CGRectMake(0, KScreenHeight - 276, KScreenWidth, 276)];
    _beautyPanelView.delegate = self;
    _beautyPanelView.hidden = YES;
    [_superView addSubview:_beautyPanelView];
    return _beautyPanelView;
}

- (NSInteger)FilterIndex:(TuFilterModel)filterModel
{
    NSInteger filterIndex = 0;

    if ([_filterChain containsObject:[NSNumber numberWithInteger:filterModel]])
    {
        filterIndex = [_filterChain indexOfObject:[NSNumber numberWithInteger:filterModel]];
    }
    
    return filterIndex;
}

#pragma mark - TuFilterPanelViewDelegate
// --------------------------------------------------
- (SelesParameters *)tuFilterPanelView:(TuFilterPanelView *)panelView didSelectedFilterCode:(NSString *)code
{
    SelesParameters *params = [self changeFilter:code];
        
    return params;
}

#pragma mark - TuStickerPanelViewDelegate
- (void)stickerPanelView:(TuStickerPanelView *)panelView didSelectItem:(__kindof TuStickerBaseData *)categoryItem;
{
    [_stickerPanelView enableStickers:NO];
    
    //动态贴纸和哈哈镜不能同时存在
    if ([categoryItem isKindOfClass:[TuMonsterData class]])
    {
        // 微整形移除
        [_beautyPanelView enablePlastic:NO];
        [_beautyPanelView enableExtraPlastic:NO];
        
        //贴纸移除
        [self removeStickerFilter];
        
        TuMonsterData *monsterData = (TuMonsterData *)categoryItem;
        [self addFaceMonsterFilter:(TuSDKMonsterFaceType)[((NSNumber *)monsterData.item) unsignedIntValue]];
    }
    else
    {
        TuStickerGroup *item = (TuStickerGroup *)categoryItem.item;
        if (item)
        {
            [self addStickerFilter:item];
        }
    }
}

- (void)stickerPanelView:(TuStickerPanelView *)panelView unSelectItem:(__kindof TuStickerBaseData *)categoryItem;
{
    //贴纸移除
    [self removeStickerFilter];
    //哈哈镜移除
    [self removeFaceMonsterFilter];
}

- (void)stickerPanelView:(TuStickerPanelView *)panelView didRemoveItem:(__kindof TuStickerBaseData *)categoryItem;
{
    //[[TuViews shared].messageHub showToast:@"贴纸删除"];
}

- (void)stickerPanelViewHidden:(TuStickerPanelView *)panelView;
{
    //[[TuViews shared].messageHub showToast:@"贴纸页面隐藏"];
}

#pragma mark - TuBeautyPanelViewDelegate
// --------------------------------------------------
- (SelesParameters *)tuBeautyPanelView:(TuBeautyPanelView *)view enablePlastic:(BOOL)enable
{
    // 哈哈镜移除
    [self removeFaceMonsterFilter];
    
    if (enable)
    {
        SelesParameters *params = [TuBeautyPanelConfig defaultPlasticParameters];
        SelesParameters *palsticParams = [self addFacePlasticFilter:params];
        return palsticParams;
    }
    else
    {
        [self removeFacePlasticFilter];
        return nil;
    }
}

- (SelesParameters *)tuBeautyPanelView:(TuBeautyPanelView *)view enableExtraPlastic:(BOOL)enable
{
    // 哈哈镜移除
    [self removeFaceMonsterFilter];
    
    if (enable)
    {
        SelesParameters *params = [TuBeautyPanelConfig defaultPlasticExtraParameters];
        SelesParameters *palsticExtraParams = [self addFacePlasticExtraFilter:params];
        return palsticExtraParams;
    }
    else
    {
        [self removeFacePlasticExtraFilter];
        return nil;
    }
}

- (SelesParameters *)tuBeautyPanelView:(TuBeautyPanelView *)view enableSkin:(BOOL)enable mode:(TuSkinFaceType)mode
{
    if (enable)
    {
        SelesParameters *params = [TuBeautyPanelConfig defaultSkinParameters:mode];
        {
            SelesParameters *preParams = [_beautyPanelView skinParams];
            if (preParams)
            {
                [params setArgWithKey:@"smoothing" precent:[preParams argWithKey:@"smoothing"].value];
                [params setArgWithKey:@"whitening" precent:[preParams argWithKey:@"whitening"].value];
                
                SelesParameterArg *ruddyOrSharpenArg = [params argWithKey:@"ruddy"];
                if (ruddyOrSharpenArg == Nil)
                {
                    ruddyOrSharpenArg = [params argWithKey:@"sharpen"];
                }
                
                if (ruddyOrSharpenArg)
                {
                    SelesParameterArg *preRuddyOrSharpenArg = [preParams argWithKey:@"ruddy"];
                    if (preRuddyOrSharpenArg == Nil)
                    {
                        preRuddyOrSharpenArg = [preParams argWithKey:@"sharpen"];
                    }
                    
                    if (preRuddyOrSharpenArg)
                    {
                        ruddyOrSharpenArg.value = preRuddyOrSharpenArg.value;
                    }
                }
            }
        }
        SelesParameters *skinParams = [self addFaceSkinBeautifyFilter:params type:mode];
        
        return skinParams;
    }
    else
    {
        [self removeFaceSkinBeautifyFilter];
        return nil;
    }
}

- (SelesParameters *)tuBeautyPanelView:(TuBeautyPanelView *)view enableCosmetic:(BOOL)enable
{
    if (enable)
    {
        SelesParameters *params = [TuBeautyPanelConfig defaultCosmeticParameters];
        SelesParameters *cosmeticParams = [self addFaceCosmeticFilter:params];
        return cosmeticParams;
    }
    else
    {
        //清除所有美妆效果
        [self resetAllCosmeticAction];
        return nil;
    }
}

- (SelesParameters *)tuBeautyPanelView:(TuBeautyPanelView *)view enableCosmetic:(BOOL)enable isAskPop:(BOOL)isAskPop
{
    // 哈哈镜移除
//    [_cameraShower removeFaceMonsterFilter];

    if (enable)
    {
        SelesParameters *params = [TuBeautyPanelConfig defaultCosmeticParameters];
        SelesParameters *cosmeticParams = [self addFaceCosmeticFilter:params];
        return cosmeticParams;
    }
    else
    {
        if (isAskPop)
        {
            //清除所有美妆效果
            [self resetAllCosmeticAction];
        }
        else
        {
            [self removeFaceCosmeticFilter];
            _beautyPanelView.resetCosmetic = YES;
        }
        return nil;
    }
}

- (void)tuBeautyPanelView:(TuBeautyPanelView *)view plasticdidSelectCode:(NSString *)code;
{
    // 哈哈镜移除
    [_stickerPanelView enableStickers:YES];
}

- (void)tuBeautyPanelView:(TuBeautyPanelView *)view cosmeticParamCode:(NSString *)code enable:(BOOL)enable
{
    [self updateCosmeticParam:code enable:enable];
}

- (void)tuBeautyPanelView:(TuBeautyPanelView *)view cosmeticParamCode:(NSString *)code value:(NSInteger)value
{
    [self updateCosmeticParam:code value:value];
}

//重置所有美妆效果
- (void)resetAllCosmeticAction
{
    typeof(self)weakSelf = self;
    NSString *title = NSLocalizedStringFromTable(@"tu_美妆", @"VideoDemo", @"美妆");
    NSString *msg = NSLocalizedStringFromTable(@"tu_确定删除所有美妆效果?", @"VideoDemo", @"美妆");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LSQString(@"lsq_nav_cancel", @"取消") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *confimAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"tu_确定", @"VideoDemo", @"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf removeFaceCosmeticFilter];
        weakSelf->_beautyPanelView.resetCosmetic = YES;
        
    }];
    [alert addAction:cancelAction];
    [alert addAction:confimAction];
}

#pragma mark - Filter Process Functions
// 滤镜添加删除功能列表 --------------------------------------------------
- (SelesParameters *)changeFilter:(NSString *)code
{
    NSString *filterCode = code;
    TuFilterModel filterModel = TuFilterModel_Filter;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    if ([filterCode isEqualToString:@"Normal"])
    {
        [_pipeOprationQueue runSync:^{
            if ([self->_pipeline getFilter:filterIndex])
            {
                [self->_pipeline deleteFilterAt:filterIndex];
            }
        }];

        // 无效果
        return nil;
    }
    
    // params
    SelesParameters *filterParams = [SelesParameters parameterWithCode:filterCode model:filterModel];
    TuFilterOption *filtrOption = [[TuFilterLocalPackage package] optionWithCode:filterCode];
    for (NSString *key in filtrOption.args)
    {
        NSNumber *val = [filtrOption.args valueForKey:key];
        [filterParams appendFloatArgWithKey:key value:val.floatValue];
    }
    filterParams.listener = self;


    // filter
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }

        TUPFPFilter *filter = [[TUPFPFilter alloc] init:self->_pipeline.getContext withName:TUPFPTusdkImageFilter_TYPE_NAME];
        {
            TUPConfig *config = [[TUPConfig alloc] init];
            [config setString:filterParams.code forKey:TUPFPTusdkImageFilter_CONFIG_NAME];
            [filter setConfig:config];
        }
        [self->_pipeline addFilter:filter at:filterIndex];

        // property
        if (filterParams.count > 0)
        {
            TUPFPTusdkImageFilter_Type10PropertyBuilder *property = [[TUPFPTusdkImageFilter_Type10PropertyBuilder alloc] init];
            {
                property.strength = filterParams.args[0].value;
            }
            [filter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
            [self->_filterPropertys setObject:property forKey:@(filterModel)];
        }
    }];

    return filterParams;
}

//添加贴纸数据
- (void)addStickerFilter:(TuStickerGroup *)stickerGroup
{
    NSString *filterCode = TUPFPTusdkLiveStickerFilter_TYPE_NAME;
    TuFilterModel filterModel = TuFilterModel_StickerFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    if (stickerGroup == nil)
    {
        return;
    }
        
    NSInteger stickerGroupId = stickerGroup.idt;

    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }

        TUPFPFilter* stickerFilter = [[TUPFPFilter alloc] init:self->_pipeline.getContext withName:filterCode];
        {
            TUPConfig* config = [[TUPConfig alloc] init];
            [config setNumber:[NSNumber numberWithInteger:stickerGroupId] forKey:TUPFPTusdkLiveStickerFilter_CONFIG_GROUP];
            [stickerFilter setConfig:config];
        }
        [self->_pipeline addFilter:stickerFilter at:filterIndex];
    }];
}

//添加哈哈镜数据
- (void)addFaceMonsterFilter:(TuSDKMonsterFaceType)type
{
    NSString *filterCode = nil;
    TuFilterModel filterModel = TuFilterModel_MonsterFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    switch (type)
    {
    case TuSDKMonsterFaceTypeBigNose:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_BigNose;
        break;
    case TuSDKMonsterFaceTypePieFace:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_PieFace;
        break;
    case TuSDKMonsterFaceTypeSquareFace:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_SquareFace;
        break;
    case TuSDKMonsterFaceTypeThickLips:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_ThickLips;
        break;
    case TuSDKMonsterFaceTypeSmallEyes:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_SmallEyes;
        break;
    case TuSDKMonsterFaceTypePapayaFace:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_PapayaFace;
        break;
    case TuSDKMonsterFaceTypeSnakeFace:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_SnakeFace;
        break;
    default:
        filterCode = TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE_Empty;
        break;
    }
    
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
        TUPFPFilter* monsterFilter = [[TUPFPFilter alloc] init:self->_pipeline.getContext withName:TUPFPTusdkFaceMonsterFilter_TYPE_NAME];
        {
            TUPConfig* config = [[TUPConfig alloc] init];
            [config setString:filterCode forKey:TUPFPTusdkFaceMonsterFilter_CONFIG_TYPE];
            [monsterFilter setConfig:config];
        }
        [self->_pipeline addFilter:monsterFilter at:filterIndex];
    }];
}

//移除贴纸
- (void)removeStickerFilter
{
    TuFilterModel filterModel = TuFilterModel_StickerFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
}

//移除哈哈镜
- (void)removeFaceMonsterFilter
{
    TuFilterModel filterModel = TuFilterModel_MonsterFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
}

//添加美肤
- (SelesParameters *)addFaceSkinBeautifyFilter:(SelesParameters *)params type:(TuSkinFaceType)type
{
    NSString *filterCode = nil;
    TuFilterModel filterModel = TuFilterModel_SkinFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    switch (type)
    {
    case TuSkinFaceTypeNatural:
        filterCode = TUPFPTusdkImageFilter_NAME_SkinNatural;
        break;
    case TuSkinFaceTypeMoist:
        filterCode = TUPFPTusdkImageFilter_NAME_SkinHazy;
        break;
    case TuSkinFaceTypeBeauty:
    default:
        filterCode = TUPFPTusdkBeautFaceV2Filter_TYPE_NAME;
        break;
    }
    
    
    // params
    SelesParameters *filterParams = [SelesParameters parameterWithCode:filterCode model:filterModel];
    for (SelesParameterArg *arg in params.args)
    {
        [filterParams appendFloatArgWithKey:arg.key value:arg.value];
    }
    filterParams.listener = self;
    
    switch (type)
    {
        case TuSkinFaceTypeNatural:
        {
            TUPFPTusdkImageFilter_SkinNaturalPropertyBuilder *property = [[TUPFPTusdkImageFilter_SkinNaturalPropertyBuilder alloc] init];
            for (SelesParameterArg *arg in filterParams.args)
            {
                if ([arg.key isEqualToString:@"smoothing"]) { property.smoothing = arg.value; }
                else if ([arg.key isEqualToString:@"whitening"]) { property.fair = arg.value; }
                else if ([arg.key isEqualToString:@"ruddy"]) { property.ruddy = arg.value; }
            }
            [_filterPropertys setObject:property forKey:@(TuFilterModel_SkinFace)];
            
            TUPFPFilter* skinBeautifyFilter = [[TUPFPFilter alloc] init:_pipeline.getContext withName:TUPFPTusdkImageFilter_TYPE_NAME];
            {
                TUPConfig* config = [[TUPConfig alloc] init];
                [config setString:filterCode forKey:TUPFPTusdkImageFilter_CONFIG_NAME];
                [skinBeautifyFilter setConfig:config];
            }
            
            
            // filter
            [_pipeOprationQueue runSync:^{
                if ([self->_pipeline getFilter:filterIndex])
                {
                    [self->_pipeline deleteFilterAt:filterIndex];
                }
                [self->_pipeline addFilter:skinBeautifyFilter at:filterIndex];
                [skinBeautifyFilter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
            }];
        }
        break;
                
        case TuSkinFaceTypeMoist:
        {
            TUPFPTusdkImageFilter_SkinHazyPropertyBuilder *property = [[TUPFPTusdkImageFilter_SkinHazyPropertyBuilder alloc] init];
            for (SelesParameterArg *arg in filterParams.args)
            {
                if ([arg.key isEqualToString:@"smoothing"]) { property.smoothing = arg.value; }
                else if ([arg.key isEqualToString:@"whitening"]) { property.fair = arg.value; }
                else if ([arg.key isEqualToString:@"ruddy"]) { property.ruddy = arg.value; }
            }
            [_filterPropertys setObject:property forKey:@(TuFilterModel_SkinFace)];
            
            TUPFPFilter* skinBeautifyFilter = [[TUPFPFilter alloc] init:_pipeline.getContext withName:TUPFPTusdkImageFilter_TYPE_NAME];
            {
                TUPConfig* config = [[TUPConfig alloc] init];
                [config setString:filterCode forKey:TUPFPTusdkImageFilter_CONFIG_NAME];
                [skinBeautifyFilter setConfig:config];
            }

            // filter
            [_pipeOprationQueue runSync:^{
                if ([self->_pipeline getFilter:filterIndex])
                {
                    [self->_pipeline deleteFilterAt:filterIndex];
                }
                [self->_pipeline addFilter:skinBeautifyFilter at:filterIndex];
                [skinBeautifyFilter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
            }];
        }
        break;
                
        case TuSkinFaceTypeBeauty:
        default:
        {
            TUPFPTusdkBeautFaceV2Filter_PropertyBuilder *property = [[TUPFPTusdkBeautFaceV2Filter_PropertyBuilder alloc] init];
            for (SelesParameterArg *arg in filterParams.args)
            {
                if ([arg.key isEqualToString:@"smoothing"]) { property.smoothing = arg.value; }
                else if ([arg.key isEqualToString:@"whitening"]) { property.whiten = arg.value; }
                else if ([arg.key isEqualToString:@"sharpen"]) { property.sharpen = arg.value; }
            }
            [_filterPropertys setObject:property forKey:@(TuFilterModel_SkinFace)];
            
            // filter
            [_pipeOprationQueue runSync:^{
                if ([self->_pipeline getFilter:filterIndex])
                {
                    [self->_pipeline deleteFilterAt:filterIndex];
                }
                TUPFPFilter *skinBeautifyFilter = [[TUPFPFilter alloc] init:self->_pipeline.getContext withName:filterCode];
                [self->_pipeline addFilter:skinBeautifyFilter at:filterIndex];
                [skinBeautifyFilter setProperty:property.makeProperty forKey:TUPFPTusdkBeautFaceV2Filter_PROP_PARAM];
            }];
        }
        break;
    }

    return filterParams;
}

//添加微整形
- (SelesParameters *)addFacePlasticFilter:(SelesParameters *)params
{
    NSString *filterCode = TUPFPTusdkFacePlasticFilter_TYPE_NAME;
    TuFilterModel filterModel = TuFilterModel_PlasticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    // params
    SelesParameters *filterParams = [SelesParameters parameterWithCode:filterCode model:filterModel];
    for (SelesParameterArg *arg in params.args)
    {
        
        
        [filterParams appendFloatArgWithKey:arg.key value:arg.value minValue:arg.minFloatValue maxValue:arg.maxFloatValue];
    }
    filterParams.listener = self;
    
    // Property
    TUPFPTusdkFacePlasticFilter_PropertyBuilder *property = [[TUPFPTusdkFacePlasticFilter_PropertyBuilder alloc] init];
    for (SelesParameterArg *arg in filterParams.args)
    {
        if ([arg.key isEqualToString:@"eyeSize"]) { property.eyeEnlarge = arg.value; }
        else if ([arg.key isEqualToString:@"chinSize"]) { property.cheekThin = arg.value; }
        else if ([arg.key isEqualToString:@"cheekNarrow"]) { property.cheekNarrow = arg.value; }
        else if ([arg.key isEqualToString:@"smallFace"]) { property.faceSmall = arg.value; }
        else if ([arg.key isEqualToString:@"noseSize"]) { property.noseWidth = arg.value; }
        else if ([arg.key isEqualToString:@"noseHeight"]) { property.noseHeight = arg.value; }
        else if ([arg.key isEqualToString:@"mouthWidth"]) { property.mouthWidth = arg.value; }
        else if ([arg.key isEqualToString:@"lips"]) { property.lipsThickness = arg.value; }
        else if ([arg.key isEqualToString:@"philterum"]) { property.philterumThickness = arg.value; }
        else if ([arg.key isEqualToString:@"archEyebrow"]) { property.browThickness = arg.value; }
        else if ([arg.key isEqualToString:@"browPosition"]) { property.browHeight = arg.value; }
        else if ([arg.key isEqualToString:@"jawSize"]) { property.chinThickness = arg.value; }
        else if ([arg.key isEqualToString:@"cheekLowBoneNarrow"]) { property.cheekLowBoneNarrow = arg.value; }
        else if ([arg.key isEqualToString:@"eyeAngle"]) { property.eyeAngle = arg.value; }
        else if ([arg.key isEqualToString:@"eyeInnerConer"]) { property.eyeInnerConer = arg.value; }
        else if ([arg.key isEqualToString:@"eyeOuterConer"]) { property.eyeOuterConer = arg.value; }
        else if ([arg.key isEqualToString:@"eyeDis"]) { property.eyeDistance = arg.value; }
        else if ([arg.key isEqualToString:@"eyeHeight"]) { property.eyeHeight = arg.value; }
        else if ([arg.key isEqualToString:@"forehead"]) { property.foreheadHeight = arg.value; }
        else if ([arg.key isEqualToString:@"cheekBoneNarrow"]) { property.cheekBoneNarrow = arg.value; }
    }
    [_filterPropertys setObject:property forKey:@(filterModel)];

    
    // filter
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
        TUPFPFilter *plasticFilter = [[TUPFPFilter alloc]init:[self->_pipeline getContext] withName:TUPFPTusdkFacePlasticFilter_TYPE_NAME];
        [self->_pipeline addFilter:plasticFilter at:filterIndex];
        [plasticFilter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
    
    return filterParams;
}

- (SelesParameters *)addFacePlasticExtraFilter:(SelesParameters *)params
{
    NSString *filterCode = TUPFPTusdkFaceReshapeFilter_TYPE_NAME;
    TuFilterModel filterModel = TuFilterModel_ReshapeFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    // params
    SelesParameters *filterParams = [SelesParameters parameterWithCode:filterCode model:filterModel];
    for (SelesParameterArg *arg in params.args)
    {
        [filterParams appendFloatArgWithKey:arg.key value:arg.value];
    }
    filterParams.listener = self;
    
    // Property
    TUPFPTusdkFaceReshapeFilter_PropertyBuilder *property = [[TUPFPTusdkFaceReshapeFilter_PropertyBuilder alloc] init];
    for (SelesParameterArg *arg in filterParams.args)
    {
        if ([arg.key isEqualToString:@"eyelid"]) { property.eyelidOpacity = arg.value; }
        else if ([arg.key isEqualToString:@"eyemazing"]) { property.eyemazingOpacity = arg.value; }
        else if ([arg.key isEqualToString:@"whitenTeeth"]) { property.whitenTeethOpacity = arg.value; }
        else if ([arg.key isEqualToString:@"eyeDetail"]) { property.eyeDetailOpacity = arg.value; }
        else if ([arg.key isEqualToString:@"removePouch"]) { property.removePouchOpacity = arg.value; }
        else if ([arg.key isEqualToString:@"removeWrinkles"]) { property.removeWrinklesOpacity = arg.value; }
    }
    [_filterPropertys setObject:property forKey:@(filterModel)];

    // filter
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
        TUPFPFilter *reshapeFilter = [[TUPFPFilter alloc]init:[self->_pipeline getContext] withName:filterCode];
        [self->_pipeline addFilter:reshapeFilter at:filterIndex];
        [reshapeFilter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
    
    return filterParams;
}

//添加美妆
- (SelesParameters *)addFaceCosmeticFilter:(SelesParameters *)params
{
    NSString *filterCode = TUPFPTusdkCosmeticFilter_TYPE_NAME;
    TuFilterModel filterModel = TuFilterModel_CosmeticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    // params
    SelesParameters *filterParams = [SelesParameters parameterWithCode:filterCode model:filterModel];
    for (SelesParameterArg *arg in params.args)
    {
        [filterParams appendFloatArgWithKey:arg.key value:arg.value];
    }
    filterParams.listener = self;
            

    // Property
    TUPFPTusdkCosmeticFilter_PropertyBuilder *cosmeticProperty = [[TUPFPTusdkCosmeticFilter_PropertyBuilder alloc] init];
    
    for (SelesParameterArg *arg in filterParams.args)
    {
        if ([arg.key isEqualToString:@"facialEnable"]) { cosmeticProperty.facialEnable = arg.value; } // 修容开关
        else if ([arg.key isEqualToString:@"facialOpacity"]) { cosmeticProperty.facialOpacity = arg.value; } // 修容不透明度
        else if ([arg.key isEqualToString:@"facialId"]) { cosmeticProperty.facialId = arg.value; } // 修容贴纸id

        else if ([arg.key isEqualToString:@"lipEnable"]) { cosmeticProperty.lipEnable = arg.value; } // 口红开关
        else if ([arg.key isEqualToString:@"lipOpacity"]) { cosmeticProperty.lipOpacity = arg.value; } // 口红不透明度
        else if ([arg.key isEqualToString:@"lipStyle"]) { cosmeticProperty.lipStyle = arg.value; } // 口红类型
        else if ([arg.key isEqualToString:@"lipColor"]) { cosmeticProperty.lipColor = arg.value; } // 口红颜色
        
        else if ([arg.key isEqualToString:@"blushEnable"]) { cosmeticProperty.blushEnable = arg.value; } // 腮红开关
        else if ([arg.key isEqualToString:@"blushOpacity"]) { cosmeticProperty.blushOpacity = arg.value; } // 腮红不透明度
        else if ([arg.key isEqualToString:@"blushId"]) { cosmeticProperty.blushId = arg.value; } // 腮红贴纸id

        else if ([arg.key isEqualToString:@"browEnable"]) { cosmeticProperty.browEnable = arg.value; } // 眉毛开关
        else if ([arg.key isEqualToString:@"browOpacity"]) { cosmeticProperty.browOpacity = arg.value; } // 眉毛不透明度
        else if ([arg.key isEqualToString:@"browId"]) { cosmeticProperty.browId = arg.value; } // 眉毛贴纸id

        else if ([arg.key isEqualToString:@"eyeshadowEnable"]) { cosmeticProperty.eyeshadowEnable = arg.value; } // 眼影开关
        else if ([arg.key isEqualToString:@"eyeshadowOpacity"]) { cosmeticProperty.eyeshadowOpacity = arg.value; } // 眼影不透明度
        else if ([arg.key isEqualToString:@"eyeshadowId"]) { cosmeticProperty.eyeshadowId = arg.value; } // 眼影贴纸id

        else if ([arg.key isEqualToString:@"eyelineEnable"]) { cosmeticProperty.eyelineEnable = arg.value; } // 眼线开关
        else if ([arg.key isEqualToString:@"eyelineOpacity"]) { cosmeticProperty.eyelineOpacity = arg.value; } // 眼线不透明度
        else if ([arg.key isEqualToString:@"eyelineId"]) { cosmeticProperty.eyelineId = arg.value; } // 眼线贴纸id

        else if ([arg.key isEqualToString:@"eyelashEnable"]) { cosmeticProperty.eyelashEnable = arg.value; } // 睫毛开关
        else if ([arg.key isEqualToString:@"eyelashOpacity"]) { cosmeticProperty.eyelashOpacity = arg.value; } // 睫毛不透明度
        else if ([arg.key isEqualToString:@"eyelashId"]) { cosmeticProperty.eyelashId = arg.value; } // 睫毛贴纸id
    }
    [_filterPropertys setObject:cosmeticProperty forKey:@(filterModel)];

    
    // filter
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }

        TUPFPFilter *cosmeticFilter = [[TUPFPFilter alloc]init:[self->_pipeline getContext] withName:filterCode];
        [self->_pipeline addFilter:cosmeticFilter at:filterIndex];
        [cosmeticFilter setProperty:cosmeticProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
    return filterParams;
}

//移除美肤
- (void)removeFaceSkinBeautifyFilter
{
    TuFilterModel filterModel = TuFilterModel_SkinFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
    
}

//移除微整形
- (void)removeFacePlasticFilter
{
    TuFilterModel filterModel = TuFilterModel_PlasticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
}

- (void)removeFacePlasticExtraFilter
{
    TuFilterModel filterModel = TuFilterModel_ReshapeFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
}

//移除美妆数据
- (void)removeFaceCosmeticFilter
{
    TuFilterModel filterModel = TuFilterModel_CosmeticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    [_pipeOprationQueue runSync:^{
        if ([self->_pipeline getFilter:filterIndex])
        {
            [self->_pipeline deleteFilterAt:filterIndex];
        }
    }];
}

#pragma mark - SelesParametersListener
// 滤镜参数调节功能列表 --------------------------------------------------
- (void)onSelesParametersUpdate:(TuFilterModel)model code:(NSString *)code arg:(SelesParameterArg *)arg
{
    NSInteger filterIndex = [self FilterIndex:model];

    switch (model)
    {
        case TuFilterModel_Filter:
        {
            TUPFPTusdkImageFilter_Type10PropertyBuilder *property = (TUPFPTusdkImageFilter_Type10PropertyBuilder *)[_filterPropertys objectForKey:@(model)];
            {
                property.strength = arg.value;
            }
            
            [_pipeOprationQueue runSync:^{
                TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
                [filter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
            }];
        }
        break;
        
        case TuFilterModel_PlasticFace:
            [self updatePlasticParams:arg];
            break;

        case TuFilterModel_ReshapeFace:
            [self updatePlasticExtraParams:arg];
            break;


        case TuFilterModel_SkinFace:
            [self updateSkinBeautifyParams:arg];
            break;

        case TuFilterModel_CosmeticFace:
            [self updateCosmeticParams:arg];
            break;
        
        default:
        break;
    }
}

//更新微整形数据
- (void)updatePlasticParams:(SelesParameterArg*)arg
{
    TuFilterModel filterModel = TuFilterModel_PlasticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    TUPFPTusdkFacePlasticFilter_PropertyBuilder *plasticProperty = (TUPFPTusdkFacePlasticFilter_PropertyBuilder*)[_filterPropertys objectForKey:@(filterModel)];

    if ([arg.key isEqualToString:@"eyeSize"]) { plasticProperty.eyeEnlarge = arg.value; } // 大眼
    
    else if ([arg.key isEqualToString:@"chinSize"]) { plasticProperty.cheekThin = arg.value; } // 瘦脸
    else if ([arg.key isEqualToString:@"cheekNarrow"]) { plasticProperty.cheekNarrow = arg.value; } // 窄脸
    
    else if ([arg.key isEqualToString:@"smallFace"]) { plasticProperty.faceSmall = arg.value; } // 小脸
    else if ([arg.key isEqualToString:@"cheekBoneNarrow"]) { plasticProperty.cheekBoneNarrow = arg.value; } // 瘦颧骨
    else if ([arg.key isEqualToString:@"cheekLowBoneNarrow"]) { plasticProperty.cheekLowBoneNarrow = arg.value; } // 下颌骨

    else if ([arg.key isEqualToString:@"forehead"]) { plasticProperty.foreheadHeight = arg.value; } // 额头高低

    else if ([arg.key isEqualToString:@"archEyebrow"]) { plasticProperty.browThickness = arg.value; } // 眉毛粗细
    else if ([arg.key isEqualToString:@"browPosition"]) { plasticProperty.browHeight = arg.value; } // 眉毛高低

    else if ([arg.key isEqualToString:@"eyeHeight"]) { plasticProperty.eyeHeight = arg.value; } // 眼睛高低
    else if ([arg.key isEqualToString:@"eyeAngle"]) { plasticProperty.eyeAngle = arg.value; } // 眼角
    else if ([arg.key isEqualToString:@"eyeDis"]) { plasticProperty.eyeDistance = arg.value; } // 眼距
    else if ([arg.key isEqualToString:@"eyeInnerConer"]) { plasticProperty.eyeInnerConer = arg.value; } // 内眼角
    else if ([arg.key isEqualToString:@"eyeOuterConer"]) { plasticProperty.eyeOuterConer = arg.value; } // 外眼角
    
    else if ([arg.key isEqualToString:@"noseSize"]) { plasticProperty.noseWidth = arg.value; } // 鼻子宽度
    else if ([arg.key isEqualToString:@"noseHeight"]) { plasticProperty.noseHeight = arg.value; } // 鼻子长度
    
    else if ([arg.key isEqualToString:@"philterum"]) { plasticProperty.philterumThickness = arg.value; } // 缩人中
    
    else if ([arg.key isEqualToString:@"mouthWidth"]) { plasticProperty.mouthWidth = arg.value; } // 嘴巴宽度
    else if ([arg.key isEqualToString:@"lips"]) { plasticProperty.lipsThickness = arg.value; } // 嘴唇厚度

    else if ([arg.key isEqualToString:@"jawSize"]) { plasticProperty.chinThickness = arg.value; }  // 下巴高低
    
    [_pipeOprationQueue runSync:^{
        TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
        [filter setProperty:plasticProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
}

- (void)updatePlasticExtraParams:(SelesParameterArg*)arg
{
    TuFilterModel filterModel = TuFilterModel_ReshapeFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    TUPFPTusdkFaceReshapeFilter_PropertyBuilder *property = (TUPFPTusdkFaceReshapeFilter_PropertyBuilder*)[_filterPropertys objectForKey:@(filterModel)];

    if ([arg.key isEqualToString:@"eyeDetail"]) { property.eyeDetailOpacity = arg.value; } // 亮眼
    else if ([arg.key isEqualToString:@"eyelid"]) { property.eyelidOpacity = arg.value; } // 双眼皮
    else if ([arg.key isEqualToString:@"eyemazing"]) { property.eyemazingOpacity = arg.value; } // 卧蚕
    else if ([arg.key isEqualToString:@"removePouch"]) { property.removePouchOpacity = arg.value; } // 祛除眼袋
    else if ([arg.key isEqualToString:@"removeWrinkles"]) { property.removeWrinklesOpacity = arg.value; } // 祛除法令纹
    else if ([arg.key isEqualToString:@"whitenTeeth"]) { property.whitenTeethOpacity = arg.value; } // 白牙

    [_pipeOprationQueue runSync:^{
        TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
        [filter setProperty:property.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
}

//更新美肤数据
- (void)updateSkinBeautifyParams:(SelesParameterArg*)arg
{
    TuFilterModel filterModel = TuFilterModel_SkinFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];
    
    TUPFPFilter *skinBeautifyFilter = [_pipeline getFilter:filterIndex];

    NSObject *property = [_filterPropertys objectForKey:@(filterModel)];
    if ([property isKindOfClass:[TUPFPTusdkImageFilter_SkinNaturalPropertyBuilder class]])
    {
        TUPFPTusdkImageFilter_SkinNaturalPropertyBuilder *naturalProperty = (TUPFPTusdkImageFilter_SkinNaturalPropertyBuilder *)property;

        if ([arg.key isEqualToString:@"smoothing"]) { naturalProperty.smoothing = arg.value; }
        else if ([arg.key isEqualToString:@"whitening"]) { naturalProperty.fair = arg.value; }
        else if ([arg.key isEqualToString:@"ruddy"]) { naturalProperty.ruddy = arg.value; }
        
        [_pipeOprationQueue runSync:^{
            [skinBeautifyFilter setProperty:naturalProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
        }];
    }
    else if ([property isKindOfClass:[TUPFPTusdkImageFilter_SkinHazyPropertyBuilder class]])
    {
        TUPFPTusdkImageFilter_SkinHazyPropertyBuilder *hazyProperty = (TUPFPTusdkImageFilter_SkinHazyPropertyBuilder *)property;

        if ([arg.key isEqualToString:@"smoothing"]) { hazyProperty.smoothing = arg.value; }
        else if ([arg.key isEqualToString:@"whitening"]) { hazyProperty.fair = arg.value; }
        else if ([arg.key isEqualToString:@"ruddy"]) { hazyProperty.ruddy = arg.value; }
        
        [_pipeOprationQueue runSync:^{
            [skinBeautifyFilter setProperty:hazyProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
        }];
    }
    else if ([property isKindOfClass:[TUPFPTusdkBeautFaceV2Filter_PropertyBuilder class]])
    {
        TUPFPTusdkBeautFaceV2Filter_PropertyBuilder *beautyFaceV2Property = (TUPFPTusdkBeautFaceV2Filter_PropertyBuilder *)property;

        if ([arg.key isEqualToString:@"smoothing"]) { beautyFaceV2Property.smoothing = arg.value; }
        else if ([arg.key isEqualToString:@"whitening"]) { beautyFaceV2Property.whiten = arg.value; }
        else if ([arg.key isEqualToString:@"sharpen"]) { beautyFaceV2Property.sharpen = arg.value; }
        
        [_pipeOprationQueue runSync:^{
            [skinBeautifyFilter setProperty:beautyFaceV2Property.makeProperty forKey:TUPFPTusdkBeautFaceV2Filter_PROP_PARAM];
        }];
    }
}

//更新美妆数据
- (void)updateCosmeticParams:(SelesParameterArg*)arg
{
    TuFilterModel filterModel = TuFilterModel_CosmeticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    // Property
    TUPFPTusdkCosmeticFilter_PropertyBuilder *cosmeticProperty = (TUPFPTusdkCosmeticFilter_PropertyBuilder*)[_filterPropertys objectForKey:@(filterModel)];

    if ([arg.key isEqualToString:@"facialEnable"]) { cosmeticProperty.facialEnable = arg.value; } // 修容开关
    else if ([arg.key isEqualToString:@"facialOpacity"]) { cosmeticProperty.facialOpacity = arg.value; } // 修容不透明度
    else if ([arg.key isEqualToString:@"facialId"]) { cosmeticProperty.facialId = arg.value; } // 修容贴纸id

    else if ([arg.key isEqualToString:@"lipEnable"]) { cosmeticProperty.lipEnable = arg.value; } // 口红开关
    else if ([arg.key isEqualToString:@"lipOpacity"]) { cosmeticProperty.lipOpacity = arg.value; } // 口红不透明度
    else if ([arg.key isEqualToString:@"lipStyle"]) { cosmeticProperty.lipStyle = arg.value; } // 口红类型
    else if ([arg.key isEqualToString:@"lipColor"]) { cosmeticProperty.lipColor = arg.value; } // 口红颜色
    
    else if ([arg.key isEqualToString:@"blushEnable"]) { cosmeticProperty.blushEnable = arg.value; } // 腮红开关
    else if ([arg.key isEqualToString:@"blushOpacity"]) { cosmeticProperty.blushOpacity = arg.value; } // 腮红不透明度
    else if ([arg.key isEqualToString:@"blushId"]) { cosmeticProperty.blushId = arg.value; } // 腮红贴纸id

    else if ([arg.key isEqualToString:@"browEnable"]) { cosmeticProperty.browEnable = arg.value; } // 眉毛开关
    else if ([arg.key isEqualToString:@"browOpacity"]) { cosmeticProperty.browOpacity = arg.value; } // 眉毛不透明度
    else if ([arg.key isEqualToString:@"browId"]) { cosmeticProperty.browId = arg.value; } // 眉毛贴纸id

    else if ([arg.key isEqualToString:@"eyeshadowEnable"]) { cosmeticProperty.eyeshadowEnable = arg.value; } // 眼影开关
    else if ([arg.key isEqualToString:@"eyeshadowOpacity"]) { cosmeticProperty.eyeshadowOpacity = arg.value; } // 眼影不透明度
    else if ([arg.key isEqualToString:@"eyeshadowId"]) { cosmeticProperty.eyeshadowId = arg.value; } // 眼影贴纸id

    else if ([arg.key isEqualToString:@"eyelineEnable"]) { cosmeticProperty.eyelineEnable = arg.value; } // 眼线开关
    else if ([arg.key isEqualToString:@"eyelineOpacity"]) { cosmeticProperty.eyelineOpacity = arg.value; } // 眼线不透明度
    else if ([arg.key isEqualToString:@"eyelineId"]) { cosmeticProperty.eyelineId = arg.value; } // 眼线贴纸id

    else if ([arg.key isEqualToString:@"eyelashEnable"]) { cosmeticProperty.eyelashEnable = arg.value; } // 睫毛开关
    else if ([arg.key isEqualToString:@"eyelashOpacity"]) { cosmeticProperty.eyelashOpacity = arg.value; } // 睫毛不透明度
    else if ([arg.key isEqualToString:@"eyelashId"]) { cosmeticProperty.eyelashId = arg.value; } // 睫毛贴纸id
    
    [_pipeOprationQueue runSync:^{
        TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
        [filter setProperty:cosmeticProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
}

- (void)updateCosmeticParam:(NSString *)code enable:(BOOL)enable
{
    TuFilterModel filterModel = TuFilterModel_CosmeticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    // Property
    TUPFPTusdkCosmeticFilter_PropertyBuilder *cosmeticProperty = (TUPFPTusdkCosmeticFilter_PropertyBuilder*)[_filterPropertys objectForKey:@(filterModel)];

    if ([code isEqualToString:@"facialEnable"])
    {
        cosmeticProperty.facialEnable = enable; // 修容开关
    }
    else if ([code isEqualToString:@"lipEnable"])
    {
        cosmeticProperty.lipEnable = enable; // 口红开关
    }
    else if ([code isEqualToString:@"blushEnable"])
    {
        cosmeticProperty.blushEnable = enable; // 腮红开关
    }
    else if ([code isEqualToString:@"browEnable"])
    {
        cosmeticProperty.browEnable = enable; // 眉毛开关
    }
    else if ([code isEqualToString:@"eyeshadowEnable"])
    {
        cosmeticProperty.eyeshadowEnable = enable; // 眼影开关
    }
    else if ([code isEqualToString:@"eyelineEnable"])
    {
        cosmeticProperty.eyelineEnable = enable; // 眼线开关
    }
    else if ([code isEqualToString:@"eyelashEnable"])
    {
        cosmeticProperty.eyelashEnable = enable; // 睫毛开关
    }
    
    [_pipeOprationQueue runSync:^{
        TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
        [filter setProperty:cosmeticProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
}

- (void)updateCosmeticParam:(NSString *)code value:(NSInteger)value
{
    TuFilterModel filterModel = TuFilterModel_CosmeticFace;
    NSInteger filterIndex = [self FilterIndex:filterModel];

    // Property
    TUPFPTusdkCosmeticFilter_PropertyBuilder *cosmeticProperty = (TUPFPTusdkCosmeticFilter_PropertyBuilder*)[_filterPropertys objectForKey:@(filterModel)];

    if ([code isEqualToString:@"lipStyle"])
    {
        cosmeticProperty.lipStyle = value; // 口红类型
    }
    else if ([code isEqualToString:@"lipColor"])
    {
        cosmeticProperty.lipColor = value; // 口红颜色
    }
    else
    {
        NSInteger stickerId = -1;
        
        TuStickerGroup *stickerGroup = [[TuStickerLocalPackage package] groupWithGroupID:value];
        if (stickerGroup && stickerGroup.stickers)
        {
            TuSticker *sticker = stickerGroup.stickers[0];
            stickerId = sticker.idt;
        }

        if (stickerId == -1)
        {
            return;
        }
        
        if ([code isEqualToString:@"facialId"])
        {
            cosmeticProperty.facialId = stickerId; // 修容贴纸id
        }
        else if ([code isEqualToString:@"blushId"])
        {
            cosmeticProperty.blushId = stickerId; // 腮红贴纸id
        }
        else if ([code isEqualToString:@"browId"])
        {
            cosmeticProperty.browId = stickerId; // 眉毛贴纸id
        }
        else if ([code isEqualToString:@"eyeshadowId"])
        {
            cosmeticProperty.eyeshadowId = stickerId; // 眼影贴纸id
        }
        else if ([code isEqualToString:@"eyelineId"])
        {
            cosmeticProperty.eyelineId = stickerId; // 眼线贴纸id
        }
        else if ([code isEqualToString:@"eyelashId"])
        {
            cosmeticProperty.eyelashId = stickerId; // 睫毛贴纸id
        }
    }
    
    [_pipeOprationQueue runSync:^{
        TUPFPFilter *filter = [self->_pipeline getFilter:filterIndex];
        [filter setProperty:cosmeticProperty.makeProperty forKey:TUPFPTusdkImageFilter_PROP_PARAM];
    }];
}

#pragma mark - TuSDKFilterPipe output
- (CVPixelBufferRef)syncProcessSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!_isInitedTuSDK) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    if (!_isInitFilterPipeline) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    int64_t timeStampMs = (int64_t)(1000 * presentationTimeStamp.value) / presentationTimeStamp.timescale;
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    [_pipeOprationQueue runSync:^{

        bool isMarkSense = false;
        if ([self->_pipeline getFilter:[self FilterIndex:TuFilterModel_ReshapeFace]]
            || [self->_pipeline getFilter:[self FilterIndex:TuFilterModel_CosmeticFace]])
        {
            isMarkSense = true;
        }

        self->_pipeInImage = [self->_imgcvt convert:pixelBuffer withTimestamp:timeStampMs];
        [self->_pipeInImage setMarkSenceEnable:isMarkSense];

        [self->_pipeOutLock lock];

        self->_pipeOutImage = [self->_pipeline process:self->_pipeInImage];


        [self->_pipeOutLock unlock];

    }];
    
    CVPixelBufferRef newPixelBuffer = [_pipeOutImage getCVPixelBuffer];
    
    return newPixelBuffer;
}

- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer timeStamp:(int64_t)timeStamp;
{
    if (!_isInitedTuSDK) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    if (!_isInitFilterPipeline) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    
    [_pipeOprationQueue runSync:^{

        bool isMarkSense = false;
        if ([self->_pipeline getFilter:[self FilterIndex:TuFilterModel_ReshapeFace]]
            || [self->_pipeline getFilter:[self FilterIndex:TuFilterModel_CosmeticFace]])
        {
            isMarkSense = true;
        }

        self->_pipeInImage = [self->_imgcvt convert:pixelBuffer withTimestamp:timeStamp];
        [self->_pipeInImage setMarkSenceEnable:isMarkSense];

        [self->_pipeOutLock lock];

        self->_pipeOutImage = [self->_pipeline process:self->_pipeInImage];


        [self->_pipeOutLock unlock];

    }];
    
    CVPixelBufferRef newPixelBuffer = [_pipeOutImage getCVPixelBuffer];
    
    return newPixelBuffer;
}


- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer timeStamp:(int64_t)timeStamp rotation:(int)rotation;
{
    if (!_isInitedTuSDK) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    if (!_isInitFilterPipeline) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    
    [_pipeOprationQueue runSync:^{

        bool isMarkSense = false;
        if ([self->_pipeline getFilter:[self FilterIndex:TuFilterModel_ReshapeFace]]
            || [self->_pipeline getFilter:[self FilterIndex:TuFilterModel_CosmeticFace]])
        {
            isMarkSense = true;
        }

//        self->_pipeInImage = [self->_imgcvt convert:pixelBuffer withTimestamp:timeStamp];
        self->_pipeInImage = [self->_imgcvt convert:pixelBuffer
                                      withTimestamp:timeStamp
                                         orientaion:rotation
                                               flip:FALSE
                                             mirror:FALSE];

        
        
        
        
        [self->_pipeInImage setMarkSenceEnable:isMarkSense];

        [self->_pipeOutLock lock];

        self->_pipeOutImage = [self->_pipeline process:self->_pipeInImage];


        [self->_pipeOutLock unlock];

    }];
    
    CVPixelBufferRef newPixelBuffer = [_pipeOutImage getCVPixelBuffer];
    
    return newPixelBuffer;
}

@end
