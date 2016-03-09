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
#define InvalidWarningWidth (25.0f)

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
        
        _invalidWarning = [[UILabel alloc] init];
        _invalidWarning.text = @"\u26A0";
        _invalidWarning.textAlignment = NSTextAlignmentRight;
        _invalidWarning.hidden = YES;
        [self addSubview:_invalidWarning];
        
        _valid = YES;
        
        _defaultTitleAlignment = -1;
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    super.title = title;
    self.textLabel.text = title;
    _input.placeholder = title;
}

- (void)setIsPassword:(BOOL)isPassword {
    _isPassword = isPassword;
    _input.secureTextEntry = isPassword;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = CGRectInset( self.contentView.bounds, Padding, Padding);
    
    self.textLabel.frame = frame;
    
    CGFloat detailTextLabelWidth = frame.size.width - InvalidWarningWidth;
    self.detailTextLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, detailTextLabelWidth, frame.size.height);
    _invalidWarning.frame = CGRectMake(frame.origin.x + detailTextLabelWidth, frame.origin.y, InvalidWarningWidth, frame.size.height);

    _inputContentView.frame = self.contentView.bounds;
    _input.frame = frame;
}

- (void)setValue:(id)value {
    // Record the title label's default text alignement if not already recorded.
    if (_defaultTitleAlignment < 0) {
        _defaultTitleAlignment = self.textLabel.textAlignment;
    }
    // Ensure the value is a string.
    if (![value isKindOfClass:[NSString class]]) {
        value = [value description];
    }
    super.value = value;
    NSString *valueLabel = value;
    BOOL hasValue = [value length] > 0;
    // Mark value if field is a password input.
    if (_isPassword) {
        NSMutableString *password = [[NSMutableString alloc] initWithCapacity:[value length]];
        for (NSInteger i = 0; i < [value length]; i++) {
            [password appendString:@"\u25CF"];
        }
        valueLabel = password;
    }
    // Display the value.
    dispatch_async(dispatch_get_main_queue(), ^{
        _input.text = value;
        self.textLabel.textAlignment = hasValue ? NSTextAlignmentLeft : _defaultTitleAlignment;
        self.detailTextLabel.text = valueLabel;
        // Check whether sufficient room to display both detail and text labels, hide the text label if not.
        CGFloat textWidth = [self.textLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.textLabel.font }].width;
        CGFloat labelWidth = [self.detailTextLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.detailTextLabel.font }].width;
        self.textLabel.hidden = self.contentView.bounds.size.width - labelWidth - textWidth < Padding;
    });
    [self validate];
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
                            if (!_valid) {
                                // TODO: Proper error messages
                                [self.form notifyError:@"Invalid field"];
                            }
                        }];
    }
    return focusable;
}

- (void)releaseFieldFocus {
    if ([_input isFirstResponder]) {
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
}

- (BOOL)validate {
    _valid = YES;
    if (_isRequired && [self.value length] == 0) {
        _valid = NO;
    }
    else if (_hasSameValueAs) {
        id otherValue = [self.form getFieldValue:_hasSameValueAs];
        _valid = [self.value isEqual:otherValue];
    }
    _invalidWarning.hidden = _valid;
    return _valid;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.value = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.value = textField.text;
    [self.form moveFocusToNextField];
    return NO;
}

@end
