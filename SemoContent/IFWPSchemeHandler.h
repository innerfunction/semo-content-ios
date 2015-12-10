//
//  IFWPSchemeHandler.h
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"
#import "IFDB.h"

/**
 * Handler for URIs in the wp: scheme.
 * The wp: scheme provides access to Wordpress posts downloaded to the local content database.
 * The scheme supports the following forms:
 *
 *  wp:posts        Return a list of post data. The following URI parameters are available:
 *                  - type: Filter by post type.
 *                  - modifiedTime: With optional .min, .max modifiers; filter by post modification time.
 *                  - where: Specify an arbitrary SQL where clause on the posts table.
 *                  - filter: Apply a pre-defined filter.
 *                  - format: Apply a named formatter to the result. Defaults to 'listdata'.
 *
 * wp:posts/{id}    Return data for a specific post. The following URI parameters are available:
 *                  - format: Apply a named formatter to the result. Defaults to 'webview'.
 */
@interface IFWPSchemeHandler : NSObject <IFSchemeHandler>

/** The WP post database. */
@property (nonatomic, strong) IFDB *postDB;
/** Map of pre-defined post filters, keyed by name. */
@property (nonatomic, strong) NSDictionary *filters;
/** Map of pre-defined post list formats, keyed by name. */
@property (nonatomic, strong) NSDictionary *listFormats;
/** Map of pre-defined post item formats, keyed by name. */
@property (nonatomic, strong) NSDictionary *postFormats;
/** Path to the content directory (i.e. location of downloaded images and other media resources). */
@property (nonatomic, strong) NSString *contentPath;

@end
