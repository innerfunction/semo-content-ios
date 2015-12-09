//
//  IFSemoWPProtocol.m
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFSemoWPProtocol.h"
#import "IFCommand.h"
#import "IFFileIO.h"
#import "NSString+IF.h"

@interface IFSemoWPProtocol ()

- (QPromise *)refresh:(NSArray *)args;
- (QPromise *)process:(NSArray *)args;

@end

@implementation IFSemoWPProtocol

- (id)init {
    self = [super init];
    if (self) {
        _feedFile = @""; // TODO
        
        // Register command handlers.
        __block id this = self;
        [self addCommand:@"refresh" withBlock:^QPromise *(NSArray *args) {
            return [this refresh:args];
        }];
        [self addCommand:@"process" withBlock:^QPromise *(NSArray *args) {
            return [this process:args];
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
    // Construct and return get command with url and file name to write result to, with 3 retries.
    NSDictionary *command = @{
        @"name":  @"get",
        @"args":  @[ refreshURL, _feedFile, @3 ]
    };
    // Return 'get' command.
    return [Q resolve:@[ command ]];
}

- (QPromise *)process:(NSArray *)args {
    // Read result of previous get.
    NSDictionary *feedData = [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    // If base content update then get base content, unzip result to content location
    // If media content updates then get each update, write to content location
    // Map post data into db (as part of this command? or as separate follow up command?)
    return nil;
}

@end
