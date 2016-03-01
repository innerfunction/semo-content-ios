//
//  IFHTTPClient.h
//  SemoContent
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Q.h"

@interface IFHTTPClientResponse : NSObject

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data;

@property (nonatomic, strong) NSURLResponse *httpResponse;
@property (nonatomic, strong) NSData *data;

- (id)parseData;

@end

@interface IFHTTPClientAuthenticationHandler : NSObject <NSURLSessionTaskDelegate>

@end

@interface IFHTTPClient : NSObject <NSURLSessionTaskDelegate>

+ (QPromise *)get:(NSString *)url;
+ (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
+ (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
+ (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
