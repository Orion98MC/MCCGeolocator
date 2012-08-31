//
//  MCCGeolocator.h
//  MCCGeolocator
//
//  Created by Thierry Passeron on 31/08/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

/*
 
 A Dead Simple Geolocation Retriever Object for iOS 4+
 
 Usage:
 ======
 
 [MCCGeolocator geolocationWithAccuracy: myAccuracy
                            updateBlock: myUpdateBlock
                             errorBlock: myErrorBlock];
 
 That's all folk!
 
 
 REM:
 ----
 
 Don't forget to set the BOOL *stop in the update blocks or else the location manager will endlessly track location / heading changes
 which can reduce battery life.
 
*/

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MCCGeolocator : NSObject

/* Standard geo-localization service */
+ (BOOL)geolocationWithAccuracy:(CLLocationAccuracy)accuracy
                    updateBlock:(void(^)(CLLocation *newLocation, CLLocation *oldLocation, BOOL *stop))updateBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/* Significant location changes service */
+ (BOOL)significantLocationChangesWithBlock:(void(^)(CLLocation *newLocation, CLLocation *oldLocation, BOOL *stop))updateBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

/* Heading service */
+ (BOOL)headingWithBlock:(void(^)(CLHeading *newHeading, BOOL *stop))updateBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

/* Region boundaries crossing service */
+ (BOOL)boundaryCrossingWithAccuracy:(CLLocationAccuracy)accuracy
                              region:(CLRegion *)region
                        enteredBlock:(void(^)(CLRegion *region, BOOL *stop))enteredBlock
                         exitedBlock:(void(^)(CLRegion *region, BOOL *stop))exitedBlock
                          errorBlock:(void(^)(CLRegion *region, NSError *error))errorBlock; /* The region may be nil */

@end
