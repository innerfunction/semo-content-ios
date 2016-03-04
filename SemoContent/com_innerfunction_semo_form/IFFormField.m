//
//  IFFormTableViewCell.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"
#import "IFFormView.h"
#import "IFAppContainer.h"

@implementation IFFormField

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:IFFormFieldReuseID];
    if (self) {
        self.isInput = NO;
        self.height = @45.0f;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.isInput = NO;
        self.height = @45.0f;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setValue:(id)value {
    _value = value;
}

- (void)setTitle:(NSString *)title {
    self.textLabel.text = title;
}

- (NSString *)title {
    return self.textLabel.text;
}

- (void)setTitleStyle:(IFTextStyle *)titleStyle {
    _titleStyle = titleStyle;
    [_titleStyle applyToLabel:self.textLabel];
}

- (BOOL)isSelectable {
    return self.isInput || self.action != nil;
}

// TODO: The UITableViewCell class does have a backgroundColor property, but this isn't being detected by
// the container when configuring form fields; need to investigate in IFTypeInfo if there is a reason for this.
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    super.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor {
    return super.backgroundColor;
}

- (BOOL)takeFieldFocus {
    return NO;
}

- (void)releaseFieldFocus {}

- (BOOL)validate {
    return YES;
}

- (void)selectField {
    if (_action) {
        [IFAppContainer postMessage:_action sender:self];
    }
}

#pragma mark - Overrides

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
