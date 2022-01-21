//
//  BAENotificationServiceExtension.m
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

#import "BAENotificationServiceExtension.h"

#if __has_include(<BatchExtension/BatchExtension-Swift.h>)
#import <BatchExtension/BatchExtension-Swift.h>
#else
#import "BatchExtension-Swift.h"
#endif

@implementation BAENotificationServiceExtension
{
    BAERichNotificationHelper *_richNotificationHelper;
    BAEDisplayReceiptHelper   *_displayReceiptHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _richNotificationHelper = [BAERichNotificationHelper new];
        _displayReceiptHelper = [BAEDisplayReceiptHelper new];
    }
    return self;
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler
{
    [_richNotificationHelper didReceiveNotificationRequest:request withContentHandler:contentHandler];
    [_displayReceiptHelper didReceiveNotificationRequest:request];
}

- (void)serviceExtensionTimeWillExpire
{
    [_richNotificationHelper serviceExtensionTimeWillExpire];
    [_displayReceiptHelper serviceExtensionTimeWillExpire];
}

@end
