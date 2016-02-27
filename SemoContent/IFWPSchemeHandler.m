//
//  IFWPSchemeHandler.m
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPSchemeHandler.h"
#import "IFWPContentContainer.h"
#import "NSString+IF.h"

@implementation IFWPSchemeHandler

- (id)initWithContentContainer:(IFWPContentContainer *)contentContainer {
    self = [super init];
    if (self) {
        _contentContainer = contentContainer;
    }
    return self;
}

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    // The following URI path forms are supported:
    // * posts:                 Query all posts, and possibly filter by specified parameters.
    // * posts/filter/{name}:   Query all posts and apply the named filter.
    // * posts/{id}             Return the post with the specified ID.
    // * posts/{id}/children:   Return the children of a post with the specified ID.
    // TODO: Would it make more sense to use the first name component - i.e. 'posts' in all of the above
    // examples - as the data format name? Or posts/{filter}, post/{filter}/{id} ? Note also that the list
    // filter will need to generate URIs referencing the post detail.
    NSString *path = uri.name;
    NSArray *pathComponents = [path split:@"/"];
    NSString *firstComponent = [pathComponents firstObject];
    NSString *postID;
    if ([pathComponents count] > 0) {
        if ([@"posts" isEqualToString:firstComponent]) {
            switch ([pathComponents count]) {
                case 1:
                    return [_contentContainer queryPostsUsingFilter:nil params:params];
                case 2:
                    postID = [pathComponents objectAtIndex:1];
                    return [_contentContainer getPost:postID withParams:params];
                case 3:
                    postID = [pathComponents objectAtIndex:1];
                    if ([@"children" isEqualToString:[pathComponents objectAtIndex:2]]) {
                        return [_contentContainer getPostChildren:postID withParams:params];
                    }
                    if ([@"filter" isEqualToString:[pathComponents objectAtIndex:1]]) {
                        return [_contentContainer queryPostsUsingFilter:[pathComponents objectAtIndex:2] params:params];
                    }
                default:
                    break;
            }
        }
        else if ([@"search" isEqualToString:firstComponent]) {
            NSString *text = [params objectForKey:@"text"];
            NSString *mode = [params objectForKey:@"mode"];
            return [_contentContainer searchPostsForText:text searchMode:mode];
        }
    }
    return nil;
}

@end
