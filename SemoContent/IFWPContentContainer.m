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
        self.contentLocation = @"caches";
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
        // Configuration template.
        id template = @{
            @"postDB": @{
                @"ios:class":   @"IFDB", // NOTE: These types can potentially be inferred from the property, if named are mapped to container props.
                @"name":        @"$postDBName",
                @"version":     @1,
                @"tables": @{
                    @"posts": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },    // Post ID
                            @"title":       @{ @"type": @"TEXT" },
                            @"type":        @{ @"type": @"TEXT" },
                            @"status":      @{ @"type": @"TEXT" },      // i.e. WP post status
                            @"modified":    @{ @"type": @"TEXT" },      // Modification date/time; ISO 8601 format string.
                            @"content":     @{ @"type": @"TEXT" },
                            @"imageid":     @{ @"type": @"INTEGER" },   // ID of the post's featured image.
                            @"policy":      @{ @"type": @"STRING" },    // The post's download policy.
                            @"url":         @{ @"type": @"STRING" },    // The post's WP URL.
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
    // NOTES on staging and content paths:
    // * Freshly downloaded content is stored under the staging path until the download is complete, after which
    //   it is deployed to the content path and deleted from the staging location. The staging path is placed
    //   under NSApplicationSupportDirectory to avoid it being deleted by the system mid-download, if the system
    //   needs to free up disk space.
    // * Deployed content is stored under the content path, which is placed under NSCachesDirectory. This means
    //   that the system may remove this content if disk space is required. It is possible to change this location
    //   by changing the value of the contentLocation property from 'caches' to 'applicationsupport'.
    // See:
    // http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
    // https://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/PerformanceTuning/PerformanceTuning.html#//apple_ref/doc/uid/TP40007072-CH8-SW8
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    NSString *stagingPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.staging"];
    // Switch cache path for content location.
    if ([_contentLocation isEqualToString:@"caches"]) {
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [paths objectAtIndex:0];
    }
    NSString *contentPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.content"];
    // Setup configuration parameters.
    id parameters = @{
        @"postDBName":  _postDBName,
        @"feedURL":     _feedURL,
        @"stagingPath": stagingPath,
        @"contentPath": contentPath,
        @"listFormats": _listFormats,
        @"postFormats": _postFormats
    };
    // Generate the full container configuration.
    IFConfiguration *componentConfig = [_configTemplate extendWithParameters:parameters];
    [self configureWith:componentConfig];
}

@end
