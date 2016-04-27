//
//  ViewController.m
//  TestGeoFence
//
//  Created by Shashi Shaw on 26/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import "ViewController.h"
#import "GeoFenceController.h"


@interface ViewController ()<GeoFenceControllerDelegate>

@property (strong, nonatomic) GeoFenceController* geoFenceController;
@property (strong, nonatomic) UILabel* userPosition;
@property (strong, nonatomic) UIButton* startMonitorButton;
@property (strong, nonatomic) UIButton* stopMonitorButton;
@property (strong, nonatomic) UILabel* controllerStatus;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self initializeView];
    
    // Initialize the geo fence controller.
    self.geoFenceController = [[GeoFenceController alloc] initWithDelegate:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Start Monitoring.
-(void) startMonitoring
{
    [self.geoFenceController start];
}


// Stop monitoring.
-(void) stopMonitoring
{
    [self.geoFenceController stop];
}

#pragma mark - GeoFence Delegate.

// Used to update the current status of the geo fence controller.
-(void) didUpdateStatus:(NSString*)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateControllerStatus:status];
    });
}

-(void) didUpdateLocationWithLatitude:(double)latitude longitude:(double)longitude
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLatitude:latitude longitude:longitude];
    });
}

-(void) didEnterGeoFence
{

}


-(void) didExitGeoFence
{

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
                [self showAlertToUpdateAuthorizationInSettings];
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
-(void) showAlertToUpdateAuthorizationInSettings
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
                [self stopMonitoring];
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


#pragma mark - Button events.

-(void) didSelectStartButton:(id)sender
{
    [self startMonitoring];
}


-(void) didSelectStopButton:(id)sender
{
    [self stopMonitoring];
}


#pragma mark - Private methods.

-(void) initializeView
{
    // Controller status.
    CGRect frame = CGRectMake(20.0,
                              0.15 * self.view.frame.size.height,
                              self.view.frame.size.width - 20.0,
                              40.0);
    self.controllerStatus = [[UILabel alloc] initWithFrame:frame];
    self.controllerStatus.text = @"Status:";
    self.controllerStatus.textColor = [UIColor blackColor];
    [self.view addSubview:self.controllerStatus];
    
    
    // Set the User Position label.
    frame = CGRectMake(20.0,
                       self.view.frame.size.height/2.0,
                       self.view.frame.size.width - 20.0,
                       40.0);
    self.userPosition = [[UILabel alloc] initWithFrame:frame];
    self.userPosition.text = @"Position";
    self.userPosition.textColor = [UIColor blackColor];
    [self.view addSubview:self.userPosition];
    
    // Add the Stop monitor button.
    self.startMonitorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.startMonitorButton.frame = CGRectMake(self.view.frame.size.width/2.0 - 110.0,
                                               self.userPosition.frame.origin.y + self.userPosition.frame.size.height + 20.0,
                                               100.0,
                                               50.0);
    [self.startMonitorButton setBackgroundColor:[UIColor grayColor]];
    [self.startMonitorButton setTitle:@"Start"
                             forState:UIControlStateNormal];
    self.startMonitorButton.titleLabel.textColor = [UIColor blackColor];
    [self.startMonitorButton addTarget:self
                                action:@selector(didSelectStartButton:)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startMonitorButton];
    
    // Stop monitor button.
    self.stopMonitorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.stopMonitorButton.frame = CGRectMake(self.view.frame.size.width/2.0 + 10.0,
                                              self.userPosition.frame.origin.y + self.userPosition.frame.size.height + 20.0,
                                              100.0,
                                              50.0);
    [self.stopMonitorButton setBackgroundColor:[UIColor grayColor]];
    [self.stopMonitorButton setTitle:@"Stop"
                             forState:UIControlStateNormal];
    self.stopMonitorButton.titleLabel.textColor = [UIColor blackColor];
    [self.stopMonitorButton addTarget:self
                                action:@selector(didSelectStopButton:)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stopMonitorButton];
    
    
    
}

// updates the latitude, longitude position.
-(void) updateLatitude:(double)latitude longitude:(double)longitude
{
    self.userPosition.text = [NSString stringWithFormat:@"Lat:%f Long:%f",
                              latitude,longitude];
}


// Updates the controller status text.
-(void) updateControllerStatus:(NSString*)status
{
    self.controllerStatus.text = [NSString stringWithFormat:@"Status: %@...",
                                  status];
}

@end
