//
//  IFHTTPClient.m
//  SemoContent
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFHTTPClient.h"

@implementation IFHTTPClientResponse

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data {
    self = [super init];
    if (self) {
        self.httpResponse = response;
        self.data = data;
    }
    return self;
}

- (id)parseData {
    id data = nil;
    NSString *contentType = _httpResponse.MIMEType;
    if ([@"application/json" isEqualToString:contentType]) {
        data = [NSJSONSerialization JSONObjectWithData:_data
                                               options:0
                                                 error:nil];
        // TODO: Parse error handling.
    }
    else if ([@"application/x-www-form-urlencoded" isEqualToString:contentType]) {
        // Adapted from http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
        NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
        // TODO: Proper handling of response text encoding.
        NSString *paramString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSArray *params = [paramString componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *pair = [param componentsSeparatedByString:@"="];
            NSString *name = [(NSString *)[pair objectAtIndex:0] stringByRemovingPercentEncoding];
            NSString *value = [(NSString *)[pair objectAtIndex:1] stringByRemovingPercentEncoding];
            [mdata setObject:value forKey:name];
        }
        data = mdata;
    }
    else if ([@"text/html" isEqualToString:contentType]) {
        data = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    }
    return data;
}

@end

@implementation IFHTTPClient

+ (QPromise *)get:(NSString *)url {
    return [IFHTTPClient get:url data:nil];
}

+ (QPromise *)get:(NSString *)url data:(NSDictionary *)data {
    QPromise *promise = [[QPromise alloc] init];
    // Build URL.
    NSURLComponents *urlParts = [NSURLComponents componentsWithString:url];
    if (data) {
        NSMutableArray *queryItems = [[NSMutableArray alloc] init];
        for (NSString *name in data) {
            NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:name value:[data objectForKey:name]];
            [queryItems addObject:queryItem];
        }
        urlParts.queryItems = queryItems;
    }
    // Send request.
    NSURLRequest *request = [NSURLRequest requestWithURL:urlParts.URL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                [promise reject:error];
            }
            else {
                [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:data]];
            }
        }];
    [task resume];
    return promise;
}

+ (QPromise *)post:(NSString *)url data:(NSDictionary *)data {
    QPromise *promise = [[QPromise alloc] init];
    // Build URL.
    NSURL *nsURL = [NSURL URLWithString:url];
    // Send request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL];
    request.HTTPMethod = @"POST";
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    if (data) {
        NSMutableArray *queryItems = [[NSMutableArray alloc] init];
        NSCharacterSet *alphanum = [NSCharacterSet alphanumericCharacterSet];
        for (NSString *name in data) {
            NSString *pname = [name stringByAddingPercentEncodingWithAllowedCharacters:alphanum];
            NSString *pvalue = [[[data objectForKey:name] description] stringByAddingPercentEncodingWithAllowedCharacters:alphanum];
            NSString *param = [NSString stringWithFormat:@"%@=%@", pname, pvalue];
            [queryItems addObject:param];
        }
        NSString *body = [queryItems componentsJoinedByString:@"&"];
        request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                [promise reject:error];
            }
            else {
                [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:data]];
            }
        }];
    [task resume];
    return promise;
}

+ (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data {
    if ([@"POST" isEqualToString:method]) {
        return [IFHTTPClient post:url data:data];
    }
    return [IFHTTPClient get:url data:data];
}

@end
