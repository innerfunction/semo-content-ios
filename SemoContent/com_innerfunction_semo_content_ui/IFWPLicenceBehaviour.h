//
//  IFWPPrivacyPolicyBehaviour.h
//  SemoContent
//
//  Created by Julian Goacher on 12/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFViewBehaviourObject.h"
#import "IFWPAuthManager.h"

/**
 * A view behaviour providing functionality for presenting a licence to a user, and for
 * prompting the user to accept or reject the licence.
 * When this behaviour is attached to a view (controller), it first checks when the view
 * appears whether a flag is set which indicates that the licence has been accepted by the
 * current user.
 * If the flag isn't set then the behaviour presents a modal view which should show the
 * licence text to the user and give them the option of accepting or rejecting the policy.
 * The behaviour recognizes two action messages:
 * 1. licence/accept: Set the flag indicating licence acceptance, and hide the licence view.
 * 2. licence/reject: Hide the licence view and post the reject action (e.g. to log out again).
 */
@interface IFWPLicenceBehaviour : IFViewBehaviourObject {
    NSUserDefaults *_locals;
}

/**
 * The name under which the licence accepted flag is stored in local settings.
 * Defaults to 'licenceAccepted'.
 */
@property (nonatomic, strong) NSString *localsKey;
/**
 * The view used to display the licence text. The view should include controls (e.g. buttons
 * which the user can use to accept or reject the licence.
 */
@property (nonatomic, strong) UIViewController *licenceView;
/* The action message to be posted if the user rejects the licence. */
@property (nonatomic, strong) NSString *rejectAction;
/**
 * A reference to the Wp auth manager. This is needed to get the username of the current logged in user,
 * so that the behaviour can detect if the current user has accepted the licence.
 * If not set then the behaviour uses just a default string value.
 */
@property (nonatomic, weak) IFWPAuthManager *authManager;

@end
