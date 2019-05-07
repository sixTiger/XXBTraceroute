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
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"XXB: %@",XXBTracerouteVersionString);
}


- (IBAction)startTraceRoute:(id)sender {
}
    @end
