//
//  MessagesListViewController.h
//  Sharetribe
//
//  Created by Janne Käki on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConversationListViewController : UITableViewController

@property (strong) NSMutableArray *conversations;

- (void)refreshConversations;

@end
