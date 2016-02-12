//
//  IFFormView.h
//  SemoContent
//
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFFormField.h"
#import "IFActionDispatcher.h"

@interface IFFormView : UITableView <UITableViewDataSource, UITableViewDelegate, IFActionDispatcher> {
    NSInteger _focusedFieldIdx;
    UIEdgeInsets _defaultInsets;
}

@property (nonatomic, strong) NSArray *fields;

- (IFFormField *)getFocusedField;
- (void)clearFieldFocus;
- (void)moveFocusToNextField;
- (NSDictionary *)getInputValues;

@end
