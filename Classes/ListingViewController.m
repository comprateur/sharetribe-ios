//
//  ListingViewController.m
//  Sharetribe
//
//  Created by Janne Käki on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ListingViewController.h"

#import "ConversationViewController.h"
#import "Location.h"
#import "LocationPickerViewController.h"
#import "Message.h"
#import "NewListingViewController.h"
#import "ProfileViewController.h"
#import "SharetribeAPIClient.h"
#import "User.h"
#import "NSDate+Sharetribe.h"
#import "NSString+Sharetribe.h"
#import "UIImageView+AFNetworking.h"
#import "UIImageView+Sharetribe.h"
#import <QuartzCore/QuartzCore.h>

#define kActionSheetTagForOwnerActions 1000

#define kAlertViewTagForConfirmClose   1000
#define kAlertViewTagForConfirmDelete  2000

@interface ListingViewController () <UIActionSheetDelegate, UIAlertViewDelegate> {
    Listing *listing;
    BOOL firstAppearance;
}
@end

@implementation ListingViewController

@dynamic listing;
@synthesize listingId;

@synthesize scrollView = _scrollView;
@synthesize imageView;
@synthesize backgroundView;
@synthesize topShadowBar;

@synthesize titleLabel;
@synthesize textLabel;

@synthesize mapView;
@synthesize addressLabel;

@synthesize authorView;
@synthesize authorImageView;
@synthesize authorIntroLabel;
@synthesize authorNameLabel;
@synthesize feedbackIntroLabel;
@synthesize feedbackPercentLabel;
@synthesize feedbackOutroLabel;
@synthesize agestampLabel;

@synthesize respondButton;
@synthesize messageButton;

@synthesize commentsView;

- (Listing *)listing
{
    return listing;
}

- (void)setListing:(Listing *)newListing
{
    listing = newListing;
    listingId = newListing.listingId;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = kSharetribeBackgroundColor;
    
    // self.hidesBottomBarWhenPushed = YES;
        
    self.mapView = [[MKMapView alloc] init];
    mapView.mapType = MKMapTypeStandard;
    mapView.scrollEnabled = NO;
    mapView.zoomEnabled = NO;
    mapView.showsUserLocation = NO;
    mapView.layer.borderWidth = 1;
    mapView.layer.borderColor = [UIColor whiteColor].CGColor;
    mapView.layer.cornerRadius = 8;
    mapView.frame = CGRectMake(10, 0, 300, 87);
    [self.scrollView addSubview:mapView];
        
    UIButton *mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mapButton.frame = mapView.bounds;
    mapButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [mapButton addTarget:self action:@selector(showDetailedLocation) forControlEvents:UIControlEventTouchUpInside];
    [mapView addSubview:mapButton];
    
    self.addressLabel = [[UILabel alloc] init];
    addressLabel.x = 18;
    addressLabel.width = 320-2*18;
    addressLabel.font = [UIFont systemFontOfSize:13];
    addressLabel.textColor = [UIColor darkGrayColor];
    addressLabel.backgroundColor = [UIColor clearColor];
    addressLabel.numberOfLines = 0;
    addressLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.scrollView addSubview:addressLabel];
    
    self.commentsView = [[MessagesView alloc] init];
    commentsView.sendButtonTitle = NSLocalizedString(@"button.send.comment", @"");
    commentsView.composeFieldPlaceholder = NSLocalizedString(@"placeholder.comment", @"");
    commentsView.delegate = self;
    [self.scrollView addSubview:commentsView];
    
    [respondButton setImage:[UIImage imageNamed:@"icon-contact"] forState:UIControlStateNormal];
    [respondButton setBackgroundImage:[[UIImage imageWithColor:kSharetribeThemeColor] stretchableImageWithLeftCapWidth:5 topCapHeight:19] forState:UIControlStateNormal];
    [respondButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [respondButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.7] forState:UIControlStateNormal];
    respondButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    respondButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    respondButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
    respondButton.layer.cornerRadius = 8;
    respondButton.clipsToBounds = YES;
    [respondButton addTarget:self action:@selector(respondButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [messageButton setImage:[UIImage imageWithIconNamed:@"mail" pointSize:24 color:kSharetribeThemeColor insets:UIEdgeInsetsMake(4, 0, 0, 0)] forState:UIControlStateNormal];
    
    self.authorNameLabel.textColor = kSharetribeThemeColor;
    
    self.authorImageView.clipsToBounds = YES;
    self.authorImageView.layer.cornerRadius = 5;
    
    UIView *leftEdgeLine = [[UIView alloc] init];
    leftEdgeLine.frame = CGRectMake(-1, 0, 1, 460);
    leftEdgeLine.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:leftEdgeLine];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToGoBack)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.scrollView addGestureRecognizer:swipeRecognizer];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRefreshListing:) name:kNotificationForDidRefreshListing object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPostMessage:) name:kNotificationForDidPostMessage object:nil];
    
    if (listing == nil) {
        [[SharetribeAPIClient sharedClient] getListingWithId:listingId];
    }
    
    firstAppearance = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (firstAppearance) {
        firstAppearance = NO;
        [self reloadData];
    }
}

- (void)reloadData
{
    NSString *respondTextKey;
    if (listing == nil) {
        respondTextKey = @"";
    } else if (listing.shareType == nil) {
        respondTextKey = [NSString stringWithFormat:@"listing.button_for_%@", listing.type];
    } else {
        respondTextKey = [NSString stringWithFormat:@"listing.button_for_%@_%@", listing.type, listing.shareType];
    }
    [respondButton setTitle:NSLocalizedString(respondTextKey, @"") forState:UIControlStateNormal];
    
    BOOL messagingDisabled = (listing == nil) || (listing.author.isCurrentUser);  // one cannot respond to oneself
    respondButton.hidden = messagingDisabled;
    // messageButton.hidden = messagingDisabled;
    
    if (listing.author.isCurrentUser) {
        self.navigationItem.rightBarButtonItem = nil; // [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    NSURL *imageURL = [listing.imageURLs objectOrNilAtIndex:0];
    if (imageURL != nil) {
        
        backgroundView.y = 200;
        
        [imageView setImageWithURL:imageURL];
        titleLabel.y = backgroundView.y+12;
        
        CAGradientLayer *topShade = [[CAGradientLayer alloc] init];
        topShade.frame = CGRectMake(0, 20, 320, 70);
        topShade.colors = [NSArray arrayWithObjects:(id)([UIColor colorWithWhite:0 alpha:0.5].CGColor), (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
        topShade.startPoint = CGPointMake(0.5, 0.4);
        topShade.endPoint = CGPointMake(0.5, 1.0);
        [topShadowBar.layer insertSublayer:topShade atIndex:0];
        
        CAGradientLayer *midShade = [[CAGradientLayer alloc] init];
        midShade.frame = CGRectMake(0, -2, 320, 2);
        midShade.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)([UIColor colorWithWhite:0 alpha:0.6].CGColor), nil];
        midShade.startPoint = CGPointMake(0.5, 0.2);
        midShade.endPoint = CGPointMake(0.5, 1.0);
        [backgroundView.layer insertSublayer:midShade atIndex:0];

    } else {
        
        backgroundView.y = 0;
        
        imageView.image = nil;
        if (respondButton.hidden) {
            titleLabel.y = 21;
        } else {
            titleLabel.y = respondButton.y+respondButton.height+21;
        }
        
        [[topShadowBar.layer.sublayers objectOrNilAtIndex:0] removeFromSuperlayer];
        [[backgroundView.layer.sublayers objectOrNilAtIndex:0] removeFromSuperlayer];
    }
    
    titleLabel.text = listing.title;
    titleLabel.height = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(titleLabel.width, 10000) lineBreakMode:NSLineBreakByWordWrapping].height;
    
    int yOffset = titleLabel.y + titleLabel.height + 10;
    
    UIView *(^valueViewWithIconAndTextAndFontSize)(NSString *icon, NSString *text, CGFloat pointSize) = ^UIView *(NSString *icon, NSString *text, CGFloat pointSize) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 30, 0)];
        iconLabel.font = [UIFont boldSystemFontOfSize:(int) (1.2 * pointSize)];
        [iconLabel setIconWithName:icon];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        [iconLabel sizeToFit];
        [view addSubview:iconLabel];
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconLabel.right + 5, 0, 0, iconLabel.height)];
        valueLabel.font = [UIFont boldSystemFontOfSize:pointSize];
        valueLabel.text = text;
        valueLabel.width = [valueLabel.text sizeWithFont:valueLabel.font].width;
        [view addSubview:valueLabel];
        view.height = iconLabel.height;
        view.width = valueLabel.right;
        return view;
    };
    
    [self.categoryView removeFromSuperview];
    self.categoryView = valueViewWithIconAndTextAndFontSize([Listing iconNameForItem:listing.category], listing.localizedShareType, 15);
    self.categoryView.x = self.titleLabel.left;
    self.categoryView.y = yOffset;
    [self.scrollView addSubview:self.categoryView];
    
    yOffset += self.categoryView.height + 14;
    
    textLabel.text = listing.description;
    if (textLabel.text != nil) {
        textLabel.y = yOffset;
        textLabel.height = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:CGSizeMake(textLabel.width, 10000) lineBreakMode:NSLineBreakByWordWrapping].height;
        yOffset = textLabel.y + textLabel.height + 14;
    }
    
    if (self.valueViews == nil) {
        self.valueViews = [NSMutableArray array];
    }
    for (UIView *view in self.valueViews) {
        [view removeFromSuperview];
    }
    [self.valueViews removeAllObjects];
    
    if (listing.priceInCents > 0) {
        [self.valueViews addObject:valueViewWithIconAndTextAndFontSize(@"tag", listing.formattedPrice, 13)];
    }
    [self.valueViews addObject:valueViewWithIconAndTextAndFontSize(@"calendar", [NSString stringWithFormat:@"Created %@", listing.createdAt.agestamp], 13)];
    [self.valueViews addObject:valueViewWithIconAndTextAndFontSize(@"eye", [NSString stringWithFormat:@"Viewed %d times", listing.numberOfTimesViewed], 13)];
    if (listing.validUntil) {
        [self.valueViews addObject:valueViewWithIconAndTextAndFontSize(@"alarmclock", [NSString stringWithFormat:@"Open until %@", listing.validUntil.dateAndTimeString], 13)];
    }
        
    int valueViewX = textLabel.left;
    for (UIView *view in self.valueViews) {
        if (valueViewX + view.width > self.view.width - 20) {
            valueViewX = textLabel.left;
            yOffset += view.height + 2;
        }
        view.x = valueViewX;
        view.y = yOffset;
        valueViewX += view.width + 12;
        [self.scrollView addSubview:view];
    }
    yOffset += [self.valueViews.lastObject height] + 14;
    
    if (listing.location != nil) {
        if (![mapView.annotations containsObject:listing]) {
            [mapView addAnnotation:listing];
        }
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(listing.coordinate, 2000, 4000) animated:NO];
        mapView.hidden = NO;
        mapView.y = yOffset+6;
        yOffset = mapView.y+mapView.height+7;
        addressLabel.text = listing.location.address;
        if (listing.location.address != nil) {
            addressLabel.y = yOffset;
            addressLabel.height = [addressLabel.text sizeWithFont:addressLabel.font constrainedToSize:CGSizeMake(addressLabel.width, 100) lineBreakMode:NSLineBreakByWordWrapping].height;
            yOffset += addressLabel.height+3;
        }
        yOffset += 7;
    } else {
        mapView.hidden = YES;
    }
    
    authorView.y = yOffset+6;
    [authorImageView setImageWithUser:listing.author];
    if (listing != nil) {
        authorIntroLabel.text = ([listing.type isEqual:kListingTypeOffer]) ?  [NSLocalizedString(@"listing.offered_by", @"") stringByAppendingString:@":"] : [NSLocalizedString(@"listing.requested_by", @"") stringByAppendingString:@":"];
        authorNameLabel.text = listing.author.name;
        agestampLabel.text = [listing.createdAt agestamp];
    } else {
        authorIntroLabel.text = nil;
        authorNameLabel.text = nil;
        agestampLabel.text = nil;
    }
    yOffset = authorView.y+authorView.height+14;
    
    commentsView.x = 10;
    commentsView.y = yOffset+6;
    
    [self setComments:listing.comments];
    
    backgroundView.height = commentsView.y+commentsView.height-backgroundView.y;
    
    self.title = listing.title;
    
    self.topBarTitleLabel = [[UILabel alloc] init];
    self.topBarTitleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.topBarTitleLabel.minimumScaleFactor = 0.6;
    self.topBarTitleLabel.numberOfLines = 3;
    self.topBarTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.topBarTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.topBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.topBarTitleLabel.textColor = [UIColor whiteColor];
    self.topBarTitleLabel.backgroundColor = [UIColor clearColor];
    self.topBarTitleLabel.shadowColor = [UIColor blackColor];
    self.topBarTitleLabel.shadowOffset = CGSizeMake(0, 1);
    self.topBarTitleLabel.text = listing.title;
    self.topBarTitleLabel.frame = CGRectMake(0, 44, 220, 40);
    
    self.navigationItem.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.topBarTitleLabel.width, 44)];
    self.navigationItem.titleView.clipsToBounds = YES;
    [self.navigationItem.titleView addSubview:self.topBarTitleLabel];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didRefreshListing:(NSNotification *)notification
{
    Listing *refreshedListing = notification.object;
    if (refreshedListing.listingId == self.listingId) {
        self.listing = refreshedListing;
        [self reloadData];
    }
}

- (void)didPostMessage:(NSNotification *)notification
{
    if (self == self.navigationController.topViewController && self.navigationController.tabBarController.selectedViewController == self.navigationController) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"alert.posted_reply_to_listing.message_format", @""), listing.author.givenName];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert.posted_reply_to_listing.title", @"") message:message delegate:self cancelButtonTitle:NSLocalizedString(@"button.ok", @"") otherButtonTitles:nil];
        [alert show];
    }
}

- (void)didFailToPostMessage:(NSNotification *)notification
{
    if (self == self.navigationController.topViewController && self.navigationController.tabBarController.selectedViewController == self.navigationController) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"alert.failed_to_post_reply_to_listing.message_format", @""), listing.author.givenName];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert.failed_to_post_reply_to_listing.title", @"") message:message delegate:self cancelButtonTitle:NSLocalizedString(@"button.ok", @"") otherButtonTitles:nil];
        [alert show];
    }
}

- (void)setComments:(NSArray *)comments
{
    commentsView.messages = comments;
    int contentHeight = commentsView.y + commentsView.height + 10;
    self.scrollView.contentSize = CGSizeMake(320, contentHeight);
}

- (IBAction)swipedToGoBack
{
    if (commentsView.composeField.isFirstResponder) {
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)respondButtonPressed
{
    [self showComposerForDirectReplyToListing:YES];
}

- (IBAction)messageButtonPressed
{
    [self showComposerForDirectReplyToListing:NO];
}

- (IBAction)actionButtonPressed
{
    if (listing.author.isCurrentUser) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"button.cancel", @"") destructiveButtonTitle:NSLocalizedString(@"button.listing.delete", @"") otherButtonTitles:NSLocalizedString(@"button.listing.edit", @""), NSLocalizedString(@"button.listing.close", @""), nil];
        actionSheet.tag = kActionSheetTagForOwnerActions;
        [actionSheet showFromTabBar:self.navigationController.tabBarController.tabBar];
    }
}

- (void)showComposerForDirectReplyToListing:(BOOL)isDirectReply
{
    ConversationViewController *composer = [[ConversationViewController alloc] init];
    composer.recipient = listing.author;
    composer.listing = (isDirectReply) ? listing : nil;
    // composer.inModalComposerMode = YES;
    composer.isDirectReplyToListing = isDirectReply;
    
    [self.navigationController pushViewController:composer animated:YES];

}

- (IBAction)showAuthorProfile
{
    ProfileViewController *profileViewer = [[ProfileViewController alloc] init];
    profileViewer.user = listing.author;
    [self.navigationController pushViewController:profileViewer animated:YES];
}

- (IBAction)showDetailedLocation
{
    LocationPickerViewController *mapViewer = [[LocationPickerViewController alloc] init];
    mapViewer.mapType = MKMapTypeHybrid;
    mapViewer.coordinate = listing.coordinate;
    mapViewer.address = listing.location.address;
    [self.navigationController pushViewController:mapViewer animated:YES];
}

#pragma mark - MessagesViewDelegate

- (void)messagesViewDidBeginEditing:(MessagesView *)theMessagesView
{
    int contentHeight = commentsView.y + commentsView.height + 10;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.height = self.view.height - 216 + 44 + 5;
        respondButton.alpha = 0;
        topShadowBar.alpha = 0;
        backgroundView.height = contentHeight-backgroundView.y;
    }];
    
    self.scrollView.contentSize = CGSizeMake(320, contentHeight);
    
    [self.scrollView setContentOffset:CGPointMake(0, commentsView.y + commentsView.composeField.y - 10) animated:YES];
}

- (void)messagesViewDidChange:(MessagesView *)theMessagesView
{
    [self.scrollView setContentOffset:CGPointMake(0, commentsView.y + commentsView.composeField.y - 10) animated:YES];
}

- (void)messagesViewDidEndEditing:(MessagesView *)theMessagesView
{
    int contentHeight = commentsView.y + commentsView.height + 10;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.height = self.view.height - 5;
        respondButton.alpha = 1;
        topShadowBar.alpha = 1;
        backgroundView.height = contentHeight-backgroundView.y;
    }];
    
    self.scrollView.contentSize = CGSizeMake(320, contentHeight);
}

- (void)messagesView:(MessagesView *)theMessagesView didSaveMessageText:(NSString *)messageText
{
    [[SharetribeAPIClient sharedClient] postNewComment:messageText onListing:listing];
    
    Message *comment = [Message messageWithAuthor:[User currentUser] content:messageText createdAt:[NSDate date]];
    NSMutableArray *comments = [NSMutableArray arrayWithArray:listing.comments];
    [comments addObject:comment];
    listing.comments = comments;
    commentsView.messages = listing.comments;
}

- (void)messagesView:(MessagesView *)messagesView didSelectUser:(User *)user
{
    ProfileViewController *profileViewer = [[ProfileViewController alloc] init];
    profileViewer.user = user;
    [self.navigationController pushViewController:profileViewer animated:YES];
}

- (CGFloat)availableHeightForComposerInMessagesView:(MessagesView *)messagesView
{
    return self.view.height - 216 + 44;
}

#pragma mark -

- (void)postedNewComment:(NSNotification *)notification
{
    [[SharetribeAPIClient sharedClient] getListingWithId:listing.listingId];  // refresh to get the canonical state from server
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        
        CGFloat imageViewBaselineY = -(imageView.height - 200) / 2;
        CGFloat y = imageViewBaselineY - scrollView.contentOffset.y / 2;
        imageView.frame = CGRectMake(0, y, imageView.width, imageView.height);
        
        int titleY = [self.titleLabel convertPoint:CGPointZero toView:self.view].y;
        if (self.topBarTitleLabel.height > 0) {
            self.topBarTitleLabel.y = MAX((self.navigationItem.titleView.height + titleY * (self.topBarTitleLabel.height / self.titleLabel.height)),
                                          (self.navigationItem.titleView.height - self.topBarTitleLabel.height) / 2 - 1);
        }

        int buttonY;
        if (scrollView.contentOffset.y > titleLabel.y - 68) {
            buttonY = titleLabel.y - 68 - scrollView.contentOffset.y + 10;
        } else {
            buttonY = 10;
        }
        respondButton.y = buttonY;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kActionSheetTagForOwnerActions) {
        
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm.delete_listing.title", @"") message:NSLocalizedString(@"confirm.delete_listing.message", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"button.cancel", @"") otherButtonTitles:NSLocalizedString(@"button.delete", @""), nil];
            alert.tag = kAlertViewTagForConfirmDelete;
            [alert show];
        
        } else if ([buttonTitle isEqualToString:NSLocalizedString(@"button.listing.close", @"")]) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm.close_listing.title", @"") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"button.cancel", @"") otherButtonTitles:NSLocalizedString(@"button.close", @""), nil];
            alert.tag = kAlertViewTagForConfirmClose;
            [alert show];
        
        } else if ([buttonTitle isEqualToString:NSLocalizedString(@"button.listing.edit", @"")]) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard_iPhone" bundle:[NSBundle mainBundle]];
            NewListingViewController *editor = [storyboard instantiateViewControllerWithIdentifier:@"NewListing"];
            editor.listing = listing;
            listing.image = imageView.image;
            UINavigationController *editorNavigator = [[UINavigationController alloc] initWithRootViewController:editor];
            [self presentViewController:editorNavigator animated:YES completion:nil];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertViewTagForConfirmClose) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [[SharetribeAPIClient sharedClient] closeListing:listing];
        }
    } else if (alertView.tag == kAlertViewTagForConfirmDelete) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [[SharetribeAPIClient sharedClient] deleteListing:listing];
        }
    }
}

@end
