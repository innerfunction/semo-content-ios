//
//  IFSubmitField.m
//  SemoContent
//
//  Created by Julian Goacher on 23/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFSubmitField.h"

@implementation IFSubmitField

- (id)init {
    self = [super init];
    if (self) {
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _loadingIndicator.hidden = YES;
        [self.contentView addSubview:_loadingIndicator];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _loadingIndicator.frame = self.contentView.bounds;
}

- (void)showFormLoading:(BOOL)loading {
    if (loading) {
        [_loadingIndicator startAnimating];
    }
    else {
        [_loadingIndicator stopAnimating];
    }
}

@end
