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
    }
    return self;
}

- (NSArray *)supportedCommands {
    return @[ @"refresh", @"process" ];
}

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    // Split the protocol prefix from the name to get the actual command name.
    NSString *commandName = [[name split:@"."] objectAtIndex:1];
    if ([@"refresh" isEqualToString:commandName]) {
        return [self refresh:args];
    }
    if ([@"process" isEqualToString:commandName]) {
        return [self process:args];
    }
    return [Q reject:[NSString stringWithFormat:@"Unrecognized command name: %@", commandName]];
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
    [IFFileIO readJSONFromFileAtPath:_feedFile encoding:NSUTF8StringEncoding];
    // If base content update then get base content, unzip result to content location
    // If media content updates then get each update, write to content location
    // Map post data into db (as part of this command? or as separate follow up command?)
    return nil;
}

@end
