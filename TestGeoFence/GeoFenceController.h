//
//  GeoFenceController.h
//  TestGeoFence
//
//  Created by Shashi Shaw on 26/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import <Foundation/Foundation.h>

// Constants to notify probable errors.
typedef enum
{
    kErrorGeneral,
    kAuthorizationNotAvailable,                 // Required authorization not available.
    kAuthorizationDenied,                       // Required authorization was modified.
    kErrorReadingLocation
    
} GeoFenceControllerError;

//------------------------------------------GeoFenceControllerDelegate----------------------------------------------

/*!
 * @brief The protocol class for GeoFenceController. Notifies when user enters/exits 
 *        a geo fence.
 */
@protocol GeoFenceControllerDelegate<NSObject>

-(void) didUpdateStatus:(NSString*)status;
-(void) didUpdateFenceWithLatitude:(double)latitude longitude:(double)longitude;
-(void) didEnterGeoFence:(NSString*)fenceName;
-(void) didExitGeoFence:(NSString*)fenceName;
-(void) didFailWithError:(GeoFenceControllerError)error
             description:(NSString*)description;

@end

//------------------------------------------GeoFenceController-------------------------------------------------------

/*!
 * @brief A geo fence monitoring class which allows to add geo fences and monitor
 *        user's entry/exit into these geo fences.
 */
@interface GeoFenceController : NSObject

/*!
 * @brief Initializer: Creates and returns an instance of GeoFenceController.
 * @param  delegate             A reference to the GeoFenceControllerDelegate.
 * @return GeoFenceController*  An instance of a GeoFenceController object.
 */
-(GeoFenceController*) initWithDelegate:(id<GeoFenceControllerDelegate>)delegate;

/// Start the controller.
-(void) start;
/// Stop the controller.
-(void) stop;

/*!
 * @brief Add a fence to monitor.
 * @param  title                An identifier for the geo fence.
 * @param  latitude             The latitude value in degrees for the center of the fence.
 * @param  longitude            The longitude value in degress for the center of the fence.
 * @param  radius               The radius in meters for the fence.
 * @return BOOL                 return YES when fence is successfully added for tracking.
 */
-(BOOL) addFenceWithTitle:(NSString*)title
                 latitude:(double)latitude
                longitude:(double)longitude
                   radius:(double)radius;

@end

//------------------------------------------------------------------------------------------------------------------