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

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.geoFenceController = [[GeoFenceController alloc] initWithDelegate:self];
    
    dispatch_async(dispatch_get_main_queue(),^{
        [self startMonitoring];
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) startMonitoring
{
    [self.geoFenceController start];
}


#pragma mark - GeoFence Delegate.

-(void) didEnterGeoFence
{

}


-(void) didExitGeoFence
{

}

@end
