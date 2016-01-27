//
//  IFContentTableViewController.m
//  SemoContent
//
//  Created by Julian Goacher on 27/01/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentTableViewController.h"
#import "NSDictionary+IFValues.h"

@interface IFContentTableViewController ()

- (void)configureCell:(IFContentTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end

@interface IFContentTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, readonly) CGFloat height;

@end

@implementation IFContentTableViewController

#pragma mark - IFIOCConfigurationInitable

- (id)initWithConfiguration:(IFConfiguration *)configuration {
    self = [super initWithConfiguration:configuration];
    if (self) {
        [(UITableView *)self registerClass:[IFContentTableViewCell class] forCellReuseIdentifier:@"content"];
    }
    return self;
}

#pragma mark - private methods

- (void)configureCell:(IFContentTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.tableData rowDataForIndexPath:indexPath];
    cell.title = [data getValueAsString:@"title"];
    cell.content = [data getValueAsString:@"content"];
    if ([data hasValue:@"action"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_layoutCell) {
        _layoutCell = (IFContentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"content"];
    }
    [self configureCell:_layoutCell forIndexPath:indexPath];
    return _layoutCell.height;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFContentTableViewCell *cell = (IFContentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"content"];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

@end

@implementation IFContentTableViewCell

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"content"];
    self.imageView.hidden = YES;
    self.detailTextLabel.numberOfLines = 0;
    return self;
}

- (NSString *)title {
    return self.textLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.textLabel.text = title;
}

- (NSString *)content {
    return self.detailTextLabel.attributedText.description;
}

- (void)setContent:(NSString *)content {
    NSAttributedString *asContent = [[NSAttributedString alloc] initWithString:content attributes:@{}];
    self.detailTextLabel.attributedText = asContent;
}

- (CGFloat)height {
    CGFloat width = self.detailTextLabel.bounds.size.width;
    CGSize contentSize = [self.detailTextLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    return contentSize.height;
}

#pragma mark - overloads

- (void)layoutSubviews {
    self.detailTextLabel.bounds = CGRectMake(0.0f, 0.0f, self.detailTextLabel.bounds.size.width, self.height);
    [super layoutSubviews];
}

@end