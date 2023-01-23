#import "RCTConvert+RNCarPlay.h"
#import <React/RCTConvert+CoreLocation.h>
#import <Availability.h>

@implementation RCTConvert (RNCarPlay)

+ (CPAlertActionStyle)CPAlertActionStyle:(NSString*) json {
    if ([json isEqualToString:@"cancel"]) {
        return CPAlertActionStyleCancel;
    } else if ([json isEqualToString:@"destructive"]) {
        return CPAlertActionStyleDestructive;
    }
    return CPAlertActionStyleDefault;
}

@end
