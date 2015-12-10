//
//  IFWPSchemeHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPSchemeHandler.h"
#import "NSString+IF.h"
#import "NSDictionary+IFValues.h"

@interface IFWPSchemeHandler ()

- (id)queryPosts:(NSDictionary *)params;
- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params;

@end

@implementation IFWPSchemeHandler

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(id<IFResourceContext>)parent {
    NSString *path = uri.name;
    NSArray *pathComponents = [path split:@"/"];
    switch ([pathComponents count]) {
        case 1:
            return [self queryPosts:params];
            break;
        case 2:
            return [self getPost:[pathComponents objectAtIndex:1] withParams:params];
            break;
        default:
            break;
    }
    return nil;
}

- (id)queryPosts:(NSDictionary *)params {
    id postData = nil;
    NSString *where = [params getValueAsString:@"where"];
    if (where) {
        // ..
    }
    if (!postData) {
        NSString *filter = [params getValueAsString:@"filter"];
        if (filter) {
            // ..
        }
    }
    if (!postData) {
        for (NSString *paramName in [params allKeys]) {
            // type, [min.|max.]modifiedTime etc.
        }
    }
    NSString *format = [params getValueAsString:@"format" defaultValue:@"table"];
    id formatter = [_listFormats objectForKey:format];
    if (formatter) {
        // ..
    }
    else {
        
    }
    return postData;
}

- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params {
    NSDictionary *postData = [_postDB readRecordWithID:postID fromTable:@"posts"];
    NSString *format = [params getValueAsString:@"format" defaultValue:@"webview"];
    id formatter = [_postFormats objectForKey:format];
    if (formatter) {
        // ..
    }
    else {
        
    }
    return postData;
}

@end
