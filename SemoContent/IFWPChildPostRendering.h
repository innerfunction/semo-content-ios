//
//  IFWPChildPostRendering.h
//  SemoContent
//
//  Created by Julian Goacher on 10/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFWPSchemeHandler.h"
#import "GRMustache.h"

@interface IFWPChildPostRendering : NSObject <GRMustacheRendering>

@property (nonatomic, weak) IFWPSchemeHandler *schemeHandler;

@end
