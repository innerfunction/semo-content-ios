//
//  IFFormTextField.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"
#import "IFTextStyle.h"

@interface IFFormTextField : IFFormField <UITextFieldDelegate> {
    UIView *_inputContentView;
    UITextField *_input;
    NSTextAlignment _defaultTitleAlignment;
}

@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, assign) BOOL isEditable;
@property (nonatomic, strong) IFTextStyle *inputStyle;

@end
