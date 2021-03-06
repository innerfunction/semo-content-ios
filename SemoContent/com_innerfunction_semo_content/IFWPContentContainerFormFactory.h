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
#import "IFViewBehaviourObject.h"

@class IFWPContentContainer;

@interface IFWPContentContainerFormFactory : IFIOCObjectFactoryBase {
    __weak IFWPContentContainer *_container;
    NSDictionary *_stdParams;
    NSUserDefaults *_userDefaults;
}

- (id)initWithContainer:(IFWPContentContainer *)container;

@end

@interface IFWPContentLoginBehaviour : IFViewBehaviourObject

- (id)initWithContainer:(IFWPContentContainer *)container loginAction:(NSString *)loginAction;

@property (nonatomic, weak) IFWPContentContainer *container;
@property (nonatomic, strong) NSString *loginAction;

@end