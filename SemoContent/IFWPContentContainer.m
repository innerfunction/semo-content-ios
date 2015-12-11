//
//  IFWPContentContainer.m
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentContainer.h"

@implementation IFWPContentContainer

- (id)init {
    self = [super init];
    if (self) {
        // TODO: Use this configuration to examine the outstanding question about named
        // container objects - should they go into a property called "named", or should all
        // top level names in a container configuration make up the named?
        // Also, this is a good use case for whether named components should somehow be
        // be applied to the container's configurable properties.
        // Finally, are "ios:class" and "and:class" properties needed to avoid using "type"
        // properties in this kind of use case?
        [self configureWithData:@{
            @"postDB": @{
                @"ios:class":   @"IFDB", // NOTE: These types can potentially be inferred from the property, if named are mapped to container props.
                @"name":        @"com.innerfunction.semo.content",
                @"version":     @1,
                @"tables": @{
                    @"posts": @{
                        @"columns": @{
                            @"id":              @{ @"type": @"TEXT", @"tag": @"id" },
                            @"title":           @{ @"type": @"TEXT" },
                            @"content":         @{ @"type": @"TEXT" },
                            @"modifiedTime":    @{ @"type": @"TEXT" }
                        }
                    }
                }
            },
            @"contentProtocol": @{
                @"ios:class":   @"IFWPContentProtocol",
                @"feedURL":     @"",
                @"postDB":      @"#postDB"
            },
            @"uriScheme": @{
                @"ios:class":   @"IFWPSchemeHandler",
                @"postDB":      @"#postDB",
                @"listFormats": @{
                    @"table": @{
                                    
                    }
                },
                @"postFormats": @{
                    @"webview": @{
                                    
                    }
                },
                @"contentPath": @""
            }
        }];
    }
    return self;
}

@end
