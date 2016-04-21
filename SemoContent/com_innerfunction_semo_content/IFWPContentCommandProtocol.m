//
//  IFSemoWPProtocol.m
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentCommandProtocol.h"
#import "IFCommand.h"
#import "IFFileIO.h"
#import "NSString+IF.h"
#import "NSDictionary+IFValues.h"

#define BaseContentType (@"semo:base-content")
// Read an NSInteger value from a NSNumber stored in a dictionary.
#define AsInteger(name,data) ([[data getValueAsNumber:name] integerValue])

/* NOTES:
 * 1. Base content download: Currently this is processed in-line with the other attachment downloads;
 *    Should it instead be prioritized, perhaps done before the post content is deployed (i.e. loaded
 *    into the db)? Or is it probably OK for content styling to lag?
 * 2. Attachment downloads: If a single refresh generates a large number of attachment downloads then
 *    the resulting GET requests will probably trigger WP's DOS attack defenses (due to a large number
 *    of requests from the same client in a short period of time). This will result in all attachment
 *    requests failing past a certain point. This isn't necessarily a problem - if an image fails to
 *    download then the client code will re-request the image from the server again when a page
 *    containing the image is displayed. However, a well behaved client should attempt to avoid
 *    spamming the server, and should attempt to do multiple downloads within the server's limits.
 *    Alternatively, bulk downloads should be done when a large number of attachments needs to be
 *    downloaded.
 */
@interface IFWPContentCommandProtocol ()

- (QPromise *)refresh:(NSArray *)args;

- (QPromise *)continueDownload:(NSArray *)args;
- (QPromise *)deployDownload:(NSArray *)args;
/*
- (QPromise *)stage:(NSArray *)args;
- (QPromise *)deploy:(NSArray *)args;
*/
- (QPromise *)unpack:(NSArray *)args;

@end

@implementation IFWPContentCommandProtocol

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
        // Register command handlers.
        __block id this = self;
        [self addCommand:@"refresh" withBlock:^QPromise *(NSArray *args) {
            return [this refresh:args];
        }];
        
        [self addCommand:@"continue-download" withBlock:^QPromise *(NSArray *args) {
            return [this continueDownload:args];
        }];
        [self addCommand:@"deploy-download" withBlock:^QPromise *(NSArray *args) {
            return [this deployDownload:args];
        }];
        /*
        [self addCommand:@"stage" withBlock:^QPromise *(NSArray *args) {
            return [this stage:args];
        }];
        [self addCommand:@"deploy" withBlock:^QPromise *(NSArray *args) {
            return [this deploy:args];
        }];
        */
        [self addCommand:@"unpack" withBlock:^QPromise *(NSArray *args) {
            return [this unpack:args];
        }];
    }
    return self;
}

- (void)setPostDB:(IFDB *)postDB {
    // Use a new copy of the post DB. This it to ensure thread-safe access to the db.
    _postDB = [postDB newInstance];
}

- (void)setStagingPath:(NSString *)stagingPath {
    _stagingPath = stagingPath;
    _feedFile = [stagingPath stringByAppendingPathComponent:@"feed.json"];
    _baseContentFile = [stagingPath stringByAppendingPathComponent:@"base-content.zip"];
    _stagedContentPath = [stagingPath stringByAppendingPathComponent:@"content"];
}
/*
- (QPromise *)refresh:(NSArray *)args {
    NSArray *commands = @[];
    
    NSString *refreshURL = [_feedURL stringByAppendingString:@"/updates"];
    NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:@{ @"refreshURL": refreshURL }];
    refreshURL = _args[@"refreshURL"];
    
    // A follow-up refresh with 'since' and 'page' args is generated for multi-page feed results.
    // NOTE: It is important that the 'since' parameter is passed here so that each page of
    // the feed response is requested with the same starting position.
    id page = _args[@"page"];
    id since = _args[@"since"];
    BOOL doRefresh = YES; // Assume we're going to do a refresh.
    
    if (page && since) {
        // _refreshInProgress will normally be true here, but may be false if resuming after an app restart.
        since = [since stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        refreshURL = [NSString stringWithFormat:@"%@?page=%@&since=%@", refreshURL, page, since];
    }
    else if (_refreshInProgress) {
        // A refresh is already in progress, so don't start a new one.
        doRefresh = NO;
        NSLog(@"*** Refresh in progress ***");
    }
    else {
        // No refresh in progress, so OK to start a new one.
        // Query post DB for the last modified time.
        NSArray *rs = [_postDB performQuery:@"SELECT max(modified) FROM posts" withParams:@[]];
        if ([rs count] > 0) {
            // Previously downloaded posts exist, so read latest post modification time.
            NSDictionary *record = rs[0];
            NSString *modifiedTime = record[@"max(modified)"];
            // Construct feed URL with since parameter.
            modifiedTime = [modifiedTime stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            refreshURL = [NSString stringWithFormat:@"%@?since=%@", refreshURL, modifiedTime];
        }
        // If no posts, and no last modified time, then simply omit the 'since' parameter; the feed
        // will return all posts, starting at the earliest.
    }
    
    if (doRefresh) {
        // Flag a refresh in progress - note that may already be true if doing a multi-page refresh.
        _refreshInProgress = YES;
        // Construct get command with url and file name to write result to, with 3 retries.
        NSDictionary *getCommand = @{
            @"name":  @"get",
            @"args":  @[ refreshURL, _feedFile, @3 ]
        };
        // Construct process command to process download.
        NSDictionary *processCommand = @{
            @"name": [self qualifiedCommandName:@"stage"],
            @"args": @[]
        };
        commands = @[ getCommand, processCommand ];
    }
    
    // Return commands.
    return [Q resolve:commands];
}
*/
- (QPromise *)refresh:(NSArray *)args {
    NSArray *commands = @[];
    
    if (!_refreshInProgress) {

        _refreshInProgress = YES;
        
        NSString *refreshURL = [_feedURL stringByAppendingString:@"/updates"];
        NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:@{ @"refreshURL": refreshURL }];
        refreshURL = _args[@"refreshURL"];
    
        // Query post DB for the last modified time.
        NSArray *rs = [_postDB performQuery:@"SELECT max(modified) FROM posts" withParams:@[]];
        if ([rs count] > 0) {
            // Previously downloaded posts exist, so read latest post modification time.
            NSDictionary *record = rs[0];
            NSString *modifiedTime = record[@"max(modified)"];
            // Construct feed URL with since parameter.
            modifiedTime = [modifiedTime stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            refreshURL = [NSString stringWithFormat:@"%@?since=%@", refreshURL, modifiedTime];
        }
        // If no posts, and no last modified time, then simply omit the 'since' parameter; the feed
        // will return all posts, starting at the earliest.

        NSString *pageFile = [_stagingPath stringByAppendingPathComponent:@"page.json"];
        
        // Construct get command with url and file name to write result to, with 3 retries.
        id getCommand = @{
            @"name":  @"get",
            @"args":  @[ refreshURL, pageFile, @3 ]
        };
        // Construct process command to continue downloading the feed.
        id processCommand = @{
            @"name": [self qualifiedCommandName:@"continue-download"],
            @"args": @[ refreshURL, pageFile ]
        };
        commands = @[ getCommand, processCommand ];
    }
    
    // Return commands.
    return [Q resolve:commands];
}

- (QPromise *)continueDownload:(NSArray *)args {
    // Parse arguments. Allow the feed file path to be optionally specified as a command argument.
    NSDictionary *dargs = [self parseArgArray:args
                                     argOrder:@[ @"refreshURL", @"pageFile" ]
                                     defaults:@{}];
    NSString *refreshURL = dargs[@"refreshURL"];
    NSString *pageFile = dargs[@"pageFile"];

    // List of generated commands.
    NSArray *commands = @[];

    // Command to delete the current page file.
    id rmPageFileCommand = @{ @"name": @"rm", @"args": @[ pageFile ] };
    
    BOOL ok = YES;
    NSDictionary *pageData = nil;
    // Check that previous page download succeeded.
    if (![_fileManager fileExistsAtPath:pageFile]) {
        ok = NO;
    }
    else {
        // Read result of previous get.
        // Data format: { since:,  page: { size:, number:, count: }, items }
        pageData = [IFFileIO readJSONFromFileAtPath:pageFile encoding:NSUTF8StringEncoding];
        // Append page items to previously downloaded items.
        NSArray *pageItems = pageData[@"items"];
        NSArray *items = [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
        if (items) {
            items = [items arrayByAddingObjectsFromArray:pageItems];
        }
        else {
            items = pageItems;
        }
        // Write items to feed file.
        ok = [IFFileIO writeJSON:items toFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    }
    
    if (ok) {
        // Check for multi-page feed response, and whether a next page request needs to be issued.
        NSInteger pageCount = AsInteger(@"page.pageCount", pageData);
        NSInteger pageNumber = AsInteger(@"page.pageNumber", pageData);
        if (pageNumber < pageCount) {
            NSInteger page = pageNumber + 1;
            NSString *since = [pageData getValueAsString:@"parameters.since"];
            since = [since stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            NSString *downloadURL = [NSString stringWithFormat:@"%@?page=%ld&since=%@", refreshURL, page, since];
            // Construct get command with url and file name to write result to, with 3 retries.
            id getCommand = @{
                @"name": @"get",
                @"args": @[ downloadURL, pageFile, @2 ]
            };
            // Construct process command to continue downloading the feed.
            id continueCommand = @{
                @"name": [self qualifiedCommandName:@"continue-download"],
                @"args": @[ refreshURL, pageFile ]
            };
            commands = @[ rmPageFileCommand, getCommand, continueCommand ];
        }
        else {
            // All pages download, process the feed items next.
            id deployCommand = @{
                @"name": [self qualifiedCommandName:@"deploy-download"],
                @"args": @[]
            };
            commands = @[ rmPageFileCommand, deployCommand ];
        }
    }
    else {
        // Process failed for some reason; clean up and abort the download, try again on next refresh.
        [_fileManager removeItemAtPath:_feedFile error:nil];
        _refreshInProgress = NO;
    }
    
    // Return commands.
    return [Q resolve:commands];
}

- (QPromise *)deployDownload:(NSArray *)args {
    // All feed pages should be downloaded by this point, and all updated feed items written to the
    // feed file.
    NSArray *feedItems = [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    // List of generated commands.
    NSMutableArray *commands = [NSMutableArray new];
    // Iterate over items and update post database, generate commands to download base content & media items.
    [_postDB beginTransaction];
    for (NSDictionary *item in feedItems) {
        NSString *type = item[@"type"];
        if ([BaseContentType isEqualToString:type]) {
            // Download base content update.
            [commands addObject:@{
                @"name": @"get",
                @"args": @[ item[@"url"], _baseContentFile, @3 ]
            }];
            [commands addObject:@{
                @"name": @"unzip",
                @"args": @[ _baseContentFile, _baseContentPath ]
            }];
            [commands addObject:@{
                @"name": @"rm",
                @"args": @[ _baseContentFile ]
            }];
        }
        else {
            // Upadate post item in database.
            NSString *status = item[@"status"];
            if ([status isEqualToString:@"trash"]) {
                // Item is deleted.
                id postid = item[@"id"];
                NSArray *params = @[ postid, postid ];
                [_postDB performUpdate:@"DELETE FROM posts WHERE id=?" withParams:params];
                [_postDB performUpdate:@"DELETE FROM closures WHERE child=? OR parent=?" withParams:params];
                // If attachment then delete file from content path.
                if ([@"attachment" isEqualToString:type]) {
                    NSString *filename = item[@"filename"];
                    NSString *filepath = [_contentPath stringByAppendingPathComponent:filename];
                    [commands addObject:@{
                        @"name": @"rm",
                        @"args": @[ filepath ]
                    }];
                }
            }
            else {
                [_postDB upsertValues:item intoTable:@"posts"];
                updateClosureTableForPost(_postDB, item);
                // Download attachment updates.
                if ([@"attachment" isEqualToString:type]) {
                    NSString *filename = item[@"filename"];
                    // NOTE that file is downloaded directly to the content path.
                    NSString *filepath = [_contentPath stringByAppendingPathComponent:filename];
                    [commands addObject:@{
                        @"name": @"get",
                        @"args": @[ item[@"url"], filepath, @2 ]
                    }];
                }
            }
        }
    }
    [_postDB commitTransaction];
    // Tidy up.
    [commands addObject:@{
        @"name": @"rm",
        @"args": @[ _feedFile ]
    }];
    _refreshInProgress = NO;
    return [Q resolve:commands];
}
/*
- (QPromise *)stage:(NSArray *)args {
    // Parse arguments. Allow the feed file path to be optionally specified as a command argument.
    NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:@{ @"feedFile": _feedFile }];
    NSString *feedFile = _args[@"feedFile"];
    // List of generated commands.
    NSMutableArray *commands = [NSMutableArray new];
    // Read result of previous get.
    // Data format:
    // { since:,  page: { size:, number:, count: }, items }
    NSDictionary *feedData = [IFFileIO readJSONFromFileAtPath:feedFile encoding:NSUTF8StringEncoding];
    NSArray *feedItems = feedData[@"items"];
    // Iterate over items and generate commands to download base content & media items.
    for (NSDictionary *item in feedItems) {
        NSString *type = item[@"type"];
        if ([BaseContentType isEqualToString:type]) {
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ item[@"url"], _baseContentFile, @3 ]
            }];
            [commands addObject:@{
                @"name":  @"unzip",
                @"args":  @[ _baseContentFile, _baseContentPath ]
            }];
            [commands addObject:@{
                @"name":  @"rm",
                @"args":  @[ _baseContentFile ]
            }];
        }
        else if ([@"attachment" isEqualToString:type]) {
            NSString *filename = item[@"filename"];
            NSString *filepath = [_stagedContentPath stringByAppendingPathComponent:filename];
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ item[@"url"], filepath, @3 ]
            }];
        }
    }
    [commands addObject:@{
        @"name":  [self qualifiedCommandName:@"deploy"],
        @"args":  @[]
    }];
    return [Q resolve:commands];
}

- (QPromise *)deploy:(NSArray *)args {
    // Parse arguments. Allow the feed file path to be optionally specified as a command argument.
    NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:@{ @"feedFile": _feedFile }];
    NSString *feedFile = _args[@"feedFile"];
    NSDate *startTime = [NSDate date];
    // List of generated commands.
    NSMutableArray *commands = [NSMutableArray new];
    // Read result of previous get.
    // Data format:
    // { since:,  page: { size:, number:, count: }, items }
    NSDictionary *feedData = [IFFileIO readJSONFromFileAtPath:feedFile encoding:NSUTF8StringEncoding];
    NSArray *feedItems = feedData[@"items"];
    // Iterate over items and update post database.
    [_postDB beginTransaction];
    for (NSDictionary *item in feedItems) {
        NSString *status = item[@"status"];
        if ([status isEqualToString:@"trash"]) {
            id postid = item[@"id"];
            NSArray *params = @[ postid, postid ];
            [_postDB performUpdate:@"DELETE FROM posts WHERE id=?" withParams:params];
            [_postDB performUpdate:@"DELETE FROM closures WHERE child=? OR parent=?" withParams:params];
        }
        else {
            [_postDB upsertValues:item intoTable:@"posts"];
            updateClosureTableForPost(_postDB, item);
        }
    }
    [_postDB commitTransaction];
    // Commands to move staged content and delete temporary files.
    [commands addObject:@{
        @"name":  @"mv",
        @"args":  @[ _stagedContentPath, _contentPath ]
    }];
    [commands addObject:@{
        @"name":  @"rm",
        @"args":  @[ feedFile ]
    }];
    NSDate *endTime = [NSDate date];
    NSLog(@"Content deploy took %f s", [endTime timeIntervalSinceNow] - [startTime timeIntervalSinceNow]);
    // Check whether this is a multi-page feed response, and whether a follow up refresh request needs to
    // be scheduled.
    NSInteger pageCount = [[feedData getValueAsNumber:@"page.pageCount"] integerValue];
    NSInteger pageNumber = [[feedData getValueAsNumber:@"page.pageNumber"] integerValue];
    if (pageNumber < pageCount) {
        NSArray *args = @[ @"-page", [NSNumber numberWithInteger:pageNumber + 1] ];
        NSString *since = [feedData getValueAsString:@"parameters.since"];
        if (since) {
            args = [args arrayByAddingObjectsFromArray:@[ @"-since", since ]];
        }
        [commands addObject:@{
            @"name":  [self qualifiedCommandName:@"refresh"],
            @"args":  args
        }];
    }
    else {
        _refreshInProgress = NO;
    }
    return [Q resolve:commands];
}
*/
- (QPromise *)unpack:(NSArray *)args {
    NSMutableArray *commands = [NSMutableArray new];
    // Parse arguments.
    NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:nil];
    NSString *packagedContentPath = _args[@"packagedContentPath"];
    if (!packagedContentPath) {
        packagedContentPath = _packagedContentPath;
    }
    if (packagedContentPath) {
        NSDate *startTime = [NSDate date];
        NSString *feedFile = [packagedContentPath stringByAppendingPathComponent:@"feed.json"];
        NSString *baseContentFile = [packagedContentPath stringByAppendingPathComponent:@"base-content.zip"];
        // Read initial posts data from packaged feed file.
        NSArray *feedItems = [IFFileIO readJSONFromFileAtPath:feedFile encoding:NSUTF8StringEncoding];
        if (feedItems) {
            // Iterate over items and update post database.
            [_postDB beginTransaction];
            [_postDB upsertValueList:feedItems intoTable:@"posts"];
            rebuildClosureTable(_postDB, feedItems);
            [_postDB commitTransaction];
        }
        NSDate *endTime = [NSDate date];
        NSLog(@"Content unpack took %f s", [endTime timeIntervalSinceNow] - [startTime timeIntervalSinceNow]);
        // Schedule command to unzip base content if the base content zip exists.
        if ([[NSFileManager defaultManager] fileExistsAtPath:baseContentFile]) {
            NSDictionary *unzipCommand = @{
                @"name":  @"unzip",
                @"args":  @[ baseContentFile, _baseContentPath ]
            };
            [commands addObject:unzipCommand];
        }
    }
    return [Q resolve:commands];
}

void updateClosureTableForPost(IFDB *postDB, NSDictionary *post) {
    id postid = post[@"id"];
    [postDB performUpdate:@"DELETE FROM closures WHERE child=?"
               withParams:@[ postid ] ];
    insertClosureEntriesForPost(postDB, post);
}

void insertClosureEntriesForPost(IFDB *postDB, NSDictionary *post) {
    id parent = post[@"parent"];
    id postid = post[@"id"];

    [postDB insertValues:@{ @"parent": postid, @"child": postid, @"depth": @0 }
               intoTable:@"closures"];
    
    if (parent && ![@0 isEqual:parent]) {
        [postDB performUpdate:@"INSERT INTO closures (parent, child, depth) \
         SELECT p.parent, c.child, p.depth + c.depth + 1 \
         FROM closures p, closures c \
         WHERE p.child=? AND c.parent=?"
                   withParams:@[ parent, postid ]];
    }
}

void rebuildClosureTable(IFDB *postDB, NSArray *posts) {
    [postDB deleteFromTable:@"closures" where:@"1 = 1"];
    for (NSDictionary *post in posts) {
        insertClosureEntriesForPost(postDB, post);
    }
}

@end
