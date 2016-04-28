//
//  LocationMonitor.h
//  TestGeoFence
//
//  Created by Shashi Shaw on 28/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LocationMonitor;

// Constants to notify probable errors.
typedef enum
{
    kLocationMonitorErrorGeneral = 0x1000,
    kLocationMonitorAuthorizationNotAvailable,                 // Required authorization not available.
    kLocationMonitorAuthorizationDenied,                       // Required authorization was modified.
    kLocationMonitorErrorReadingLocation
    
} LocationMonitorError;

/*!
 * @brief Location monitor Delegate: Notifies about updates to the current user location.
 */
@protocol LocationMonitorDelegate <NSObject>

/*!
 * @brief Notifies about the successful current state of the monitor.
 * @param  monitor                  The location monitor instance.
 * @param  status                   The current activity state of the location monitor.
 */
-(void) locationMonitor:(LocationMonitor*)monitor
        didUpdateStatus:(NSString*)status;
/*!
 * @brief Notifies about the current updated location of the User/device.
 * @param  monitor                  The location monitor instance.
 * @param  latitude                 The current latitude value.
 * @param  longitude                The current longitude value.
 */
-(void) locationMonitor:(LocationMonitor*)monitor updateLocationWithLatitude:(double)latitude
              longitude:(double)longitude;

/*!
 * @brief Notifies about the error
 * @param  monitor                  The location monitor instance.
 * @param  error                    The error code for the process.
 * @param  errorDescription         The description for the error.
 */
-(void) locationMonitor:(LocationMonitor*)monitor
       didFailWithError:(LocationMonitorError)error
       errorDescription:(NSString*)errorDescription;

@end


/*!
 * @brief Class which provides info about the current location of the User.
 */
@interface LocationMonitor : NSObject

/*!
 * @brief Initializer: Creates and returns an instance of LocationMonitor.
 * @param  delegate                 A reference to the LocationMonitorDelegate.
 * @return LocationMonitor*         An instance of a GeoFenceController object.
 */
-(LocationMonitor*) initWithDelegate:(id<LocationMonitorDelegate>)delegate;

/// Start the monitor.
-(void) start;
/// Stop the monitor.
-(void) stop;

@end
