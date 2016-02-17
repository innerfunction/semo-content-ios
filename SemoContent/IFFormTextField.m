//
//  IFFormTextField.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormTextField.h"
#import "IFFormView.h"

#define Padding             (10.0f)
#define AnimationDuration   (0.33f)

@implementation IFFormTextField

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:IFFormFieldReuseID];
    if (self) {
        self.isInput = YES;
        self.isEditable = YES;
        
        _inputContentView = [[UIView alloc] init];
        _input = [[UITextField alloc] init];
        _input.delegate = self;

        [_inputContentView addSubview:_input];
        _inputContentView.hidden = YES;
        [self addSubview:_inputContentView];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    super.title = title;
    self.textLabel.text = title;
    _input.placeholder = title;
}

- (void)setInputStyle:(IFTextStyle *)inputStyle {
    _inputStyle = inputStyle;
    [_inputStyle applyToTextField:_input];
}

- (void)setIsPassword:(BOOL)isPassword {
    _isPassword = isPassword;
    _input.secureTextEntry = isPassword;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.contentView.bounds;
    self.textLabel.frame = frame;
    _inputContentView.frame = frame;
    _input.frame = CGRectMake(Padding, Padding, frame.size.width - (Padding * 2), frame.size.height - (Padding * 2));
}

// TODO Set input's keyboard, capitalization, spell checking and keyboard types.

- (void)setValue:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        value = [value description];
    }
    super.value = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_isPassword) {
            NSMutableString *password = [[NSMutableString alloc] initWithCapacity:[value length]];
            for (NSInteger i = 0; i < [value length]; i++) {
                [password appendString:@"\u25CF"];
            }
            self.detailTextLabel.text = password;
        }
        else {
            self.detailTextLabel.text = value;
        }
        _input.text = value;
    });
}

- (BOOL)takeFieldFocus {
    BOOL focusable = _isEditable && self.form.isEnabled;
    if (focusable) {
        // Animate transition to edit view.
        [UIView transitionWithView: self
                          duration: AnimationDuration
                           options: UIViewAnimationOptionTransitionFlipFromTop + UIViewAnimationOptionCurveLinear
                        animations: ^{
                            self.contentView.hidden = YES;
                            _inputContentView.hidden = NO;
                        }
                        completion: ^(BOOL finished) {
                            [_input becomeFirstResponder];
                        }];
    }
    return focusable;
}

- (void)releaseFieldFocus {
    [_input resignFirstResponder];
    [UIView transitionWithView: self
                      duration: AnimationDuration
                       options: UIViewAnimationOptionTransitionFlipFromTop + UIViewAnimationOptionCurveLinear
                    animations: ^{
                        self.contentView.hidden = NO;
                        _inputContentView.hidden = YES;
                    }
                    completion: ^(BOOL finished) {
                    }];
}

- (BOOL)validate {
    // TODO: Actual validation should happen immediately after edit.
    // TODO: Initial validation is restricted to required field validation.
    // TODO: If a field is invalid, then an icon should be displayed next to the text input.
    // TODO: And a toast with the validation error should be displayed on focus and on leave focus.
    return YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.value = textField.text;
    [self.form moveFocusToNextField];
    return NO;
}

@end
