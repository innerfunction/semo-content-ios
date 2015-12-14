//
//  IFWPContentContainer.m
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentContainer.h"
#import "NSDictionary+IF.h"

@implementation IFWPContentContainer

- (id)init {
    self = [super init];
    if (self) {
        self.postDBName = @"com.innerfunction.semo.content";
        self.stagingPath = @""; // TODO
        self.contentPath = @""; // TODO
        self.feedURL = @"";
        self.listFormats = @{
            @"table": @{
                @"ios:class": @"IFWPDataTableFormatter"
            }
        };
        self.postFormats = @{
            @"webview": @{
                @"ios:class": @"IFWPDataWebviewFormatter"
            }
        };
        // TODO: Use this configuration to examine the outstanding question about named
        // container objects - should they go into a property called "named", or should all
        // top level names in a container configuration make up the named?
        // Also, this is a good use case for whether named components should somehow be
        // be applied to the container's configurable properties.
        // Finally, are "ios:class" and "and:class" properties needed to avoid using "type"
        // properties in this kind of use case?
        id template = @{
            @"postDB": @{
                @"ios:class":   @"IFDB", // NOTE: These types can potentially be inferred from the property, if named are mapped to container props.
                @"name":        @"$postDBName",
                @"version":     @1,
                @"tables": @{
                    @"posts": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },    // Post ID
                            @"type":        @{ @"type": @"TEXT" },
                            @"title":       @{ @"type": @"TEXT" },
                            @"content":     @{ @"type": @"TEXT" },
                            @"status":      @{ @"type": @"TEXT" },      // i.e. WP post status
                            @"date":        @{ @"type": @"TEXT" },      // Modification date/time; ISO 8601 format string.
                            @"image":       @{ @"type": @"INTEGER" },   // Post ID of featured image.
                            @"filename":    @{ @"type": @"TEXT" }       // Name of associated media file (i.e. for attachments)
                        }
                    }
                }
            },
            @"contentProtocol": @{
                @"ios:class":   @"IFWPContentProtocol",
                @"feedURL":     @"$feedURL",
                @"postDB":      @"@named:postDB",
                @"stagingPath": @"$stagingPath",
                @"contentPath": @"$contentPath"
            },
            @"uriScheme": @{
                @"ios:class":   @"IFWPSchemeHandler",
                @"postDB":      @"@named:postDB",
                @"listFormats": @"$listFormats",
                @"postFormats": @"$postFormats",
                @"contentPath": @"$contentPath"
            }
        };
        _configTemplate = [[IFConfiguration alloc] initWithData:template];
    }
    return self;
}

- (void)setListFormats:(NSDictionary *)listFormats {
    _listFormats = [_listFormats extendWith:listFormats];
}

- (void)setPostFormats:(NSDictionary *)postFormats {
    _postFormats = [_postFormats extendWith:postFormats];
}

#pragma mark - IFIOCConfigurable

- (void)beforeConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {}

- (void)afterConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {
    id parameters = @{
        @"postDBName":  _postDBName,
        @"feedURL":     _feedURL,
        @"stagingPath": _stagingPath,
        @"contentPath": _contentPath,
        @"listFormats": _listFormats,
        @"postFormats": _postFormats
    };
    IFConfiguration *componentConfig = [_configTemplate extendWithParameters:parameters];
    [self configureWith:componentConfig];
}

@end
