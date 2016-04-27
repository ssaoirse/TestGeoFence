//
//  GeoFenceController.m
//  TestGeoFence
//
//  Created by Shashi Shaw on 26/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import "GeoFenceController.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface GeoFenceController() <CLLocationManagerDelegate>

typedef enum
{
    EIdle,
    // Ask User to allow always access.
    ERequestingAuthorization,
    // User has once denied authorization, prompt User to change authorization in Settings.
    ERequestingSettingsUpdate,
    // Request location update to find current user location.
    ERequestingLocationUpdate,
    // Monitor available geo fences.
    EMonitoringRegion
}GeoFenceControllerState;

/// The Core Location Location Manager instance.
@property (strong, nonatomic) CLLocationManager* locationManager;
/// The geo fence delegate.
@property (weak, nonatomic) id<GeoFenceControllerDelegate> geoFenceDelegate;
/// Flag to indicate if authorization status was requested by application.
@property (assign, nonatomic) GeoFenceControllerState state;
/// Holds the current User location.
@property (strong, nonatomic) CLLocation* userLocation;
/// Array to hold all geo fences.
@property (strong, nonatomic) NSMutableArray* allFences;

@end

@implementation GeoFenceController

// Initializer.
-(GeoFenceController*) initWithDelegate:(id<GeoFenceControllerDelegate>)delegate
{
    self = [super init];
    if(self){
        
        // initialize with Idle state.
        self.state = EIdle;
        
        // NOTE:
        // On initializing the location manager object, the didChangeAuthorizationStatus delegate
        // method is called.
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.geoFenceDelegate = delegate;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // Allow updates when app is in background.
        if([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]){
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
        
        // Initialize the user location.
        self.userLocation = [[CLLocation alloc] init];
        
        // Initialize array to hold fences.(CLLocation)
        self.allFences = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - Public Methods.


-(void) start
{
    // Return if location manager is busy.
    if(self.state != EIdle && self.state != ERequestingSettingsUpdate){
        return;
    }
    
    // Check authorization status.
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch(status)
    {
        case(kCLAuthorizationStatusNotDetermined):
        {
            // Request authorization.
            self.state = ERequestingAuthorization;
            [self notifyControllerStatus:@"Requesting Authorization"];
            [self requestAuthorization];
            return;
        }
        case(kCLAuthorizationStatusAuthorizedWhenInUse):
        case(kCLAuthorizationStatusRestricted):
        case(kCLAuthorizationStatusDenied):
        default:
        {
            self.state = ERequestingSettingsUpdate;
            [self notifyControllerStatus:@"Requesting Settings update"];
            [self notifyError:kAuthorizationNotAvailable
              withDescription:@"Authorization not available."];
            break;
        }
            
        case(kCLAuthorizationStatusAuthorizedAlways):
        {
            // Permission available.
            [self getCurrentLocation];
            break;
        }
    }
}

// Stop the location manager activity.
-(void) stop
{
    // If doing nothing just update the status.
    if(self.state == EIdle){
        [self notifyControllerStatus:@"Idle"];
        return;
    }
    
    // if requesting update in settings.
    if(self.state == ERequestingSettingsUpdate){
        self.state = EIdle;
        [self notifyControllerStatus:@"Idle"];
        return;
    }

    // Stop location update if active.
    if(self.state == ERequestingLocationUpdate){
        self.state = EIdle;
        [self.locationManager stopUpdatingLocation];
        [self notifyControllerStatus:@"Idle"];
    }
}

#pragma mark - CLLocationManagerDelegate

// Handle Change in authorization Status.
// This callback is received in 3 cases.
// 1. Location Manager object is initialized.
// 2. The location authorization status is explicitly changed by the User from Settings.
// 3. The User is prompted with an authorization request to grant access.
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Do nothing if we are idle
    if(self.state == EIdle){
        return;
    }
    
    // else authorization has been requested or User has explicity changed the auth status.
    switch(status)
    {
        default:
        case(kCLAuthorizationStatusNotDetermined):
        case(kCLAuthorizationStatusDenied):
        case(kCLAuthorizationStatusRestricted):
        case(kCLAuthorizationStatusAuthorizedWhenInUse):
        {
            // App is requesting for authorization.
            if(self.state == ERequestingAuthorization){
                self.state = EIdle;
                [self notifyControllerStatus:@"Idle"];
                [self notifyError:kAuthorizationDenied
                  withDescription:@"Authorization Denied."];
            }
            // Stop the location manager if it is active and notify error to user.
            else if(self.state == ERequestingLocationUpdate){
                self.state = EIdle;
                [self notifyControllerStatus:@"Idle"];
                [self.locationManager stopUpdatingLocation];
            }
            else if(self.state == EMonitoringRegion){
                self.state = EIdle;
            }
            return;;
        }
            
        case(kCLAuthorizationStatusAuthorizedAlways):
        {
            // Check if a request for authorization was made.
            if(self.state == ERequestingAuthorization ||
               self.state == ERequestingSettingsUpdate){
                // Initiate request to get current location..
                [self getCurrentLocation];
            }
            break;
        }
    }
}


// Handle the initial location, return after startUpdatingLocation
-(void) locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    NSLog(@"didUpdateLocations: %@",locations);
    CLLocation* currentLocation = [locations lastObject];
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (currentLocation.horizontalAccuracy < 0) {
        NSLog(@"didUpdateLocations: horizontal accuracy < 0");
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    //
    NSTimeInterval locationAge = -[currentLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        NSLog(@"didUpdateLocations: age > 5.0");
        return;
    }
    
    // Notify listener if user location has updated.
    if(self.userLocation != currentLocation){
        self.userLocation =  currentLocation;
        [self notifyControllerStatus:@"Monitor User location"];
        [self notifyUserLocation];
    }
    
    if (currentLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
        NSLog(@"Stopping location manager.");
        [self.locationManager stopUpdatingLocation];
    }
    
}

// Handle error in requesting current location.
-(void) locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self notifyError:kErrorReadingLocation
      withDescription:[error localizedDescription]];
}


// Monitoring for Region started.
-(void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{

}


// Monitoring failed for region.
-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{

}


// User entered in one of the geo fences.
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{

}


// User has exited from one of the geo fences.
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{

}


#pragma mark - Private methods.

-(void) requestAuthorization
{
    [self.locationManager requestAlwaysAuthorization];
}


// Initiate request to get current device location.
-(void) getCurrentLocation
{
    // Alternatively can use requestLocation on v9 and above.
    self.state = ERequestingLocationUpdate;
    [self notifyControllerStatus:@"Requesting current location"];
    [self.locationManager startUpdatingLocation];
}


// Update current location to listener.
-(void) notifyUserLocation
{
    if([self.geoFenceDelegate respondsToSelector:@selector(didUpdateLocationWithLatitude:longitude:)]){
        [self.geoFenceDelegate didUpdateLocationWithLatitude:self.userLocation.coordinate.latitude
                                                   longitude:self.userLocation.coordinate.longitude];
    }
}


// Notify error to listener.
-(void) notifyError:(GeoFenceControllerError)error
    withDescription:(NSString*)description
{
    if([self.geoFenceDelegate respondsToSelector:@selector(didFailWithError:description:)]){
        [self.geoFenceDelegate didFailWithError:error description:description];
    }
}


// Notify the current activity of controller.
-(void) notifyControllerStatus:(NSString*)status
{
    if([self.geoFenceDelegate respondsToSelector:@selector(didUpdateStatus:)]){
        [self.geoFenceDelegate didUpdateStatus:status];
    }

}


@end

