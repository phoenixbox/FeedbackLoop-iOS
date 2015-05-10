//
//  FBLMessage.m
//  Stndout
//
//  Created by Shane Rogers on 4/18/15.
//  Copyright (c) 2015 REPL. All rights reserved.
//

#import "FBLChat.h"

@implementation FBLChat

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

+(JSONKeyMapper*)keyMapper {
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"text": @"text",
                                                       @"username": @"username",
                                                       @"user": @"user",
                                                       @"type": @"type",
                                                       @"subtype": @"subtype",
                                                       @"ts": @"ts",
                                                       @"file.url": @"imgUrl"
                                                       }];
}

- (BOOL)isMessage {
    return ![_subtype isEqualToString:@"file_share"];
}

- (BOOL)isMedia {
    return [_subtype isEqualToString:@"file_share"];
}

@end

// File Schema Example
//{
//    file =     {
//        channels = (C04Q953UF);
//        "comments_count" = 0;
//        created = 1431240202;
//        editable = 0;
//        "external_type" = "";
//        filetype = png;
//        groups = ();
//        id = F04PUKX9Y;
//        "image_exif_rotation" = 1;
//        ims = ();
//        "is_external" = 0;
//        "is_public" = 1;
//        mimetype = "image/png";
//        mode = hosted;
//        name = "Pasted image at 2015_05_09 11_59 PM.png"; // Yes
//        permalink = "https://stndout.slack.com/files/shanerogers/F04PUKX9Y/pasted_image_at_2015_05_09_11_59_pm.png";
//        "permalink_public" = "https://slack-files.com/T04KQTG87-F04PUKX9Y-f7bc225c43";
//        "pretty_type" = PNG;
//        "public_url_shared" = 0;
//        size = 10675;
//        thumb_160 = "https://slack-files.com/files-tmb/T04KQTG87-F04PUKX9Y-3ee62e990d/pasted_image_at_2015_05_09_11_59_pm_160.png"; // Image
//        thumb_360 = "https://slack-files.com/files-tmb/T04KQTG87-F04PUKX9Y-3ee62e990d/pasted_image_at_2015_05_09_11_59_pm_360.png";
//        "thumb_360_h" = 114;
//        "thumb_360_w" = 249;
//        "thumb_64" = "https://slack-files.com/files-tmb/T04KQTG87-F04PUKX9Y-3ee62e990d/pasted_image_at_2015_05_09_11_59_pm_64.png";
//        "thumb_80" = "https://slack-files.com/files-tmb/T04KQTG87-F04PUKX9Y-3ee62e990d/pasted_image_at_2015_05_09_11_59_pm_80.png";
//        timestamp = 1431240202;
//        title = "Pasted image at 2015-05-09, 11:59 PM";
//        url = "https://slack-files.com/files-pub/T04KQTG87-F04PUKX9Y-f7bc225c43/pasted_image_at_2015_05_09_11_59_pm.png";
//        url_download = "https://slack-files.com/files-pub/T04KQTG87-F04PUKX9Y-f7bc225c43/download/pasted_image_at_2015_05_09_11_59_pm.png";
//        url_private = "https://files.slack.com/files-pri/T04KQTG87-F04PUKX9Y/pasted_image_at_2015_05_09_11_59_pm.png";
//        url_private_download = "https://files.slack.com/files-pri/T04KQTG87-F04PUKX9Y/download/pasted_image_at_2015_05_09_11_59_pm.png";
//        user = U04KQTG8D;
//    };
//    subtype = "file_share";
//    text = "<@U04KQTG8D|shanerogers> uploaded a file: <https://stndout.slack.com/files/shanerogers/F04PUKX9Y/pasted_image_at_2015_05_09_11_59_pm.png|Pasted image at 2015-05-09, 11:59 PM>";
//    ts = "1431240203.000002";
//    type = message;
//    upload = 1;
//    user = U04KQTG8D;
//}
