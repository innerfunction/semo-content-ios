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

#define ValueOrNSNull(value)    (value == nil ? [NSNull null] : value)

@implementation IFWPContentLoginBehaviour

- (id)initWithContainer:(IFWPContentContainer *)container loginAction:(NSString *)loginAction {
    self = [super init];
    if (self) {
        _container = container;
        _loginAction = loginAction;
    }
    return self;
}

- (void)viewDidAppear {
    // Check if user already logged in, if so then dispatch a specified event.
    if ([_container.authManager isLoggedIn]) {
        [IFAppContainer postMessage:_loginAction sender:self.viewController];
    }
}

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
                @"*ios-class":              @"IFFormImageField"
            },
            @"FirstnameField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"first_name",
                @"title":                   @"First name",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                },
                @"input": @{
                    @"autocapitalization":  @"words",
                    @"autocorrection":      @NO,
                    @"style":               @"$InputStyle"
                }
            },
            @"LastnameField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"last_name",
                @"title":                   @"Last name",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                },
                @"input": @{
                    @"autocapitalization":  @"words",
                    @"autocorrection":      @NO,
                    @"style":               @"$InputStyle"
                }
            },
            @"EmailField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"user_email",
                @"isRequired":              @YES,
                @"title":                   @"Email",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                },
                @"input": @{
                    @"keyboard":            @"email",
                    @"autocapitalization":  @"none",
                    @"autocorrection":      @NO,
                    @"style":               @"$InputStyle"
                }
            },
            @"UsernameField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"user_login",
                @"isRequired":              @YES,
                @"title":                   @"Username",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                },
                @"input": @{
                    @"autocapitalization":  @"none",
                    @"autocorrection":      @NO,
                    @"style":               @"$InputStyle"
                }
            },
            @"PasswordField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"user_pass",
                @"isPassword":              @YES,
                @"isRequired":              @YES,
                @"title":                   @"Password",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                }
            },
            @"ConfirmPasswordField": @{
                @"*ios-class":              @"IFFormTextField",
                @"name":                    @"confirm_pass",
                @"isPassword":              @YES,
                @"title":                   @"Confirm password",
                @"hasSameValueAs":          @"user_pass",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                }
            },
            @"ProfileIDField": @{
                @"*ios-class":              @"IFFormHiddenField",
                @"name":                    @"ID"
            },
            @"SubmitField": @{
                @"*ios-class":              @"IFSubmitField",
                @"title":                   @"Login",
                @"titleLabel": @{
                    @"style":               @"$TitleStyle"
                }
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
    id<IFViewBehaviour> viewBehaviour = nil;
    IFFormViewDataEvent onSubmitOk;
    IFFormViewErrorEvent onSubmitError;
    // TODO: Following need to be filled in properly
    if ([@"login" isEqualToString:formType]) {
        submitURL = _container.authManager.loginURL;
        BOOL checkForLogin = [configuration getValueAsBoolean:@"checkForLogin" defaultValue:YES];
        if (checkForLogin) {
            viewBehaviour = [[IFWPContentLoginBehaviour alloc] initWithContainer:_container loginAction:loginAction];
        }
        //isEnabled = NO;
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
            NSString *message = [data objectForKey:@"error"];
            if (!message) {
                message = @"Account creation failure";
            }
            message = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", message];
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
            NSString *message = [data objectForKey:@"error"];
            if (!message) {
                message = @"Account update failure";
            }
            message = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            NSString *action = [NSString stringWithFormat:@"post:toast+message=%@", message];
            [IFAppContainer postMessage:action sender:form];
        };
    }
    NSDictionary *params = [_stdParams extendWith:@{
        @"SubmitURL":   submitURL,
        @"IsEnabled":   [NSNumber numberWithBool:isEnabled],
        @"Fields":      ValueOrNSNull([configuration getValue:@"fields"]),
        @"TitleStyle":  ValueOrNSNull([configuration getValue:@"titleStyle"]),
        @"InputStyle":  ValueOrNSNull([configuration getValue:@"inputStyle"])
    }];
    configuration = [configuration configurationWithKeysExcluded:@[ @"*factory", @"formType", @"fields" ]];
    IFFormViewController *formView = (IFFormViewController *)[self buildObjectWithConfiguration:configuration
                                                                                    inContainer:container
                                                                                 withParameters:params
                                                                                     identifier:identifier];
    formView.behaviour = viewBehaviour;
    formView.form.onSubmitOk = onSubmitOk;
    formView.form.onSubmitError = onSubmitError;
    formView.form.httpClient = _container.httpClient;
    if ([@"profile" isEqualToString:formType]) {
        formView.form.inputValues = [_container.authManager getUserProfile];
    }
    return formView;
}

@end
