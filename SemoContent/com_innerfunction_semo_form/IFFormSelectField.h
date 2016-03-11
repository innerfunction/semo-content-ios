//
//  IFFormSelectField.h
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormTextField.h"
#import "IFTableViewController.h"

@class IFFormSelectField;

@interface IFFormSelectItemsViewController : IFTableViewController {
    UIBarButtonItem *_cancelButton;
}

@property (nonatomic, weak) IFFormSelectField *parentField;
@property (nonatomic, assign) NSInteger selectedIndex;

- (void)cancel;

@end

@interface IFFormSelectField : IFFormTextField <IFIOCConfigurable> {
    IFConfiguration *_itemsListConfig;
    IFFormSelectItemsViewController *_itemsList;
    UINavigationController *_itemsListContainer;
}

@property (nonatomic, strong) NSArray *items;

@end
