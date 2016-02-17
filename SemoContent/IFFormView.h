//
//  IFFormView.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFFormField.h"
#import "IFActionDispatcher.h"

typedef void (^IFFormViewEventCallback)(IFFormView *);
typedef void (^IFFormViewDataEventCallback)(IFFormView *, id);
typedef void (^IFFormViewErrorEventCallback)(IFFormView *, NSError *);

@interface IFFormView : UITableView <UITableViewDataSource, UITableViewDelegate> {
    NSInteger _focusedFieldIdx;
    UIEdgeInsets _defaultInsets;
    NSDictionary *_defaultValues;
    NSDictionary *_inputValues;
}

/** The list of form fields. */
@property (nonatomic, strong) NSArray *fields;
/** The form submit method, e.g. GET or POST. */
@property (nonatomic, strong) NSString *method;
/** The URL to submit the form to. */
@property (nonatomic, strong) NSString *submitURL;
/** A dictionary containing values for all named input fields. */
@property (nonatomic, strong) NSDictionary *inputValues;
/** Flag specifying whether the form is enabled or not. */
@property (nonatomic, assign) BOOL isEnabled;

@property (nonatomic, strong) id<IFActionDispatcher> actionDispatcher;
@property (nonatomic, assign) IFFormViewEventCallback onShowCallback;
@property (nonatomic, assign) IFFormViewErrorEventCallback onSubmitTransportErrorCallback;
@property (nonatomic, assign) IFFormViewDataEventCallback onSubmitErrorCallback;
@property (nonatomic, assign) IFFormViewDataEventCallback onSubmitOkCallback;

/** Get the currently focused field. */
- (IFFormField *)getFocusedField;
/** Clear the current field focus. */
- (void)clearFieldFocus;
/** Move field focus to the next focusable field. */
- (void)moveFocusToNextField;
/** Reset all fields to the original values. */
- (void)reset;
/**
 * Validate all field values.
 * If any field is invalid then moves field focus to the first invalid field, and then returns false.
 */
- (BOOL)validate;
/**
 * Submit the form.
 * Validates the form before submitting. Returns true if the form is valid and was submitted.
 */
- (BOOL)submit;
/**
 * Submit event callback.
 * Called when the submit response is received. Allows the response data to be parsed.
 */
- (id)onSubmitResponse:(NSURLResponse *)response data:(id)data;
/**
 * Submit event callback.
 * Called if a transport (i.e. HTTP) error occurs on submit.
 */
- (void)onSubmitTransportError:(NSError *)error;
/**
 * Test if a submit response is an application level error.
 */
- (BOOL)isSubmitErrorResponse:(NSURLResponse *)response data:(id)data;
/**
 * Submit event callback.
 * Called if an application level error occurs on submit.
 */
- (void)onSubmitError:(id)data;
/**
 * Submit event callback.
 * Called if the submit request is successful.
 */
- (void)onSubmitOk:(id)data;
/**
 * Form show event callback.
 */
- (void)onShow;

@end
