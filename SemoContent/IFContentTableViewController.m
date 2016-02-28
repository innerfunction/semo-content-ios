//
//  IFContentTableViewController.m
//  SemoContent
//
//  Created by Julian Goacher on 27/01/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentTableViewController.h"
#import "IFStringTemplate.h"
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
        [self.tableView registerClass:[IFContentTableViewCell class] forCellReuseIdentifier:@"content"];
        _showContent = YES;
    }
    return self;
}

#pragma mark - Overridden methods

- (void)setContent:(id)content {
    if (_dataFormatter) {
        content = [_dataFormatter formatData:content];
    }
    [super setContent:content];
}

#pragma mark - private methods

- (void)configureCell:(IFContentTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.tableData rowDataForIndexPath:indexPath];
    cell.title = [data getValueAsString:@"title"];
    if (_showContent) {
        cell.content = [data getValueAsString:@"content"];
    }
    
    CGFloat imageHeight = [[data getValueAsNumber:@"imageHeight" defaultValue:_rowImageHeight] floatValue];
    if (!imageHeight) {
        imageHeight = 40.0f;
    }
    CGFloat imageWidth = imageHeight;
    if ([data hasValue:@"imageWidth"]) {
        imageWidth = [[data getValueAsNumber:@"imageWidth" defaultValue:_rowImageWidth] floatValue];
    }
    UIImage *image = [self loadImageWithRowData:data dataName:@"image" width:imageWidth height:imageHeight defaultImage:_rowImage];
    if (image) {
        cell.imageView.image = image;
        // Add rounded corners to image.
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 3.0;
    }
    else {
        cell.imageView.image = nil;
    }

    if (_action || [data hasValue:@"action"]) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.tableData rowDataForIndexPath:indexPath];
    // Check for action on cell data.
    NSString *action = [data getValueAsString:@"action"];
    // If no action on cell data, but action defined on table then eval as a template on the cell data.
    if (!action && _action) {
        action = [IFStringTemplate render:_action context:data uriEncode:YES];
    }
    // If we have an action then dispatch it.
    if (action) {
        [self postMessage:action];
    }
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
    [self layoutIfNeeded];
    CGSize titleSize = self.textLabel.bounds.size;
    CGFloat width = self.detailTextLabel.bounds.size.width;
    CGSize contentSize = [self.detailTextLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    return titleSize.height + contentSize.height;
}

#pragma mark - overloads

- (void)layoutSubviews {
    self.detailTextLabel.bounds = CGRectMake(0.0f, 0.0f, self.detailTextLabel.bounds.size.width, self.height);
    [super layoutSubviews];
}

@end