#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MglFleetSdk, NSObject)

RCT_EXTERN_METHOD(initialize:(NSDictionary *)opts
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(presentFleetFlow:(NSDictionary *)opts
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
