//
//  IFHTTPClient.h
//  SemoContent
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Q.h"

// TODO: Should this be in pttn.utils?

@class IFHTTPClient;

@interface IFHTTPClientResponse : NSObject

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data;
- (id)initWithHTTPResponse:(NSURLResponse *)response downloadLocation:(NSURL *)location;

@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *downloadLocation;

- (id)parseData;

@end

// Protocol to be implemented by class providing authentication related functionality.
@protocol IFHTTPClientAuthenticationDelegate <NSObject>

// Test whether a response represents an authentication error.
- (BOOL)httpClient:(IFHTTPClient *)httpClient isAuthenticationErrorResponse:(IFHTTPClientResponse *)response;
// Perform a reauthentication.
- (QPromise *)reauthenticateUsingHttpClient:(IFHTTPClient *)httpClient;

@end

/*
@interface IFHTTPClientAuthenticationHandler : NSObject <NSURLSessionTaskDelegate>

@end
*/
@interface IFHTTPClient : NSObject //<NSURLSessionTaskDelegate>

@property (nonatomic, weak) id<IFHTTPClientAuthenticationDelegate> authenticationDelegate;

- (QPromise *)get:(NSString *)url;
- (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)getFile:(NSString *)url;
- (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
