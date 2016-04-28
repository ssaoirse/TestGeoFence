//
//  ViewController.m
//  TestGeoFence
//
//  Created by Shashi Shaw on 26/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import "ViewController.h"
#import "GeoFenceController.h"
#import "LocationMonitor.h"

@interface ViewController () <LocationMonitorDelegate,GeoFenceControllerDelegate>

@property (strong,nonatomic) LocationMonitor* locationMonitor;
@property (strong, nonatomic) UILabel* monitorTitleLabel;
@property (strong, nonatomic) UILabel* currentLatitudeLabel;
@property (strong, nonatomic) UILabel* currentLongitudeLabel;
@property (strong, nonatomic) UILabel* accuracyLabel;
@property (strong, nonatomic) UILabel* monitorStatusLabel;
@property (strong, nonatomic) UIButton* startMonitorButton;
@property (strong, nonatomic) UIButton* stopMonitorButton;


@property (strong, nonatomic) GeoFenceController* geoFenceController;

@property (strong, nonatomic) UILabel* fenceControllerTitleLabel;
@property (strong, nonatomic) UILabel* fenceLatitudeLabel;
@property (strong, nonatomic) UILabel* fenceLongitudeLabel;
@property (strong, nonatomic) UIButton* fenceStartButton;
@property (strong, nonatomic) UIButton* fenceStopButton;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize monitor view.
    [self initializeMonitorView];
    
    // Initialize controls
    [self initializeGeoFenceView];
    
    // Initialize location monitor.
    self.locationMonitor = [[LocationMonitor alloc] initWithDelegate:self];
    
    // Initialize the geo fence controller.
    self.geoFenceController = [[GeoFenceController alloc] initWithDelegate:self];
    
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


// Start Monitoring.
-(void) startFenceMonitor
{
    [self.geoFenceController start];
}


// Stop monitoring.
-(void) stopFenceMonitor
{
    [self.geoFenceController stop];
}


#pragma mark - Location Monitor Delegate.

// Notifies the current state of the Monitor.
-(void) locationMonitor:(LocationMonitor*)monitor
        didUpdateStatus:(NSString*)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMonitorStatus:status];
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


#pragma mark - GeoFence Delegate.

// Used to update the current status of the geo fence controller.
-(void) didUpdateStatus:(NSString*)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateControllerStatus:status];
    });
}

-(void) didUpdateFenceWithLatitude:(double)latitude longitude:(double)longitude
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateFenceLatitude:latitude longitude:longitude];
    });
}

-(void) didEnterGeoFence:(NSString*)fenceName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* message = [NSString stringWithFormat:@"Moving into: %@.",fenceName];
        [self showFenceEntryExitMessage:message];
    });

}


-(void) didExitGeoFence:(NSString*)fenceName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* message = [NSString stringWithFormat:@"Moving out of: %@.",fenceName];
        [self showFenceEntryExitMessage:message];
    });
}


// Handle errors.
-(void) didFailWithError:(GeoFenceControllerError)error
             description:(NSString*)description
{
    switch(error)
    {
        // User needs to modify the authorization status in Settings.
        case kAuthorizationNotAvailable:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertToUpdateAuthorizationInSettingsWithMonitorEnabled:NO];
            });
            break;
        }
        // User has explicity denied authorization to location access for the app.
        case kAuthorizationDenied:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertForAuthorizationDenied];
            });
            break;
        }
        // Error reading location.
        case kErrorReadingLocation:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showGeneralErrorAlertWithMessage:description];
            });
            break;
        }
        default:
        {
            break;
        }
    }
}


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
                else{
                    // Stop Geo fence controller.
                    [self stopFenceMonitor];
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


#pragma mark - Button events.

-(void) didSelectLocationMonitorStartButton:(id)sender
{
    [self startLocationMonitor];
}


-(void) didSelectLocationMonitorStopButton:(id)sender
{
    [self stopLocationMonitor];
}


-(void) didSelectFenceStartButton:(id)sender
{
    [self startFenceMonitor];
}


-(void) didSelectFenceStopButton:(id)sender
{
    [self stopFenceMonitor];
}

#pragma mark - Private methods.


-(void) initializeMonitorView
{
    // Monitor Title.
    CGRect frame = CGRectMake(10,
                              40.0,
                              140.0,
                              30.0);
    self.monitorTitleLabel = [[UILabel alloc] initWithFrame:frame];
    self.monitorTitleLabel.text = @"Location Monitor:";
    self.monitorTitleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.monitorTitleLabel];
    
    // Monitor Status.
    frame = CGRectMake(self.monitorTitleLabel.frame.origin.x + self.monitorTitleLabel.frame.size.width + 1.0,
                       40.0,
                       self.view.frame.size.width - (10.0 + self.monitorTitleLabel.frame.size.width + 1.0) ,
                       30.0);
    self.monitorStatusLabel = [[UILabel alloc] initWithFrame:frame];
    self.monitorStatusLabel.text = @"Status goes here...";
    self.monitorStatusLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.monitorStatusLabel];
    
    // Latitude
    frame = CGRectMake(10,
                       self.monitorTitleLabel.frame.origin.y + self.monitorTitleLabel.frame.size.height + 1.0,
                       self.view.frame.size.width - 10.0,
                       30.0);
    self.currentLatitudeLabel = [[UILabel alloc] initWithFrame:frame];
    self.currentLatitudeLabel.text = @"Lat:";
    self.currentLatitudeLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.currentLatitudeLabel];
    
    // current Longitude
    frame = CGRectMake(10.0,
                       self.currentLatitudeLabel.frame.origin.y + self.currentLatitudeLabel.frame.size.height + 1.0,
                       self.view.frame.size.width - 10.0,
                       30.0);
    self.currentLongitudeLabel = [[UILabel alloc] initWithFrame:frame];
    self.currentLongitudeLabel.text = @"Long:";
    self.currentLongitudeLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.currentLongitudeLabel];
    
    // Accuracy label.
    frame = CGRectMake(10.0,
                       self.currentLongitudeLabel.frame.origin.y + self.currentLongitudeLabel.frame.size.height + 1.0,
                       self.view.frame.size.width - 10.0,
                       30.0);
    self.accuracyLabel = [[UILabel alloc] initWithFrame:frame];
    self.accuracyLabel.text = @"Accuracy:";
    self.accuracyLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.accuracyLabel];
    
    // Add the start monitor button.
    self.startMonitorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.startMonitorButton.frame = CGRectMake(self.view.frame.size.width/2.0 - 80.0,
                                               self.accuracyLabel.frame.origin.y + self.accuracyLabel.frame.size.height + 5.0,
                                               70.0,
                                               30.0);
    [self.startMonitorButton setBackgroundColor:[UIColor grayColor]];
    [self.startMonitorButton setTitle:@"Start"
                             forState:UIControlStateNormal];
    [self.startMonitorButton setTitleColor:[UIColor blackColor]
                                forState:UIControlStateNormal];
    [self.startMonitorButton addTarget:self
                                action:@selector(didSelectLocationMonitorStartButton:)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startMonitorButton];
    
    // Stop monitor button.
    self.stopMonitorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.stopMonitorButton.frame = CGRectMake(self.view.frame.size.width/2.0 + 10.0,
                                              self.accuracyLabel.frame.origin.y + self.accuracyLabel.frame.size.height + 5.0,
                                              70.0,
                                              30.0);
    [self.stopMonitorButton setBackgroundColor:[UIColor grayColor]];
    [self.stopMonitorButton setTitle:@"Stop"
                            forState:UIControlStateNormal];
    [self.stopMonitorButton setTitleColor:[UIColor blackColor]
                                forState:UIControlStateNormal];
    [self.stopMonitorButton addTarget:self
                               action:@selector(didSelectLocationMonitorStopButton:)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stopMonitorButton];
   
}


// Initialize labels for geofence view.
-(void) initializeGeoFenceView
{
    // fence controller title.
    CGRect frame = CGRectMake(10.0,
                              0.5 * self.view.frame.size.height,
                              self.view.frame.size.width - 10.0,
                              30.0);
    
    self.fenceControllerTitleLabel = [[UILabel alloc] initWithFrame:frame];
    self.fenceControllerTitleLabel.text = @"GeoFence:";
    self.fenceControllerTitleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.fenceControllerTitleLabel];

    // fence latitude.
    frame = CGRectMake(10.0,
                       self.fenceControllerTitleLabel.frame.origin.y + self.fenceControllerTitleLabel.frame.size.height + 1.0,
                       self.view.frame.size.width - 10.0,
                       30.0);
    self.fenceLatitudeLabel = [[UILabel alloc] initWithFrame:frame];
    self.fenceLatitudeLabel.text = @"Lat:";
    self.fenceLatitudeLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.fenceLatitudeLabel];
    
    // fence longitude.
    frame = CGRectMake(10.0,
                       self.fenceLatitudeLabel.frame.origin.y + self.fenceLatitudeLabel.frame.size.height + 1.0,
                       self.view.frame.size.width - 10.0,
                       30.0);
    self.fenceLongitudeLabel = [[UILabel alloc] initWithFrame:frame];
    self.fenceLongitudeLabel.text = @"Long:";
    self.fenceLongitudeLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.fenceLongitudeLabel];
    
    // Add the fence start button.
    self.fenceStartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.fenceStartButton.frame = CGRectMake(self.view.frame.size.width/2.0 - 80.0,
                                             self.fenceLongitudeLabel.frame.origin.y + self.fenceLongitudeLabel.frame.size.height + 5.0,
                                             70.0,
                                             30.0);
    [self.fenceStartButton setBackgroundColor:[UIColor grayColor]];
    [self.fenceStartButton setTitle:@"Start"
                             forState:UIControlStateNormal];
    [self.fenceStartButton setTitleColor:[UIColor blackColor]
                                forState:UIControlStateNormal];
    [self.fenceStartButton addTarget:self
                              action:@selector(didSelectFenceStartButton:)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.fenceStartButton];
    
    
    // fence Stop button.
    self.fenceStopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.fenceStopButton.frame = CGRectMake(self.view.frame.size.width/2.0 + 10.0,
                                            self.fenceLongitudeLabel.frame.origin.y + self.fenceLongitudeLabel.frame.size.height + 5.0,
                                            70.0,
                                            30.0);
    [self.fenceStopButton setBackgroundColor:[UIColor grayColor]];
    [self.fenceStopButton setTitle:@"Stop"
                          forState:UIControlStateNormal];
    [self.fenceStopButton setTitleColor:[UIColor blackColor]
                                forState:UIControlStateNormal];
    self.fenceStopButton.titleLabel.textColor = [UIColor blackColor];
    [self.fenceStopButton addTarget:self
                               action:@selector(didSelectFenceStopButton:)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.fenceStopButton];
}

// updates the latitude, longitude position.
-(void) updateFenceLatitude:(double)latitude longitude:(double)longitude
{
    self.fenceLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %2.8f",
                                    latitude];
    self.fenceLongitudeLabel.text = [NSString stringWithFormat:@"Long: %3.8f",
                                     longitude];
}


// Updates the controller status text.
-(void) updateControllerStatus:(NSString*)status
{
    self.fenceControllerTitleLabel.text = [NSString stringWithFormat:@"GeoFence: %@...",
                                           status];
}

-(void) updateMonitorStatus:(NSString*)status
{
    self.monitorStatusLabel.text = status;
}


// updates the latitude, longitude position.
-(void) updateMonitorLatitude:(double)latitude
                    longitude:(double)longitude
                     accuracy:(double)accuracy
{
    self.currentLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %2.8f",
                                      latitude];
    self.currentLongitudeLabel.text = [NSString stringWithFormat:@"Long: %3.8f",
                                       longitude];
    self.accuracyLabel.text = [NSString stringWithFormat:@"Accuracy: +/-%.2fm",
                               accuracy];
}


@end
