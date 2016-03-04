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
            @"EmailField": @{
                @"*ios-class":          @"IFFormTextField",
                @"name":                @"user_email",
                @"isRequired":          @YES,
                @"title":               @"Email"
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
            @"ProfileIDField": @{
                @"*ios-class":          @"IFFormHiddenField",
                @"name":                @"ID"
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
    IFFormViewErrorEvent onSubmitError;
    // TODO: Following need to be filled in properly
    if ([@"login" isEqualToString:formType]) {
        submitURL = _container.authManager.loginURL;
        //isEnabled = NO;
        onShow = ^(IFViewController *view) {
            // Check if user already logged in, if so then dispatch a specified event.
            if ([_container.authManager isLoggedIn]) {
                [IFAppContainer postMessage:loginAction sender:view];
            }
            // Else change the form to enabled, populate with any existing credentials.
        };
        onSubmitOk = ^(IFFormView *form, NSDictionary *data) {
            // Store user credentials & user info
            [_container.authManager storeUserProfile:data[@"profile"]];
            [_container.authManager storeUserCredentials:form.inputValues];
            // Dispatch the specified event
            [IFAppContainer postMessage:loginAction sender:form];
        };
        onSubmitError = ^(IFFormView *form, id data) {
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", @"Login%20failure"];
            [IFAppContainer postMessage:action sender:form];
        };
    }
    else if ([@"new-account" isEqualToString:formType]) {
        submitURL = _container.authManager.createAccountURL;
        onSubmitOk = ^(IFFormView *form, NSDictionary *data) {
            // Store user credentials & user info
            [_container.authManager storeUserCredentials:form.inputValues];
            [_container.authManager storeUserProfile:data[@"profile"]];
            // Dispatch the specified event
            [IFAppContainer postMessage:loginAction sender:form];
        };
        onSubmitError = ^(IFFormView *form, id data) {
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", @"Account%20creation%20failure"];
            [IFAppContainer postMessage:action sender:form];
        };
    }
    else if ([@"profile" isEqualToString:formType]) {
        submitURL = _container.authManager.profileURL;
        onSubmitOk = ^(IFFormView *form, NSDictionary *data) {
            // Update stored user info
            [_container.authManager storeUserProfile:data[@"profile"]];
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", @"Account%20updated"];
            [IFAppContainer postMessage:action sender:form];
        };
        onSubmitError = ^(IFFormView *form, id data) {
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", @"Account%20update%20failure"];
            [IFAppContainer postMessage:action sender:form];
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
    formView.form.onSubmitError = onSubmitError;
    formView.form.httpClient = _container.httpClient;
    if ([@"profile" isEqualToString:formType]) {
        formView.form.inputValues = [_container.authManager getUserProfile];
    }
    return formView;
}

@end
