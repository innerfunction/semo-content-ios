//
//  IFWPClientTemplateContext.m
//  SemoContent
//
//  Created by Julian Goacher on 15/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPClientTemplateContext.h"
#import "NSString+IF.h"
#import "NSDictionary+IF.h"

@implementation IFWPClientTemplateContext

@synthesize iocContainer = _container;

- (void)setIocContainer:(IFContainer *)iocContainer {
    _attachments = [[IFWPAttachmentsProxy alloc] init];
    _attachments.container = (IFWPContentContainer *)iocContainer;
    _attachments.postDB = (IFDB *)[iocContainer getNamed:@"postDB"];
    _attachments.packagedContentPath = (NSString *)[iocContainer getNamed:@"packagedContentPath"];
    _attachments.contentPath = (NSString *)[iocContainer getNamed:@"contentPath"];
    
    _posts = [[IFWPPostsProxy alloc] init];
    _posts.postDB = _attachments.postDB;
    _posts.container = _attachments.container;
}

- (id)templateContextForPostData:(id)postData {
    // Create the template context by extending the basic post data with additional extensions.
    // Note that post values are available as top level names.
    return [postData extendWith:@{
        @"attachments": _attachments,
        @"posts":       _posts,
        @"ext":         _ext
    }];
}

@end

@implementation IFWPAttachmentsProxy

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    // The template placeholder is in the form {attachment.x}, where 'x' is an attachment post ID.
    // Read the attachment data from the posts DB and base on its 'location' value, return one of
    // the following:
    // * packaged:   Attachment file is packaged with the app; return file: URL pointing at the
    //               file under the packaged content path.
    // * downloaded: Attachment file has been downloaded from the server; return a file: URL
    //               pointing at the file under the content path.
    // * server:     Attachment file hasn't been downloaded and is still on the server; return its
    //               server URL.
    NSDictionary *attachment = [_postDB readRecordWithID:key fromTable:@"posts"];
    NSString *location = [attachment valueForKey:@"location"];
    NSString *filename = [attachment valueForKey:@"filename"];
    NSString *url = [attachment valueForKey:@"url"];
    if ([@"packaged" isEqualToString:location]) {
        NSString *path = [_packagedContentPath stringByAppendingPathComponent:filename];
        url = [NSString stringWithFormat:@"file://%@", path];
    }
    else if ([@"downloaded" isEqualToString:location]) {
        NSString *path = [_contentPath stringByAppendingPathComponent:filename];
        if ([_fileManager fileExistsAtPath:path]) {
            url = [NSString stringWithFormat:@"file://%@", path];
        }
        else {
            // File probably removed by system to free disk space. The attachment URL will be
            // returned instead, meaning that the webview can attempt to download the file from
            // the server if a connection is available.
            // Start a download of the file through the content protocol. Note that if the
            // webview was able to download the file then the protocol should be able to load
            // from the cache.
            [_container getContentFromURL:url writeToFilename:filename];
        }
    }
    // Else location == 'server' or other. Use the attachment URL to download from server.
    return url;
}

@end

@implementation IFWPPostsProxy

- (id)valueForKey:(NSString *)key {
    NSDictionary *post = [_postDB readRecordWithID:key fromTable:@"posts"];
    NSString *location = [post valueForKey:@"location"];
    NSString *uri;
    if ([@"server" isEqualToString:location]) {
        uri = [post valueForKey:@"url"];
    }
    else {
        uri = [_container uriForPostWithID:key];
    }
    return uri;

}

@end