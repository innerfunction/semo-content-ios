//
//  IFWPContentContainer.m
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentContainer.h"
#import "IFAppContainer.h"
#import "IFSemoContent.h"
#import "IFWPClientTemplateContext.h"
#import "IFWPDataTableFormatter.h"
#import "IFWPDataWebviewFormatter.h"
#import "IFGetURLCommand.h"
#import "IFStringTemplate.h"
#import "IFDBFilter.h"
#import "IFDataFormatter.h"
#import "IFRegExp.h"
#import "NSDictionary+IF.h"
#import "NSDictionary+IFValues.h"
#import "GRMustache.h"

static IFLogger *Logger;

@interface IFWPContentContainer()

/** Render a template with the specified data. */
- (NSString *)renderTemplate:(NSString *)template withData:(id)data;

@end

@implementation IFWPContentContainer

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFWPContentContainer"];
}

- (id)init {
    self = [super init];
    if (self) {
        _postDBName = @"com.innerfunction.semo.content";
        _feedURL = @"";
        _packagedContentPath = @"";
        _uriSchemeName = @"wp";
        _wpRealm = @"semo";
        _listFormats = @{
            @"table": [[IFWPDataTableFormatter alloc] init]
        };
        _postFormats = @{
            @"webview": [[IFWPDataWebviewFormatter alloc] init]
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
            @"clientTemplateContext": @{
                @"*ios-class":              @"IFWPClientTemplateContext",
                @"ext": @{
                    @"childPosts": @{
                        @"*ios-class":      @"IFWPChildPostRendering"
                    }
                }
            },
            @"packagedContentPath":         @"$packagedContentPath",
            @"contentPath":                 @"$contentPath"
        };
        _configTemplate = [[IFConfiguration alloc] initWithData:template];
        
        _uriScheme = [[IFWPSchemeHandler alloc] initWithContentContainer:self];
        
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
        [self->_services addObject:_commandScheduler];
        
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
        
        _fileManager = [NSFileManager defaultManager];

        _httpClient = [[IFHTTPClient alloc] init];
        
        _authManager = [[IFWPAuthManager alloc] initWithContainer:self];
        _httpClient.authenticationDelegate = _authManager;
        
        _searchResultLimit = 100;
    }
    return self;
}

- (void)setListFormats:(NSDictionary *)listFormats {
    _listFormats = [_listFormats extendWith:listFormats];
}

- (void)setPostFormats:(NSDictionary *)postFormats {
    _postFormats = [_postFormats extendWith:postFormats];
}

#pragma mark - Instance methods

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
        filter.orderBy = @"menu_order";
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

- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params {
    IFDBFilter *filter = [[IFDBFilter alloc] init];
    filter.table = @"posts";
    filter.filters = [params extendWith:@{ @"parent": postID }];
    filter.orderBy = @"menu_order";
    // Query the database.
    NSArray *childPosts = [filter applyTo:_postDB withParameters:@{}];
    // Render content for each child post.
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[childPosts count]];
    for (NSDictionary *post in childPosts) {
        [result addObject:[self renderPostContent:post]];
    }
    return result;
}

- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params {
    // Read the post data.
    NSDictionary *postData = [_postDB readRecordWithID:postID fromTable:@"posts"];
    // Render the post content.
    postData = [self renderPostContent:postData];
    // Load the client template for the post type.
    NSString *postType = [postData objectForKey:@"type"];
    NSString *templateName = [NSString stringWithFormat:@"template-%@.html", postType];
    NSString *templatePath = [_baseContentPath stringByAppendingPathComponent:templateName];
    if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
        templatePath = [_baseContentPath stringByAppendingString:@"template-single.html"];
        if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
            [Logger warn:@"Client template for post type '%@' not found at %@", postType, _contentPath];
            return nil;
        }
    }
    // Assume at this point that the template file exists.
    NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    // Generate the full post HTML using the post data and the client template.
    id context = [_clientTemplateContext templateContextForPostData:postData];
    // Render the post template
    NSString *postHTML = [self renderTemplate:template withData:context];
    // Generate a content URL within the base content directory - this to ensure that references to base
    // content can be resolved as relative references.
    NSString *separator = [_baseContentPath hasSuffix:@"/"] ? @"" : @"/";
    NSString *contentURL = [NSString stringWithFormat:@"file://%@%@%@-%@.html", _baseContentPath, separator, postType, postID ];
    // Add the post content and URL to the post data.
    postData = [postData extendWith:@{
      @"content":     postHTML,
      @"contentURL":  contentURL
    }];
    /* TODO: Review the need for this.
     NSString *format = [params getValueAsString:@"_format" defaultValue:@"webview"];
     // Format the data result.
     id<IFDataFormatter> formatter = [_postFormats objectForKey:format];
     if (formatter) {
     postData = [formatter formatData:postData];
     }
     */
    return postData;
}

- (id)searchPostsForText:(NSString *)text searchMode:(NSString *)searchMode postTypes:(NSArray *)postTypes {
    id postData = nil;
    NSString *where;
    NSMutableArray *params = [NSMutableArray new];
    text = [NSString stringWithFormat:@"%%%@%%", text];
    if ([@"exact" isEqualToString:searchMode]) {
        where = @"title LIKE ? OR content LIKE ?";
        [params addObject:text];
        [params addObject:text];
    }
    else {
        NSMutableArray *terms = [NSMutableArray new];
        NSArray *tokens = [text componentsSeparatedByString:@" "];
        for (NSString *token in tokens) {
            // TODO: Trim the token, check for empty tokens.
            NSString *param = [NSString stringWithFormat:@"%%%@%%", token];
            [terms addObject:@"(title LIKE ? OR content LIKE ?)"];
            [params addObject:param];
            [params addObject:param];
        }
        if ([@"any" isEqualToString:searchMode]) {
            where = [terms componentsJoinedByString:@" OR "];
        }
        else if ([@"all" isEqualToString:searchMode]) {
            where = [terms componentsJoinedByString:@" AND "];
        }
    }
    if (postTypes) {
        if ([postTypes count] == 1) {
            where = [NSString stringWithFormat:@"(%@) AND type='%@'", where, [postTypes firstObject]];
        }
        else {
            where = [NSString stringWithFormat:@"(%@) AND type IN ('%@')", where, [postTypes componentsJoinedByString:@"','"]];
        }
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM posts WHERE %@ LIMIT %ld", where, _searchResultLimit];
    postData = [_postDB performQuery:sql withParams:params];
    // TODO: Filters?
    id<IFDataFormatter> formatter = [_listFormats objectForKey:@"search"];
    if (!formatter) {
        formatter = [_listFormats objectForKey:@"table"];
    }
    if (formatter) {
        postData = [formatter formatData:postData];
    }
    return postData;
}

- (NSDictionary *)renderPostContent:(NSDictionary *)postData {
    id context = [_clientTemplateContext templateContext];
    NSString *contentHTML = [self renderTemplate:[postData objectForKey:@"content"] withData:context];
    return [postData dictionaryWithAddedObject:contentHTML forKey:@"content"];
}

- (void)showLoginForm {
    [IFAppContainer postMessage:_showLoginAction sender:self];
}

#pragma mark - Private methods

- (NSString *)renderTemplate:(NSString *)template withData:(id)data {
    NSError *error;
    // TODO: Investigate using template repositories to load templates
    // https://github.com/groue/GRMustache/blob/master/Guides/template_repositories.md
    // as they should allow partials to be used within templates, whilst supporting the two
    // use cases of loading templates from file (i.e. for full post html) or evaluating
    // a template from a string (i.e. for post content only).
    NSString *result = [GRMustacheTemplate renderObject:data fromString:template error:&error];
    if (error) {
        result = [NSString stringWithFormat:@"<h1>Template error</h1><pre>%@</pre>", error];
    }
    return result;
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
    _commandScheduler.commands = @{ @"get": [[IFGetURLCommand alloc] initWithHTTPClient:_httpClient] };

    
    // Register the URI scheme handler.
    if (_uriSchemeName && _uriScheme) {
        // Need to use the config's URI handler for wp: schemes to work within the config.
        [componentConfig.uriHandler addHandler:_uriScheme forScheme:_uriSchemeName];
    }
}

#pragma mark - IFMessageTarget

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"logout"]) {
        [_authManager logout];
        [self showLoginForm];
        return YES;
    }
    if ([message hasName:@"password-reminder"]) {
        [_authManager showPasswordReminder];
        return YES;
    }
    if ([message hasName:@"show-login"]) {
        [self showLoginForm];
        return YES;
    }
    return NO;
}

#pragma mark - IFService

- (void)startService {
    [super startService];
    [self unpackPackagedContent];
    // Schedule content updates.
    if (_updateCheckInterval > 0) {
        [_commandScheduler appendCommand:@"content.refresh"];
        [NSTimer scheduledTimerWithTimeInterval:(_updateCheckInterval * 60.0f)
                                         target:self
                                       selector:@selector(refreshContent)
                                       userInfo:nil
                                        repeats:YES];
    }
    // Start command queue execution.
    [_commandScheduler executeQueue];
}

#pragma mark - IFTargetContainer

- (BOOL)dispatchURI:(NSString *)uri {
    return YES;
}

@end
