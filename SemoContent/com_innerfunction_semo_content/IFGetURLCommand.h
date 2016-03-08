//
//  IFGetURLCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"
#import "IFHTTPClient.h"

/**
 * A command to get the contents of a URL and write it to a file.
 * Arguments: <url> <filename> <retries>
 * - url:       The URL to fetch.
 * - filename:  The name of the file to write the result to.
 * - attempt:   The number of attempts made to fetch the URL. Defaults to 0 and is incremented after
 *              each failed attempt. The command fails once maxRetries number of attempts has been made.
 */
@interface IFGetURLCommand : NSObject <IFCommand> {
    IFHTTPClient *_httpClient;
    QPromise *_promise;
    NSString *_commandName;
    NSString *_url;
    NSString *_filename;
}

- (id)initWithHTTPClient:(IFHTTPClient *)httpClient;

@property (nonatomic, assign) NSInteger maxRetries;

@end
