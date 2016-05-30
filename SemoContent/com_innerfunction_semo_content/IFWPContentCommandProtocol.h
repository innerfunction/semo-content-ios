//
//  IFSemoWPProtocol.h
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommandProtocol.h"
#import "IFDB.h"

@interface IFWPContentCommandProtocol : IFCommandProtocol {
    // The file manager.
    NSFileManager *_fileManager;
    // Path to file used to store downloaded feed result.
    NSString *_feedFile;
    // Path to file used to store downloaded base content zip.
    NSString *_baseContentFile;
    // Path to store downloaded content prior to deployment.
    NSString *_stagedContentPath;
    // A flag indicating that a refresh is in progress.
    BOOL _refreshInProgress;
}

/** The WP feed URL. Note that query parameters will be appened to the URL. */
@property (nonatomic, strong) NSString *feedURL;
/** A URL for doing a bulk-download of initial image content. */
@property (nonatomic, strong) NSString *imagePackURL;
/** The local database used to store post and content data. */
@property (nonatomic, strong) IFDB *postDB;
/** Path to directory holding staged content. */
@property (nonatomic, strong) NSString *stagingPath;
/** Path to directory holding base content. */
@property (nonatomic, strong) NSString *baseContentPath;
/** Path to directory containing pre-packaged content. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** Path to directory hosting downloaded content. */
@property (nonatomic, strong) NSString *contentPath;

@end
