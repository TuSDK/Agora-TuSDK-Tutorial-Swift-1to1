
# TuSDK 功能操作说明

## 1.文件构成

### 1.包名

iOS 应用的包名是 Bundle Identifier，它定义在 Project Target 中的 Bundle Identifier。

### 2.秘钥（AppKey）

* 替换 TuSDK 初始化中的秘钥（AppKey），`AppDelegate.m`中引入 #import "TuSDKManager.h"。
* 进行初始化 `[[TuSDKManager sharedManager] initSdkWithAppKey:TuSDKAPPKET];`;
* appKey 需要在控制台申请，控制台使用说明请参考[官方文档](https://tutucloud.com/docs/quick-start/console-guide)

### 3.资源文件

* 提供的压缩包中会有 **package_XXXXXX.zip** 文件。
* 解压缩该文件后会有，滤镜、特效资源：*other*、*texture*，贴纸资源：*sticker* 文件。
* *other* 和 *texture*  这两个是必要文件，*sticker*有动态贴纸服务才会出现。


## 4.文件替换操作

* 替换 AppKey 至 TuSDK init 初始化方法中秘钥（AppKey）。
* 将解压缩后的文件替换 **TuSDKPulse.bundle**  文件中的对应文件。
* TuSDK.bundle文件介绍：

（1）model 文件，鉴权文件，必须保留。

（2）others 文件夹，包含使用到的滤镜资源文件的索引，进行滤镜资源文件操作是需要进行替换。

（3）stickers 文件夹，包含打包到本地使用的贴纸的资源文件，进行资源文件操作是需要进行替换（无贴纸功能的可删除）。

（4）textures 文件夹，包含打包到本地使用的滤镜的资源文件，进行资源文件操作是需要进行替换。


## 2.项目集成、配置
### 1.集成方式：
一、Demo提供的TuSDKManager文件集成方式。该集成方式中TuSDKManager封装了对滤镜、贴纸、美颜功能的实现，客户通过一些简单方法就可以快速实现并使用滤镜、贴纸、美颜功能。

* 将Demo中的`TuSDKManager` 文件夹引入即可，`Localized` 文件需要获取Demo 中的`VideoDemo.strings` 和 `TuSDKConstants.strings`

二、如下的集成方式：**（客户需自定义该功能的UI、逻辑等处理时，建议使用该方式，下面的内容都是介绍该方式的）**

1、将示例工程源码中以下文件拖入到 Xcode 项目中

* `TuCamera.framework` ：核心库相机库
* `TuViews.framework`：核心库视图库
* `TuSDKPulseFilter.framework`：特效处理库
* `TuSDKPulse.framework`：核心库
* `TuSDKPulseCore.framework`：核心库
* `Localized`：`VideoDemo.strings` 和`TuSDKConstants.strings`为项目语言文件。（如有自己的语言文件可以自行配置文案显示）
* `resource`:`TuSDKPulse.bundle` ：为项目资源文件，包含滤镜，动态贴纸等文件。
* `resource`:`Thumbnails`:为项目缩略图（效果图）、UI风格切图资源文件，展示UI布局切图、滤镜，场景特效的效果封面图等图片资源。
* `resource`:`customStickerCategories.json`为贴纸资源文件的索引，无使用贴纸可忽略不添加。
* `resource`:`cosmeticCategories.json`为美妆资源文件的索引，无使用美妆可忽略不添加。
* `resource`:`Constants.h`为宏定义索引。
* `Views`:包含TuSDK的滤镜、贴纸、微整形功能板块等视图文件

2、勾选 **Copy items if needed**，点击 **Finish**。

### 2.项目配置

1、打开 app target，查看 **Build Settings** 中的 **Linking** - **Other Linker Flags** 选项，确保含有 `-ObjC` 一值，若没有则添加。用户使用 Cocoapods 进行了第三方依赖库管理，需要在 `-ObjC` 前添加 `$(inherited)`。`目前直播 SDK 暂不支持 Cocoapods`。

2、 - **Build settings**中将**Bitcode**选项设置为**NO**（TuSDK编译平台支持的关系）。

3、 - **Linked framworks and libs**中添加**libc++.tbd**的依赖。

4、 - **Linked framworks and libs**中添加**libresolv.tbd**的依赖。

5、资源文件中包含 `others` 和 `textures`，需要将这两个文件夹替换到 TuSDK.bundle 中对应位置。

6、SDK 暂时不支持 Cocoapods，进行更新操作，请重复步骤1和步骤7。

7、关于TuSDK的滤镜、贴纸、微整形功能的使用，具体可以参考demo中的TuSDKManager类中的实现。

8、注意 ：在`Project` -> `Targets` -> `General` -> `Frameworks,Libraries,andEmbedded Content` 设置中，需要把`TuCamera.framework` 、 `TuViews.framework`、`TuSDKPulseFilter.framework`、 `TuSDKPulse.framework`和`TuSDKPulseCore.framework` 的属性置为`Embed & Sign`


## 3.自定义集成方式（项目集成、配置的方式二）

### 1.TuSDK 的初始化

1、在`AppDelegate.m`引入头文件 `#import <TuSDKPulseCore/TuSDKPulseCore.h>` 和 `#import <TuSDKPulse/TUPEngine.h>`。

2、在 `AppDelegate.m` 的 `didFinishLaunchingWithOptions`方法中添加初始化代码，用户如果需求同一应用不同版本发布，可以参考文档[如何使用多个masterkey](https://tutucloud.com/docs/image-ios-faq/masterkey)
```
[TUCCore initSdkWithAppKey:appKey];
[TUPEngine Init:nil];
```

3、为便于开发，可打开 TuSDK 的调试日志，在初始化方法的同一位置添加以下代码：`[TUCCore setLogLevel:TuLogLevelDEBUG];`发布应用时请关闭日志。

``` objective-c
    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        // 初始化SDK (请前往 http://tusdk.com 获取您的 APP 开发密钥)
        [TUCCore initSdkWithAppKey:@"***"];
        // 多包名 masterkey 方式启动方法
        // @see-https://tusdk.com/docs/ios-faq/masterkey
        // if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.XXXXXXXX.XXXX"]) {
        //  [TUCCore initSdkWithAppKey:@"***" devType:@"release"];
        //}
        // 开发时请打开调试日志输出
        [TUCCore setLogLevel:TuLogLevelDEBUG];
    }
```

4、资源释放，需要在应用程序关闭的时候释放资源`[TUPEngine Terminate];`
```
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [TUPEngine Terminate];
}
```

### 2.TUPFilterPipe 的使用

TUPFilterPipe 是视频滤镜处理 API 的接口，处理的是视频 帧buffer 数据

1. 在文件中引入 `<TuSDKPulseFilter/TuSDKPulseFilter.h>` 和 `<TuSDKPulse/TUPDispatchQueue.h>`
2. 创建对象 `TUPFilterPipe *_pipeline;`
3. 初始化对象，对象的创建需要在单独线程创建

```objective-c
[_pipeOprationQueue runSync:^{
    
    self->_imgcvt = [[TUPFPImage_CMSampleBufferCvt alloc] init];
    self->_pipeline = [[TUPFilterPipe alloc] init];
    TUPConfig *config = [[TUPConfig alloc] init];
    [config setIntNumber:1 forKey:@"pbout"];
    [self->_pipeline setConfig:config];
    [self->_pipeline open];
}];
```

4. 滤镜参数配置

```objective-c
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

```

5. 贴纸数据配置

```objective-c
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
```

6. 美肤配置

```objective-c
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

```

7. 微整形配置

```objective-c
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

```

8. 美妆配置

```objective-c

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

```
