//
//  IFWPClientTemplateContext.h
//  SemoContent
//
//  Created by Julian Goacher on 15/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFWPSchemeHandler.h"

/**
 * Data context implementation for the client template.
 * The client template is used to generate post HTML pages using the latest mobile
 * theme. The main purpose of this class is to replace image attachment references
 * with URLs referencing the attachment file in its current location.
 */
@interface IFWPClientTemplateContext : NSObject {
    NSFileManager *_fileManager;
    IFWPSchemeHandler *_parent;
}

@property (nonatomic, strong) NSDictionary *postData;

- (id)initWithParent:(IFWPSchemeHandler *)parent;

@end
