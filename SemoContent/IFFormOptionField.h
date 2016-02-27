//
//  IFFormOptionField.h
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"

@interface IFFormOptionField : IFFormField

@property (nonatomic, assign) BOOL optionSelected;
@property (nonatomic, strong) NSString *optionValue;

@end
