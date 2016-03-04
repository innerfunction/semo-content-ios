//
//  IFFormHiddenField.m
//  SemoContent
//
//  Created by Julian Goacher on 28/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormHiddenField.h"

@implementation IFFormHiddenField

- (id)init {
    self = [super init];
    if (self) {
        self.isInput = YES;
        self.height = @0;
    }
    return self;
}

@end
