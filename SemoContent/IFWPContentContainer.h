//
//  IFWPContentContainer.h
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFContainer.h"
#import "IFDB.h"
#import "IFWPContentProtocol.h"
#import "IFWPSchemeHandler.h"
#import "IFCommandScheduler.h"
#import "IFIOCConfigurable.h"
#import "IFWPContentContainerFormFactory.h"
#import "IFWPAuthenticationHandler.h"
#import "IFHTTPClient.h"

@class IFWPClientTemplateContext;

@interface IFWPContentContainer : IFContainer <IFIOCConfigurable> {
    // Container configuration template.
    IFConfiguration *_configTemplate;
    // Command scheduler for unpack and refresh operations.
    IFCommandScheduler *_commandScheduler;
    // Location for staging downloaded content prior to deployment.
    NSString *_stagingPath;
    // File manager.
    NSFileManager *_fileManager;
}

/** The name of the posts DB. */
@property (nonatomic, strong) NSString *postDBName;
/** The URL of the WP posts feed. */
@property (nonatomic, strong) NSString *feedURL;
/** The location of pre-packaged post content, relative to the installed app. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** The location of base content. */
@property (nonatomic, strong) NSString *baseContentPath;
/** The location of downloaded post content once deployed. */
@property (nonatomic, strong) NSString *contentPath;
/** The scheme name the URI handler should be bound to; defaults to wp: */
@property (nonatomic, strong) NSString *uriSchemeName;
/** The posts DB instance. */
@property (nonatomic, strong) IFDB *postDB;
/** Whether to reset the post DB on start. (Useful for debug). */
@property (nonatomic, assign) BOOL resetPostDB;
/** The content protocol instance; manages feed downloads. */
@property (nonatomic, strong) IFWPContentProtocol *contentProtocol;
/** The wp: URI scheme. */
@property (nonatomic, strong) IFWPSchemeHandler *uriScheme;
/** Post list data formats. */
@property (nonatomic, strong) NSDictionary *listFormats;
/** Post data formats. */
@property (nonatomic, strong) NSDictionary *postFormats;
/** Template for generating post URIs. See uriForPostWithID: */
@property (nonatomic, strong) NSString *postURITemplate;
/** Factory for producing login and account managment forms. */
@property (nonatomic, strong, readonly) IFWPContentContainerFormFactory *formFactory;
/** Map of pre-defined post filters, keyed by name. */
@property (nonatomic, strong) NSDictionary *filters;
/** An object to use as the template context when rendering the client template for a post. */
@property (nonatomic, strong) IFWPClientTemplateContext *clientTemplateContext;
/** An object used to manage WP server authentication. */
@property (nonatomic, strong) IFWPAuthenticationHandler *authenticationHandler;
/** A HTTP client. */
@property (nonatomic, strong) IFHTTPClient *httpClient;

/** Unpack packaged content. */
- (void)unpackPackagedContent;
/** Refresh content. */
- (void)refreshContent;
/** Download content from the specified URL and store in the content location using the specified filename. */
- (void)getContentFromURL:(NSString *)url writeToFilename:(NSString *)filename;
/** Generate a URI to reference the post with the specified ID. */
- (NSString *)uriForPostWithID:(NSString *)postID;
/** Return the child posts of a specified post. */
- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params;
/** Return data for a specified post. */
- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params;
/** Query the post database using a predefined filter. */
- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params;
/** Search the post database for the specified text in the specified post types. */
- (id)searchPostsForText:(NSString *)text searchMode:(NSString *)searchMode postTypes:(NSArray *)postTypes;
/** Render a post's content by evaluating template reference's within the content field. */
- (NSDictionary *)renderPostContent:(NSDictionary *)postData;

@end
