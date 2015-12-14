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

@property (nonatomic, strong) NSString *postDBName;
@property (nonatomic, strong) NSString *stagingPath;
@property (nonatomic, strong) NSString *contentPath;
@property (nonatomic, strong) NSString *feedURL;
@property (nonatomic, strong) IFDB *postDB;
@property (nonatomic, strong) IFWPContentProtocol *contentProtocol;
@property (nonatomic, strong) IFWPSchemeHandler *uriScheme;
@property (nonatomic, strong) NSDictionary *listFormats;
@property (nonatomic, strong) NSDictionary *postFormats;

@end
