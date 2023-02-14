#import "RNCarPlay.h"
#import <React/RCTConvert.h>
#import <React/RCTRootView.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Intents/Intents.h>
#import <SDWebImage/SDWebImage.h>

@implementation RNCarPlay

@synthesize interfaceController;
@synthesize window;
@synthesize searchResultBlock;
@synthesize selectedResultBlock;
@synthesize isNowPlayingActive;

+ (void) connectWithInterfaceController:(CPInterfaceController*)interfaceController window:(CPWindow*)window {
    RNCPStore * store = [RNCPStore sharedManager];
    store.interfaceController = interfaceController;
    store.window = window;
    [store setConnected:true];

    RNCarPlay *cp = [RNCarPlay allocWithZone:nil];
    if (cp.bridge) {
        [cp sendEventWithName:@"didConnect" body:@{}];
    }
}

+ (void) disconnect {
    RNCarPlay *cp = [RNCarPlay allocWithZone:nil];
    RNCPStore *store = [RNCPStore sharedManager];
    [store setConnected:false];

    if (cp.bridge) {
        [cp sendEventWithName:@"didDisconnect" body:@{}];
    }
}

RCT_EXPORT_MODULE();

+ (id)allocWithZone:(NSZone *)zone {
    static RNCarPlay *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        @"didConnect",
        @"didDisconnect",
        // interface
        @"barButtonPressed",
        @"backButtonPressed",
        @"didAppear",
        @"didDisappear",
        @"willAppear",
        @"willDisappear",
        // grid
        @"gridButtonPressed",
        // information
        @"actionButtonPressed",
        // list
        @"didSelectListItem",
        @"didSelectListItemImage",
        // nowplaying
        @"nowPlayingButtonPressed",
        // search
        @"updatedSearchText",
        @"searchButtonPressed",
        @"selectedResult",
        // tabbar
        @"didSelectTemplate",
        // map
        @"mapButtonPressed",
        @"didUpdatePanGestureWithTranslation",
        @"didEndPanGestureWithVelocity",
        @"panBeganWithDirection",
        @"panEndedWithDirection",
        @"panWithDirection",
        @"didBeginPanGesture",
        @"didDismissPanningInterface",
        @"willDismissPanningInterface",
        @"didShowPanningInterface",
        @"didDismissNavigationAlert",
        @"willDismissNavigationAlert",
        @"didShowNavigationAlert",
        @"willShowNavigationAlert",
        @"didCancelNavigation",
        @"alertActionPressed",
        @"selectedPreviewForTrip",
        @"startedTrip"
    ];
}

//- (dispatch_queue_t)methodQueue
//{
//    return dispatch_get_main_queue();
//}

-(UIImage *)imageWithTint:(UIImage *)image andTintColor:(UIColor *)tintColor {
    UIImage *imageNew = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imageNew];
    imageView.tintColor = tintColor;
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, 0.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (UIImage *)imageWithSize:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

RCT_EXPORT_METHOD(checkForConnection) {
    RNCPStore *store = [RNCPStore sharedManager];
    if ([store isConnected]) {
        [self sendEventWithName:@"didConnect" body:@{}];
    }
}

RCT_EXPORT_METHOD(createTemplate:(NSString *)templateId config:(NSDictionary*)config) {
    RNCPStore *store = [RNCPStore sharedManager];

    NSString *type = [RCTConvert NSString:config[@"type"]];
    NSString *title = [RCTConvert NSString:config[@"title"]];
    NSArray *leadingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"leadingNavigationBarButtons"]] templateId:templateId];
    NSArray *trailingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"trailingNavigationBarButtons"]] templateId:templateId];

    CPTemplate *template = [[CPTemplate alloc] init];

    if ([type isEqualToString:@"grid"]) {
        NSArray *buttons = [self parseGridButtons:[RCTConvert NSArray:config[@"buttons"]] templateId:templateId];
        CPGridTemplate *gridTemplate = [[CPGridTemplate alloc] initWithTitle:title gridButtons:buttons];
        [gridTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
        [gridTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
        template = gridTemplate;
    }
    else if ([type isEqualToString:@"list"]) {
        CPListTemplate *listTemplate;
        NSArray *sections = [self parseSections:[RCTConvert NSArray:config[@"sections"]] templateId:templateId];
        
        if (config[@"assistant"]) {
            CPAssistantCellPosition *position = [config[@"assistant"][@"position"] isEqual: @"bottom"] ? CPAssistantCellPositionBottom : CPAssistantCellPositionTop;
            CPAssistantCellActionType *actionType = [config[@"assistant"][@"actionType"] isEqual: @"startCall"] ? CPAssistantCellActionTypeStartCall : CPAssistantCellActionTypePlayMedia;
            CPAssistantCellVisibility *visibility;
            if ([config[@"assistant"][@"visibility"] isEqual: @"always"]) {
                visibility = CPAssistantCellVisibilityAlways;
            } else if ([config[@"assistant"][@"visibility"] isEqual: @"limited"]) {
                visibility = CPAssistantCellVisibilityWhileLimitedUIActive;
            } else {
                visibility = CPAssistantCellVisibilityOff;
            }
            
            CPAssistantCellConfiguration *cellConfig = [[CPAssistantCellConfiguration alloc] initWithPosition:position visibility:CPAssistantCellVisibilityAlways assistantAction:actionType];
            
            listTemplate = [[CPListTemplate alloc] initWithTitle:title sections:sections assistantCellConfiguration:cellConfig];
        } else {
            listTemplate = [[CPListTemplate alloc] initWithTitle:title sections:sections];
        }
        
        [listTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
        [listTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
        CPBarButton *backButton = [[CPBarButton alloc] initWithTitle:@" Back" handler:^(CPBarButton * _Nonnull barButton) {
            [self sendEventWithName:@"backButtonPressed" body:@{@"templateId":templateId}];
            [self popTemplate:false];
        }];
        [listTemplate setBackButton:backButton];
        if (config[@"emptyViewTitleVariants"]) {
            listTemplate.emptyViewTitleVariants = [RCTConvert NSArray:config[@"emptyViewTitleVariants"]];
        }
        if (config[@"emptyViewSubtitleVariants"]) {
            listTemplate.emptyViewSubtitleVariants = [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]];
        }
        listTemplate.delegate = self;
        template = listTemplate;
    }
    else if ([type isEqualToString:@"nowplaying"]) {
        CPNowPlayingTemplate *nowPlayingTemplate = [CPNowPlayingTemplate sharedTemplate];
        [nowPlayingTemplate setAlbumArtistButtonEnabled:[RCTConvert BOOL:config[@"albumArtistButton"]]];
        [nowPlayingTemplate setUpNextTitle:[RCTConvert NSString:config[@"upNextTitle"]]];
        [nowPlayingTemplate setUpNextButtonEnabled:[RCTConvert BOOL:config[@"upNextButton"]]];
        
        NSArray *buttons = [self parseNowPlayingButtons:config[@"buttons"] templateId:templateId];
        if ([buttons count] > 0) {
            [nowPlayingTemplate updateNowPlayingButtons:buttons];
        }
        
        template = nowPlayingTemplate;
    } else if ([type isEqualToString:@"tabbar"]) {
        CPTabBarTemplate *tabBarTemplate = [[CPTabBarTemplate alloc] initWithTemplates:[self parseTemplatesFrom:config]];
        tabBarTemplate.delegate = self;
        template = tabBarTemplate;
    } else if ([type isEqualToString:@"alert"]) {
        NSMutableArray<CPAlertAction *> *actions = [NSMutableArray new];
        NSArray<NSDictionary*> *_actions = [RCTConvert NSDictionaryArray:config[@"actions"]];
        for (NSDictionary *_action in _actions) {
            CPAlertAction *action = [[CPAlertAction alloc] initWithTitle:[RCTConvert NSString:_action[@"title"]] style:[RCTConvert CPAlertActionStyle:_action[@"style"]] handler:^(CPAlertAction *a) {
                [self sendEventWithName:@"actionButtonPressed" body:@{@"templateId":templateId, @"id": _action[@"id"] }];
            }];
            [actions addObject:action];
        }
        NSArray<NSString*>* titleVariants = [RCTConvert NSArray:config[@"titleVariants"]];
        CPAlertTemplate *alertTemplate = [[CPAlertTemplate alloc] initWithTitleVariants:titleVariants actions:actions];
        template = alertTemplate;
    }

    if (config[@"tabSystemItem"]) {
        template.tabSystemItem = [RCTConvert NSInteger:config[@"tabSystemItem"]];
    }
    if (config[@"tabSystemImg"]) {
        template.tabImage = [UIImage systemImageNamed:[RCTConvert NSString:config[@"tabSystemImg"]]];
    }
    if (config[@"tabImage"]) {
        template.tabImage = [RCTConvert UIImage:config[@"tabImage"]];
    }


    [template setUserInfo:@{ @"templateId": templateId }];
    [store setTemplate:templateId template:template];
}

RCT_EXPORT_METHOD(setRootTemplate:(NSString *)templateId animated:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];

    store.interfaceController.delegate = self;

    if (template) {
        [store.interfaceController setRootTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
            NSLog(@"error %@", err);
            // noop
        }];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(pushTemplate:(NSString *)templateId animated:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        [store.interfaceController pushTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
            NSLog(@"error %@", err);
            // noop
        }];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(popToTemplate:(NSString *)templateId animated:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        [store.interfaceController popToTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
            NSLog(@"error %@", err);
            // noop
        }];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(popToRootTemplate:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    [store.interfaceController popToRootTemplateAnimated:animated completion:^(BOOL done, NSError * _Nullable err) {
        NSLog(@"error %@", err);
        // noop
    }];
}

RCT_EXPORT_METHOD(popTemplate:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    [store.interfaceController popTemplateAnimated:animated completion:^(BOOL done, NSError * _Nullable err) {
        NSLog(@"error %@", err);
        // noop
    }];
}

RCT_EXPORT_METHOD(presentTemplate:(NSString *)templateId animated:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        [store.interfaceController presentTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
            NSLog(@"error %@", err);
            // noop
        }];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(dismissTemplate:(BOOL)animated) {
    RNCPStore *store = [RNCPStore sharedManager];
    [store.interfaceController dismissTemplateAnimated:animated];
}

RCT_EXPORT_METHOD(updateNowPlayingButtons:(NSArray*)buttons templateId:(NSString*)templateId) {
    NSArray *_buttons = [self parseNowPlayingButtons:buttons templateId:templateId];
    if ([_buttons count] > 0) {
        [CPNowPlayingTemplate.sharedTemplate updateNowPlayingButtons:_buttons];
    }
}

RCT_EXPORT_METHOD(updateListTemplate:(NSString*)templateId config:(NSDictionary*)config) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template && [template isKindOfClass:[CPListTemplate class]]) {
        CPListTemplate *listTemplate = (CPListTemplate *)template;
        if (config[@"leadingNavigationBarButtons"]) {
            NSArray *leadingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"leadingNavigationBarButtons"]] templateId:templateId];
            [listTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
        }
        if (config[@"trailingNavigationBarButtons"]) {
            NSArray *trailingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"trailingNavigationBarButtons"]] templateId:templateId];
            [listTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
        }
        if (config[@"emptyViewTitleVariants"]) {
            listTemplate.emptyViewTitleVariants = [RCTConvert NSArray:config[@"emptyViewTitleVariants"]];
        }
        if (config[@"emptyViewSubtitleVariants"]) {
            NSLog(@"%@", [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]]);
            listTemplate.emptyViewSubtitleVariants = [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]];
        }
    }
}

RCT_EXPORT_METHOD(updateTabBarTemplates:(NSString *)templateId templates:(NSDictionary*)config) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        CPTabBarTemplate *tabBarTemplate = (CPTabBarTemplate*) template;
        [tabBarTemplate updateTemplates:[self parseTemplatesFrom:config]];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}


RCT_EXPORT_METHOD(updateListTemplateSections:(NSString *)templateId sections:(NSArray*)sections) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        CPListTemplate *listTemplate = (CPListTemplate*) template;
        [listTemplate updateSections:[self parseSections:sections templateId:templateId]];
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(updateListTemplateItem:(NSString *)templateId config:(NSDictionary*)config) {
    RNCPStore *store = [RNCPStore sharedManager];
    CPTemplate *template = [store findTemplateById:templateId];
    if (template) {
        CPListTemplate *listTemplate = (CPListTemplate*) template;
        
        NSInteger index = [RCTConvert NSInteger:config[@"itemIndex"]];
        __block NSInteger lastCount = 0;
        __block NSInteger sectionIndex;
        
        if (config[@"sectionIndex"]) {
            sectionIndex = [RCTConvert NSInteger:config[@"sectionIndex"]];
        } else {
            [listTemplate.sections enumerateObjectsUsingBlock:^(CPListSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                lastCount += obj.items.count;
                if (lastCount > index) {
                    sectionIndex = idx;
                    *stop = YES;
                }
            }];
        }
        
        if (sectionIndex >= listTemplate.sections.count) {
            NSLog(@"Failed to update item at section %d, sections size is %d", index, listTemplate.sections.count);
            return;
        }
        
        CPListSection *section = listTemplate.sections[sectionIndex];
        NSInteger itemIndex = index - (lastCount - section.items.count);
        if (itemIndex >= section.items.count) {
            NSLog(@"Failed to update item at index %d, section size is %d", itemIndex, section.items.count);
            return;
        }
        
        CPListItem *item = (CPListItem *)section.items[itemIndex];
        if (config[@"imgUrl"]) {
            [item setImage:[UIImage sd_imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[RCTConvert NSString:config[@"imgUrl"]]]]]];
        }
        if (config[@"image"]) {
            [item setImage:[RCTConvert UIImage:config[@"image"]]];
        }
        if (config[@"text"]) {
            [item setText:[RCTConvert NSString:config[@"text"]]];
        }
        if (config[@"detailText"]) {
            [item setDetailText:[RCTConvert NSString:config[@"text"]]];
        }
        if (config[@"isPlaying"]) {
            [item setPlaying:[RCTConvert BOOL:config[@"isPlaying"]]];
        }
        if (config[@"playbackProgress"]) {
            [item setPlaybackProgress:[config[@"playbackProgress"] doubleValue]];
        }
    } else {
        NSLog(@"Failed to find template %@", template);
    }
}

RCT_EXPORT_METHOD(enableNowPlaying:(BOOL)enable) {
    if (enable && !isNowPlayingActive) {
        [CPNowPlayingTemplate.sharedTemplate addObserver:self];
    } else if (!enable && isNowPlayingActive) {
        [CPNowPlayingTemplate.sharedTemplate removeObserver:self];
    }
}

RCT_EXPORT_METHOD(reactToUpdatedSearchText:(NSArray *)items templateId:(NSString*)templateId) {
    NSArray *sectionsItems = [self parseListItems:items startIndex:0 templateId:templateId];

    if (self.searchResultBlock) {
        self.searchResultBlock(sectionsItems);
        self.searchResultBlock = nil;
    }
}

RCT_EXPORT_METHOD(reactToSelectedResult:(BOOL)status) {
    if (self.selectedResultBlock) {
        self.selectedResultBlock();
        self.selectedResultBlock = nil;
    }
}

# pragma parsers

- (NSArray<__kindof CPTemplate*>*) parseTemplatesFrom:(NSDictionary*)config {
    RNCPStore *store = [RNCPStore sharedManager];
    NSMutableArray<__kindof CPTemplate*> *templates = [NSMutableArray new];
    NSArray<NSDictionary*> *tpls = [RCTConvert NSDictionaryArray:config[@"templates"]];
    for (NSDictionary *tpl in tpls) {
        CPTemplate *templ = [store findTemplateById:tpl[@"id"]];
        // @todo UITabSystemItem
        [templates addObject:templ];
    }
    return templates;
}

- (NSArray<CPButton*>*) parseButtons:(NSArray*)buttons templateId:(NSString *)templateId {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *button in buttons) {
        CPButton *_button;
        NSString *_id = [button objectForKey:@"id"];
        NSString *type = [button objectForKey:@"type"];

        BOOL _disabled = [button objectForKey:@"disabled"];
        [_button setEnabled:!_disabled];

        NSString *_title = [button objectForKey:@"title"];
        [_button setTitle:_title];

        [result addObject:_button];
    }
    return result;
}

- (NSArray<CPBarButton*>*) parseBarButtons:(NSArray*)barButtons templateId:(NSString *)templateId {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *barButton in barButtons) {
        CPBarButtonType _type;
        NSString *_id = [barButton objectForKey:@"id"];
        NSString *type = [barButton objectForKey:@"type"];
        if (type && [type isEqualToString:@"image"]) {
            _type = CPBarButtonTypeImage;
        } else {
            _type = CPBarButtonTypeText;
        }
        CPBarButton *_barButton = [[CPBarButton alloc] initWithType:_type handler:^(CPBarButton * _Nonnull barButton) {
            [self sendEventWithName:@"barButtonPressed" body:@{@"id": _id, @"templateId":templateId}];
        }];
        BOOL _disabled = [barButton objectForKey:@"disabled"];
        [_barButton setEnabled:!_disabled];

        if (_type == CPBarButtonTypeText) {
            NSString *_title = [barButton objectForKey:@"title"];
            [_barButton setTitle:_title];
        } else if (_type == CPBarButtonTypeImage) {
            UIImage *_image = [RCTConvert UIImage:[barButton objectForKey:@"image"]];
            [_barButton setImage:_image];
        }
        [result addObject:_barButton];
    }
    return result;
}

- (NSArray<CPListSection*>*)parseSections:(NSArray*)sections templateId:(NSString*)templateId {
    NSMutableArray *result = [NSMutableArray array];
    int index = 0;
    for (NSDictionary *section in sections) {
        NSArray *items = [section objectForKey:@"items"];
        NSString *_sectionIndexTitle = [section objectForKey:@"sectionIndexTitle"];
        NSString *_header = [section objectForKey:@"header"];
        NSArray *_items = [self parseListItems:items startIndex:index templateId:templateId];
        CPListSection *_section = [[CPListSection alloc] initWithItems:_items header:_header sectionIndexTitle:_sectionIndexTitle];
        [result addObject:_section];
        int count = (int) [items count];
        index = index + count;
    }
    return result;
}

- (NSArray<CPListItem*>*)parseListItems:(NSArray*)items startIndex:(int)startIndex templateId:(NSString*)templateId {
    NSMutableArray *_items = [NSMutableArray array];
    int index = startIndex;
    for (NSDictionary *item in items) {
        if ([RCTConvert BOOL:[item objectForKey:@"imgRow"]]) {
            NSMutableArray<UIImage *> *_images = [NSMutableArray array];
            NSArray<NSString*> *_imgsUrls = [item objectForKey:@"imgUrls"];
            for (NSString *imgUrl in _imgsUrls) {
                UIImage *_image = [UIImage sd_imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]]];
                [_images addObject:_image];
            }
            NSString *_text = [item objectForKey:@"text"];
            CPListImageRowItem *_item = [[CPListImageRowItem alloc] initWithText:_text images:_images];
//            double maxSize = CPListImageRowItem.maximumImageSize.width - CPMaximumNumberOfGridImages;
            [_item setUserInfo:@{ @"index": @(index) }];
            __weak CPListImageRowItem *_weakItem = _item;
            [_item setListImageRowHandler:^(CPListImageRowItem * _Nonnull item, NSInteger index, dispatch_block_t  _Nonnull completionBlock) {
                [self sendEventWithName:@"didSelectListItemImage" body:@{@"templateId":templateId, @"index": @(index), @"itemIndex": [_weakItem.userInfo objectForKey:@"index"] }];
            }];
            [_items addObject:_item];
            index = index + 1;
        } else {
            BOOL _showsDisclosureIndicator = [item objectForKey:@"showsDisclosureIndicator"];
            NSString *_detailText = [item objectForKey:@"detailText"];
            NSString *_text = [item objectForKey:@"text"];
            __block UIImage *_image = [RCTConvert UIImage:[item objectForKey:@"image"]];
            if (item[@"imgUrl"]) {
                _image = [UIImage sd_imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[RCTConvert NSString:item[@"imgUrl"]]]]];
            }
            CPListItem *_item = [[CPListItem alloc] initWithText:_text detailText:_detailText image:_image showsDisclosureIndicator:_showsDisclosureIndicator];
            if ([item objectForKey:@"isPlaying"]) {
                [_item setPlaying:[RCTConvert BOOL:[item objectForKey:@"isPlaying"]]];
            }
            if ([item objectForKey:@"playbackProgress"]) {
                [_item setPlaybackProgress:[[item objectForKey:@"playbackProgress"] doubleValue]];
            }
            [_item setUserInfo:@{ @"index": @(index) }];
            [_items addObject:_item];
            index = index + 1;
        }
    }
    return _items;
}

- (NSArray<CPGridButton*>*)parseGridButtons:(NSArray*)buttons templateId:(NSString*)templateId {
    NSMutableArray *result = [NSMutableArray array];
    int index = 0;
    for (NSDictionary *button in buttons) {
        NSString *_id = [button objectForKey:@"id"];
        NSArray<NSString*> *_titleVariants = [button objectForKey:@"titleVariants"];
        UIImage *_image = [RCTConvert UIImage:[button objectForKey:@"image"]];
        CPGridButton *_button = [[CPGridButton alloc] initWithTitleVariants:_titleVariants image:_image handler:^(CPGridButton * _Nonnull barButton) {
            [self sendEventWithName:@"gridButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"index": @(index) }];
        }];
        BOOL _disabled = [button objectForKey:@"disabled"];
        [_button setEnabled:!_disabled];
        [result addObject:_button];
        index = index + 1;
    }
    return result;
}

- (NSArray<CPNowPlayingButton*>*)parseNowPlayingButtons:(NSArray*)buttons templateId:(NSString*)templateId {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *button in buttons) {
        CPNowPlayingButton *_button;
        
        NSString *_id = [button objectForKey:@"id"];
        if (!_id) {
            _id = @"none";
        }
        
        NSString *_type = [button objectForKey:@"type"];
        if ([_type isEqual:@"rate"]) {
            CPNowPlayingPlaybackRateButton *rate = [[CPNowPlayingPlaybackRateButton alloc] initWithHandler:^(CPNowPlayingPlaybackRateButton * _Nonnull button) {
                [self sendEventWithName:@"nowPlayingButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"action": @"rate" }];
            }];
            _button = rate;
        }
        else if ([_type isEqual:@"add"]) {
            CPNowPlayingAddToLibraryButton *addToLib = [[CPNowPlayingAddToLibraryButton alloc] initWithHandler:^(CPNowPlayingAddToLibraryButton * _Nonnull button) {
                [self sendEventWithName:@"nowPlayingButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"action": @"add" }];
            }];
            _button = addToLib;
        }
        else if ([_type isEqual:@"repeat"]) {
            CPNowPlayingRepeatButton *repeat = [[CPNowPlayingRepeatButton alloc] initWithHandler:^(CPNowPlayingRepeatButton * _Nonnull button) {
                [self sendEventWithName:@"nowPlayingButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"action": @"repeat" }];
            }];
            _button = repeat;
        }
        else if (([button objectForKey:@"image"] || [button objectForKey:@"imgUrl"]) && _type != nil) {
            UIImage *_image = [RCTConvert UIImage:[button objectForKey:@"image"]];
            if ([button objectForKey:@"imgUrl"]) {
                _image = [UIImage sd_imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString:[RCTConvert NSString:[button objectForKey:@"imgUrl"]]]]];
            }
            
            if (_image != nil) {
                CPNowPlayingImageButton *custom = [[CPNowPlayingImageButton alloc] initWithImage:_image handler:^(CPNowPlayingImageButton * _Nonnull button) {
                    [self sendEventWithName:@"nowPlayingButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"action": _type }];
                }];
                _button = custom;
            }
        }
        
        BOOL _disabled = [button objectForKey:@"disabled"];
        [_button setEnabled:!_disabled];
        [result addObject:_button];
    }
    return result;
}

- (CPAlertAction*)parseAlertAction:(NSDictionary*)json body:(NSDictionary*)body {
    return [[CPAlertAction alloc] initWithTitle:[RCTConvert NSString:json[@"title"]] style:(CPAlertActionStyle) [RCTConvert NSUInteger:json[@"style"]] handler:^(CPAlertAction * _Nonnull action) {
        [self sendEventWithName:@"alertActionPressed" body:body];
    }];
}

- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString*)name {
    [self sendTemplateEventWithName:template name:name json:@{}];
}

- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString*)name json:(NSDictionary*)json {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] initWithDictionary:json];
    NSDictionary *userInfo = [template userInfo];
    [body setObject:[userInfo objectForKey:@"templateId"] forKey:@"templateId"];
    [self sendEventWithName:name body:body];
}

# pragma ListTemplate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)(void))completionHandler {
    NSNumber* index = [item.userInfo objectForKey:@"index"];
//    NSNumber* sectionIndex = [item.userInfo objectForKey:@"sectionIndex"];
    [self sendTemplateEventWithName:listTemplate name:@"didSelectListItem" json:@{ @"index": index }]; //@"sectionIndex": sectionIndex
    self.selectedResultBlock = completionHandler;
}

# pragma TabBarTemplate
- (void)tabBarTemplate:(CPTabBarTemplate *)tabBarTemplate didSelectTemplate:(__kindof CPTemplate *)selectedTemplate {
    NSString* selectedTemplateId = [[selectedTemplate userInfo] objectForKey:@"templateId"];
    [self sendTemplateEventWithName:tabBarTemplate name:@"didSelectTemplate" json:@{@"selectedTemplateId":selectedTemplateId}];
}

# pragma InterfaceController

- (void)templateDidAppear:(CPTemplate *)aTemplate animated:(BOOL)animated {
    [self sendTemplateEventWithName:aTemplate name:@"didAppear" json:@{ @"animated": @(animated) }];
}

- (void)templateDidDisappear:(CPTemplate *)aTemplate animated:(BOOL)animated {
    [self sendTemplateEventWithName:aTemplate name:@"didDisappear" json:@{ @"animated": @(animated) }];
}

- (void)templateWillAppear:(CPTemplate *)aTemplate animated:(BOOL)animated {
    [self sendTemplateEventWithName:aTemplate name:@"willAppear" json:@{ @"animated": @(animated) }];
}

- (void)templateWillDisappear:(CPTemplate *)aTemplate animated:(BOOL)animated {
    [self sendTemplateEventWithName:aTemplate name:@"willDisappear" json:@{ @"animated": @(animated) }];
}

# pragma NowPlaying

- (void)nowPlayingTemplateUpNextButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate {

}

- (void)nowPlayingTemplateAlbumArtistButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate {

}

RCT_EXPORT_METHOD(checkMPNowPlayingInfoCenter) {
    NSDictionary *nowPlayingInfo = [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo;
    NSLog(@"Current Now Playing Info: %@", nowPlayingInfo);
}

RCT_EXPORT_METHOD(setAllIsPlayingFalse:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    RNCPStore * store = [RNCPStore sharedManager];
    [store setAllIsPlayingFalse:^{
        resolve(@{});
    }];
}

RCT_EXPORT_METHOD(isSetMPNowPlayingInfoCenter:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *nowPlayingInfo = [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo;
//    resolve(@{@"info": @(nowPlayingInfo.count)});
    if (nowPlayingInfo != nil && nowPlayingInfo.count > 0) {
//        NSError* error = nil;
//        NSData* data = [NSJSONSerialization dataWithJSONObject:nowPlayingInfo options:NSJSONWritingPrettyPrinted error: &error];
        resolve(@{@"info": @(nowPlayingInfo.count), @"title": [nowPlayingInfo objectForKey:@"title"]});
    } else {
//        NSError *error = [[NSError alloc] init];
//        reject(@"not_set", @"Now Playing info not set yet", error);
        resolve(@{});
    }
}

RCT_EXPORT_METHOD(updateNowPlayingInfo:(NSDictionary *)info) {
    MPNowPlayingInfoCenter *nowPlayingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];

    NSMutableDictionary *nowPlayingInfo = [nowPlayingInfoCenter.nowPlayingInfo mutableCopy];
    if (info[@"title"]) {
        [nowPlayingInfo setObject:info[@"title"] forKey:MPMediaItemPropertyTitle];
    }
    if (info[@"artist"]) {
        [nowPlayingInfo setObject:info[@"artist"] forKey:MPMediaItemPropertyArtist];
    }
    if (info[@"album"]) {
        [nowPlayingInfo setObject:info[@"album"] forKey:MPMediaItemPropertyAlbumTitle];
    }
    if (info[@"progress"]) {
        [nowPlayingInfo setObject:[NSNumber numberWithDouble:[info[@"progress"] doubleValue]] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    }
    if (info[@"duration"]) {
        [nowPlayingInfo setObject:[NSNumber numberWithDouble:[info[@"duration"] doubleValue]] forKey:MPMediaItemPropertyPlaybackDuration];
    }
    if (info[@"rate"]) {
        [nowPlayingInfo setObject:[NSNumber numberWithDouble:[info[@"rate"] doubleValue]] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [nowPlayingInfo setObject:[NSNumber numberWithDouble:[info[@"rate"] doubleValue]] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
    }
    if (info[@"type"]) {
        [nowPlayingInfo setObject:[NSNumber numberWithInt:[info[@"type"] intValue]] forKey:MPNowPlayingInfoPropertyMediaType];
    }
    if (info[@"image"]) {
        // Load the cover image asynchronously
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *coverImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:info[@"image"]]];
            UIImage *coverImage = [UIImage imageWithData:coverImageData];

            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:coverImage];
            [nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo;
            });
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo;
        });
    }
}

# pragma Siri Intents

// Request Siri authorization
RCT_EXPORT_METHOD(requestSiriAuthorization:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
        switch (status) {
            case INSiriAuthorizationStatusAuthorized:
                // Siri authorization was successful
                resolve(@"authorized");
                break;
                
            case INSiriAuthorizationStatusDenied:
                // Siri authorization was denied by the user
                resolve(@"denied");
                break;
                
            case INSiriAuthorizationStatusRestricted:
                // Siri authorization is restricted on this device
                resolve(@"restricted");
                break;
                
            default: {
                NSError *error = [[NSError alloc] init];
                reject(@"unknown", @"No Status", error);
                break;
            }
        }
    }];
}

@end
