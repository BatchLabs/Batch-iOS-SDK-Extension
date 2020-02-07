//
//  BAENotificationServiceExtension.h
//  BatchExtension
//
//  Copyright © 2019 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UserNotifications/UserNotifications.h>

/**
Drop-in replacement for UNNotificationServiceExtension.

Simply set it as your base class without overriding any methods and Batch will automatically:
 - Download and set rich content
 - Send display receipts
*/
@interface BAENotificationServiceExtension : UNNotificationServiceExtension

@end
