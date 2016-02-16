//
//  IFWPContentContainerFormFactory.h
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFIOCObjectFactoryBase.h"

@class IFWPContentContainer;

@interface IFWPContentContainerFormFactory : IFIOCObjectFactoryBase {
    IFWPContentContainer *_container;
    NSDictionary *_stdParams;
}

- (id)initWithContainer:(IFWPContentContainer *)container;

@end
