//
//  IFContentTableViewController.m
//  SemoContent
//
//  Created by Julian Goacher on 27/01/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentTableViewController.h"
#import "IFStringTemplate.h"
#import "IFHTMLString.h"
#import "NSDictionary+IFValues.h"

@interface IFContentTableViewController ()

- (void)configureCell:(IFContentTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;
- (NSString *)reuseIdentifier;

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
        [self.tableView registerClass:[IFContentTableViewCell class] forCellReuseIdentifier:@"title"];
        _showRowContent = NO;
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
    cell.title = data[@"title"];
    if (_showRowContent) {
        cell.content = data[@"content"];
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

- (NSString *)reuseIdentifier {
    return _showRowContent ? @"content" : @"title";
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_layoutCell) {
        NSString *reuseIdentifier = [self reuseIdentifier];
        _layoutCell = (IFContentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
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
    NSString *reuseIdentifier = [self reuseIdentifier];
    IFContentTableViewCell *cell = (IFContentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

@end

@implementation IFContentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    BOOL contentMode = [@"content" isEqualToString:reuseIdentifier];
    style = contentMode ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    // TODO: Fix detail view to 3 lines - this is a temp measure because of problems calculating row height.
    //self.imageView.hidden = contentMode;
    self.detailTextLabel.numberOfLines = 3;
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
    IFHTMLString *html = [[IFHTMLString alloc] initWithString:content];
    html.inlineParagraphs = YES;
    [html parse];
    self.detailTextLabel.attributedText = [html asAttributedString];
}

- (CGFloat)height {
    [self layoutIfNeeded];
    CGFloat height;
    if (self.detailTextLabel) {
        CGRect detailFrame = self.detailTextLabel.frame;
        // NOTE height is calculated here as the vertical offset of the detail label + its height + a small
        // vertical padding constant.
//        height = detailFrame.origin.y + detailFrame.size.height + 10.0f;
        CGRect textFrame = self.textLabel.frame;
        height = 5.0f + textFrame.size.height + 5.0f + detailFrame.size.height + 5.0f;
    }
    else {
        height = self.textLabel.bounds.size.height;
    }
    return height;
}

#pragma mark - overloads

- (void)layoutSubviews {
    CGFloat layoutWidth = self.contentView.bounds.size.width;
    CGSize contentSize = [self.detailTextLabel sizeThatFits:CGSizeMake(layoutWidth, CGFLOAT_MAX)];
//    self.detailTextLabel.bounds = CGRectMake(0.0f, 0.0f, self.detailTextLabel.bounds.size.width, contentSize.height);
//    CGRect titleFrame = self.textLabel.frame;
//    CGFloat y = titleFrame.origin.y + titleFrame.size.height + 10.0f;
//    self.detailTextLabel.frame = CGRectMake(0.0f, y, contentSize.width, contentSize.height);
    self.detailTextLabel.bounds = CGRectMake(0.0f, 0.0f, contentSize.width, contentSize.height);
    [super layoutSubviews];
}

@end
