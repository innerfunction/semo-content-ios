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
#import "IFAppContainer.h"
#import "NSDictionary+IF.h"

@interface IFWPContentContainerFormFactory ()

- (void)storeUserCredentials:(IFFormView *)form;

@end
    
@implementation IFWPContentContainerFormFactory

- (id)initWithContainer:(IFWPContentContainer *)container {
    NSDictionary *baseConfiguration = @{
        @"*ios-class":      @"IFFormViewController",
        @"form": @{
            @"method":      @"POST",
            @"submitURL":   @"$SubmitURL",
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
            @"FirstnameField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"first_name",
                @"title":               @"First name"
            },
            @"LastnameField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"last_name",
                @"title":               @"Last name"
            },
            @"UsernameField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"user_login",
                @"isRequired":          @YES,
                @"title":               @"Username"
            },
            @"PasswordField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"user_pass",
                @"isPassword":          @YES,
                @"isRequired":          @YES,
                @"title":               @"Password"
            },
            @"ConfirmPasswordField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"confirm_pass",
                @"isPassword":          @YES,
                @"title":               @"Confirm password",
                @"hasSameValueAs":      @"user_pass"
            },
            // TODO: How does this field invoke functionality on the container?
            @"ForgotPasswordField": @{
                @"*ios-class":          @"IFFormField",
                @"title":               @"Password reminder"
            },
            // TODO: How does this field invoke functionality on the container to do logout, redisplay login form?
            @"LogoutField:": @{
                @"*ios-class":          @"IFFormField",
                @"title":               @"Logout"
            },
            @"SubmitField": @{
                @"*ios-class":          @"IFSubmitField",
                @"title":               @"Login"
            }
        };
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container identifier:(NSString *)identifier {
    NSString *formType = [configuration getValueAsString:@"formType"];
    NSString *submitURL = @"";
    NSString *loginAction = [configuration getValueAsString:@"loginAction"];
    BOOL isEnabled = YES;
    IFViewControllerEvent onShow;
    IFFormViewDataEvent onSubmitOk;
    // TODO: Following need to be filled in properly
    if ([@"login" isEqualToString:formType]) {
        submitURL = [_container.feedURL stringByAppendingPathComponent:@"account/login"];
        //isEnabled = NO;
        onShow = ^(IFViewController *view) {
            // Check if user already logged in, if so then dispatch a specified event.
            if ([_userDefaults boolForKey:@"semo/logged-in"]) {
                [IFAppContainer postMessage:loginAction sender:view];
            }
            // Else change the form to enabled, populate with any existing credentials.
        };
        onSubmitOk = ^(IFFormView *form, id data) {
            // Store user credentials & user info
            [self storeUserCredentials:form];
            // Dispatch the specified event
            [IFAppContainer postMessage:loginAction sender:form];
        };
    }
    else if ([@"new-account" isEqualToString:formType]) {
        submitURL = [_container.feedURL stringByAppendingPathComponent:@"account/create"];
        onSubmitOk = ^(IFFormView *form, id data) {
            // Store user credentials & user info
            [self storeUserCredentials:form];
            // Dispatch the specified event
            [IFAppContainer postMessage:loginAction sender:form];
        };
    }
    else if ([@"profile" isEqualToString:formType]) {
        submitURL = [_container.feedURL stringByAppendingPathComponent:@"account/profile"];
        onSubmitOk = ^(IFFormView *form, id data) {
            // Update stored user info
        };
    }
    NSDictionary *params = [_stdParams extendWith:@{
        @"SubmitURL":   submitURL,
        @"IsEnabled":   [NSNumber numberWithBool:isEnabled],
        @"Fields":      [configuration getValue:@"fields"]
    }];
    configuration = [configuration configurationWithKeysExcluded:@[ @"*factory", @"formType", @"fields" ]];
    IFFormViewController *formView = (IFFormViewController *)[self buildObjectWithConfiguration:configuration
                                                                                    inContainer:container
                                                                                 withParameters:params
                                                                                     identifier:identifier];
    formView.onShow = onShow;
    formView.form.onSubmitOk = onSubmitOk;
    formView.form.onSubmitError = ^(IFFormView *form, id data) {
        NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", @"Login%20failure"];
        [IFAppContainer postMessage:action sender:form];
    };
    formView.form.httpClient = _container.httpClient;
    return formView;
}

#pragma mark - Private methods

- (void)storeUserCredentials:(IFFormView *)form {
    NSDictionary *formValues = form.inputValues;
    [_container.authenticationHandler storeUserCredentials:formValues];
}

@end
