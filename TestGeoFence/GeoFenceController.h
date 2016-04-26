//
//  GeoFenceController.h
//  TestGeoFence
//
//  Created by Shashi Shaw on 26/04/16.
//  Copyright © 2016 Shashi Shaw. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @brief The protocol class for GeoFenceController. Notifies when user enters/exits 
 *        a geo fence.
 */
@protocol GeoFenceControllerDelegate<NSObject>

-(void) didEnterGeoFence;
-(void) didExitGeoFence;

@end


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

-(void) start;

@end
