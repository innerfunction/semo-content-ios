//
//  IFFormView.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormView.h"

@implementation IFFormView

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

- (NSDictionary *)getInputValues {
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    for (IFFormField *field in _fields) {
        if (field.isInput && field.name && field.value != nil) {
            [values setObject:field.value forKey:field.name];
        }
    }
    return values;
}

#pragma mark - IFActionDispatcher

- (BOOL)dispatchURI:(NSString *)uri {
    return NO;
}

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
    NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndex:_focusedFieldIdx];
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
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    IFFormField *field = [_fields objectAtIndex:_focusedFieldIdx];
    [field releaseFieldFocus];
    if (field.action) {
        // TODO: Dispatch action
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFFormField *field = [_fields objectAtIndex:indexPath.row];
    return [field.height floatValue];
}

@end
