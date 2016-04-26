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

/// The Core Location Location Manager instance.
@property (strong, nonatomic) CLLocationManager* locationManager;
/// The geo fence delegate.
@property (weak, nonatomic) id<GeoFenceControllerDelegate> geoFenceDelegate;

@end

@implementation GeoFenceController

// Initializer.
-(GeoFenceController*) initWithDelegate:(id<GeoFenceControllerDelegate>)delegate
{
    self = [super init];
    if(self){
        self.locationManager = [[CLLocationManager alloc] init];
        self.geoFenceDelegate = delegate;
    }
    return self;
}


-(void) start
{
    
}


#pragma mark - Private methods.


#pragma mark - CLLocationManagerDelegate

// Handle Change in authorization Status.
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{

}


// Handle the initial location, return after startUpdatingLocation
-(void) locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{

}

// Handle error in requesting current location.
-(void) locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{

}


// Monitoring for Region started.
-(void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{

}


// Monitoring failed for region.
-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region
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

@end


