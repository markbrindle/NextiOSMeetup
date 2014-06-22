//
//  TodayViewController.m
//  NSLondon
//
//  Created by Mark Brindle on 17/06/2014.
//  Copyright (c) 2014 Arkemm. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSString *apiKey;
@end

@implementation TodayViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.label.text = @"Loading …";
    NSURL *URL = [self eventURL];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            self.label.text = error.localizedDescription;
        }
        else {
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *nextEvent = JSON[@"results"][0];
            [self updateLabelWithEventInfo:nextEvent];
        }
    }];
    [task resume];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSURL *)eventURL
{
    if ([self.apiKey length] > 0) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.meetup.com/2/events?&sign=true&group_urlname=NSLondon&page=20&key=%@", self.apiKey]];
    }
    else {
        self.label.text = @"Provide a valid API key!";
    }
    return nil;
}

- (void)updateLabelWithEventInfo:(NSDictionary *)eventDict
{
    NSString *labelText;
    NSString *status = eventDict[@"status"];
    NSTimeInterval eventTime = [eventDict[@"time"] doubleValue] / 1000;
    BOOL upcoming = [status isEqualToString:@"upcoming"] && eventTime > [[NSDate date] timeIntervalSince1970];
    if (upcoming) {
        NSDate *eventDate = [NSDate dateWithTimeIntervalSince1970:eventTime];
        NSString *dateString = [[self dateFormatter] stringFromDate:eventDate];
        labelText = [NSString stringWithFormat:@"Next NSLondon is on %@", dateString];
    }
    else {
        labelText = @"Ask @Daniel1of1 about the next NSLondon!";
    }
    self.label.text = labelText;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_dateFormatter;
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return _dateFormatter;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    /* The widget gets killed before the call completes, needs a background session shared with the container app */
    NSURL *URL = [self eventURL];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            self.label.text = @"Failed :(";
            completionHandler(NCUpdateResultFailed);
        }
        else {
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *nextEvent = JSON[@"results"][0];
            [self updateLabelWithEventInfo:nextEvent];
            completionHandler(NCUpdateResultNewData);
        }
    }];
    [task resume];
}

@end
