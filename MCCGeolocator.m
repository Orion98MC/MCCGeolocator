//
//  MCCGeolocator.m
//  MCCGeolocatorDemo
//
//  Created by Thierry Passeron on 31/08/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import "MCCGeolocator.h"

@interface MCCGeolocator () <CLLocationManagerDelegate>
@property (retain, nonatomic) CLLocationManager *manager;
@property (copy, nonatomic) void(^updateBlock)(CLLocation *newLocation, CLLocation *oldLocation);
@property (copy, nonatomic) void(^updateHeadingBlock)(CLHeading *newHeading);
@property (copy, nonatomic) void(^regionEnteredBlock)(CLRegion *region);
@property (copy, nonatomic) void(^regionExitedBlock)(CLRegion *region);
@property (copy, nonatomic) void(^errorBlock)(NSError *error);
@property (copy, nonatomic) void(^regionErrorBlock)(CLRegion *region, NSError *error);
@property (retain, nonatomic) CLRegion *region;
@end

@implementation MCCGeolocator
@synthesize manager, errorBlock, updateBlock, updateHeadingBlock, regionEnteredBlock, regionExitedBlock, region, regionErrorBlock;

+ (BOOL)geolocationWithAccuracy:(CLLocationAccuracy)accuracy
                    updateBlock:(void(^)(CLLocation *newLocation, CLLocation *oldLocation, BOOL *stop))updateBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
  MCCGeolocator *o = [[[self alloc]init]autorelease];
  if (!o) return FALSE;
  
  o.manager.desiredAccuracy = accuracy;
  
  void(^cleanupBlock)(void) = ^{
    [o.manager stopUpdatingLocation];
    o.manager.delegate = nil;
    o.errorBlock = nil;
    o.updateBlock = nil;
  };
  
  o.updateBlock = ^(CLLocation *newLocation, CLLocation *oldLocation) {
    BOOL stop = FALSE;
    updateBlock(newLocation, oldLocation, &stop);
    if (stop) { cleanupBlock(); }
  };
  
  o.errorBlock = ^(NSError *error) {
    errorBlock(error);
    cleanupBlock();
  };
  
  [o.manager startUpdatingLocation];
  
  /* 
    Rem:
   
    - the updateBlock and errorBlock both refer to the MCCGeolocator object and thus retain it.
    - once you set *stop = FALSE in the updater block the location updating is stopped and the blocks are released
      which in turn releases the MCCGeolocator object.
  */
  
  return TRUE;
}

+ (BOOL)significantLocationChangesWithBlock:(void(^)(CLLocation *newLocation, CLLocation *oldLocation, BOOL *stop))updateBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
  __block MCCGeolocator *o = [[[self alloc]init]autorelease];
  if (!o) return FALSE;
  
  void(^cleanupBlock)(void) = ^{
    [o.manager stopMonitoringSignificantLocationChanges];
    o.manager.delegate = nil;
    o.errorBlock = nil;
    o.updateBlock = nil;
  };
  
  o.updateBlock = ^(CLLocation *newLocation, CLLocation *oldLocation) {
    BOOL stop = FALSE;
    updateBlock(newLocation, oldLocation, &stop);
    if (stop) { cleanupBlock(); }
  };
  
  o.errorBlock = ^(NSError *error) {
    errorBlock(error);
    cleanupBlock();
  };
  
  [o.manager startMonitoringSignificantLocationChanges];
  
  return TRUE;
}

+ (BOOL)headingWithBlock:(void(^)(CLHeading *newHeading, BOOL *stop))updateBlock
              errorBlock:(void(^)(NSError *error))errorBlock {
  __block MCCGeolocator *o = [[[self alloc]init]autorelease];
  if (!o) return FALSE;
  
  void(^cleanupBlock)(void) = ^{
    [o.manager stopUpdatingHeading];
    o.manager.delegate = nil;
    o.errorBlock = nil;
    o.updateHeadingBlock = nil;
  };
  
  o.updateHeadingBlock = ^(CLHeading *newHeading) {
    BOOL stop = FALSE;
    updateBlock(newHeading, &stop);
    if (stop) { cleanupBlock(); }
  };
  
  o.errorBlock = ^(NSError *error) {
    errorBlock(error);
    cleanupBlock();
  };
  
  [o.manager startUpdatingHeading];
    
  return TRUE;
}

+ (BOOL)boundaryCrossingWithRegion:(CLRegion *)region
                      enteredBlock:(void(^)(CLRegion *region, BOOL *stop))enteredBlock
                       exitedBlock:(void(^)(CLRegion *region, BOOL *stop))exitedBlock
                        errorBlock:(void(^)(CLRegion *region, NSError *error))errorBlock {
  __block MCCGeolocator *o = [[[self alloc]init]autorelease];
  if (!o) return FALSE;
  
  void(^cleanupBlock)(void) = ^{
    [o.manager stopMonitoringForRegion:region];
    o.manager.delegate = nil;
    o.errorBlock = nil;
    o.regionErrorBlock = nil;
    o.regionEnteredBlock = nil;
    o.regionExitedBlock = nil;
  };
  
  o.regionEnteredBlock = ^(CLRegion *region) {
    BOOL stop = FALSE;
    enteredBlock(region, &stop);
    if (stop) { cleanupBlock(); }
  };
  
  o.regionErrorBlock = ^(CLRegion *region, NSError *error) {
    errorBlock(region, error);
    cleanupBlock();
  };
  
  o.errorBlock = ^(NSError *error) {
    errorBlock(nil, error);
    cleanupBlock();
  };
  
  [o.manager startMonitoringForRegion:region];
    
  return TRUE;
}



#pragma mark private stuff

- (id)init {
  if ((self = [super init])) {
    manager = [[CLLocationManager alloc]init];
    manager.distanceFilter = kCLDistanceFilterNone;
    manager.delegate = self;
  }
  return self;
}

- (void)dealloc {
#ifdef DEBUG_MCCGeolocator
  NSLog(@"dealloc %@", NSStringFromClass([self class]));
#endif
  self.manager = nil;
  self.updateBlock = nil;
  self.updateHeadingBlock = nil;
  self.regionEnteredBlock = nil;
  self.regionExitedBlock = nil;
  self.regionErrorBlock = nil;
  self.errorBlock = nil;
  self.region = nil;
  [super dealloc];
}


#pragma mark delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
  updateBlock(newLocation, oldLocation);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
  updateHeadingBlock(newHeading);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)aRegion {
  regionEnteredBlock(aRegion);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)aRegion {
  regionExitedBlock(aRegion);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)aRegion withError:(NSError *)error {
  regionErrorBlock(aRegion, error);
}

- (void)locationManager:(CLLocationManager *)amanager didFailWithError:(NSError *)error {
  errorBlock(error);
}

@end
