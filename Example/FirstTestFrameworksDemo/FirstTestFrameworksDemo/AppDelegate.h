//
//  AppDelegate.h
//  FirstTestFrameworksDemo
//
//  Created by huangshupeng on 2016/10/23.
//  Copyright © 2016年 huangshupeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

