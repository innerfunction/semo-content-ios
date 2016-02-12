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
    UITextField *_input;
}

@property (nonatomic, assign) BOOL isPassword;
@property (nonatomic, assign) BOOL isEditable;

@end
