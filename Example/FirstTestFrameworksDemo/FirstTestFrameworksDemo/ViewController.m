//
//  ViewController.m
//  FirstTestFrameworksDemo
//
//  Created by huangshupeng on 2016/10/23.
//  Copyright © 2016年 huangshupeng. All rights reserved.
//

#import "ViewController.h"
#import "TestDataBaseModel.h"
#import "OkDataBaseManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   TestDataBaseModel *testDataModel =  [[TestDataBaseModel alloc] init];
    testDataModel.name = @"12";
    testDataModel.age = 12;
    [OkDataBaseManager insertToModel:testDataModel];
    NSArray *listArray = [OkDataBaseManager selectArray:0 count:0 modelClass:[TestDataBaseModel class] where:nil];
    NSLog(@"%@",listArray);
    testDataModel.name = @"ssss'";
    [OkDataBaseManager updataToModel:testDataModel where:[NSString stringWithFormat:@"name =  %@",@"12"]];
 
   
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
