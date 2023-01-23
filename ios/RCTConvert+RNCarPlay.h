#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <CarPlay/CarPlay.h>
#import <React/RCTConvert.h>

@interface RCTConvert (RNCarPlay)

+ (CPAlertActionStyle)CPAlertActionStyle:(id)json;
@end
