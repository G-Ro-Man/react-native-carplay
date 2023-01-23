#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>

@interface RNCPStore : NSObject {
    CPInterfaceController *interfaceController;
    CPWindow *window;
}

@property (nonatomic, retain) CPInterfaceController *interfaceController;
@property (nonatomic, retain) CPWindow *window;

+ (id)sharedManager;
- (CPTemplate*) findTemplateById: (NSString*)templateId;
- (NSString*) setTemplate:(NSString*)templateId template:(CPTemplate*)temp;
- (Boolean) isConnected;
- (void) setConnected:(Boolean) isConnected;

@end
