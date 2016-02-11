//
//  IFWPChildPostRendering.m
//  SemoContent
//
//  Created by Julian Goacher on 10/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPChildPostRendering.h"

@implementation IFWPChildPostRendering

- (NSString *)renderForMustacheTag:(GRMustacheTag *)tag context:(GRMustacheContext *)context HTMLSafe:(BOOL *)HTMLSafe error:(NSError *__autoreleasing *)error {
    NSString *result = @"";
    // Get the in-scope post ID.
    NSString *postID = [context valueForMustacheKey:@"id"];
    if (postID) {
        // Read the list of child posts.
        NSArray *childPosts = [_schemeHandler getPostChildren:postID withParams:@{}];
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
