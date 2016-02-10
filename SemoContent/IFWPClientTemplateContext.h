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

/**
 * Data context implementation for the client template.
 * The client template is used to generate post HTML pages using the latest mobile
 * theme. The main purpose of this class is to replace image attachment references
 * with URLs referencing the attachment file in its current location, and to replace
 * post references with appropriate URIs.
 */
@interface IFWPClientTemplateContext : NSObject <IFIOCContainerAware> {
    NSFileManager *_fileManager;
    IFWPContentContainer *_container;
    IFDB *_postDB;
    NSString *_packagedContentPath;
    NSString *_contentPath;
}

@property (nonatomic, strong) NSDictionary *postData;
/** A dictionary of registered extensions. */
@property (nonatomic, strong) NSDictionary *ext;

@end
