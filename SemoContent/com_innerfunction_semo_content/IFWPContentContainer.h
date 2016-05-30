//
//  IFWPContentContainer.h
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFContainer.h"
#import "IFDB.h"
#import "IFWPContentCommandProtocol.h"
#import "IFWPSchemeHandler.h"
#import "IFCommandScheduler.h"
#import "IFIOCContainerAware.h"
#import "IFIOCTypeInspectable.h"
#import "IFWPContentContainerFormFactory.h"
#import "IFWPAuthManager.h"
#import "IFMessageReceiver.h"
#import "IFHTTPClient.h"

@class IFWPClientTemplateContext;

@interface IFWPContentContainer : IFContainer <IFIOCContainerAware, IFMessageReceiver, IFIOCTypeInspectable> {
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
/**
 * The URL of the content image pack.
 * Used when the app is first installed, to bulk download initial image content.
 */
@property (nonatomic, strong) NSString *imagePackURL;
/** The location of pre-packaged post content, relative to the installed app. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** The location of base content. */
@property (nonatomic, strong) NSString *baseContentPath;
/** The location of downloaded post content once deployed. */
@property (nonatomic, strong) NSString *contentPath;
/** The scheme name the URI handler is bound to; defaults to wp: */
@property (nonatomic, strong) NSString *uriSchemeName;
/** The WP realm name. Used for authentication, defaults to 'semo'. */
@property (nonatomic, strong) NSString *wpRealm;
/** Action to be posted when the container wants to show the login form. */
@property (nonatomic, strong) NSString *showLoginAction;
/** The posts DB instance. */
@property (nonatomic, strong) IFDB *postDB;
/** Whether to reset the post DB on start. (Useful for debug). */
@property (nonatomic, assign) BOOL resetPostDB;
/** Interval in minutes between checks for content updates. */
@property (nonatomic, assign) NSInteger updateCheckInterval;
/** The content protocol instance; manages feed downloads. */
@property (nonatomic, strong) IFWPContentCommandProtocol *contentProtocol;
/** The wp: URI scheme. */
@property (nonatomic, strong) IFWPSchemeHandler *uriScheme;
/** Post list data formats. */
@property (nonatomic, strong) NSDictionary *listFormats;
/** Post data formats. */
@property (nonatomic, strong) NSDictionary *postFormats;
/** Template for generating post URIs. See uriForPostWithID: */
@property (nonatomic, strong) NSString *postURITemplate;
/** Factory for producing login and account management forms. */
@property (nonatomic, strong, readonly) IFWPContentContainerFormFactory *formFactory;
/** Map of pre-defined post filters, keyed by name. */
@property (nonatomic, strong) NSDictionary *filters;
/** An object to use as the template context when rendering the client template for a post. */
@property (nonatomic, strong) IFWPClientTemplateContext *clientTemplateContext;
/** An object used to manage WP server authentication. */
@property (nonatomic, strong) IFWPAuthManager *authManager;
/** A HTTP client. */
@property (nonatomic, strong) IFHTTPClient *httpClient;
/** The maximum number of rows to return for wp:search results. */
@property (nonatomic, assign) NSInteger searchResultLimit;
/**
 * A map describing legal post-type relationships.
 * Allows legal child post types for a post type to be listed. Each map key is a parent post type,
 * and is mapped to either a child post type name (as a string), or a list of child post type names.
 * If a post type has no legal child post types then the type name should be mapped to an empty list.
 * Any post type not described in this property will allow any child post type.
 * Used by the getPostChildren: methods.
 */
@property (nonatomic, strong) NSDictionary *postTypeRelations;

/** Unpack packaged content. */
- (void)unpackPackagedContent;
/** Refresh content. */
- (void)refreshContent;
/** Download content from the specified URL and store in the content location using the specified filename. */
- (void)getContentFromURL:(NSString *)url writeToFilename:(NSString *)filename;
/** Generate a URI to reference the post with the specified ID. */
- (NSString *)uriForPostWithID:(NSString *)postID;
/** Return the child posts of a specified post. Doesn't render the post content. */
- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params;
/** Return the child posts of a specified post. Optionally renders the post content. */
- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params renderContent:(BOOL)renderContent;
/** Get all descendants of a post. Returns the posts children, grandchildren etc. */
- (id)getPostDescendants:(NSString *)postID withParams:(NSDictionary *)params;
/** Return data for a specified post. */
- (id)getPost:(NSString *)postID withParams:(NSDictionary *)params;
/** Query the post database using a predefined filter. */
- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params;
/**
 * Search the post database for the specified text in the specified post types with an optional parent post.
 * When the parent post ID is specified, the search will be confined to that post and any of its descendants
 * (i.e. children, grand-children etc.).
 */
- (id)searchPostsForText:(NSString *)text searchMode:(NSString *)searchMode postTypes:(NSArray *)postTypes parentPost:(NSString *)parentID;
/** Render a post's content by evaluating template reference's within the content field. */
- (NSDictionary *)renderPostContent:(NSDictionary *)postData;
/** Show the login form. */
- (void)showLoginForm;

@end
