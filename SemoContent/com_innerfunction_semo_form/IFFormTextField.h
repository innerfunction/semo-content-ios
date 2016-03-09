//
//  IFFormTextField.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"

@interface IFFormTextField : IFFormField <UITextFieldDelegate> {
    UIView *_inputContentView;
    UILabel *_invalidWarning;
    NSTextAlignment _defaultTitleAlignment;
    BOOL _valid;
}

@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, assign) BOOL isEditable;
@property (nonatomic, assign) BOOL isRequired;
@property (nonatomic, strong) NSString *hasSameValueAs;
@property (nonatomic, readonly) UITextField *input;

@end
