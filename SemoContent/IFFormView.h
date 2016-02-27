//
//  IFFormView.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFIOCContainerAware.h"
#import "IFFormField.h"
#import "IFHTTPClient.h"

typedef void (^IFFormViewDataEvent)(IFFormView *, id);
typedef void (^IFFormViewErrorEvent)(IFFormView *, NSError *);

/**
 * Protocol implemented by form fields which can indicate form loading status.
 */
@protocol IFFormLoadingIndicator <NSObject>

- (void)showFormLoading:(BOOL)loading;

@end

@interface IFFormView : UITableView <UITableViewDataSource, UITableViewDelegate, IFIOCContainerAware> {
    NSInteger _focusedFieldIdx;
    UIEdgeInsets _defaultInsets;
    NSDictionary *_defaultValues;
    NSDictionary *_inputValues;
    id<IFFormLoadingIndicator> _loadingIndicator;
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

@property (nonatomic, copy) IFFormViewErrorEvent onSubmitRequestError;
@property (nonatomic, copy) IFFormViewDataEvent onSubmitError;
@property (nonatomic, copy) IFFormViewDataEvent onSubmitOk;

/** Get the current value of a named field. */
- (id)getFieldValue:(NSString *)name;
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
 * Update the form's visible state to show that it is submitting.
 */
- (void)submitting:(BOOL)submitting;
/**
 * Submit event callback.
 * Called if the request failed below the application layer.
 */
- (void)submitRequestError:(NSError *)error;
/**
 * Test if a submit response is an application level error.
 */
- (BOOL)isSubmitErrorResponse:(IFHTTPClientResponse *)response;
/**
 * Submit event callback.
 * Called if an application level error occurs on submit.
 */
- (void)submitError:(IFHTTPClientResponse *)response;
/**
 * Submit event callback.
 * Called if the submit request is successful.
 */
- (void)submitOk:(IFHTTPClientResponse *)response;
/**
 * Display a notification of a form error.
 */
- (void)notifyError:(NSString *)message;
/**
 * Notify the form of a field resize.
 */
- (void)notifyFormFieldResize:(IFFormField *)field;
/**
 * Return a list of the fields on this form within the same name group.
 */
- (NSArray *)getFieldsInNameGroup:(NSString *)name;

@end
