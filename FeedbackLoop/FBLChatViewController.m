//
//  ChatViewController.m
//  Stndout
//
//  Created by Shane Rogers on 4/11/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
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
#import "URBMediaFocusViewController.h"

// Utils
#import "FBLCameraUtil.h"
#import "FBLHelpers.h"
#import "FBLViewHelpers.h"

NSString *const kGlobalNotification = @"feedbackLoop__globalNotification";

@interface FBLChatViewController ()

// BackgroundViews
@property (nonatomic, strong) FBLUserDetailsBGView *userDetailsBGView;
@property (nonatomic, strong) FBLConnectionErrorBGView *connectionErrorBGView;

// Accessory Views
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) UIViewController *mediaViewController;
@property (nonatomic, strong) URBMediaFocusViewController *lightboxViewController;

// Data iVars
@property (nonatomic, strong) FBLChannel *channel;
@property (nonatomic, strong) FBLChatCollection *chatCollection;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) NSString *userChannelId;

// State iVars
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) NSInteger errorCounter;

// JSQMessages
@property (nonatomic, strong) JSQMessagesBubbleImage *bubbleImageOutgoing;
@property (nonatomic, strong) JSQMessagesBubbleImage *bubbleImageIncoming;
@property (nonatomic, strong) JSQMessagesAvatarImage *avatarImageBlank;

// Networking
@property (nonatomic, strong) SRWebSocket *webSocket;

@end

@implementation FBLChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupHUD];
    [self setupConnectionRetryListener];

    _errorCounter = 0;

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
    [self feedbackLoopAuth];
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
}

- (void)buildConnectionErrorView {
    NSArray *nibContents = [[FBLBundleStore frameworkBundle] loadNibNamed:kConnectionErrorBGView owner:nil options:nil];

    _connectionErrorBGView = [nibContents lastObject];
    [_connectionErrorBGView setDefaultState];
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

- (void)slackAuth {
    [_hud show:YES];

    void(^websocketConnect)(NSError *err)=^(NSError *error) {
        [_hud hide:YES];

        if (error == nil) {
            [self setChannelDetails];
            [self setupWebsocket];
            [self loadSlackMessages];
        } else {
            NSLog(@"Setup Webhook Fail!");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    void(^setupWebhook)(NSError *err)=^(NSError *error) {
        if (error == nil) {
            [[FBLSlackStore sharedStore] setupWebhook:websocketConnect];
        } else {
            NSLog(@"JoinOrCreateFail!");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    [[FBLSlackStore sharedStore] joinOrCreateChannel:setupWebhook];
}

- (void)feedbackLoopAuth {
    [_hud show:YES];

    void(^completionBlock)(FBLChatCollection* chatHistory, NSError *err)=^(FBLChatCollection* chatHistory, NSError *error) {
        [_hud hide:YES];

        if (error == nil) {
            [self setChannelDetails];
            [self setupWebsocket];
            _chatCollection = chatHistory;
            [self loadSlackMessages];
        } else {
            NSLog(@"SLACK AUTH HAS FAILED! - multiple times should increase the counter");
            [self showBackgroundViewOfType:kConnectionErrorBGView];
        }
    };

    [[FBLSlackStore sharedStore] feedbackLoopAuth:completionBlock];
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

        BOOL incoming = NO;
        self.automaticallyScrollsToMostRecentMessage = NO;

        for (FBLChat *chat in [_chatCollection.messages reverseObjectEnumerator])
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

        [self.collectionView reloadData];
        _isLoading = NO;
    }
}

- (void)showBackgroundViewOfType:(NSString *)viewName {
    if([viewName isEqualToString:kConnectionErrorBGView]) {
        [self setChatBarStateForCondition:kConnectionErrorBGView];

        [self.collectionView setBackgroundView:_connectionErrorBGView];

        if (_errorCounter < 3) {
            _errorCounter++;
        };

        [self setConnectionErrorBGViewState];
    } else if ([viewName isEqualToString:kUserDetailsBGView]) {
        [self.collectionView setBackgroundView:_userDetailsBGView];
    }

    // TODO: Add A fade in/grow in function for background views - lower sharp reveal
    [self.collectionView.backgroundView setHidden:NO];
    // Programatically resign the keyboard!
    [self.inputToolbar.contentView.textView resignFirstResponder];
}

- (void)setConnectionErrorBGViewState {
    switch (_errorCounter) {
        case 0:
            // Default connection error state
            [_connectionErrorBGView setDefaultState];
            break;
        case 1:
            // Retry
            [_connectionErrorBGView setDefaultState];
            break;
        case 2:
            // Try again later
            [_connectionErrorBGView setRetryState];
            break;
        case 3:
            // Try again later
            [_connectionErrorBGView setTryLaterState];
            break;

        default:
            break;
    }
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
    NSDate *dateStamp = [NSDate dateWithTimeIntervalSince1970:
                         [chat.ts doubleValue]];

    // The username is nil for Slack supporters
    if (username == nil) {
        senderId = chat.user;
        FBLMember *member = [[FBLMembersStore sharedStore] find:chat.user];

        [_users addObject:member];

        displayName = member.realName;
        text = SanitizeMessage(chat.text);
    } else {
        FBLMember *member = [[FBLMember alloc] init];
        [member setId:self.senderId];
        [member setEmail:self.senderDisplayName];
        [member setProfileImage:nil];

        [_users addObject:member];

        senderId = self.senderId;
        displayName = self.senderDisplayName;
        text = chat.text;
    }

    if (chat.isMessage) {
        message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:displayName date:dateStamp text:text];
    } else if (chat.isMedia) {
        JSQPhotoMediaItem *mediaItem = [[JSQPhotoMediaItem alloc] initWithImage:nil];

        // TODO: Figure out sender data - should be doing a lookup to members based on userName??
        mediaItem.appliesMediaViewMaskAsOutgoing = ![senderId isEqualToString:chat.user];
        message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:displayName date:dateStamp media:mediaItem];

        void(^completionBlock)(UIImage *img, NSString *error)=^(UIImage *img, NSString *error) {
            if (error == nil) {
                mediaItem.image = img;
                [self.collectionView reloadData];
            }
        };
        [[FBLChatStore sharedStore] fetchImageForChat:chat withCompletion:completionBlock];
    }

    [_messages addObject:message];

    return message;
}

// API Message Sending
- (void)sendMessageToAPI:(NSString *)text Video:(NSURL *)video Image:(UIImage *)image {
    void(^completionBlock)(FBLChat *chat, NSString *error)=^(FBLChat *chat, NSString *error) {
        if (error == nil) {
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
        }
        else {
            // TODO:Add the header notifiacation bar
            // Add the retry sending message helper to message button
        };
    };

    if (image) {
        NSLog(@"Need API support for images");
//        [[FBLChatStore sharedStore] sendSlackImage:image toChannel:self.channel withCompletion:completionBlock];
    } else {
        [[FBLChatStore sharedStore] sendMessageToAPI:text toChannel:self.channel withCompletion:completionBlock];
    }

    [self finishSendingMessage];
}


// Legacy Message Sending
- (void)sendMessageToSlack:(NSString *)text Video:(NSURL *)video Image:(UIImage *)image {

    void(^completionBlock)(FBLChat *chat, NSString *error)=^(FBLChat *chat, NSString *error) {
        if (error == nil) {
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
        }
        else {
            // TODO: Add the retry sending message helper to message button
        };
    };

    if (image) {
        [[FBLChatStore sharedStore] sendSlackImage:image toChannel:self.channel withCompletion:completionBlock];
    } else {
        [[FBLChatStore sharedStore] sendSlackMessage:text toChannel:self.channel withCompletion:completionBlock];
    }

    [self finishSendingMessage];
}

#pragma mark - JSQMessagesViewController protocol methods

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {

    if (![[FBLAuthenticationStore sharedInstance] userEmail]) {
        if (ValidateEmail(text)){
            // Set the email on the AuthStore
            [FBLAuthenticationStore sharedInstance].userEmail = text;
            // Show success message to the user
            [self triggerGlobalNotificationWithMessage:@"Success!" andColor:FEEDBACK_SUCCESS];
            [[FBLAuthenticationStore sharedInstance] setUserEmail:text];
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
            // Proceed with authentication
            [self authenticate];
        } else {
            [self triggerGlobalNotificationWithMessage:@"Invalid Email!" andColor:FEEDBACK_ERROR];
        }
    } else {
        [self sendMessageToAPI:text Video:nil Image:nil];
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

    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : [UIColor blackColor],
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };

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
    if (message.isMediaMessage) {
        NSLog(@"PresentImage");

        _lightboxViewController = [[URBMediaFocusViewController alloc] init];
//        _lightboxViewController.shouldDismissOnImageTap = YES;
        _lightboxViewController.shouldShowPhotoActions = YES;

        JSQMessagesCollectionViewCell *targetCell = (JSQMessagesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        JSQPhotoMediaItem *mediaItem = (JSQPhotoMediaItem *)message.media;
        UIImage *targetImage = mediaItem.image;
        
        [_lightboxViewController showImage:targetImage fromView:targetCell];
    } else if (message.isMediaMessage) {
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
            void(^completionBlock)(UIImage *img, NSError *error)=^(UIImage *img, NSError *error) {
                [self sendMessageToSlack:nil Video:nil Image:img];
                if(error != nil) {
                } else {
                    NSLog(@"Error fetching last image %@", error.localizedDescription);
                }
            };

            [self fetchLastPhotoWithCompletionBlock:completionBlock];
        } else {
            ShouldStartPhotoLibrary(self, YES);
        }
    }
}

- (void)fetchLastPhotoWithCompletionBlock:(void (^)(UIImage *img, NSError *error))block {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];

        // Chooses the photo at the last index
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {

            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];

                // Stop the enumerations
                *stop = YES; *innerStop = YES;

                // Do something interesting with the AV asset.
                block(latestPhoto, nil);
            }
        }];
    } failureBlock: ^(NSError *error) {
        block(nil, error);
    }];

}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];

    [self sendMessageToSlack:nil Video:nil Image:image];

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
    NSLog(@"WEBSOCKET CLOSED WITH REASON :%@", reason);
    [self showBackgroundViewOfType:kConnectionErrorBGView];
}

#pragma mark - Notification Center

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
