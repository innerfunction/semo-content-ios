//
//  IFFormViewController.m
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormViewController.h"

@implementation IFFormViewController

- (id)init {
    self = [super init];
    if (self) {
        _form = [[IFFormView alloc] init];
        _form.backgroundColor = [UIColor clearColor];
        self.view = _form;
        self.view.autoresizesSubviews = YES;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _form.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor {
    return _form.backgroundColor;
}

#pragma mark - View lifecycle methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_form onShow];
}

@end
