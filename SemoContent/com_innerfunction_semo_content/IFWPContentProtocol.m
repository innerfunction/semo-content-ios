//
//  IFSemoWPProtocol.m
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentProtocol.h"
#import "IFCommand.h"
#import "IFFileIO.h"
#import "NSString+IF.h"
#import "NSDictionary+IFValues.h"

#define BaseContentType (@"semo:base-content")

@interface IFWPContentProtocol ()

- (QPromise *)refresh:(NSArray *)args;
- (QPromise *)stage:(NSArray *)args;
- (QPromise *)deploy:(NSArray *)args;
- (QPromise *)unpack:(NSArray *)args;

@end

@implementation IFWPContentProtocol

- (id)init {
    self = [super init];
    if (self) {
        // Register command handlers.
        __block id this = self;
        [self addCommand:@"refresh" withBlock:^QPromise *(NSArray *args) {
            return [this refresh:args];
        }];
        [self addCommand:@"stage" withBlock:^QPromise *(NSArray *args) {
            return [this stage:args];
        }];
        [self addCommand:@"deploy" withBlock:^QPromise *(NSArray *args) {
            return [this deploy:args];
        }];
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

- (QPromise *)refresh:(NSArray *)args {
    NSString *refreshURL = [_feedURL stringByAppendingPathComponent:@"updates"];
    NSDictionary *_args = [self parseArgArray:args argOrder:@[] defaults:@{ @"refreshURL": refreshURL }];
    refreshURL = _args[@"refreshURL"];
    // A follow-up refresh with 'since' and 'page' args is generated for multi-page feed results.
    // NOTE: It is important that the 'since' parameter is passed here so that each page of
    // the feed response is requested with the same starting position.
    NSString *page = _args[@"page"];
    NSString *since = _args[@"since"];
    if (page && since) {
        since = [since stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        refreshURL = [NSString stringWithFormat:@"%@?since=%@&page=%@", refreshURL, since, page];
    }
    else {
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
    // Return commands.
    return [Q resolve:@[ getCommand, processCommand ]];
}

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
        [_postDB upsertValues:item intoTable:@"posts"];
        updateClosureTableForPost(_postDB, item);
    }
    // TODO: Option to delete trashed posts? e.g. delete all trashed posts over a certain age.
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
    return [Q resolve:commands];
}

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
    [postDB performUpdate:@"DELETE FROM closures WHERE child=?"
               withParams:@[ post[@"id"] ] ];
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
