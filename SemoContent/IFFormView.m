//
//  IFFormView.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormView.h"
#import "IFFormField.h"
#import "IFFormTextField.h"
#import "IFFormImageField.h"

@implementation IFFormView

@synthesize iocContainer = _iocContainer;

- (id)init {
    self = [super init];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;

        _isEnabled = YES;
    }
    return self;
}

- (void)setFields:(NSArray *)fields {
    _fields = fields;
    NSMutableDictionary *defaultValues = [NSMutableDictionary new];
    for (IFFormField *field in _fields) {
        field.form = self;
        if (field.name) {
            if (field.value != nil) {
                [defaultValues setObject:field.value forKey:field.name];
            }
        }
        if ([field conformsToProtocol:@protocol(IFFormLoadingIndicator)]) {
            _loadingIndicator = (id<IFFormLoadingIndicator>)field;
        }
    }
    _defaultValues = defaultValues;
    // If input values have already been set then set again so that field values are populated.
    if (_inputValues) {
        self.inputValues = _inputValues;
    }
}

- (void)setMethod:(NSString *)method {
    _method = [method uppercaseString];
}

- (void)setInputValues:(NSDictionary *)inputValues {
    _inputValues = inputValues;
    for (IFFormField *field in _fields) {
        if (field.name) {
            id value = [inputValues valueForKey:field.name];
            if (value != nil) {
                field.value = value == [NSNull null] ? nil : value;
            }
        }
    }
}

- (NSDictionary *)inputValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    for (IFFormField *field in _fields) {
        if (field.isInput && field.name && field.value != nil) {
            [values setObject:field.value forKey:field.name];
        }
    }
    return values;
}

#pragma mark - Instance methods

- (NSString *)getFieldValue:(NSString *)name {
    for (IFFormField *field in _fields) {
        if ([field.name isEqualToString:name]) {
            return field.value;
        }
    }
    return nil;
}

- (IFFormField *)getFocusedField {
    return (IFFormField *)[_fields objectAtIndex:_focusedFieldIdx];
}

- (void)clearFieldFocus {
    IFFormField *field = [self getFocusedField];
    [field releaseFieldFocus];
}

- (void)moveFocusToNextField {
    [self clearFieldFocus];
    IFFormField *field;
    for (NSInteger idx = _focusedFieldIdx + 1; idx < [_fields count]; idx++ ) {
        field = (IFFormField *)[_fields objectAtIndex:idx];
        if ([field takeFieldFocus]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            _focusedFieldIdx = idx;
            break;
        }
    }
}

- (void)reset {
    for (IFFormField *field in _fields) {
        if (field.name) {
            field.value = [_defaultValues objectForKey:field.name];
        }
    }
}

- (BOOL)validate {
    BOOL ok = YES;
    NSInteger row = 0;
    for (IFFormField *field in _fields) {
        if (![field validate]) {
            if (ok) {
                // Scroll to the first invalid field.
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                });
                ok = NO;
                break;
            }
        }
        row++;
    }
    return ok;
}

- (BOOL)submit {
    BOOL ok = [self validate];
    if (ok) {
        [self submitting:YES];
        [IFHTTPClient submit:_method url:_submitURL data:self.inputValues]
        .then((id)^(IFHTTPClientResponse *response) {
            if ([self isSubmitErrorResponse:response]) {
                [self submitError:response];
            }
            else {
                [self submitOk:response];
            }
            [self submitting:NO];
            return nil;
        })
        .fail(^(id error) {
            [self submitRequestError:error];
            [self submitting:NO];
        });
    }
    return ok;
}

- (void)submitting:(BOOL)submitting {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_loadingIndicator showFormLoading:submitting];
    });
    _isEnabled = !submitting;
}

- (BOOL)isSubmitErrorResponse:(IFHTTPClientResponse *)response {
    BOOL ok = YES;
    if ([response.httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response.httpResponse).statusCode;
        ok = statusCode < 400;
    }
    return !ok;
}

- (void)submitRequestError:(NSError *)error {
    if (_onSubmitRequestError) {
        _onSubmitRequestError(self, error);
    }
}

- (void)submitError:(IFHTTPClientResponse *)response {
    if (_onSubmitError) {
        _onSubmitError(self, [response parseData]);
    }
}

- (void)submitOk:(IFHTTPClientResponse *)response {
    if (_onSubmitOk) {
        _onSubmitOk(self, [response parseData]);
    }
}

- (void)notifyError:(NSString *)message {
    NSLog(@"%@", message );
}

- (void)notifyFormFieldResize:(IFFormField *)field {
    NSInteger idx = [_fields indexOfObject:field];
    if (idx != NSNotFound) {
        NSArray *paths = @[ [NSIndexPath indexPathForRow:idx inSection:0] ];
        [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (NSArray *)getFieldsInNameGroup:(NSString *)name {
    NSMutableArray *fields = [NSMutableArray new];
    for (IFFormField *field in _fields) {
        if ([field.name isEqualToString:name]) {
            [fields addObject:field];
        }
    }
    return fields;
}

#pragma mark - Overrides

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    // Notifications for when keyboard is shown or hidden.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (void)keyboardDidShow:(NSNotification *)notification {
    _defaultInsets = self.contentInset;
    // Following taken from http://stackoverflow.com/a/5324303
    NSDictionary *keyboardInfo = [notification userInfo];
    NSValue *keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [keyboardFrameBegin CGRectValue];
    // Following taken from http://stackoverflow.com/a/12125261
    self.contentInset = UIEdgeInsetsMake(_defaultInsets.top, _defaultInsets.left, keyboardRect.size.height, _defaultInsets.right);
    self.scrollIndicatorInsets = self.contentInset;
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:_focusedFieldIdx];
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.2 animations:^{
        self.contentInset = _defaultInsets;
        self.scrollIndicatorInsets = _defaultInsets;
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_fields objectAtIndex:indexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_fields count];
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    IFFormField *field = [_fields objectAtIndex:indexPath.row];
    return field.isSelectable;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self clearFieldFocus];
    _focusedFieldIdx = indexPath.row;
    IFFormField *field = [_fields objectAtIndex:_focusedFieldIdx];
    [field takeFieldFocus];
    [field selectField];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    IFFormField *field = [_fields objectAtIndex:_focusedFieldIdx];
    [field releaseFieldFocus];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFFormField *field = [_fields objectAtIndex:indexPath.row];
    return [field.height floatValue];
}

@end
