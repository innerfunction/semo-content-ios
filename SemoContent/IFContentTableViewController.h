//
//  IFContentTableViewController.h
//  SemoContent
//
//  Created by Julian Goacher on 27/01/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFTableViewController.h"
#import "IFDataFormatter.h"

@class IFContentTableViewCell;

@interface IFContentTableViewController : IFTableViewController {
    IFContentTableViewCell *_layoutCell;
}

@property (nonatomic, strong) id<IFDataFormatter> dataFormatter;
@property (nonatomic, strong) NSString *action;

@end
