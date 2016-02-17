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
        self.view = _form;
        self.view.autoresizesSubviews = YES;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

#pragma mark - View lifecycle methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_form onShow];
}

@end
