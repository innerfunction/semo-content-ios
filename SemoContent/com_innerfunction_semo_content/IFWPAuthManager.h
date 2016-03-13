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

@interface IFWPAuthManager : NSObject <IFHTTPClientAuthenticationDelegate> {
    NSUserDefaults *_userDefaults;
    __weak IFWPContentContainer *_container;
}

@property (nonatomic, readonly) NSString *loginURL;
@property (nonatomic, readonly) NSString *createAccountURL;
@property (nonatomic, readonly) NSString *profileURL;
@property (nonatomic, strong) NSArray *profileFieldNames;

- (id)initWithContainer:(IFWPContentContainer *)container;

- (BOOL)isLoggedIn;
- (void)storeUserCredentials:(NSDictionary *)values;
- (void)storeUserProfile:(NSDictionary *)values;
- (NSDictionary *)getUserProfile;
- (NSString *)getUsername;
- (void)logout;
- (void)showPasswordReminder;

@end
