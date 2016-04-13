//
//  IFFormSelectField.m
//  SemoContent
//
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormSelectField.h"
#import "IFFormView.h"

@implementation IFFormSelectItemsViewController

- (id)init {
    IFConfiguration *config = [[IFConfiguration alloc] initWithData:@{}];
    self = [self initWithConfiguration:config];
    if (self) {
        [self afterIOCConfiguration:config];
        _selectedIndex = -1;
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                      target:self
                                                                      action:@selector(cancel)];
    }
    return self;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    if (selectedIndex > -1) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = _parentField.title;
    self.navigationItem.rightBarButtonItem = _cancelButton;
    // Copy navigation bar style from the form's view controller.
    UINavigationBar *parentNavBar = _parentField.form.viewController.navigationController.navigationBar;
    UINavigationBar *ownNavBar = self.navigationController.navigationBar;
    ownNavBar.tintColor = parentNavBar.tintColor;
    ownNavBar.barTintColor = parentNavBar.barTintColor;
    ownNavBar.titleTextAttributes = parentNavBar.titleTextAttributes;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self.tableData rowDataForIndexPath:indexPath];
    _parentField.selectedItem = item;
    [_parentField releaseFieldFocus];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == _selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)cancel {
    [_parentField releaseFieldFocus];
}

@end

@implementation IFFormSelectField

@synthesize iocContainer=_iocContainer;

- (id)init {
    self = [super init];
    if (self) {
        self.isEditable = NO; // Disable text field editing.
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _itemsListConfig = [[IFConfiguration alloc] initWithData:@{}];
    }
    return self;
}

- (void)setItems:(NSArray *)items {
    // Ensure that each select item has a title and value. If either property is missing
    // then use the other to provide a value. Promote strings to title + values. If title
    // or value can't be resolved then don't add the item to the list.
    NSMutableArray *mitems = [[NSMutableArray alloc] initWithCapacity:[items count]];
    for (id item in items) {
        if ([item isKindOfClass:[NSString class]]) {
            [mitems addObject:@{ @"title": item, @"value": item }];
        }
        else if ([item isKindOfClass:[NSDictionary class]]) {
            if (item[@"title"]) {
                if (item[@"value"]) {
                    [mitems addObject:item];
                }
                else {
                    NSMutableDictionary *mitem = [item mutableCopy];
                    mitem[@"value"] = mitem[@"title"];
                    [mitems addObject:mitem];
                }
            }
            else if (item[@"value"]) {
                NSMutableDictionary *mitem = [item mutableCopy];
                mitem[@"title"] = mitem[@"value"];
                [mitems addObject:mitem];
            }
        }
    }
    _items = mitems;
    // Reset the null item to add it to the start of the new items array.
    self.nullItem = _nullItem;
    
}

- (void)setNullItem:(id)nullItem {
    if ([nullItem isKindOfClass:[NSString class]]) {
        _nullItem = @{ @"title": nullItem };
    }
    else if ([nullItem isKindOfClass:[NSDictionary class]]) {
        _nullItem = nullItem;
    }
    if (_items && _nullItem) {
        // Prepend the null item to the start of the items array.
        _items = [@[ nullItem ] arrayByAddingObjectsFromArray:_items];
    }
}

- (void)setSelectedItem:(NSDictionary *)selectedItem {
    _selectedItem = selectedItem;
    super.value = selectedItem[@"value"];
}

- (id)valueLabel {
    return _selectedItem ? _selectedItem[@"title"] : @"";
}

- (BOOL)isSelectable {
    return YES;
}

- (BOOL)takeFieldFocus {
    // Try to find index of selected list item.
    NSInteger selectedIndex = -1;
    if (self.value == nil && self.nullItem) {
        selectedIndex = 0;
    }
    else for (NSInteger i = 0; i < [_items count]; i++) {
        id item = [_items objectAtIndex:i];
        if ([item[@"value"] isEqual:self.value]) {
            selectedIndex = i;
            break;
        }
    }
    
    // Create the select list.
    _itemsList = [IFFormSelectItemsViewController new];
    _itemsList.parentField = self;
    _itemsList.content = _items;
    _itemsList.selectedIndex = selectedIndex;

    // Present the select list in a modal pop-over with a navigation bar.
    _itemsListContainer = [[UINavigationController alloc] initWithRootViewController:_itemsList];
    _itemsListContainer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    _itemsListContainer.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    [self.form.viewController presentViewController:_itemsListContainer animated:YES completion:^{}];
    
    return YES;
}

- (void)releaseFieldFocus {
    if (_itemsList) {
        [self.form.viewController dismissViewControllerAnimated:_itemsListContainer completion:^{
            _itemsList = nil;
        }];
    }
}

- (BOOL)validate {
    return YES;
}

#pragma mark - IFIOCContainerAware

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {
    self.selectedItem = self.nullItem;
    // Check for default/initial value, set the field title accordingly.
    if (self.value == nil) {
        for (NSDictionary *item in _items) {
            if (item[@"defaultValue"]) {
                self.selectedItem = item;
                break;
            }
        }
    }
    else {
        for (NSDictionary *item in _items) {
            if ([item[@"value"] isEqualToString:self.value]) {
                self.selectedItem = item;
                break;
            }
        }
    }
}

@end
