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
    }
    return self;
}

- (void)setStagingPath:(NSString *)stagingPath {
    _stagingPath = stagingPath;
    _feedFile = [stagingPath stringByAppendingPathComponent:@"feed.json"];
    _baseContentFile = [stagingPath stringByAppendingPathComponent:@"base-content.zip"];
    _stagedContentPath = [stagingPath stringByAppendingPathComponent:@"content"];
}

- (QPromise *)refresh:(NSArray *)args {
    NSString *refreshURL = _feedURL;
    // Any arguments supplied indicate 'since' and 'page' values, which are supplied when a
    // follow up requests are generated for multi-page feed results.
    // NOTE: It is important that the 'since' parameter is passed here so that each page of
    // the feed response is requested with the same starting position.
    if ([args count] >= 2) {
        id page = [args objectAtIndex:0];
        id since = [args objectAtIndex:1];
        refreshURL = [NSString stringWithFormat:@"%@?since=%@&page=%@", _feedURL, since, page];
    }
    else {
        // Query post DB for the last modified time.
        NSArray *rs = [_postDB performQuery:@"SELECT max(modifiedTime) FROM posts" withParams:@[]];
        if ([rs count] > 0) {
            // Previously downloaded posts exist, so read latest post modification time.
            NSDictionary *record = [rs objectAtIndex:0];
            NSString *modifiedTime = [record objectForKey:@"modifiedTime"];
            // Construct feed URL with since parameter.
            refreshURL = [NSString stringWithFormat:@"%@?since=%@", _feedURL, modifiedTime];
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
    NSMutableArray *commands = [[NSMutableArray alloc] init];
    // Read result of previous get.
    // Data format:
    // { since:,  page: { size:, number:, count: }, items }
    NSDictionary *feedData = [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    NSArray *feedItems = [feedData objectForKey:@"items"];
    // Iterate over items and generate commands to download base content & media items.
    for (NSDictionary *item in feedItems) {
        NSString *type = [item objectForKey:@"type"];
        if ([BaseContentType isEqualToString:type]) {
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ [item objectForKey:@"url"], _baseContentFile, @3 ]
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
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ [item objectForKey:@"url"], _stagedContentPath, @3 ]
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
    NSMutableArray *commands = [[NSMutableArray alloc] init];
    // Read result of previous get.
    // Data format:
    // { since:,  page: { size:, number:, count: }, items }
    NSDictionary *feedData = [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    NSArray *feedItems = [feedData objectForKey:@"items"];
    // Iterate over items and update post database.
    [_postDB beginTransaction];
    for (NSDictionary *item in feedItems) {
        [_postDB updateValues:item inTable:@"posts"];
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
        @"args":  @[ _feedFile ]
    }];
    // Check whether this is a multi-page feed response, and whether a follow up refresh request needs to
    // be scheduled.
    NSInteger pageCount = [[feedData getValueAsNumber:@"page.count"] integerValue];
    NSInteger pageNumber = [[feedData getValueAsNumber:@"page.number"] integerValue];
    if (pageNumber < pageCount) {
        NSArray *args = @[ [NSNumber numberWithInteger:pageCount + 1] ];
        NSString *since = [feedData getValueAsString:@"since"];
        if (since) {
            args = [args arrayByAddingObject:since];
        }
        [commands addObject:@{
            @"name":  [self qualifiedCommandName:@"refresh"],
            @"args":  args
        }];
    }
    return [Q resolve:commands];
}

@end
