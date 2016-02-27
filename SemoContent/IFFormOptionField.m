//
//  IFFormOptionField.m
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormOptionField.h"
#import "IFFormView.h"

@implementation IFFormOptionField

- (void)setOptionSelected:(BOOL)optionSelected {
    _optionSelected = optionSelected;
    dispatch_async(dispatch_get_main_queue(), ^{
         self.accessoryType = _optionSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    });
}

- (BOOL)isSelectable {
    return YES;
}

- (void)selectField {
    NSArray *fieldGroup = [self.form getFieldsInNameGroup:self.name];
    for (IFFormOptionField *field in fieldGroup) {
        field.optionSelected = NO;
        field.value = nil;
    }
    self.optionSelected = YES;
    self.value = self.optionValue;
}

@end
