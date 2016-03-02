//
//  IFWPAuthenticationHandler.h
//  SemoContent
//
//  Created by Julian Goacher on 01/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFHTTPClient.h"

@class IFWPContentContainer;

@interface IFWPAuthenticationHandler : NSObject <IFHTTPClientAuthenticationDelegate> {
    NSString *_service;
    NSUserDefaults *_userDefaults;
    __weak IFWPContentContainer *_container;
    NSString *_loginURL;
}

- (id)initWithContainer:(IFWPContentContainer *)container;

- (void)storeUserCredentials:(NSDictionary *)values;
- (void)storeUserProfile:(NSDictionary *)values;
- (NSDictionary *)getUserProfile;

@end
