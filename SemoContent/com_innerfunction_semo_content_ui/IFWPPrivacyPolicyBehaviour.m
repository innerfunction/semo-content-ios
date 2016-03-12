//
//  IFWPPrivacyPolicyBehaviour.m
//  SemoContent
//
//  Created by Julian Goacher on 12/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPPrivacyPolicyBehaviour.h"
#import "IFAppContainer.h"

@interface IFWPPrivacyPolicyMessageBehaviour : IFViewBehaviourObject {
    __weak IFWPPrivacyPolicyBehaviour *_parentBehaviour;
}

- (id)initWithParentBehaviour:(IFWPPrivacyPolicyBehaviour *)parentBehaviour;

@end

@implementation IFWPPrivacyPolicyBehaviour

- (id)init {
    self = [super init];
    if (self) {
        _locals = [NSUserDefaults standardUserDefaults];
        _localsKey = @"privacyPolicyAccepted";
    }
    return self;
}

- (void)setPolicyView:(UIViewController *)policyView {
    _policyView = policyView;
    // NOTE: The policy view must implement the IFViewBehaviourController protocol.
    if ([policyView conformsToProtocol:@protocol(IFViewBehaviourController)]) {
        // Add the message handling behaviour to the policy view.
        id<IFViewBehaviour> behaviour = [[IFWPPrivacyPolicyMessageBehaviour alloc] initWithParentBehaviour:self];
        [(id<IFViewBehaviourController>)policyView addBehaviour:behaviour];
    }
}

- (void)viewDidAppear {
    BOOL policyAccepted = [_locals boolForKey:_localsKey];
    if (!policyAccepted) {
        _policyView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        _policyView.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self.viewController presentViewController:_policyView animated:YES completion:^{}];
    }
}

- (BOOL)handleMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"privacy-policy/accept"]) {
        [_locals setBool:YES forKey:_localsKey];
        [self.viewController dismissViewControllerAnimated:_policyView completion:^{}];
        return YES;
    }
    if ([message hasName:@"privacy-policy/reject"]) {
        [self.viewController dismissViewControllerAnimated:_policyView completion:^{
            [IFAppContainer postMessage:_rejectAction sender:self.viewController];
        }];
        return YES;
    }
    return NO;
}

@end

@implementation IFWPPrivacyPolicyMessageBehaviour

- (id)initWithParentBehaviour:(IFWPPrivacyPolicyBehaviour *)parentBehaviour {
    self = [super init];
    if (self) {
        _parentBehaviour = parentBehaviour;
    }
    return self;
}

- (BOOL)handleMessage:(IFMessage *)message sender:(id)sender {
    return [_parentBehaviour handleMessage:message sender:sender];
}

@end
