//
//  IFTextStyle.h
//  SemoContent
//
//  Created by Julian Goacher on 17/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IFTextStyle : NSObject

@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) NSNumber *fontSize;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) NSString *textAlign;

- (void)applyToLabel:(UILabel *)label;
- (void)applyToTextField:(UITextField *)textField;

@end
