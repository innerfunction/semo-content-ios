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

- (id)init {
    self = [super init];
    if (self) {
        self.isInput = YES;
    }
    return self;
}

- (void)setOptionSelected:(BOOL)optionSelected {
    _optionSelected = optionSelected;
    self.value = optionSelected ? self.optionValue : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
         self.accessoryType = _optionSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    });
}

- (void)setOptionValue:(NSString *)optionValue {
    _optionValue = optionValue;
    if (_optionSelected) {
        self.value = optionValue;
    }
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
}

@end
