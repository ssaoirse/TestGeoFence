//
//  LocationMapViewController.m
//  TestGeoFence
//
//  Created by Shashi Shaw on 28/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import "LocationMapViewController.h"
#import "LocationMonitor.h"
#import <MapKit/MapKit.h>

@interface LocationMapViewController ()<LocationMonitorDelegate,MKMapViewDelegate>

@property (strong,nonatomic) LocationMonitor* locationMonitor;

@end

@implementation LocationMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Initialize location monitor.
    self.locationMonitor = [[LocationMonitor alloc] initWithDelegate:self];
    self.locationMapView.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(),^{
        //[self startLocationMonitor];
    });

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Start Monitoring.
-(void) startLocationMonitor
{
    [self.locationMonitor start];
}


// Stop monitoring.
-(void) stopLocationMonitor
{
    [self.locationMonitor stop];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Location Monitor Delegate.

// Notifies the current state of the Monitor.
-(void) locationMonitor:(LocationMonitor*)monitor
        didUpdateStatus:(NSString*)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self updateMonitorStatus:status];
    });
}


// Notifies current location.
-(void) locationMonitor:(LocationMonitor*)monitor
updateLocationWithLatitude:(double)latitude
              longitude:(double)longitude
               accuracy:(double)accuracy
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMonitorLatitude:latitude
                          longitude:longitude
                           accuracy:accuracy];
    });
}


// Notifies error in reading location.
-(void) locationMonitor:(LocationMonitor*)monitor
       didFailWithError:(LocationMonitorError)error
       errorDescription:(NSString*)errorDescription
{
    switch(error)
    {
            // User needs to modify the authorization status in Settings.
        case kLocationMonitorAuthorizationNotAvailable:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertToUpdateAuthorizationInSettingsWithMonitorEnabled:YES];
            });
            break;
        }
            // User has explicity denied authorization to location access for the app.
        case kLocationMonitorAuthorizationDenied:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertForAuthorizationDenied];
            });
            break;
        }
            // Error reading location.
        case kLocationMonitorErrorReadingLocation:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showGeneralErrorAlertWithMessage:errorDescription];
            });
            break;
        }
        default:
        {
            break;
        }
    }
    
}

#pragma mark - alerts.


// Show alert and request user to update settings.
-(void) showAlertToUpdateAuthorizationInSettingsWithMonitorEnabled:(BOOL)monitorEnabled
{
    NSString* message = @"To use background location you must turn on 'Always' in the Location Services Settings";
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"TestGeoFence"
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionOk = [UIAlertAction actionWithTitle:@"Settings"
                                                       style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            // Send the user to the Settings for this app
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL];

            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                // Stop monitoring.
                if(monitorEnabled){
                    [self stopLocationMonitor];
                }
            });
        }];
    
    [alert addAction:actionOk];
    [alert addAction:actionCancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}


-(void) showAlertForAuthorizationDenied
{
    NSString* message = @"Unable to perform geo fence monitoring without proper authorization.";
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"TestGeoFence"
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:actionOk];
    [self presentViewController:alert animated:YES completion:nil];
}


// Display general error alert.
-(void) showGeneralErrorAlertWithMessage:(NSString*)message
{
    NSString* errorMsg = [NSString stringWithFormat:@"Error: %@",message];
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"TestGeoFence - Error"
                                                                     message:errorMsg
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:actionOk];
    [self presentViewController:alert animated:YES completion:nil];
}

// Display general error alert.
-(void) showFenceEntryExitMessage:(NSString*)message
{
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"TestGeoFence"
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:actionOk];
    [self presentViewController:alert animated:YES completion:nil];
}


// updates the latitude, longitude position.
-(void) updateMonitorLatitude:(double)latitude
                    longitude:(double)longitude
                     accuracy:(double)accuracy
{
    
    float spanX = 0.005;
    float spanY = 0.005;
    MKCoordinateRegion region;
    region.center.latitude = latitude;
    region.center.longitude = longitude;
    region.span = MKCoordinateSpanMake(spanX, spanY);
    [self.locationMapView setRegion:region animated:YES];
    
#if 0
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    [self.locationMapView setCenterCoordinate:center animated:YES];
#endif
    
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    NSLog(@"UserLocation: %02.10f, %03.10f",userLocation.coordinate.latitude,userLocation.coordinate.longitude);
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    CLLocationCoordinate2D location;
    location.latitude = userLocation.coordinate.latitude;
    location.longitude = userLocation.coordinate.longitude;
    region.span = span;
    region.center = location;
    [self.locationMapView setRegion:region animated:YES];
}

@end
