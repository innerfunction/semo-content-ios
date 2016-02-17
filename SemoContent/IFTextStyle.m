//
//  IFTextStyle.m
//  SemoContent
//
//  Created by Julian Goacher on 17/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFTextStyle.h"

#define DefaultFontSize (17.0f)

@implementation IFTextStyle

- (void)applyToLabel:(UILabel *)label {
    CGFloat fontSize = DefaultFontSize;
    if (_fontSize) {
        fontSize = [_fontSize floatValue];
    }
    if (_fontName) {
        label.font = [UIFont fontWithName:_fontName size:fontSize];
    }
    else {
        label.font = [UIFont systemFontOfSize:fontSize];
    }
    if (_textColor) {
        label.textColor = _textColor;
    }
    if (_backgroundColor) {
        label.backgroundColor = _backgroundColor;
    }
    if ([@"right" isEqualToString:_textAlign]) {
        label.textAlignment = NSTextAlignmentRight;
    }
    else if ([@"center" isEqualToString:_textAlign]) {
        label.textAlignment = NSTextAlignmentCenter;
    }
    else {
        label.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)applyToTextField:(UITextField *)textField {
    CGFloat fontSize = DefaultFontSize;
    if (_fontSize) {
        fontSize = [_fontSize floatValue];
    }
    if (_fontName) {
        textField.font = [UIFont fontWithName:_fontName size:fontSize];
    }
    else {
        textField.font = [UIFont systemFontOfSize:fontSize];
    }
    if (_textColor) {
        textField.textColor = _textColor;
    }
    if (_backgroundColor) {
        textField.backgroundColor = _backgroundColor;
    }
    if ([@"right" isEqualToString:_textAlign]) {
        textField.textAlignment = NSTextAlignmentRight;
    }
    else if ([@"center" isEqualToString:_textAlign]) {
        textField.textAlignment = NSTextAlignmentCenter;
    }
    else {
        textField.textAlignment = NSTextAlignmentLeft;
    }
}

@end
