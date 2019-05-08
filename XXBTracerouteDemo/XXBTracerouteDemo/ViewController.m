//
//  ViewController.m
//  XXBTracerouteDemo
//
//  Created by xiaobing5 on 2019/4/16.
//  Copyright © 2019 xiaobing5. All rights reserved.
//

#import "ViewController.h"
#import <XXBTraceroute/XXBTraceroute.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
- (IBAction)startTraceRoute:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *resoultTextView;

@property(nonatomic, strong) XXBTraceRouteQueue    *traceRouteQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"XXB: %@",XXBTracerouteVersionString);
    self.traceRouteQueue = [XXBTraceRouteQueue traceRouteQueue];
}


- (IBAction)startTraceRoute:(id)sender {
    [self.view endEditing:YES];
    NSString *hostString = self.hostTextField.text;
    if (hostString.length == 0) {
        hostString = @"weibo.com";
    }
    __weak typeof(self) weakSelf = self;
    [self.traceRouteQueue inTraceRoute:^(XXBTracerouteUtil *tracerouteUtil) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        XXBTracerouteContext *context = [XXBTracerouteContext defaultContext];
        context.host = hostString;
        context.stepCallback = ^(XXBTracerouteRecord *record) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.resoultTextView.text = [strongSelf.resoultTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",[record getMessage]]];
            });
        };
        context.finishaCallBack = ^(NSArray<XXBTracerouteRecord *> *results, BOOL succeed) {
            NSString *endString = nil;
            if (succeed) {
                endString = @"SUCCESS\n";
            } else {
                endString = @"FAIL\n";
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                strongSelf.resoultTextView.text = [strongSelf.resoultTextView.text stringByAppendingString:endString];
            });
        };
        [tracerouteUtil startTracerouteWithContext:context];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
@end
