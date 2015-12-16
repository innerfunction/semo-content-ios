//
//  IFWPContentContainer.h
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFContainer.h"
#import "IFDB.h"
#import "IFWPContentProtocol.h"
#import "IFWPSchemeHandler.h"
#import "IFIOCConfigurable.h"

@interface IFWPContentContainer : IFContainer <IFIOCConfigurable> {
    IFConfiguration *_configTemplate;
    
}

/** The name of the posts DB. */
@property (nonatomic, strong) NSString *postDBName;
/** The URL of the WP posts feed. */
@property (nonatomic, strong) NSString *feedURL;
/** The location of pre-packaged post content, relative to the installed app. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** The scheme name the URI handler should be bound to; defaults to wp: */
@property (nonatomic, strong) NSString *uriSchemeName;
/** The posts DB instance. */
@property (nonatomic, strong) IFDB *postDB;
/** The content protocol instance; manages feed downloads. */
@property (nonatomic, strong) IFWPContentProtocol *contentProtocol;
/** The wp: URI scheme. */
@property (nonatomic, strong) IFWPSchemeHandler *uriScheme;
/** Post list data formats. */
@property (nonatomic, strong) NSDictionary *listFormats;
/** Post data formats. */
@property (nonatomic, strong) NSDictionary *postFormats;

@end
