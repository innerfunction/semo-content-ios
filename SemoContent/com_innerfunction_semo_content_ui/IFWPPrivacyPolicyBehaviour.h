//
//  IFWPPrivacyPolicyBehaviour.h
//  SemoContent
//
//  Created by Julian Goacher on 12/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFViewBehaviourObject.h"

/**
 * A behaviour providing functionality for presenting a privacy policy to a user.
 * When this behaviour is attached to a view (controller), it first checks when the view
 * appears whether a flag is set which indicates that the privacy policy has been accepted.
 * If the flag isn't set then the behaviour presents modal view which should show the
 * privacy policy to the user and give them the option of accepting or rejecting the policy.
 * The behaviour recognizes two action messages:
 * 1. privacy-policy/accept: Set the flag indicating policy acceptance, and hide the policy view.
 * 2. privacy-policy/reject: Hide the policy view and post the reject action (e.g. to log out again).
 * NOTE that this behaviour operates per-app-instance, rather than per-user. This means that
 * if a user logs in, accepts the policy, then logs out again than the policy won't be represented
 * if the same or a different user logs in again with the same app installation.
 */
@interface IFWPPrivacyPolicyBehaviour : IFViewBehaviourObject {
    NSUserDefaults *_locals;
}

/**
 * The name under which the policy accepted flag is stored in local settings.
 * Defaults to 'privacyPolicyAccepted'.
 */
@property (nonatomic, strong) NSString *localsKey;
/**
 * The view used to display the privacy policy. The view should include controls (e.g. buttons
 * which the user can use to accept or reject the policy.
 */
@property (nonatomic, strong) UIViewController *policyView;
/* The action message to be posted if the user rejects the policy. */
@property (nonatomic, strong) NSString *rejectAction;

@end
