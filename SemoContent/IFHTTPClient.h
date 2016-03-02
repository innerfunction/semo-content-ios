//
//  IFHTTPClient.h
//  SemoContent
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Q.h"

@class IFHTTPClient;

typedef QPromise *(^IFHTTPClientHandler) (IFHTTPClient *);

@interface IFHTTPClientResponse : NSObject

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data;

@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSData *data;

- (id)parseData;

@end
/*
@interface IFHTTPClientAuthenticationHandler : NSObject <NSURLSessionTaskDelegate>

@end
*/
@interface IFHTTPClient : NSObject //<NSURLSessionTaskDelegate>

@property (nonatomic, copy) IFHTTPClientHandler reauthenticationHandler;

- (QPromise *)get:(NSString *)url;
- (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)getFile:(NSString *)url;
- (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
