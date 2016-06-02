//
//  IFWPAuthenticationHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 01/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPAuthManager.h"
#import "IFWPContentContainer.h"
#import "IFAppContainer.h"
#import "Q.h"
#import "SSKeyChain.h"

#define AppendPathToURL(url,path)   ([url stringByAppendingString:[([url hasSuffix:@"/"] ? @"" : @"/") stringByAppendingString:path]])

@interface IFWPAuthManager()

- (void)handleReauthenticationFailure;

@end

// TODO: The whole authentication mechanism needs to be reviewed.
// TODO: The main feed URL doesn't require authentication, but if user's session has timed out then
//       they might loose visibility on protected post updates without receiving an authentication
//       challenge. Need a solution for this - just periodically reload the user profile as a heartbeat?
@implementation IFWPAuthManager

- (id)initWithContainer:(IFWPContentContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _profileFieldNames = @[@"ID", @"first_name", @"last_name", @"user_email"];
    }
    return self;
}

- (NSString *)loginURL {
    return AppendPathToURL(_container.feedURL, @"account/login");
}

- (NSString *)createAccountURL {
    return AppendPathToURL(_container.feedURL, @"account/create");
}

- (NSString *)profileURL {
    return AppendPathToURL(_container.feedURL, @"account/profile");
}

- (BOOL)isLoggedIn {
    NSString *key = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"logged-in"];
    return [_userDefaults boolForKey:key];
}

- (void)storeUserCredentials:(NSDictionary *)values {
    NSString *username = values[@"user_login"];
    NSString *password = values[@"user_pass"];
    // NOTE this will work for all forms - login, create account + update profile. In the latter case, if the
    // password is not updated then password will be empty and the keystore won't be updated.
    if ([username length] > 0 && [password length] > 0) {
        [SSKeychain setPassword:password forService:_container.wpRealm account:username];
        NSString *key = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"logged-in"];
        [_userDefaults setValue:@YES forKey:key];
        // TODO: Need to review whether this is best practice.
        key = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"user_login"];
        [_userDefaults setValue:username forKey:key];
    }
}

- (void)storeUserProfile:(NSDictionary *)values {
    // Store standard profile values.
    for (NSString *field in _profileFieldNames) {
        NSString *key = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, field];
        id value = values[field];
        if (value) {
            [_userDefaults setValue:value forKey:key];
        }
    }
    // Search for and store any meta data values.
    NSMutableArray *metaKeys = [NSMutableArray new];
    for (NSString *key in [values keyEnumerator]) {
        if ([key hasPrefix:@"meta_"]) {
            id value = values[key];
            NSString *storageKey = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, key];
            if (value != [NSNull null]) {
                [_userDefaults setValue:value forKey:storageKey];
            }
            else {
                [_userDefaults removeObjectForKey:storageKey];
            }
            [metaKeys addObject:key];
        }
    }
    // Store list of meta-data keys.
    NSString *metaDataKeys = [metaKeys componentsJoinedByString:@","];
    NSString *storageKey = [NSString stringWithFormat:@"%@/metaDataKeys", _container.wpRealm];
    [_userDefaults setValue:metaDataKeys forKey:storageKey];
}

- (NSDictionary *)getUserProfile {
    NSMutableDictionary *values = [NSMutableDictionary new];
    NSString *storageKey = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"user_login"];
    values[@"user_login"] = [_userDefaults stringForKey:storageKey];
    // Read standard profile fields.
    for (NSString *field in _profileFieldNames) {
        storageKey = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, field];
        id value = [_userDefaults stringForKey:storageKey];
        if (value) {
            values[field] = value;
        }
    }
    // Read profile meta-data.
    storageKey = [NSString stringWithFormat:@"%@/metaDataKeys", _container.wpRealm];
    NSArray *metaDataKeys = [[_userDefaults stringForKey:storageKey] componentsSeparatedByString:@","];
    for (NSString *metaKey in metaDataKeys) {
        storageKey = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, metaKey];
        id value = [_userDefaults stringForKey:storageKey];
        if (value) {
            values[metaKey] = value;
        }
    }
    // Return result.
    return values;
}

- (NSString *)getUsername {
    NSString *storageKey = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"user_login"];
    return [_userDefaults stringForKey:storageKey];
}

- (void)logout {
    NSString *key = [NSString stringWithFormat:@"%@/%@", _container.wpRealm, @"logged-in"];
    [_userDefaults setValue:@NO forKey:key];
}

- (void)showPasswordReminder {
    // Fetch the password reminder URL from the server.
    NSString *url = [_container.feedURL stringByAppendingPathComponent:@"account/password-reminder"];
    [_container.httpClient get:url]
    .then((id)^(IFHTTPClientResponse *response) {
        id data = [response parseData];
        NSString *reminderURL = data[@"lost_password_url"];
        if (reminderURL) {
            // Open the URL in the device browser.
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reminderURL]];
        }
        return nil;
    });
}

#pragma mark - Private

- (void)handleReauthenticationFailure {
    NSString *message = @"Reauthentication%20failure";
    NSString *toastAction = [NSString stringWithFormat:@"post:toast+message=%@", message];
    [IFAppContainer postMessage:toastAction sender:_container];
    [_container showLoginForm];
}

#pragma mark - IFHTTPClientAuthenticationDelegate

- (BOOL)httpClient:(IFHTTPClient *)httpClient isAuthenticationErrorResponse:(IFHTTPClientResponse *)response {
    NSString *requestURL = [response.httpResponse.URL description];
    // Note that authentication failures returned by login don't count as authentication errors here.
    return response.httpResponse.statusCode == 401 && ![requestURL isEqualToString:self.loginURL];
}

- (QPromise *)reauthenticateUsingHttpClient:(IFHTTPClient *)httpClient {
    QPromise *promise = [QPromise new];
    // Read username and password from local storage and keychain.
    NSString *username = [_userDefaults stringForKey:@"semo/user_login"];
    NSString *password = nil;
    if (username) {
        password = [SSKeychain passwordForService:_container.wpRealm account:username];
    }
    if (username && password) {
        // Submit a new login request.
        NSDictionary *data = @{
            @"user_login":   username,
            @"user_pass":    password
        };
        [_container.httpClient post:self.loginURL data:data]
        .then((id)^(IFHTTPClientResponse *response) {
            if (response.httpResponse.statusCode == 201) {
                [promise resolve:response];
            }
            else {
                [self handleReauthenticationFailure];
                [promise reject:response];
            }
            return nil;
        })
        .fail(^(id error) {
            [self handleReauthenticationFailure];
            [promise reject:error];
        });
    }
    else {
        [self handleReauthenticationFailure];
        [promise reject:nil];
    }
    return promise;
}

@end
