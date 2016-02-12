//
//  IFFormImageField.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"

@interface IFFormImageField : IFFormField {
    UIImageView *_imageView;
}

@property (nonatomic, strong) UIImage *image;

@end
