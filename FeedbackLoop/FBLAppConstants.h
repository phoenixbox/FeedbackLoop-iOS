//
//  FBLAppConstants.h
//  Stndout
//
//  Created by Shane Rogers on 4/11/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#ifndef Stndout_FBLAppConstants_h
#define Stndout_FBLAppConstants_h

//--------------------- APP HELPERS ----------------------------
#define     FBL_DEFAULT_EMAIL @"help@feedbackloop.com"
#define     FBL_DEFAULT_TITLE @"bot"

//--------------------- SLACK ------------------------------
#define     SLACK_API_BASE_URL @"https://slack.com/api"

//----------------- SLACK ENDPOINTS ------------------------------
//------- RTM
#define     SLACK_API_RTM_START @"/rtm.start"
//------- Channel
#define     SLACK_API_CHANNEL_CREATE @"/channels.create"
//PARAMS    "?token=#{token}&name=#{channelName}
#define     SLACK_API_CHANNEL_JOIN @"/channels.join"
//PARAMS    "?token=#{token}&name=#{channelName}
#define     SLACK_API_CHANNEL_HISTORY @"/channels.history"
//------- Message
#define     SLACK_API_MESSAGE_POST @"/chat.postMessage"
//PARAMS    "?token=#{token}  &  channel=#{channelName}"?token="
//------- Members
#define     SLACK_MEMBERS_URI @"/users.list"

//-------------------FEEDBACKLOOP ------------------------------
#define     PROD_API_BASE_URL @"http://www.getfeedbackloop.com/api";
#define     DEV_API_BASE_URL @"http://lvh.me:3000/api";

//#define     DEV_API_BASE_URL @"http://192.168.0.109:3000/api";

//--------------FEEDBACKLOOP ENDPOINTS------------------------------

#define     FBL_TEAMS_URI @"/teams"

//--------------FEEDBACKLOOP GENERAL------------------------------
#define BUNDLE_NAME @"FeedbackLoop.bundle"

#define FEEDBACK_ERROR [UIColor colorWithRed:0.8 green:0.2 blue:0.47 alpha:1]
#define FEEDBACK_SUCCESS [UIColor colorWithRed:0.36 green:0.91 blue:0.43 alpha:1]
#define FEEDBACK_BLUE [UIColor colorWithRed:0.34 green:0.64 blue:0.94 alpha:1]
#define FEEDBACK_BLUE_80 [UIColor colorWithRed:0.34 green:0.64 blue:0.94 alpha:0.8]
#define FEEDBACK_GREY [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]
#define WHITE [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1]
#define FEEDBACK_FONT @"AvenirNext-Regular"


#endif