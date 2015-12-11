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

@interface IFWPContentContainer : IFContainer

@property (nonatomic, strong) IFDB *postDB;
@property (nonatomic, strong) IFWPContentProtocol *contentProtocol;
@property (nonatomic, strong) IFWPSchemeHandler *uriScheme;

@end
