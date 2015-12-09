//
//  IFSemoWPProtocol.h
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFProtocol.h"
#import "IFDB.h"

@interface IFSemoWPProtocol : IFProtocol {
    // Path to file used to store downloaded feed result.
    NSString *_feedFile;
    
    // TODO: Following should probably be configurable properties
    // Path to file used to store downloaded base content zip.
    NSString *_baseContentFile;
    // Path to directory holding staged content.
    NSString *_stagingPath;
    // Path to directory hosting downloaded content.
    NSString *_contentPath;
}

/** The WP feed URL. Note that query parameters will be appened to the URL. */
@property (nonatomic, strong) NSString *feedURL;
/** The local database used to store post and content data. */
@property (nonatomic, strong) IFDB *postDB;

@end