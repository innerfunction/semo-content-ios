//
//  IFFormSelectField.h
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"
#import "IFIOCTypeInspectable.h"
#import "IFIOCConfigurable.h"

@interface IFFormSelectFieldItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) BOOL defaultValue;

@end

@interface IFFormSelectField : IFFormField <IFIOCTypeInspectable, IFIOCConfigurable, UIPickerViewDataSource, UIPickerViewDelegate> {
    UIPickerView *_picker;
}

@property (nonatomic, strong) NSArray *items;

@end
