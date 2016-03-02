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
// TODO: Don't know yet how to display the login page if re-authentication fails.
@implementation IFWPAuthenticationHandler

- (id)initWithContainer:(IFWPContentContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
        _service = _container.feedURL;
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _loginURL = [_container.feedURL stringByAppendingPathComponent:@"account/login"];
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

- (void)storeUserProfile:(NSDictionary *)values {
    NSArray *fields = @[@"firstname", @"lastname", @"email"];
    for (NSString *field in fields) {
        // TODO Need some kind of realm to namespace values, should also apply to username + logged-in
        NSString *fieldName = [NSString stringWithFormat:@"%@/%@", @"xxx", field];
        id value = values[field];
        [_userDefaults setValue:value forKey:fieldName];
    }
}

- (NSDictionary *)getUserProfile {
    return @{};
}

#pragma mark - IFHTTPClientAuthenticationDelegate

- (BOOL)httpClient:(IFHTTPClient *)httpClient isAuthenticationErrorResponse:(NSHTTPURLResponse *)response {
    NSString *requestURL = [response.URL description];
    // Note that authentication failures returned by login don't count as authentication errors here.
    return response.statusCode == 401 && ![requestURL isEqualToString:_loginURL];
}

- (QPromise *)reauthenticateUsingHttpClient:(IFHTTPClient *)httpClient {
    QPromise *promise = [QPromise new];
    // Read username and password from local storage and keychain.
    NSString *username = [_userDefaults stringForKey:@"semo/username"];
    NSString *password = nil;
    if (username) {
        password = [SSKeychain passwordForService:_service account:username];
    }
    if (username && password) {
        // Submit a new login request.
        NSDictionary *data = @{
            @"user_login":   username,
            @"user_pass":    password
        };
        [_container.httpClient post:_loginURL data:data]
        .then((id)^(IFHTTPClientResponse *response) {
            if (response.httpResponse.statusCode == 201) {
                [promise resolve:response];
            }
            else {
                // TODO: Reauthentication failed, so display login form.
                [promise reject:response];
            }
            return nil;
        })
        .fail(^(id error) {
            // TODO: Reauthentication failed, so display login form.
            [promise reject:error];
        });
    }
    else {
        // TODO: Reauthentication failed, so display login form.
        [promise reject:nil];
    }
    return promise;
}

@end
