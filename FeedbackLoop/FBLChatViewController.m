//
//  ChatViewController.m
//  Stndout
//
//  Created by Shane Rogers on 4/11/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "FeedbackLoop.h"

// Components
#import "FBLChatViewController.h"

#import "FBLUserDetailsBGView.h"
#import "FBLConnectionErrorBGView.h"

// Constants
#import "FBLAppConstants.h"
#import "FBLViewHelpers.h"

// Data Layer
#import "FBLChannel.h"
#import "FBLChannelStore.h"
#import "FBLChat.h"
#import "FBLChatCollection.h"
#import "FBLChatStore.h"
#import "FBLMembersStore.h"
#import "FBLSlackStore.h"
#import "FBLAuthenticationStore.h"
#import "FBLBundleStore.h"

// Libs
#import "MBProgressHUD.h"

// Utils
#import "FBLCameraUtil.h"
#import "FBLHelpers.h"
#import "FBLViewHelpers.h"

NSString *const kGlobalNotification = @"feedbackLoop__globalNotification";

@interface FBLChatViewController ()

@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL initialized;

@property (nonatomic, strong) NSString *userChannelId;

// BackgroundViews
@property (nonatomic, strong) FBLUserDetailsBGView *userDetailsBGView;
@property (nonatomic, strong) FBLConnectionErrorBGView *connectionErrorBGView;

@property (nonatomic, strong) UIView *navBar;

@property (nonatomic, strong) FBLChannel *channel;

@property (nonatomic, strong) FBLChatCollection *chatCollection;

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSMutableDictionary *avatars;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) JSQMessagesBubbleImage *bubbleImageOutgoing;
@property (nonatomic, strong) JSQMessagesBubbleImage *bubbleImageIncoming;
@property (nonatomic, strong) JSQMessagesAvatarImage *avatarImageBlank;

@property (nonatomic, strong) SRWebSocket *webSocket;

@property (nonatomic, assign) NSInteger errorCounter;

@end

@implementation FBLChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupHUD];
    [self setupConnectionRetryListener];

    self.title = [NSString stringWithFormat:@"FeedbackLoop Chat"];
    [self setupChatBatStyles];

    [self prepareBackgroundViews];
    [self provisionJSQMProperties];

    _users = [[NSMutableArray alloc] init];
    _messages = [[NSMutableArray alloc] init];
    _chatCollection = [[FBLChatCollection alloc] init];
    _avatars = [[NSMutableDictionary alloc] init];
    _isLoading = NO;
    _initialized = NO;

    // If there is no token then show a no token error message.
    if (![[FBLAuthenticationStore sharedInstance] userEmail]) {
        // View Control Point
        [_hud hide:YES];
        [self setChatBarStateForCondition:kUserDetailsBGView];
        [self showBackgroundViewOfType:kUserDetailsBGView];

    } else {
        [self authenticate];
    }
}

- (void)setupConnectionRetryListener {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(authenticate)
                   name:kConnectionRetry
                 object:nil];
}

- (void)setupChatBatStyles {
    [self.inputToolbar.contentView.textView setPlaceHolderTextColor:FEEDBACK_GREY];
    [self setChatBarStateForCondition:@"initialization"];
}

- (void)prepareBackgroundViews {
    [self buildUserDetailsView];
    [self buildConnectionErrorView];
}

// TODO: Re-route away from authentication when already done
// Compose store completion function internals into named functions for re-use
- (void)authenticate {
    if ([[FBLAuthenticationStore sharedInstance] slackToken]) {
        [self noOauth];
    } else {
        [self slackOauth];
    }
}

- (void)buildUserDetailsView {
    NSArray *nibContents = [[FBLBundleStore frameworkBundle] loadNibNamed:kUserDetailsBGView owner:nil options:nil];

    _userDetailsBGView = [nibContents lastObject];
    _userDetailsBGView.contentView.layer.cornerRadius = 20;
    _userDetailsBGView.contentView.layer.borderWidth = 1;
    _userDetailsBGView.contentView.layer.borderColor = (__bridge CGColorRef)(WHITE);
    [_userDetailsBGView.contentView setBackgroundColor:FEEDBACK_BLUE_80];
    _userDetailsBGView.contentView.clipsToBounds = YES;
    [_userDetailsBGView.welcomeTitle setFont:[UIFont fontWithName:FEEDBACK_FONT size:28]];
    float bodySize = [FBLViewHelpers bodyCopyForScreenSize];
    [_userDetailsBGView.title setFont:[UIFont fontWithName:FEEDBACK_FONT size:bodySize]];
    [_userDetailsBGView.lowerTitle setFont:[UIFont fontWithName:FEEDBACK_FONT size:bodySize]];
    [_userDetailsBGView.chattyImage setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"Chatty.png"]]];
    [_userDetailsBGView.chattyImage setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)buildConnectionErrorView {
    NSArray *nibContents = [[FBLBundleStore frameworkBundle] loadNibNamed:kConnectionErrorBGView owner:nil options:nil];

    _connectionErrorBGView = [nibContents lastObject];
    _connectionErrorBGView.contentView.layer.cornerRadius = 20;
    _connectionErrorBGView.contentView.layer.borderWidth = 1;
    _connectionErrorBGView.contentView.layer.borderColor = (__bridge CGColorRef)(WHITE);
    [_connectionErrorBGView.contentView setBackgroundColor:FEEDBACK_BLUE_80];
    _connectionErrorBGView.contentView.clipsToBounds = YES;
    [_connectionErrorBGView.title setText:@"Whoops!"];
    [_connectionErrorBGView.title setFont:[UIFont fontWithName:FEEDBACK_FONT size:34]];
    [_connectionErrorBGView.chatty setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"ChattyNeutral.png"]]];
    [_connectionErrorBGView.chatty setContentMode:UIViewContentModeScaleAspectFit];

    float bodySize = [FBLViewHelpers bodyCopyForScreenSize];
    [_connectionErrorBGView.message setFont:[UIFont fontWithName:FEEDBACK_FONT size:bodySize]];

        [_connectionErrorBGView.leftCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudA.png"]]];
    [_connectionErrorBGView.leftCloud setContentMode:UIViewContentModeScaleAspectFit];

    [_connectionErrorBGView.middleCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudB.png"]]];
    [_connectionErrorBGView.middleCloud setContentMode:UIViewContentModeScaleAspectFit];

    [_connectionErrorBGView.rightCloud setImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"CloudA.png"]]];
    [_connectionErrorBGView.rightCloud setContentMode:UIViewContentModeScaleAspectFit];
}


- (void)provisionJSQMProperties {
    // NOTE: We need to satisfy the JSQMessages internal prop requirements
    NSString *appId = [[FBLAuthenticationStore sharedInstance] AppId];
    if (appId) {
        self.senderId = appId;
    } else {
        self.senderId = @"fbl-client";
    }

    NSString *displayName = [[FBLAuthenticationStore sharedInstance] userEmail];
    if (displayName) {
        self.senderDisplayName = displayName;
    } else {
        self.senderDisplayName = @"You";
    }

    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    _bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:FEEDBACK_BLUE];
    _bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];

    _avatarImageBlank = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:[FBLBundleStore resourceNamed:@"Persona.png"]] diameter:30.0];
}

- (void)noOauth {
    [_hud show:YES];

    void(^websocketConnect)(NSError *err)=^(NSError *error) {
        [_hud hide:YES];

        if (error == nil) {
            [self setChannelDetails];
            [self setupWebsocket];
            [self loadSlackMessages];
        } else {
            NSLog(@"SLACK AUTH HAS FAILED! - multiple times should increase the counter");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    void(^setupWebhook)(NSError *err)=^(NSError *error) {
        if (error == nil) {
            [[FBLSlackStore sharedStore] setupWebhook:websocketConnect];
        } else {
            NSLog(@"SLACK AUTH HAS FAILED! - multiple times should increase the counter");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    [[FBLSlackStore sharedStore] joinOrCreateChannel:setupWebhook];
}

- (void)slackOauth {
    [_hud show:YES];

    void(^refreshWebhook)(NSError *err)=^(NSError *error) {
        [_hud hide:YES];

        if (error == nil) {
            [self setChannelDetails];
            [self setupWebsocket];
            [self loadSlackMessages];
        } else {
            NSLog(@"SLACK AUTH HAS FAILED! - multiple times should increase the counter");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    [[FBLSlackStore sharedStore] slackOAuth:refreshWebhook];
}

- (void)hideFeedbackLoopWindow {
    [self flushWebSocket];
    _popWindow();
}

- (void)flushWebSocket {
    [_webSocket close];
    [FBLSlackStore sharedStore].webhookUrl = nil;
    _webSocket.delegate = nil;
    _webSocket = nil;
}

- (void)setChannelDetails {
    self.userChannelId = [[FBLSlackStore sharedStore] userChannelId];
    self.channel = [[FBLChannelStore sharedStore] find:self.userChannelId];
}

- (void)setupWebsocket {
    NSString *websocketUrl = [FBLSlackStore sharedStore].webhookUrl;

    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:websocketUrl]];
    _webSocket.delegate = self;

    [_webSocket open];
}

- (void)setupHUD {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [_hud setCenter:self.view.center];
    _hud.mode = MBProgressHUDModeIndeterminate;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Backend methods

- (void)loadSlackMessages {
    if (_isLoading == NO) {
        _isLoading = YES;

        void(^completionBlock)(FBLChatCollection *chatCollection, NSString *error)=^(FBLChatCollection *chatCollection, NSString *error) {

            if (error == nil) {
                BOOL incoming = NO;
                self.automaticallyScrollsToMostRecentMessage = NO;

                for (FBLChat *chat in [chatCollection.messages reverseObjectEnumerator])
                {
                    [self addSlackMessage:chat];

                    if (![chat.username isEqualToString:@"bot"]) {
                        incoming = YES;
                    }
                }

                if ([_messages count] != 0)
                {
                    if (_initialized && incoming) {
                        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                    }

                    [self finishReceivingMessage];
                    [self scrollToBottomAnimated:NO];
                }
                self.automaticallyScrollsToMostRecentMessage = YES;
                _initialized = YES;

                [_hud hide:YES];
                [self setChatBarStateForCondition:nil];
                [self.collectionView.backgroundView setHidden:YES];
            }
            else {
                [self triggerGlobalNotificationWithMessage:@"Error loading Messages" andColor:FEEDBACK_ERROR];
                [self showBackgroundViewOfType:kConnectionErrorBGView];
                [self setChatBarStateForCondition:kConnectionErrorBGView];
            }

            [self.collectionView reloadData];
            _isLoading = NO;
        };

        [[FBLChatStore sharedStore] fetchHistoryForChannel:_userChannelId withCompletion:completionBlock];
    }
}

- (void)showBackgroundViewOfType:(NSString *)viewName {
    if([viewName isEqualToString:kConnectionErrorBGView]) {
        // TODO CHECK THE COUNTER TO ERROR MESSAGE AND CHATTY
        [self.collectionView setBackgroundView:_connectionErrorBGView];
    } else if ([viewName isEqualToString:kUserDetailsBGView]) {
        [self.collectionView setBackgroundView:_userDetailsBGView];
    }

    // TODO: Add A fade in/grow in function for background views - lower sharp reveal
    [self.collectionView.backgroundView setHidden:NO];
    // Programatically resign the keyboard!
    [self.inputToolbar.contentView.textView resignFirstResponder];
}

- (void)setChatBarStateForCondition:(NSString *)condition {
    if([condition isEqualToString:kConnectionErrorBGView]) {
        [self.inputToolbar setUserInteractionEnabled:NO];
        [self.inputToolbar.contentView.textView setPlaceHolder:@"Whoops! No Connection"];
    } else if ([condition isEqualToString:kUserDetailsBGView]) {
        [self.inputToolbar setUserInteractionEnabled:YES];
        [self.inputToolbar.contentView.textView setPlaceHolder:@"Hi! Type your email to start :)"];
    } else if ([condition isEqualToString:@"initialization"]) {
        [self.inputToolbar setUserInteractionEnabled:NO];
        [self.inputToolbar.contentView.textView setPlaceHolder:@"Warming up..."];
    } else {
        [self.inputToolbar setUserInteractionEnabled:YES];
        [self.inputToolbar.contentView.textView setPlaceHolder:@"What's on your mind?"];
    }
}

- (JSQMessage *)addSlackMessage:(FBLChat *)chat {
    JSQMessage *message;
    NSString *senderId;
    NSString *displayName;
    NSString *text;
    NSString *username = chat.username;

    if ([username isEqualToString:@"bot"]) {

        FBLMember *member = [[FBLMember alloc] init];
        [member setId:self.senderId];
        [member setEmail:self.senderDisplayName];
        [member setProfileImage:nil];

        [_users addObject:member];

        senderId = self.senderId;
        displayName = self.senderDisplayName;
        text = chat.text;
    } else {
        senderId = chat.user;
        FBLMember *member = [[FBLMembersStore sharedStore] find:chat.user];

        [_users addObject:member];

        displayName = member.realName;
        text = SanitizeMessage(chat.text);
    }

    NSDate *dateStamp = [NSDate dateWithTimeIntervalSince1970:
                         [chat.ts doubleValue]];

    message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:displayName date:dateStamp text:text];

    [_messages addObject:message];

    return message;
}

- (void)sendMessageToSlack:(NSString *)text Video:(NSURL *)video Picture:(UIImage *)picture {

    void(^completionBlock)(FBLChat *chat, NSString *error)=^(FBLChat *chat, NSString *error) {
        if (error == nil) {
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
        }
        else {
            // TODO: Add the retry sending message helper to message button
        };
    };

    [[FBLChatStore sharedStore] sendSlackMessage:text toChannel:self.channel withCompletion:completionBlock];

    [self finishSendingMessage];
}

#pragma mark - JSQMessagesViewController protocol methods

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {

    if (![[FBLAuthenticationStore sharedInstance] userEmail]) {
        if (ValidateEmail(text)){
            [self triggerGlobalNotificationWithMessage:@"Valid Email! Woo!" andColor:FEEDBACK_SUCCESS];
            [[FBLAuthenticationStore sharedInstance] setUserEmail:text];
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
            [self authenticate];
        } else {
            [self triggerGlobalNotificationWithMessage:@"Invalid Email!" andColor:FEEDBACK_ERROR];
        }
    } else {
        [self sendMessageToSlack:text Video:nil Picture:nil];
    }
}

- (void)triggerGlobalNotificationWithMessage:(NSString *)message andColor:(UIColor *)color {
    NSNotification *notification = [NSNotification notificationWithName:kGlobalNotification
                                                                 object:self
                                                               userInfo:@{
                                                                          @"error": message,
                                                                          @"color": color
                                                                          }];

    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Use Last Taken Photo",
                                                                 @"Choose Photo", nil];
    [action showInView:self.view];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _messages[indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    if ([self outgoing:_messages[indexPath.item]])
    {
        return _bubbleImageOutgoing;
    }
    else
    {
        return _bubbleImageIncoming;
    }
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {

    FBLMember *member = _users[indexPath.item];

    if (_avatars[member.id] == nil) {
        if (member.profileImage) {
            JSQMessagesAvatarImage *avatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:member.profileImage diameter:30.0];
            _avatars[member.id] = avatar;
            return avatar;
        } else {
            return _avatarImageBlank;
        }
    } else {
        return _avatars[member.id];
    }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item % 3 == 0)
    {
        JSQMessage *message = _messages[indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    } else {
        return nil;
    }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = _messages[indexPath.item];

    if ([self incoming:message])
    {
        if (indexPath.item > 0)
        {
            JSQMessage *previous = _messages[indexPath.item-1];
            if ([previous.senderId isEqualToString:message.senderId])
            {
                return nil;
            }
        }
        return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
    }
    else return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    if ([self outgoing:_messages[indexPath.item]])
    {
        cell.textView.textColor = [UIColor whiteColor];
    }
    else
    {
        cell.textView.textColor = [UIColor blackColor];
    }
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item % 3 == 0)
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = _messages[indexPath.item];
    if ([self incoming:message])
    {
        if (indexPath.item > 0)
        {
            JSQMessage *previous = _messages[indexPath.item-1];
            if ([previous.senderId isEqualToString:message.senderId])
            {
                return 0;
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    NSLog(@"didTapLoadEarlierMessagesButton");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
           atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didTapAvatarImageView");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = _messages[indexPath.item];
    if (message.isMediaMessage)
    {
        if ([message.media isKindOfClass:[JSQVideoMediaItem class]])
        {
            JSQVideoMediaItem *mediaItem = (JSQVideoMediaItem *)message.media;
            MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
            [self presentMoviePlayerViewControllerAnimated:moviePlayer];
            [moviePlayer.moviePlayer play];
        }
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
    NSLog(@"didTapCellAtIndexPath %@", NSStringFromCGPoint(touchLocation));
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        if (buttonIndex == 0) {
            ShouldStartPhotoLibrary(self, YES);
        } else {
            NSLog(@"Error: No Action for Button Index");
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    NSURL *video = info[UIImagePickerControllerMediaURL];
//    UIImage *picture = info[UIImagePickerControllerEditedImage];

    // TODO: Implement image picker transfer

    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper methods

- (BOOL)incoming:(JSQMessage *)message {

    return ([message.senderId isEqualToString:self.senderId] == NO);
}

- (BOOL)outgoing:(JSQMessage *)message {
    return ([message.senderId isEqualToString:self.senderId] == YES);
}

#pragma mark - Socket Rocket

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    NSString *eventType = [json objectForKey:@"type"];

    if ([eventType isEqualToString:@"hello"]) {
        NSLog(@"WEBSOCKET RESPONSE RECEIVED");
    } else if ([eventType isEqualToString:@"message"]) {
        NSString *channelId = [json objectForKey:@"channel"];;

        if ([channelId isEqualToString:self.userChannelId]) {
            FBLChat *newMessage = [[FBLChat alloc] initWithDictionary:json error:nil];
            [self addSlackMessage:newMessage];

            [self.collectionView reloadData];
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            [self finishReceivingMessage];
            [self scrollToBottomAnimated:NO];
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"WEBSOCKET OPENED");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"WEBSCOKET FAILED *** %@", error.localizedDescription);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WEBSOCKET CLOSED");
}

#pragma mark - Notification Center

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
