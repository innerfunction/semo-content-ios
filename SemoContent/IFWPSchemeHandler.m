//
//  IFWPSchemeHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPSchemeHandler.h"
#import "IFDBFilter.h"
#import "IFRegExp.h"
#import "IFStringTemplate.h"
#import "NSString+IF.h"
#import "NSDictionary+IFValues.h"
#import "NSDictionary+IF.h"

@interface IFWPSchemeHandler ()

- (id)queryPosts:(NSDictionary *)params;
- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params;

@end

@implementation IFWPSchemeHandler

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

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
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM posts WHERE %@", where];
        NSString *orderBy = [params getValueAsString:@"orderBy"];
        if (orderBy) {
            sql = [NSString stringWithFormat:@"%@ ORDER BY %@", sql, orderBy];
        }
        postData = [_postDB performQuery:sql withParams:@[]];
    }
    if (!postData) {
        NSString *filterName = [params getValueAsString:@"filter"];
        if (filterName) {
            IFDBFilter *filter = [_filters objectForKey:filterName];
            if (filter) {
                // TODO:
                // The issue here may be the way the any parameters to the filter go into the same namespace as
                // the filter name. An alternative approach would be to allow an actual filter instance to be
                // passed in here - in which case parameter names musy somehow become configurable properties of
                // the filter instance.
                // ** This is an issue for all the different query forms, e.g. the 'format' URI parameter, used
                // to specify the result format, appears in the same namespace as the filter parameters etc.
                // Overall, probably would be better to somehow support just a single 'filter' URI parameter
                // which provides a IFDBFilter instance, or a string that can be promoted to a filter instance.
                // However, it might still be useful to have filter parameter values specified on the wp: URI;
                // so is a naming scheme - e.g. a name prefix - needed for these parameters?
                // The problem with this approach is that it pushes knowledge of the posts db schema out of this
                // class - where it actually belongs - and into the URI configuration. So really need a solution
                // which allows this class to apply it's knowledge of the db schema to a partially configured
                // filter object.
                postData = [filter applyTo:_postDB withParameters:params];
            }
        }
    }
    if (!postData) {
        // Construct the filter instance.
        IFDBFilter *filter = [[IFDBFilter alloc] init];
        filter.table = @"posts";
        // Construct a set of filter parameters from the URI parameters.
        IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"^(\\w+)\\.(.*)"];
        NSMutableDictionary *filterParams = [[NSMutableDictionary alloc] init];
        for (NSString *paramName in [params allKeys]) {
            // The 'orderBy' parameter is a special name used to specify sort order.
            if ([@"orderBy" isEqualToString:paramName]) {
                filter.orderBy = [params getValueAsString:@"orderBy"];
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
    NSString *format = [params getValueAsString:@"format" defaultValue:@"table"];
    id formatter = [_listFormats objectForKey:format];
    if (formatter) {
        // TODO
    }
    return postData;
}

- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params {
    // Read the post data.
    NSDictionary *postData = [_postDB readRecordWithID:postID fromTable:@"posts"];
    // Load the client template for the post type.
    NSString *templateName = [NSString stringWithFormat:@"template-%@.html", [postData objectForKey:@"type"]];
    NSString *templatePath = [_contentPath stringByAppendingPathComponent:templateName];
    if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
        templatePath = [_contentPath stringByAppendingString:@"template-single.html"];
        if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
            // TODO: No template found!
        }
    }
    // Assume at this point that the template file exists.
    NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    // Generate the full post HTML using the post data and the client template.
    NSString *postHTML = [IFStringTemplate render:template context:postData];
    // Add the post HTML to the post data.
    // TODO: Review the dictionary key.
    postData = [postData dictionaryWithAddedObject:postHTML forKey:@"postHTML"];
    NSString *format = [params getValueAsString:@"format" defaultValue:@"webview"];
    id formatter = [_postFormats objectForKey:format];
    if (formatter) {
        // TODO
    }
    return postData;
}

@end
