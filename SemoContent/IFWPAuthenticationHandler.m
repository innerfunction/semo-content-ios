//
//  IFWPAuthenticationHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 01/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPAuthenticationHandler.h"
#import "IFWPContentContainer.h"
#import "Q.h"
#import "SSKeyChain.h"

// TODO: The whole authentication mechanism needs to be reviewed.
@implementation IFWPAuthenticationHandler

- (id)initWithContainer:(IFWPContentContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
        _service = _container.feedURL;
        _userDefaults = [NSUserDefaults standardUserDefaults];
        // TODO: This reauthentication code is getting unwieldy, and there is a risk of a recursive loop
        // as the [httpClient post: data:] method will invoke the reauthentication handler if it thinks
        // authentication is needed.
        // TODO: Don't know yet how to display the login page if re-authentication fails.
        _container.httpClient.reauthenticationHandler = ^(IFHTTPClient *client) {
            QPromise *promise = [QPromise new];
            NSString *username = [_userDefaults stringForKey:@"semo/username"];
            NSString *password = nil;
            if (username) {
                password = [SSKeychain passwordForService:_service account:username];
            }
            if (username && password) {
                NSString *url = [_container.feedURL stringByAppendingPathComponent:@"account/login"];
                NSDictionary *data = @{
                    @"user_login":   username,
                    @"user_pass":    password
                };
                [_container.httpClient post:url data:data]
                .then((id)^(IFHTTPClientResponse *response) {
                    if (response.httpResponse.statusCode == 201) {
                        [promise resolve:response];
                    }
                    else {
                        [promise reject:response];
                    }
                    return nil;
                })
                .fail(^(id error) {
                    [promise reject:error];
                });
            }
            else {
                [promise reject:nil];
            }
            return promise;
        };
    }
    return self;
}

- (void)storeUserCredentials:(NSDictionary *)values {
    NSString *username = values[@"user_login"];
    NSString *password = values[@"user_pass"];
    // NOTE this will work for all forms - login, create account + update profile. In the latter case, if the
    // password is not updated then password will be empty and the keystore won't be updated.
    if ([username length] > 0 && [password length] > 0) {
        [SSKeychain setPassword:password forService:_service account:username];
        [_userDefaults setValue:@YES forKey:@"semo/logged-in"];
        // TODO: Need to review whether this is best practice.
        [_userDefaults setValue:username forKey:@"semo/username"];
    }
}

@end
