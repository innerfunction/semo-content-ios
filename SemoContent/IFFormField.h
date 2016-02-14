//
//  IFFormTableViewCell.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IFFormView;

#define IFFormFieldReuseID  (NSStringFromClass([self class]))

@interface IFFormField : UITableViewCell

@property (nonatomic, weak) IFFormView *form;
@property (nonatomic, assign) BOOL isInput;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *focusedBackgroundImage;

- (BOOL)takeFieldFocus;
- (void)releaseFieldFocus;
- (BOOL)validate;

@end
