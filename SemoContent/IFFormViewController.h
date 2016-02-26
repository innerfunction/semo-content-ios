//
//  IFFormViewController.h
//  SemoContent
//
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFViewController.h"
#import "IFFormView.h"

@interface IFFormViewController : IFViewController

@property (nonatomic, strong, readonly) IFFormView *form;
@property (nonatomic, strong) UIColor *backgroundColor;

@end
