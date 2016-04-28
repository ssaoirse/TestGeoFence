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
#import <CoreLocation/CLCircularRegion.h>

// Max number of fences.
const NSInteger MAXIMUM_FENCE_COUNT = 20;


@interface GeoFenceController() <CLLocationManagerDelegate>

typedef enum
{
    EIdle,
    // Ask User to allow always access.
    ERequestingAuthorization,
    // User has once denied authorization, prompt User to change authorization in Settings.
    ERequestingSettingsUpdate,
    // Monitor available geo fences.
    EMonitoringRegion
}GeoFenceControllerState;

/// The Core Location Location Manager instance.
@property (strong, nonatomic) CLLocationManager* locationManager;
/// The geo fence delegate.
@property (weak, nonatomic) id<GeoFenceControllerDelegate> geoFenceDelegate;
/// Flag to indicate if authorization status was requested by application.
@property (assign, nonatomic) GeoFenceControllerState state;
/// Array to hold all geo fences.
@property (strong, nonatomic) NSMutableArray* allFences;

// DEBUG ONLY.
/// Monitored region.
@property (strong, nonatomic) CLCircularRegion* testRegion;

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
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;     //kCLLocationAccuracyBest;
        // Allow updates when app is in background.
        if([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]){
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
        
        // Initialize array to hold fences.(CLLocation)
        self.allFences = [[NSMutableArray alloc] init];
        
        // DEBUG ONLY. 18.56677862,+73.82974484
        CLLocationCoordinate2D regionCenter;
        regionCenter.latitude = 18.56677862;
        regionCenter.longitude = 73.82974484;
        self.testRegion = [[CLCircularRegion alloc] initWithCenter:regionCenter
                                                            radius:25.0
                                                        identifier:@"Silicus-B"];
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
            [self startRegionMonitoring];
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
    }
    
    // if requesting update in settings.
    else if(self.state == ERequestingSettingsUpdate){
        self.state = EIdle;
        [self notifyControllerStatus:@"Idle"];
    }

    // Stop region monitoring.
    else if(self.state == EMonitoringRegion){
        self.state = EIdle;
        [self.locationManager stopMonitoringForRegion:self.testRegion];
        [self notifyControllerStatus:@"Idle"];
    }
}


// Add fence.
-(BOOL) addFenceWithTitle:(NSString*)title
                 latitude:(double)latitude
                longitude:(double)longitude
                   radius:(double)radius
{
    // Return if max fences are already added.
    if([self.allFences count] == MAXIMUM_FENCE_COUNT){
        NSLog(@"Max fence count reached.");
        return NO;
    }
    
    // Ensure input parameters are valid. (radius cannot be negative).
    if(!(title && [title length] > 0 && radius < 0.0)){
        return NO;
    }
    
    // Create a fence instance.
    // TODO: Ensure same fence doesn't get added again.
    CLLocationCoordinate2D fenceCenter;
    fenceCenter.latitude = latitude;
    fenceCenter.longitude = longitude;
    CLCircularRegion* newFence = [[CLCircularRegion alloc] initWithCenter:fenceCenter
                                                                   radius:radius
                                                               identifier:title];
    [self.allFences addObject:newFence];
    return YES;
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
            else if(self.state == EMonitoringRegion){
                self.state = EIdle;
                [self.locationManager stopMonitoringForRegion:self.testRegion];
                [self notifyControllerStatus:@"Idle"];
            }
            return;;
        }
            
        case(kCLAuthorizationStatusAuthorizedAlways):
        {
            // Check if a request for authorization was made.
            if(self.state == ERequestingAuthorization ||
               self.state == ERequestingSettingsUpdate){
                // Initiate request to get current location..
                [self startRegionMonitoring];
            }
            break;
        }
    }
}


// Monitoring for Region started.
-(void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Monitor entry/exit for %@.",region.identifier);
}


// Monitoring failed for region.
-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    NSString* message = [NSString stringWithFormat:@"Region Monitoring error: %@.",
                         [error localizedDescription]];
    [self notifyControllerStatus:message];
}


// User entered in one of the geo fences.
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    if([self.geoFenceDelegate respondsToSelector:@selector(didEnterGeoFence:)]){
        [self.geoFenceDelegate didEnterGeoFence:region.identifier];
    }
}


// User has exited from one of the geo fences.
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    
    if([self.geoFenceDelegate respondsToSelector:@selector(didExitGeoFence:)]){
        [self.geoFenceDelegate didExitGeoFence:region.identifier];
    }
}


#pragma mark - Private methods.

-(void) requestAuthorization
{
    [self.locationManager requestAlwaysAuthorization];
}

// TEST: Add and monitor region.
-(void) startRegionMonitoring
{
    self.state = EMonitoringRegion;
    [self.locationManager startMonitoringForRegion:self.testRegion];
    [self notifyControllerStatus:@"monitoring region"];
    [self notifyCurrentFence];
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

// Update the location for current fence.
-(void) notifyCurrentFence
{
    if([self.geoFenceDelegate respondsToSelector:@selector(didUpdateFenceWithLatitude:longitude:)]){
        [self.geoFenceDelegate didUpdateFenceWithLatitude:self.testRegion.center.latitude
                                                longitude:self.testRegion.center.longitude];
    }
}

@end

