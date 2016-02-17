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
    NSMutableDictionary *defaultValues = [[NSMutableDictionary alloc] init];
    for (IFFormField *field in _fields) {
        field.form = self;
        if (field.name && field.value != nil) {
            [defaultValues setObject:field.value forKey:field.name];
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
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    for (IFFormField *field in _fields) {
        if (field.isInput && field.name && field.value != nil) {
            [values setObject:field.value forKey:field.name];
        }
    }
    return values;
}

#pragma mark - Instance methods

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
    for (NSInteger idx = _focusedFieldIdx + 1; idx != _focusedFieldIdx; idx++ ) {
        if (idx > [_fields count]) {
            idx = 0;
        }
        field = (IFFormField *)[_fields objectAtIndex:idx];
        if ([field takeFieldFocus]) {
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
                    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:row];
                    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                });
                ok = NO;
            }
        }
        row++;
    }
    return ok;
}

- (BOOL)submit {
    BOOL ok = [self validate];
    if (ok) {
        // TODO: Submit
        // 1. Prepare request - method, url, body
        // NOTE: Important to use property accessor instead of _inputValues var below, so as to get current field values.
        NSDictionary *values = self.inputValues;
        NSURLComponents *urlParts = [NSURLComponents componentsWithString:_submitURL];
        NSMutableArray *queryItems = [[NSMutableArray alloc] init];
        for (NSString *name in values) {
            NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:name value:[values objectForKey:name]];
            [queryItems addObject:queryItem];
        }
        urlParts.queryItems = queryItems;
        // 2. Send request
        NSURLRequest *request = [NSURLRequest requestWithURL:urlParts.URL];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                // 3. Process response - http ok/error, parse body, application ok/error
                if (error) {
                    [self onSubmitTransportError:error];
                }
                else {
                    id responseData = [self onSubmitResponse:response data:data];
                    if ([self isSubmitErrorResponse:response data:responseData]) {
                        [self onSubmitError:responseData];
                    }
                    else {
                        [self onSubmitOk:responseData];
                    }
                }
            }];
        [task resume];
    }
    return ok;
}

- (id)onSubmitResponse:(NSURLResponse *)response data:(id)data {
    NSString *contentType = response.MIMEType;
    if ([@"application/json" isEqualToString:contentType]) {
        data = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        // TODO: Parse error handling.
    }
    else if ([@"application/x-www-form-urlencoded" isEqualToString:contentType]) {
        // Adapted from http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
        NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
        NSURLComponents *urlParts = [NSURLComponents componentsWithURL:response.URL resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *queryItem in urlParts.queryItems) {
            [mdata setObject:queryItem.value forKey:queryItem.name];
        }
        data = mdata;
    }
    return data;
}

- (BOOL)isSubmitErrorResponse:(NSURLResponse *)response data:(id)data {
    BOOL ok = YES;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        ok = ((NSHTTPURLResponse *)response).statusCode < 400;
    }
    return ok;
}

- (void)onSubmitTransportError:(NSError *)error {
    if (_onSubmitTransportErrorCallback) {
        _onSubmitTransportErrorCallback(self, error);
    }
}

- (void)onSubmitError:(id)data {
    if (_onSubmitErrorCallback) {
        _onSubmitErrorCallback(self, data);
    }
}

- (void)onSubmitOk:(id)data {
    if (_onSubmitOkCallback) {
        _onSubmitOkCallback(self, data);
    }
}

- (void)onShow {
    if (_onShowCallback) {
        _onShowCallback(self);
    }
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
    return field.isInput || field.action != nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self clearFieldFocus];
    _focusedFieldIdx = indexPath.row;
    IFFormField *field = [_fields objectAtIndex:_focusedFieldIdx];
    [field takeFieldFocus];
    if (field.action) {
        [_actionDispatcher dispatchURI:field.action];
    }
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
