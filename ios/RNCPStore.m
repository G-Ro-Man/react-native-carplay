#import "RNCPStore.h"

@implementation RNCPStore {
    NSMutableDictionary* _templatesStore;
    NSMutableDictionary* _navigationSessionsStore;
    NSMutableDictionary* _tripsStore;
    Boolean _connected;
}

@synthesize window;
@synthesize interfaceController;

-(instancetype)init {
    if (self = [super init]) {
        _templatesStore = [[NSMutableDictionary alloc] init];
        _navigationSessionsStore = [[NSMutableDictionary alloc] init];
        _tripsStore = [[NSMutableDictionary alloc] init];
        _connected = false;
    }

    return self;
}

+ (RNCPStore*) sharedManager {
    static RNCPStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void) setConnected:(Boolean) isConnected {
    _connected = isConnected;
}

- (Boolean) isConnected {
    return _connected;
}

- (CPTemplate*) findTemplateById:(NSString*)templateId {
    return [_templatesStore objectForKey:templateId];
}

- (NSString*) setTemplate:(NSString*)templateId template:(CPTemplate*)temp {
    [_templatesStore setObject:temp forKey:templateId];
    return templateId;
}

- (void) setAllIsPlayingFalse:(void (^)(void))completion {
    for (id key in _templatesStore) {
        id template = _templatesStore[key];
        if ([template isKindOfClass:[CPListTemplate class]]) {
            CPListTemplate *listTemplate = (CPListTemplate *)template;
            for (CPListSection *section in listTemplate.sections) {
                for (CPListItem *item in section.items) {
                    if (item.isPlaying) {
                        [item setPlaying:NO];
                        completion();
                        break;
                    }
                }
            }
        }
    }
    completion();
}

@end
