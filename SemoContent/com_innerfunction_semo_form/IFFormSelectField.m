//
//  IFFormSelectField.m
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormSelectField.h"
#import "IFFormView.h"

#define PickerHeight        (100.0f)
#define AnimationDuration   (0.5f)

@implementation IFFormSelectFieldItem

- (void)setTitle:(NSString *)title {
    _title = title;
    if (_value == nil) {
        _value = title;
    }
}

- (void)setValue:(id)value {
    _value = value;
    if (_title == nil) {
        _title = value;
    }
}

@end

@implementation IFFormSelectField

- (id)init {
    self = [super init];
    if (self) {
        _picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, PickerHeight)];
        _picker.dataSource = self;
        _picker.delegate = self;
        
        _picker.hidden = YES;
        _picker.backgroundColor = [UIColor whiteColor];
        //_picker.layer.opacity = 0.0f;
        _picker.userInteractionEnabled = NO;
        
        self.backgroundColor = [UIColor yellowColor];
        [self addSubview:_picker];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    CGFloat height = _picker.hidden ? 60.0f : PickerHeight;
    self.contentView.frame = CGRectMake(0, 0, bounds.size.width, height);
    self.textLabel.frame = self.contentView.bounds;
    bounds = self.bounds;
    _picker.frame = CGRectMake(0, 0, bounds.size.width, PickerHeight);
    NSLog(@"%f",height);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (BOOL)isSelectable {
    return YES;
}

- (BOOL)takeFieldFocus {
    self.height = @PickerHeight;
    [self.form notifyFormFieldResize:self];
    [UIView animateWithDuration:AnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         _picker.hidden = NO;
                     }
                     completion:^(BOOL finished) {
                         [self bringSubviewToFront:_picker];
                         [_picker becomeFirstResponder];
                     }];
    return YES;
}

- (void)releaseFieldFocus {
    [_picker resignFirstResponder];
    // Animate the picker disappearing from the bottom of the screen.
    [UIView animateWithDuration:AnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         _picker.hidden = YES;
                     }
                     completion:^(BOOL finished) {
                         self.height = @60.0f;
                         [self.form notifyFormFieldResize:self];
                     }];
}

#pragma mark - IFIOCTypeInspectable

- (Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"items" isEqualToString:propertyName]) {
        // Return the type class of the 'items' array members.
        return [IFFormSelectFieldItem class];
    }
    return nil;
}

#pragma mark - IFIOCConfigurable

- (void)beforeConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {}

- (void)afterConfiguration:(IFConfiguration *)configuration inContainer:(IFContainer *)container {
    // Check for default/initial value, set the field title accordingly.
    if (self.value == nil) {
        for (IFFormSelectFieldItem *item in _items) {
            if (item.defaultValue) {
                self.value = item.value;
                self.title = item.title;
                break;
            }
        }
    }
    else {
        for (IFFormSelectFieldItem *item in _items) {
            if ([item.value isEqualToString:self.value]) {
                self.title = item.title;
                break;
            }
        }
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_items count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    IFFormSelectFieldItem *item = [_items objectAtIndex:row];
    return item.title;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    IFFormSelectFieldItem *item = [_items objectAtIndex:row];
    self.value = item.value;
    self.title = item.title;
}

@end
