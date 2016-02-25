//
//  IFWPSchemeHandler.h
//  SemoContent
//
//  Created by Julian Goacher on 10/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"

@class IFWPContentContainer;

/**
 * Handler for URIs in the wp: scheme.
 * The wp: scheme provides access to Wordpress posts downloaded to the local content database.
 * The scheme supports the following forms:
 *
 *  wp:posts                Return a list of post data. The following URI parameters are available:
 *                          - type: Filter by post type.
 *                          - modifiedTime: With optional .min, .max modifiers; filter by post modification time.
 *                          - where: Specify an arbitrary SQL where clause on the posts table.
 *                          - filter: Apply a pre-defined filter.
 *                          - format: Apply a named formatter to the result. Defaults to 'listdata'.
 *
 *  wp:posts/{id}           Return data for a specific post. The following URI parameters are available:
 *                          - format: Apply a named formatter to the result. Defaults to 'webview'.
 *
 *  wp:posts/{id}/children  Return a list of all posts with the specified post as their parent.
 *                          The result is sorted by the 'order' field value.
 */
@interface IFWPSchemeHandler : NSObject <IFSchemeHandler> {
    IFWPContentContainer *_contentContainer;
}

- (id)initWithContentContainer:(IFWPContentContainer *)contentContainer;

@end
