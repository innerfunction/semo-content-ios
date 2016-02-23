//
//  IFSubmitField.h
//  SemoContent
//
//  Created by Julian Goacher on 23/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormField.h"
#import "IFFormView.h"

@interface IFSubmitField : IFFormField <IFFormLoadingIndicator> {
    UIActivityIndicatorView *_loadingIndicator;
}

@end
