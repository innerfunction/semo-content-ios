//
//  IFFormTableViewCell.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"

@implementation IFFormField

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:IFFormFieldReuseID];
    if (self) {
        self.isInput = NO;
    }
    return self;
}

- (BOOL)takeFieldFocus {
    return NO;
}

- (void)releaseFieldFocus {}

#pragma mark - Overrides

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
