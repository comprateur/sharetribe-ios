//
//  ListingViewController.h
//  Sharetribe
//
//  Created by Janne Käki on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Listing.h"
#import "MessagesView.h"

@interface ListingViewController : UIViewController <MessagesViewDelegate>

@property (strong) Listing *listing;
@property (assign) NSInteger listingId;

@property (strong) IBOutlet UIScrollView *scrollView;
@property (strong) IBOutlet UIImageView *imageView;
@property (strong) IBOutlet UIView *backgroundView;
@property (strong) IBOutlet UIView *topShadowBar;

@property (strong) IBOutlet UILabel *titleLabel;
@property (strong) IBOutlet UILabel *textLabel;
@property (strong) UIView *categoryView;
@property (strong) NSMutableArray *valueViews;
@property (strong) UILabel *topBarTitleLabel;

@property (strong) MKMapView *mapView;
@property (strong) UILabel *addressLabel;

@property (strong) IBOutlet UIView *authorView;
@property (strong) IBOutlet UIImageView *authorImageView;
@property (strong) IBOutlet UILabel *authorIntroLabel;
@property (strong) IBOutlet UILabel *authorNameLabel;
@property (strong) IBOutlet UILabel *feedbackIntroLabel;
@property (strong) IBOutlet UILabel *feedbackPercentLabel;
@property (strong) IBOutlet UILabel *feedbackOutroLabel;
@property (strong) IBOutlet UILabel *agestampLabel;

@property (strong) IBOutlet UIButton *respondButton;
@property (strong) IBOutlet UIButton *messageButton;

@property (strong) MessagesView *commentsView;

- (IBAction)showAuthorProfile;
- (IBAction)messageButtonPressed;

@end
