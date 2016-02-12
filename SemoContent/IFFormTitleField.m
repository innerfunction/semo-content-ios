//
//  IFFormTitleField.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormTitleField.h"

@implementation IFFormTitleField

- (void)setValue:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        value = [value description];
    }
    super.value = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textLabel.text = value;
    });
}

@end
