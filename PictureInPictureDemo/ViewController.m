//
//  ViewController.m
//  PictureInPictureDemo
//
//  Created by HN on 2022/4/1.
//

#import "ViewController.h"
#import "TestViewController.h"
#import "AppDelegate.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (IBAction)pushNext:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (delegate.testVC) {
        [self.navigationController pushViewController:delegate.testVC animated:YES];
        return;
    }
    TestViewController *testVC = [[TestViewController alloc]init];
    [self.navigationController pushViewController:testVC animated:YES];
}

@end
