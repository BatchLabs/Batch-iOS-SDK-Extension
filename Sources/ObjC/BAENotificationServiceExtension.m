//
//  BAENotificationServiceExtension.m
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

#import "BAENotificationServiceExtension.h"

#import <BatchExtension/BatchExtension-Swift.h>

@implementation BAENotificationServiceExtension
{
    BAERichNotificationHelper *_helper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _helper = [BAERichNotificationHelper new];
    }
    return self;
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler
{
    [_helper didReceiveNotificationRequest:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire
{
    [_helper serviceExtensionTimeWillExpire];
}

@end
