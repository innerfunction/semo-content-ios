//
//  IFFormImageField.m
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormImageField.h"

@implementation IFFormImageField

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:IFFormFieldReuseID];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    _imageView.image = image;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.contentView.frame;
}

@end
