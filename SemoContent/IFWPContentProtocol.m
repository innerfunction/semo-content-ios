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

@interface IFWPContentProtocol ()

- (QPromise *)refresh:(NSArray *)args;
- (QPromise *)stage:(NSArray *)args;
- (QPromise *)deploy:(NSArray *)args;

@end

@implementation IFWPContentProtocol

- (id)init {
    self = [super init];
    if (self) {
        _feedFile = @""; // TODO
        
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

- (QPromise *)refresh:(NSArray *)args {
    NSString *refreshURL = _feedURL;
    // Query post DB for last modified time.
    NSArray *rs = [_postDB performQuery:@"SELECT max(modifiedTime) FROM posts" withParams:@[]];
    if ([rs count] > 0) {
        // Previously downloaded posts exist, so read latest post modification time.
        NSDictionary *record = [rs objectAtIndex:0];
        NSString *modifiedTime = [record objectForKey:@"modifiedTime"];
        // Construct feed URL with since parameter.
        refreshURL = [NSString stringWithFormat:@"%@?since=%@", _feedURL, modifiedTime];
    }
    // Construct get command with url and file name to write result to, with 3 retries.
    NSDictionary *getCommand = @{
        @"name":  @"get",
        @"args":  @[ refreshURL, _feedFile, @3 ]
    };
    // Construct process command to process download.
    NSDictionary *processCommand = @{
        @"name": [self qualifyCommandName:@"stage"],
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
        // TODO: This needs to be reviewed.
        if ([@"semo:base-content" isEqualToString:type]) {
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ [item objectForKey:@"url"], _baseContentFile, @3 ]
            }];
            [commands addObject:@{
                @"name":  @"unzip",
                @"args":  @[ _baseContentFile, _stagingPath ]
            }];
        }
        else if ([@"attachment" isEqualToString:type]) {
            [commands addObject:@{
                @"name":  @"get",
                @"args":  @[ [item objectForKey:@"url"], _stagingPath, @3 ]
            }];
        }
    }
    [commands addObject:@{
        @"name":  [self qualifyCommandName:@"#update"],
        @"args":  @[]
    }];
    // If base content update then get base content, unzip result to content location
    // If media content updates then get each update, write to content location
    // Map post data into db (as part of this command? or as separate follow up command?)
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
        NSString *type = [item objectForKey:@"type"];
        if ([@"page" isEqualToString:type] || [@"post" isEqualToString:type]) {
            [_postDB updateValues:item inTable:@"posts"];
        }
        // TODO: Are attachments also inserted into db? Could help in managing deleted content etc.
    }
    // TODO: Option to delete trashed posts?
    [_postDB commitTransaction];
    // Commands to move staged content and delete temporary files.
    [commands addObject:@{
        @"name":  @"mv",
        @"args":  @[ _stagingPath, _contentPath ]
    }];
    [commands addObject:@{
        @"name":  @"rm",
        @"args":  @[ _feedFile, _baseContentFile ]
    }];
    // TODO if more than one page, schedule follow up refresh to download next page?
    return [Q resolve:commands];
}

@end
