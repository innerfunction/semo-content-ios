//
//  IFWPContentContainerFormFactory.m
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPContentContainerFormFactory.h"
#import "IFWPContentContainer.h"
#import "NSDictionary+IF.h"

@implementation IFWPContentContainerFormFactory

- (id)initWithContainer:(IFWPContentContainer *)container {
    NSDictionary *baseConfiguration = @{
        @"*ios-class":  @"IFFormView",
        @"method":      @"POST",
        @"actionURL":   @"$ActionURL"
    };
    self = [super initWithBaseConfiguration:baseConfiguration];
    if (self) {
        _container = container;
        _stdParams = @{
           @"ImageField": @{
               @"*ios-class":   @"IFFormImageField"
           },
           @"UsernameField": @{
               @"*ios-class":   @"IFFormTextField",
               @"name":         @"username"
           },
           @"PasswordField": @{
               @"*ios-class":   @"IFFormTextField",
               @"name":         @"password",
               @"isPassword":   [NSNumber numberWithBool:YES]
           },
           @"SubmitField": @{
               @"*ios-class":   @"IFFormField"
           }
        };
    }
    return self;
}

- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container identifier:(NSString *)identifier {
    NSDictionary *params = _stdParams;
    NSString *formType = [configuration getValueAsString:@"formType"];
    if ([@"login" isEqualToString:formType]) {
        // Username + Password field params
        // onSubmit: Save credentials, dispatch login action
        params = [params extendWith:@{
            @"SubmitURL": @""
        }];
    }
    else if ([@"new-account" isEqualToString:formType]) {
        // Username + Password + other field params
        // onSubmit: Save credentials, dispatch login action
    }
    else if ([@"account" isEqualToString:formType]) {
        // Username + Password + other field params
        // onSubmit: ?
    }
    return [self buildObjectWithConfiguration:configuration inContainer:container withParameters:params identifier:identifier];
}

@end
