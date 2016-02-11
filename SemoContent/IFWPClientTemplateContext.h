//
//  IFWPClientTemplateContext.h
//  SemoContent
//
//  Created by Julian Goacher on 15/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDB.h"
#import "IFIOCContainerAware.h"
#import "IFWPContentContainer.h"

@interface IFWPAttachmentsProxy : NSObject {
    NSFileManager *_fileManager;
}

@property (nonatomic, strong) IFWPContentContainer *container;
@property (nonatomic, strong) IFDB *postDB;
@property (nonatomic, strong) NSString *packagedContentPath;
@property (nonatomic, strong) NSString *contentPath;

@end

@interface IFWPPostsProxy : NSObject

@property (nonatomic, strong) IFWPContentContainer *container;
@property (nonatomic, strong) IFDB *postDB;

@end

/**
 * Data context implementation for the client template.
 * The client template is used to generate post HTML pages using the latest mobile
 * theme. The main purpose of this class is to replace image attachment references
 * with URLs referencing the attachment file in its current location, and to replace
 * post references with appropriate URIs.
 */
@interface IFWPClientTemplateContext : NSObject <IFIOCContainerAware> {
    IFWPAttachmentsProxy *_attachments;
    IFWPPostsProxy *_posts;
}

/** A dictionary of registered extensions. */
@property (nonatomic, strong) NSDictionary *ext;

- (id)templateContextForPostData:(id)postData;

@end
