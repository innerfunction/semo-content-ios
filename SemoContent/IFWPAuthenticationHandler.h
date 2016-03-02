//
//  IFWPAuthenticationHandler.h
//  SemoContent
//
//  Created by Julian Goacher on 01/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IFWPContentContainer;

@interface IFWPAuthenticationHandler : NSObject {
    NSString *_service;
    NSUserDefaults *_userDefaults;
    __weak IFWPContentContainer *_container;
}

- (id)initWithContainer:(IFWPContentContainer *)container;

- (void)storeUserCredentials:(NSDictionary *)values;

@end
