#import "SimplePermissionsPlugin.h"

@import CoreLocation;

@interface SimplePermissionsPlugin() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (copy, nonatomic)   FlutterResult      flutterResult;
@property (nonatomic)   BOOL whenInUse;
@end

@implementation SimplePermissionsPlugin




+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"simple_permissions" binaryMessenger:registrar.messenger];
    
    SimplePermissionsPlugin *instance = [[SimplePermissionsPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

-(instancetype)init {
    self = [super init];
    
    if (self) {
        self.clLocationManager = nil;
    }
    return self;
}

-(void)checkPermission:(NSString *)permission result:(FlutterResult)result {
    if([permission isEqualToString:@"ACCESS_COARSE_LOCATION"] ||
       [permission isEqualToString:@"ACCESS_FINE_LOCATION"] ||
       [permission isEqualToString:@"WHEN_IN_USE_LOCATION"] ) {
        result( [self checkLocationWhenInUsePermission] );
    } else if([permission isEqualToString:@"ALWAYS_LOCATION"] ) {
        result( [self checkLocationAlwaysPermission ] );
    }
}

-(void)getPermissionStatus:(NSString *)permission result:(FlutterResult)result {
    if([permission isEqualToString:@"ACCESS_COARSE_LOCATION"] ||
       [permission isEqualToString:@"ACCESS_FINE_LOCATION"] ||
       [permission isEqualToString:@"WHEN_IN_USE_LOCATION"] ) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if(status == kCLAuthorizationStatusAuthorizedWhenInUse ||
           status == kCLAuthorizationStatusAuthorizedAlways) {
            result(@(3));
        }else{
            result( [NSNumber numberWithInt:(int)status] );
        }
    } else if([permission isEqualToString:@"ALWAYS_LOCATION"] ) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if(status == kCLAuthorizationStatusAuthorizedAlways) {
            result(@(3));
        }else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
            result(@(1));
        }else{
            result( [NSNumber numberWithInt:(int)status] );
        }
    }
}

-(void)requestPermission:(NSString *)permission result:(FlutterResult)result {
    if([permission isEqualToString:@"ACCESS_COARSE_LOCATION"] ||
       [permission isEqualToString:@"ACCESS_FINE_LOCATION"] ||
       [permission isEqualToString:@"WHEN_IN_USE_LOCATION"] ) {
        [self requestLocationWhenInUsePermission:result ];
    } else if([permission isEqualToString:@"ALWAYS_LOCATION"] ) {
        [self requestLocationAlwaysPermission:result ];
    }

}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [self initLocation];
    NSDictionary *arguments = call.arguments;
    if ([call.method isEqualToString:@"checkPermission"]) {
        NSString *perm = [arguments objectForKey:@"permission"];
        if( perm != nil ) {
            [self checkPermission:perm result:result];
        } else {
            result([FlutterError errorWithCode:@"permission missing" message:nil details:nil]);
        }
    } else if ([call.method isEqualToString:@"getPermissionStatus"]) {
        NSString *perm = [arguments objectForKey:@"permission"];
        if( perm != nil ) {
            [self getPermissionStatus:perm result:result];
        } else {
            result([FlutterError errorWithCode:@"permission missing" message:nil details:nil]);
        }
    } else if ([call.method isEqualToString:@"requestPermission"]) {
        NSString *perm = [arguments objectForKey:@"permission"];
        if( perm != nil ) {
            [self requestPermission:perm result:result];
        } else {
            result([FlutterError errorWithCode:@"permission missing" message:nil details:nil]);
        }
    } else if ([call.method isEqualToString:@"getPlatformVersion"]) {
        result([NSString stringWithFormat:@"iOS %@", UIDevice.currentDevice.systemVersion]);
    } else if ([call.method isEqualToString:@"openSettings"]) {
        UIApplication *app = [UIApplication sharedApplication];
        if (@available(iOS 10, *) && [app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [app        openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                        options:@{}
              completionHandler:^(BOOL success) {
                   if (success) {
                       result(nil);
                   } else {
                       result([FlutterError
                               errorWithCode:@"Error"
                               message:[NSString stringWithFormat:@"Error while launching %@", UIApplicationOpenSettingsURLString]
                               details:nil]);
                   }
               }];
        } else {
            BOOL success = [app openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            if (success) {
                result(nil);
            } else {
                result([FlutterError
                        errorWithCode:@"Error"
                        message:[NSString stringWithFormat:@"Error while launching %@", UIApplicationOpenSettingsURLString]
                        details:nil]);
            }
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(NSNumber *)checkLocationWhenInUsePermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return [NSNumber numberWithBool:(
                    status == kCLAuthorizationStatusAuthorizedAlways ||
                    status == kCLAuthorizationStatusAuthorizedWhenInUse)];
}

-(NSNumber *)checkLocationAlwaysPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return [NSNumber numberWithBool:(
                                     status == kCLAuthorizationStatusAuthorizedAlways )];

}

-(void)initLocation {
    if( !self.clLocationManager && [CLLocationManager locationServicesEnabled] ) {
        self.clLocationManager = [[CLLocationManager alloc] init];
        self.clLocationManager.delegate = self;
    }
}

-(void)requestLocationWhenInUsePermission:(FlutterResult)result {
    if( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self initLocation];
        if( self.clLocationManager ) {
            self.flutterResult = result;
            self.whenInUse = YES;
            [self.clLocationManager requestWhenInUseAuthorization];
        }else{
            result( [NSNumber numberWithBool:NO] );
        }
    }else{
        result( [self checkLocationWhenInUsePermission] );
    }
}

-(void)requestLocationAlwaysPermission:(FlutterResult)result {
    if( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self initLocation];
        if( self.clLocationManager ) {
            self.flutterResult = result;
            self.whenInUse = NO;
            [self.clLocationManager requestAlwaysAuthorization];
        }else{
            result( [NSNumber numberWithBool:NO] );
        }
    }else{
        result( [self checkLocationAlwaysPermission] );
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"Auth change %d", (int)status);
    if( status != kCLAuthorizationStatusNotDetermined ) {
        if(self.flutterResult) {
            if(self.whenInUse) {
                if(status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                   status == kCLAuthorizationStatusAuthorizedAlways) {
                    self.flutterResult(@(3));
                }else{
                    self.flutterResult( [NSNumber numberWithInt:(int)status] );
                }
            }else{
                if(status == kCLAuthorizationStatusAuthorizedAlways) {
                    self.flutterResult(@(3));
                }else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
                    self.flutterResult(@(1));
                }else{
                    self.flutterResult( [NSNumber numberWithInt:(int)status] );
                }
            }
        }
    }
}


@end
