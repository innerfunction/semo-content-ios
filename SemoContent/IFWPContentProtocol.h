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

@interface IFWPContentProtocol : IFProtocol {
    // Path to file used to store downloaded feed result.
    NSString *_feedFile;
    // Path to file used to store downloaded base content zip.
    NSString *_baseContentFile;
    // Path to store downloaded content prior to deployment.
    NSString *_stagedContentPath;
}

/** The WP feed URL. Note that query parameters will be appened to the URL. */
@property (nonatomic, strong) NSString *feedURL;
/** The local database used to store post and content data. */
@property (nonatomic, strong) IFDB *postDB;
/** Path to directory holding staged content. */
@property (nonatomic, strong) NSString *stagingPath;
/** Path to directory hosting downloaded content. */
@property (nonatomic, strong) NSString *contentPath;

@end
