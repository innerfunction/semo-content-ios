//
//  IFWPSchemeHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPSchemeHandler.h"
#import "IFSemoContent.h"
#import "IFDBFilter.h"
#import "IFDataFormatter.h"
#import "IFRegExp.h"
#import "IFStringTemplate.h"
#import "NSString+IF.h"
#import "NSDictionary+IFValues.h"
#import "NSDictionary+IF.h"

static IFLogger *Logger;

@interface IFWPSchemeHandler ()

- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params;
- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params;

@end

@implementation IFWPSchemeHandler

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFWPSchemeHandler"];
}

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(id<IFResourceContext>)parent {
    // The following URI path forms are supported:
    // * posts:                 Query all posts, and possibly filter by specified parameters.
    // * posts/filter/{name}:   Query all posts and apply the named filter.
    // * posts/{id}             Return the post with the specified ID.
    NSString *path = uri.name;
    NSArray *pathComponents = [path split:@"/"];
    if ([pathComponents count] > 0 && [@"posts" isEqualToString:[pathComponents objectAtIndex:0]]) {
        switch ([pathComponents count]) {
            case 1:
                return [self queryPostsUsingFilter:nil params:params];
            case 2:
                return [self getPost:[pathComponents objectAtIndex:1] withParams:params];
            case 3:
                if ([@"filter" isEqualToString:[pathComponents objectAtIndex:1]]) {
                    return [self queryPostsUsingFilter:[pathComponents objectAtIndex:2] params:params];
                }
            default:
                break;
        }
    }
    [Logger warn:@"Unhandled URI %@", uri];
    return nil;
}

- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params {
    id postData = nil;
    if (filterName) {
        IFDBFilter *filter = [_filters objectForKey:filterName];
        if (filter) {
            postData = [filter applyTo:_postDB withParameters:params];
        }
    }
    else {
        // Construct an anonymous filter instance.
        IFDBFilter *filter = [[IFDBFilter alloc] init];
        filter.table = @"posts";
        // Construct a set of filter parameters from the URI parameters.
        IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"^(\\w+)\\.(.*)"];
        NSMutableDictionary *filterParams = [[NSMutableDictionary alloc] init];
        for (NSString *paramName in [params allKeys]) {
            // The 'orderBy' parameter is a special name used to specify sort order.
            if ([@"_orderBy" isEqualToString:paramName]) {
                filter.orderBy = [params getValueAsString:@"_orderBy"];
                continue;
            }
            NSString *fieldName = paramName;
            NSString *paramValue = [params objectForKey:paramName];
            // Check for a comparison suffix on the name.
            NSArray *groups = [re match:paramName];
            if ([groups count] > 1) {
                fieldName = [groups objectAtIndex:0];
                NSString *comparison = [groups objectAtIndex:1];
                if ([@"min" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@">%@", paramValue];
                }
                else if ([@"max" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"<%@", paramValue];
                }
                else if ([@"like" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"LIKE %@", paramValue];
                }
                else if ([@"not" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"NOT %@", paramValue];
                }
            }
            [filterParams setObject:paramValue forKey:fieldName];
        }
        // Remove any parameters not corresponding to a column on the posts table.
        filter.filters = [_postDB filterValues:filterParams forTable:@"posts"];
        // Apply the filter.
        postData = [filter applyTo:_postDB withParameters:@{}];
    }
    NSString *format = [params getValueAsString:@"_format" defaultValue:@"table"];
    id<IFDataFormatter> formatter = [_listFormats objectForKey:format];
    if (formatter) {
        postData = [formatter formatData:postData];
    }
    return postData;
}

- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params {
    // Read the post data.
    NSDictionary *postData = [_postDB readRecordWithID:postID fromTable:@"posts"];
    // Load the client template for the post type.
    NSString *postType = [postData objectForKey:@"type"];
    NSString *templateName = [NSString stringWithFormat:@"template-%@.html", postType];
    NSString *templatePath = [_contentPath stringByAppendingPathComponent:templateName];
    if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
        templatePath = [_contentPath stringByAppendingString:@"template-single.html"];
        if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
            [Logger warn:@"Client template for post type '%@' not found at %@", postType, _contentPath];
        }
        return nil;
    }
    // Assume at this point that the template file exists.
    NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    // Generate the full post HTML using the post data and the client template.
    NSString *postHTML = [IFStringTemplate render:template context:postData];
    // Add the post HTML to the post data.
    // TODO: Review the dictionary key.
    postData = [postData dictionaryWithAddedObject:postHTML forKey:@"postHTML"];
    NSString *format = [params getValueAsString:@"_format" defaultValue:@"webview"];
    id<IFDataFormatter> formatter = [_postFormats objectForKey:format];
    if (formatter) {
        postData = [formatter formatData:postData];
    }
    return postData;
}

@end