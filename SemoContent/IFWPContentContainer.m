//
//  IFWPContentContainer.m
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentContainer.h"
#import "IFSemoContent.h"
#import "IFStringTemplate.h"
#import "NSDictionary+IF.h"

@implementation IFWPContentContainer

@synthesize parentTargetContainer = _parentTargetContainer, namedTargets = _namedTargets, uriHandler = _uriHandler;

- (id)init {
    self = [super init];
    if (self) {
        _postDBName = @"com.innerfunction.semo.content";
        _feedURL = @"";
        _packagedContentPath = @"";
        _uriSchemeName = @"wp";
        _listFormats = @{
            @"table": @{
                @"*ios-class": @"IFWPDataTableFormatter"
            }
        };
        _postFormats = @{
            @"webview": @{
                @"*ios-class": @"IFWPDataWebviewFormatter"
            }
        };
        _postURITemplate = @"{uriSchemeName}:/post/{postID}";
        
        // Configuration template. Note that the top-level property types are inferred from the
        // corresponding properties on the container object (i.e. self).
        id template = @{
            @"postDB": @{
                @"name":                    @"$postDBName",
                @"version":                 @1,
                @"resetDatabase":           @"$resetPostDB",
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
                            @"location":    @{ @"type": @"STRING" },    // The post's location; packaged, downloaded or server.
                            @"url":         @{ @"type": @"STRING" },    // The post's WP URL.
                            @"filename":    @{ @"type": @"TEXT" },      // Name of associated media file (i.e. for attachments)
                            @"parent":      @{ @"type": @"INTEGER" },   // ID of parent page/post.
                            @"menu_order":  @{ @"type": @"INTEGER" }    // Sort order; mapped to post.menu_order.
                        }
                    }
                }
            },
            @"contentProtocol": @{
                @"feedURL":                 @"$feedURL",
                @"postDB":                  @"#postDB",
                @"stagingPath":             @"$stagingPath",
                @"packagedContentPath":     @"$packagedContentPath",
                @"baseContentPath":         @"$baseContentPath",
                @"contentPath":             @"$contentPath"
            },
            @"uriScheme": @{
                @"postDB":                  @"#postDB",
                @"listFormats":             @"$listFormats",
                @"postFormats":             @"$postFormats",
                @"baseContentPath":         @"$baseContentPath",
                @"contentPath":             @"$contentPath",
                @"clientTemplateContext": @{
                    @"*ios-class":          @"IFWPClientTemplateContext",
                    @"ext": @{
                        @"childPosts": @{
                            @"*ios-class":      @"IFWPChildPostRendering",
                            @"schemeHandler":   @"#uriScheme"
                        }
                    }
                }
            },
            @"packagedContentPath":         @"$packagedContentPath",
            @"contentPath":                 @"$contentPath"
        };
        _configTemplate = [[IFConfiguration alloc] initWithData:template];
        // TODO: Is there a way for the command scheduler to use the same DB as the post DB? This would
        //       require the ability for the scheduler to merge its table schema over the schema above;
        //       May also complicate schema versioning.
        //       Note that currently there is a potential problem if more than one content container is
        //       used (or if more than one command scheduler is used) as every command scheduler instance
        //       currently uses the same named database. (Perhaps this isn't a problem? just needs proper
        //       management).
        _commandScheduler = [[IFCommandScheduler alloc] init];
        _commandScheduler.deleteExecutedQueueRecords = NO; // DEBUG setting.
        // Command scheduler is manually instantiated, so has to be manually added to the services list.
        // TODO: This is another aspect that needs to be considered when formalizing the configuration
        //       template pattern used by this container.
        [self->services addObject:_commandScheduler];
        
        // NOTES on staging and content paths:
        // * Freshly downloaded content is stored under the staging path until the download is complete, after which
        //   it is deployed to the content path and deleted from the staging location. The staging path is placed
        //   under NSApplicationSupportDirectory to avoid it being deleted by the system mid-download, if the system
        //   needs to free up disk space.
        // * Base content is deployed under NSApplicationSupportDirectory to avoid it being cleared by the system.
        // * All other content is deployed under NSCachesDirectory, where the system may remove it if it needs to
        //   recover disk space. If this happens then Semo will attempt to re-downloaded the content again, if needed.
        // See:
        // http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
        // https://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/PerformanceTuning/PerformanceTuning.html#//apple_ref/doc/uid/TP40007072-CH8-SW8
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        _stagingPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.staging"];
        _baseContentPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.base"];
        
        // Switch cache path for content location.
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [paths objectAtIndex:0];
        _contentPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.content"];
        
        // Factory for producing login + account management forms.
        _formFactory = [[IFWPContentContainerFormFactory alloc] initWithContainer:self];
    }
    return self;
}

- (void)setListFormats:(NSDictionary *)listFormats {
    _listFormats = [_listFormats extendWith:listFormats];
}

- (void)setPostFormats:(NSDictionary *)postFormats {
    _postFormats = [_postFormats extendWith:postFormats];
}

- (void)unpackPackagedContent {
    NSInteger count = [_postDB countInTable:@"posts" where:@"1 = 1"];
    if (count == 0) {
        [_commandScheduler appendCommand:@"content.unpack"];// -packagedContentPath %@", _packagedContentPath];
    }
}

- (void)refreshContent {
    [_commandScheduler appendCommand:@"content.refresh"];
    [_commandScheduler executeQueue];
}

- (void)getContentFromURL:(NSString *)url writeToFilename:(NSString *)filename {
    NSString *filepath = [_contentPath stringByAppendingPathComponent:filename];
    [_commandScheduler appendCommand:@"get %@ %@", url, filepath];
    [_commandScheduler executeQueue];
}

- (NSString *)uriForPostWithID:(NSString *)postID {
    NSDictionary *context = @{ @"uriSchemeName": _uriSchemeName, @"postID": postID };
    return [IFStringTemplate render:_postURITemplate context:context];
}

#pragma mark - IFIOCConfigurable

- (void)beforeConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {}

- (void)afterConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {
    // Packaged content is packaged with the app executable.
    NSString *packagedContentPath = [MainBundlePath stringByAppendingPathComponent:_packagedContentPath];
    
    // Setup configuration parameters.
    id parameters = @{
        @"postDBName":          _postDBName,
        @"resetPostDB":         [NSNumber numberWithBool:_resetPostDB],
        @"feedURL":             _feedURL,
        @"stagingPath":         _stagingPath,
        @"packagedContentPath": packagedContentPath,
        @"baseContentPath":     _baseContentPath,
        @"contentPath":         _contentPath,
        @"listFormats":         _listFormats,
        @"postFormats":         _postFormats
    };
    
    // Generate the full container configuration.
    IFConfiguration *componentConfig = [_configTemplate extendWithParameters:parameters];
    // TODO: There should be some standard method for doing the following, but need to consider what
    // the component configuration template pattern is exactly first.
    componentConfig.uriHandler = configuration.uriHandler; // This necessary for relative URIs within the config to work.
    componentConfig.root = self;
    [self configureWith:componentConfig];
    
    // Configure the command scheduler.
    _commandScheduler.queueDBName = [NSString stringWithFormat:@"%@.scheduler", _postDBName];
    if (_contentProtocol) {
        _commandScheduler.commands = @{ @"content": _contentProtocol };
    }
    
    // Register the URI scheme handler.
    if (_uriSchemeName && _uriScheme) {
        // Need to use the config's URI handler for wp: schemes to work within the config.
        [componentConfig.uriHandler addHandler:_uriScheme forScheme:_uriSchemeName];
    }
}

#pragma mark - IFService

- (void)startService {
    [super startService];
    [self unpackPackagedContent];
    [_commandScheduler executeQueue];
}

#pragma mark - IFTargetContainer

- (BOOL)dispatchURI:(NSString *)uri {
    return YES;
}

@end
