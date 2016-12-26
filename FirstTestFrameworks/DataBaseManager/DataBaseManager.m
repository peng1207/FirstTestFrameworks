//
//  DataBaseManager.m
//  FirstTestFrameworks
//
//  Created by Mac on 16/12/26.
//  Copyright © 2016年 huangshupeng. All rights reserved.
//

#import "DataBaseManager.h"

@implementation DataBaseManager
    
/**
 插入一条数据到数据库

 @param model 需要插入model
 */
+ (void)insertToModel:(id)model{
    
}

/**
 插入数组model到数据库

 @param arrayModel 需要插入数组model
 */
+ (void)insertToArrayModel:(NSArray *)arrayModel{
    
}
    
/**
 查询数据

 @param startIndex 开始的位置
 @param count 查询多少条数据  为0 则查询全部
 @param model 需要查询model的类名
 @param where 条件语句 key为model里的属性
 @return 数组
 */
+ (NSArray *)selectArray:(NSInteger)startIndex count:(NSInteger)count model:(id)model where:(NSString *)where{
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    return dataArray;
}

/**
 删除数据

 @param model 需要删除的model类
 @param where 条件语句 key为model里的属性
 */
+ (void)deleteToModel:(id)model where:(NSString *)where{
    
}
/**
 更新数据

 @param model 需要更新的model
 @param where 条件语句 key为model里的属性
 */
+ (void)updataToModel:(id)model where:(NSString *)where{
    
}
    
@end
