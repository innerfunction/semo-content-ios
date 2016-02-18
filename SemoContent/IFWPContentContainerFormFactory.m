//
//  IFWPContentContainerFormFactory.m
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPContentContainerFormFactory.h"
#import "IFWPContentContainer.h"
#import "IFFormViewController.h"
#import "NSDictionary+IF.h"

@implementation IFWPContentContainerFormFactory

- (id)initWithContainer:(IFWPContentContainer *)container {
    NSDictionary *baseConfiguration = @{
        @"*ios-class":      @"IFFormViewController",
        @"form": @{
            @"method":      @"POST",
            @"actionURL":   @"$ActionURL",
            @"isEnabled":   @"$IsEnabled",
            @"fields":      @"$Fields"
        }
    };
    self = [super initWithBaseConfiguration:baseConfiguration];
    if (self) {
        _container = container;
        _stdParams = @{
            @"ImageField": @{
                @"*ios-class":          @"IFFormImageField"
            },
            @"UsernameField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"username",
                @"title":               @"Username"
            },
            @"PasswordField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"password",
                @"isPassword":          [NSNumber numberWithBool:YES],
                @"title":               @"Password"
            },
            @"ConfirmPasswordField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"confirm-password",
                @"isPassword":          [NSNumber numberWithBool:YES],
                @"title":               @"Password"
            },
            @"ForgotPasswordField": @{
                @"*ios-class":          @"IFFormField",
                @"title":               @"Password reminder"
            },
            @"SubmitField": @{
                @"*ios-class":          @"IFFormField",
                @"title":               @"Login"
            }
        };
    }
    return self;
}

- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container identifier:(NSString *)identifier {
    NSString *formType = [configuration getValueAsString:@"formType"];
    NSString *actionURL = @"";
    BOOL isEnabled = YES;
    IFFormViewEventCallback onShow;
    IFFormViewDataEventCallback onSubmitOk;
    // TODO: Following need to be filled in properly
    if ([@"login" isEqualToString:formType]) {
        actionURL = @"login";
        isEnabled = NO;
        onShow = ^(IFFormView *form) {
            // Check if user already logged in, if so then dispatch a specified event.
            // Else change the form to enabled, populate with any existing credentials.
        };
        onSubmitOk = ^(IFFormView *form, id data) {
            // Store user credentials & user info
            // Dispatch the specified event
        };
    }
    else if ([@"new-account" isEqualToString:formType]) {
        actionURL = @"create-account";
        // onSubmitOk probably same as for login
    }
    else if ([@"account" isEqualToString:formType]) {
        actionURL = @"update-account";
        onSubmitOk = ^(IFFormView *form, id data) {
            // Update stored user info
        };
    }
    NSDictionary *params = [_stdParams extendWith:@{
        @"ActionURL":   actionURL,
        @"IsEnabled":   [NSNumber numberWithBool:isEnabled],
        // TODO: Note that 'fields' will itself contain parameter references; this should work but is untested.
        @"Fields":      [configuration getValue:@"fields"]
    }];
    configuration = [configuration configurationWithKeysExcluded:@[ @"*factory", @"formType", @"fields" ]];
    IFFormViewController *formView = (IFFormViewController *)[self buildObjectWithConfiguration:configuration
                                                                                    inContainer:container
                                                                                 withParameters:params
                                                                                     identifier:identifier];
    formView.form.onShowCallback = onShow;
    formView.form.onSubmitOkCallback = onSubmitOk;
    return formView;
}

@end
