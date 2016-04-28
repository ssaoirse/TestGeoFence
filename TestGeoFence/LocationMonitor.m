//
//  LocationMonitor.m
//  TestGeoFence
//
//  Created by Shashi Shaw on 28/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import "LocationMonitor.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface LocationMonitor() <CLLocationManagerDelegate>

typedef enum
{
    EIdle = 0x100,
    // Ask User to allow always access.
    ERequestingAuthorization,
    // User has once denied authorization, prompt User to change authorization in Settings.
    ERequestingSettingsUpdate,
    // Request location update to find current user location.
    EMonitoringLocation
    
}LocationMonitorState;

/// The Core Location Location Manager instance.
@property (strong, nonatomic) CLLocationManager* locationManager;
/// The location monitor delegate.
@property (weak, nonatomic) id<LocationMonitorDelegate> monitorDelegate;
/// Holds the current state of the monitor.
@property (assign, nonatomic) LocationMonitorState state;
/// Holds the current Location of the User..
@property (strong, nonatomic) CLLocation* userLocation;


@end

@implementation LocationMonitor

// Initializer.
-(LocationMonitor*) initWithDelegate:(id<LocationMonitorDelegate>)delegate
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
        self.monitorDelegate = delegate;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;     //kCLLocationAccuracyBest;
        // Allow updates when app is in background.
        if([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]){
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
        
        // Initialize user's current location.
        self.userLocation = [[CLLocation alloc] init];
    }
    return self;
}


// Start the monitor operation.
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
            [self notifyMonitorStatus:@"Requesting Authorization"];
            [self.locationManager requestAlwaysAuthorization];
            return;
        }
        case(kCLAuthorizationStatusAuthorizedWhenInUse):
        case(kCLAuthorizationStatusRestricted):
        case(kCLAuthorizationStatusDenied):
        default:
        {
            self.state = ERequestingSettingsUpdate;
            [self notifyMonitorStatus:@"Requesting Settings update"];
            [self notifyError:kLocationMonitorAuthorizationNotAvailable
              withDescription:@"Authorization not available."];
            break;
        }
            
        case(kCLAuthorizationStatusAuthorizedAlways):
        {
            // Permission available.
            [self startMonitor];
            break;
        }
    }
}

// Stop the location monitor operation.
-(void) stop
{
    // If doing nothing just update the status.
    if(self.state == EIdle){
        [self notifyMonitorStatus:@"Idle"];
    }
    
    // if requesting update in settings.
    else if(self.state == ERequestingSettingsUpdate){
        self.state = EIdle;
        [self notifyMonitorStatus:@"Idle"];
    }
    
    // Stop location update if active.
    else if(self.state == EMonitoringLocation){
        self.state = EIdle;
        [self.locationManager stopUpdatingLocation];
        [self notifyMonitorStatus:@"Idle"];
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
                [self notifyMonitorStatus:@"Idle"];
                [self notifyError:kLocationMonitorAuthorizationDenied
                  withDescription:@"Authorization Denied."];
            }
            // Stop the location manager if it is active and notify error to user.
            else if(self.state == EMonitoringLocation){
                self.state = EIdle;
                [self notifyMonitorStatus:@"Idle"];
                [self.locationManager stopUpdatingLocation];
            }
            return;;
        }
            
        case(kCLAuthorizationStatusAuthorizedAlways):
        {
            // Check if a request for authorization was made.
            if(self.state == ERequestingAuthorization ||
               self.state == ERequestingSettingsUpdate){
                // Initiate request to get start location monitor..
                [self startMonitor];
            }
            break;
        }
    }
}


// Handle the initial location, return after startUpdatingLocation
-(void) locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    NSLog(@"LocationManager didUpdateLocations: %@",locations);
    CLLocation* currentLocation = [locations lastObject];
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (currentLocation.horizontalAccuracy < 0) {
        NSLog(@"LocationManager didUpdateLocations: horizontal accuracy < 0");
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    //
    NSTimeInterval locationAge = -[currentLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        NSLog(@"LocationManager didUpdateLocations: age > 5.0");
        return;
    }
    
    // Update the User location.
    self.userLocation = currentLocation;
    
    // Update displayed lat/long.
    [self notifyUserLocation];
}


// Handle error in requesting current location.
-(void) locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self notifyError:kLocationMonitorErrorReadingLocation
      withDescription:[error localizedDescription]];
}


#pragma mark - Private methods.

// Initiate request to update location..
-(void) startMonitor
{
    // Alternatively can use requestLocation on v9 and above.
    self.state = EMonitoringLocation;
    [self notifyMonitorStatus:@"Monitoring Location..."];
    [self.locationManager startUpdatingLocation];
}


// Update current location to listener.
-(void) notifyUserLocation
{
    if([self.monitorDelegate respondsToSelector:@selector(locationMonitor:updateLocationWithLatitude:longitude:)]){
        [self.monitorDelegate locationMonitor:self
                   updateLocationWithLatitude:self.userLocation.coordinate.latitude
                                    longitude:self.userLocation.coordinate.longitude];
    }
}


// Notify error to listener.
-(void) notifyError:(LocationMonitorError)error
    withDescription:(NSString*)description
{
    if([self.monitorDelegate respondsToSelector:@selector(locationMonitor:didFailWithError:errorDescription:)]){
        [self.monitorDelegate locationMonitor:self
                             didFailWithError:error
                             errorDescription:description];
    }
}


// Notify the current activity of controller.
-(void) notifyMonitorStatus:(NSString*)status
{
    if([self.monitorDelegate respondsToSelector:@selector(locationMonitor:didUpdateStatus:)]){
        [self.monitorDelegate locationMonitor:self
                              didUpdateStatus:status];
    }
}

@end
