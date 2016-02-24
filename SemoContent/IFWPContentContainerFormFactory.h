//
//  IFWPContentContainerFormFactory.h
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFIOCObjectFactoryBase.h"
#import "IFURIHandling.h"

@class IFWPContentContainer;

@interface IFWPContentContainerFormFactory : IFIOCObjectFactoryBase {
    IFWPContentContainer *_container;
    NSDictionary *_stdParams;
    NSUserDefaults *_userDefaults;
}

- (id)initWithContainer:(IFWPContentContainer *)container;

@end
