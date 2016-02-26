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
#import "SFHFKeychainUtils.h"

@interface IFWPContentContainerFormFactory ()

void storeUserCredentials(IFFormView *form, NSString *service);

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
            @"ForgotPasswordField": @{
                @"*ios-class":          @"IFFormField",
                @"title":               @"Password reminder"
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
                NSLog(@"**** Loading main screen");
            }
            // Else change the form to enabled, populate with any existing credentials.
        };
        onSubmitOk = ^(IFFormView *form, id data) {
            // Store user credentials & user info
            storeUserCredentials(form, _container.feedURL);
            [_userDefaults setValue:@YES forKey:@"semo/logged-in"];
            // Dispatch the specified event
        };
    }
    else if ([@"new-account" isEqualToString:formType]) {
        submitURL = [_container.feedURL stringByAppendingPathComponent:@"account/create"];
        onSubmitOk = ^(IFFormView *form, id data) {
            // Store user credentials & user info
            storeUserCredentials(form, _container.feedURL);
            [_userDefaults setValue:@YES forKey:@"semo/logged-in"];
            // Dispatch the specified event
            NSLog(@"**** Loading main screen");
        };
    }
    else if ([@"profile" isEqualToString:formType]) {
        submitURL = [_container.feedURL stringByAppendingPathComponent:@"account/profile"];
        onSubmitOk = ^(IFFormView *form, id data) {
            // Update stored user info
            storeUserCredentials(form, _container.feedURL);

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
        // TODO: Display error notification
    };
    return formView;
}

void storeUserCredentials(IFFormView *form, NSString *service) {
    NSDictionary *formValues = form.inputValues;
    NSString *username = [formValues objectForKey:@"user_login"];
    NSString *password = [formValues objectForKey:@"user_pass"];
    // NOTE this will work for all forms - login, create account + update profile. In the latter case, if the
    // password is not updated then password will be empty and the keystore won't be updated.
    if ([username length] > 0 && [password length] > 0) {
        [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:service updateExisting:YES error:nil];
    }
}

@end
