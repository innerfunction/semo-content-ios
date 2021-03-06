//
//  IFWPChildPostRendering.m
//  SemoContent
//
//  Created by Julian Goacher on 10/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPChildPostRendering.h"

@implementation IFWPChildPostRendering

- (IFContainer *)iocContainer {
    return _contentContainer;
}

- (void)setIocContainer:(IFContainer *)iocContainer {
    if ([iocContainer isKindOfClass:[IFWPContentContainer class]]) {
        _contentContainer = (IFWPContentContainer *)iocContainer;
    }
}

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {}

- (NSString *)renderForMustacheTag:(GRMustacheTag *)tag context:(GRMustacheContext *)context HTMLSafe:(BOOL *)HTMLSafe error:(NSError *__autoreleasing *)error {
    NSString *result = @"";
    // Get the in-scope post ID.
    NSString *postID = [context valueForMustacheKey:@"id"];
    if (postID) {
        // Read the list of child posts.
        NSArray *childPosts = [_contentContainer getPostChildren:postID withParams:@{} renderContent:YES];
        // Iterate and render each child post.
        for (id childPost in childPosts) {
            GRMustacheContext *childContext = [context contextByAddingObject:childPost];
            NSString *childHTML = [tag renderContentWithContext:childContext HTMLSafe:HTMLSafe error:error];
            if (*error) {
                NSString *errHTML = [NSString stringWithFormat:@"<pre class=\"error\">Template error: %@</pre>", *error];
                result = [result stringByAppendingString:errHTML];
                *error = nil;
            }
            result = [result stringByAppendingString:childHTML];
        }
    }
    *HTMLSafe = YES;
    return result;
}

@end
