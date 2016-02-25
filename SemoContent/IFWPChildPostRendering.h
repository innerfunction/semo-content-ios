//
//  IFWPChildPostRendering.h
//  SemoContent
//
//  Created by Julian Goacher on 10/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFWPSchemeHandler.h"
#import "IFIOCContainerAware.h"
#import "IFWPContentContainer.h"
#import "GRMustache.h"

@interface IFWPChildPostRendering : NSObject <IFIOCContainerAware, GRMustacheRendering> {
    IFWPContentContainer *_contentContainer;
}

@property (nonatomic, weak) IFWPSchemeHandler *schemeHandler;

@end
