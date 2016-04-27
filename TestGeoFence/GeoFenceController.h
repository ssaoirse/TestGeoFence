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
    kAuthorizationNotAvailable,                 // Required authorization not available.
    kAuthorizationDenied                        // Required authorization was modified.
    
} GeoFenceControllerError;

//------------------------------------------GeoFenceControllerDelegate----------------------------------------------

/*!
 * @brief The protocol class for GeoFenceController. Notifies when user enters/exits 
 *        a geo fence.
 */
@protocol GeoFenceControllerDelegate<NSObject>

-(void) didUpdateLocationWithLatitude:(double)latitude longitude:(double)longitude;
-(void) didEnterGeoFence;
-(void) didExitGeoFence;
-(void) didFailWithError:(GeoFenceControllerError)error;

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

#if 0
-(void) addFenceWithTitle:(NSString*)title
                 latitude:(double)latitude
                longitude:(double)longitude
                   radius:(double)radius;
#endif

@end

//------------------------------------------------------------------------------------------------------------------