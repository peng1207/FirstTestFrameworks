//
//  DataBaseManager.m
//  FirstTestFrameworks
//
//  Created by Mac on 16/12/26.
//  Copyright © 2016年 huangshupeng. All rights reserved.
//

#import "OkDataBaseManager.h"
#import "MJExtension.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
 static OkDataBaseManager *dataManager = nil;

@interface OkDataBaseManager ()

@property (nonatomic,strong)  FMDatabase * db;      /**< 数据库对象*/
    
@end

@implementation OkDataBaseManager
#pragma mark - //****************** 内部的方法 ******************//
+(instancetype)allocWithZone:(struct _NSZone *)zone{
   
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataManager = [super allocWithZone:zone];
    });
    return dataManager;
}
 
/**
   初始化单例

 @return 返回当前类的对象
 */
+ (instancetype)shareDatabase{
    return [[self alloc] init ];
}
#pragma mark - //****************** 数据库的初始化 打开关闭方法 ******************//
/**
 创建数据库
 */
- (void)creatDatabase{
    if (!_db) {
        // 一般保存到cache目录里面
        NSString *dataPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
         dataPath = [dataPath stringByAppendingPathComponent:@"okdeerData.db"];
        _db = [FMDatabase databaseWithPath:dataPath];
    }
}
/**
 打开数据库
 */
- (void)openDatabase{
    if (![_db open]) {
        [_db open]; 
    }
}
/**
 关闭数据库
 */
- (void)closeDatabase{
    [_db close];
}
#pragma mark - //****************** 创建表的操作 ******************//
/**
 获取表的名字

 @param class model 的clas
 @return 表名
 */
- (NSString *)getTableNameToModel:(Class)class{
    return [@"t_" stringByAppendingString:NSStringFromClass(class)];
 }
/**
 创建表

 @param class model的class
 */
- (void)creatTable:(Class)class{
    if (class) {
        [self creatDatabase];
        [self openDatabase];
        // 创建表  只创建一个主键
        NSString *tableName = [self getTableNameToModel:class];
        [self.db executeUpdate:[NSString stringWithFormat:@"create table if not exists %@ (id INTEGER PRIMARY KEY AUTOINCREMENT)",tableName]];
        for (NSString *key in  [self getAllPropertyNames:class]) {
            [self addTableColumn:key table:tableName];
        }
    }
}
/**
 添加字段到表中 这个方法会处理字段是否存在的

 @param column 字段名
 @param tableName 表名
 */
- (void)addTableColumn:(NSString *)column table:(NSString *)tableName{
    if ([self customcolumnExists:column andtableName:tableName]) {
        // 存在表中 不操作
    }else{
        // 不存在表中 需要添加到表中
        [self addTableToColumn:column table:tableName];
    }
}
/**
 添加字段到表中 不做任何处理

 @param column 字段名
 @param tableName 表名
 */
- (void)addTableToColumn:(NSString *)column table:(NSString *)tableName{
    if ([column isKindOfClass:[NSString class]] && column.length && [tableName isKindOfClass:[NSString class]] && tableName.length) {
         // 判断字段名称和表名是否为字符串 并且大于0 字段添加到数据库中
        NSString *sql = [NSString stringWithFormat:@"alter table %@ add %@ text",tableName,column];
        [self creatDatabase];
        [self openDatabase];
        [_db executeUpdate:sql];
    }
}
    
/**
 判断字段是否存在表中

 @param columnName 字段名
 @param tableName 表名
 @return 是否存在  YES 存在  NO 不存在
 */
- (BOOL)customcolumnExists:(NSString *)columnName andtableName:(NSString *)tableName{
    if ([columnName isKindOfClass:[NSString class]] && columnName.length && [tableName isKindOfClass:[NSString class]] && tableName.length) {
        // 判断字段名称和表名是否为字符串 并且大于0
        [self creatDatabase];
        [self openDatabase];
        return [_db columnExists:columnName inTableWithName:tableName] ;
    }else{
        // 否则设置为存在表中
        return YES;
    }
}
#pragma mark - //****************** 表的操作 增删改相关的方法 ******************//

/**
 插入一条数据到数据库

 @param model 需要插入model
 */
- (void)insertToModel:(id)model{
    if (model) {
        Class class = [model class];
        [self creatDatabase];
        [self openDatabase];
        [self creatTable:class];
        //格式化插入sql语句
        NSString * sql = @"insert into %@ (%@) values(%@)";
        NSDictionary *keyValueDic = [model mj_keyValues];
        // 获取所有的字段
        NSArray *keyArray = [keyValueDic allKeys];
        NSString * namelist = [keyArray componentsJoinedByString:@","];
        NSMutableString * valuelist = [NSMutableString string];
        
        for (NSInteger i = 0 ; i < keyArray.count; i++) {
            if (i==0) {
                [valuelist appendFormat:keyValueDic[keyArray[i]]];
            }else{
                [valuelist appendFormat:@",%@",keyValueDic[keyArray[i]]];
            }
        }
         //格式化最终的插入语句
        sql = [NSString stringWithFormat:sql,[self getTableNameToModel:class],namelist,valuelist];
        BOOL sussess = [_db executeUpdate:sql];
        NSLog(@"insert status is %d",sussess);
        [self closeDatabase];
    }
}
/**
 插入数组model到数据库

 @param arrayModel 需要插入数组model
 */
- (void)insertToArrayModel:(NSArray *)arrayModel{
    @try {
        [self creatDatabase];
        //开始事务
        [_db beginTransaction];
        for (id model in arrayModel) {
            [self insertToModel:model];
        }
    } @catch (NSException *exception) {
        [_db rollback];
    } @finally {
        [_db commit];
    }
}
/**
 查询数据

 @param startIndex 开始的位置
 @param count 查询多少条数据  为0或小于0 则查询全部
 @param modelClass 需要查询model的类名
 @param where 条件语句 例如 key = value and key1 = value1
 @return 数组
 */
- (NSArray *)selectArray:(NSInteger)startIndex count:(NSInteger)count modelClass:(Class)modelClass where:(NSString *)where{
    if (modelClass) {
        [self creatDatabase];
        [self openDatabase];
        
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        //查询指定表中从startindex条记录开始的count条记录
        NSString * sql = @"select %@ from %@";
        //如果有查询条件
        if (where && [where isKindOfClass:[NSString class]] && where.length) {
            sql = [sql stringByAppendingFormat:@" where %@", where];//where是段名
        }
        //如果需要读取限制
        if (count > 0 ) {
            sql = [sql stringByAppendingFormat:@" limit %ld,%ld", (long)startIndex, (long)count];
        }
        id model = [[modelClass alloc] init];
        //获得查询的字段列表字符串
         NSString * namelist = [[self getAllPropertyNames:modelClass] componentsJoinedByString:@","];
        //格式化查询语句
        sql = [NSString stringWithFormat:sql,namelist,[self getTableNameToModel:modelClass]];
        //执行查询
        FMResultSet * rs = [_db executeQuery:sql];
        //便利结果集，一次或得一条记录
        while ([rs next]) {
            //获得当前记录数据字典
            NSDictionary * dict = [rs resultDictionary];//当前记录转换为字典
            
            //根据传入的模型创建相同类型对象
            id  newModel = [modelClass mj_objectWithKeyValues:dict];
            if (newModel) {
                [dataArray addObject:newModel];
            }
        }
        if (dataArray.count == 0) {
            NSLog(@"error is %@",[_db lastErrorMessage]);
        }
        return dataArray;
    }else{
        return nil;
    }
}
/**
 删除数据

 @param model 需要删除的model类
 @param where 条件语句 例如 key = value and key1 = value1
 */
- (void)deleteToModel:(id)model where:(NSString *)where{
    if (model) {
        [self creatDatabase];
        [self openDatabase];
        NSString * sql = @"delete from %@";
        if (where && [where isKindOfClass:[NSString class]] && where.length) {
            sql = [sql stringByAppendingFormat:@"where %@", where];
        }
        sql = [NSString stringWithFormat:sql,[self getTableNameToModel:[model class]]];
       BOOL sussess = [_db executeUpdate:[NSString stringWithFormat:sql]];
        NSLog(@"delete status is %d",sussess);
        [self closeDatabase];
    }
}
/**
 更新数据

 @param model 需要更新的model
 @param where 条件语句 例如 key = value and key1 = value1
 */
- (void)updataToModel:(id)model where:(NSString *)where{
    if (model && where && [where isKindOfClass:[NSString class]] && where.length) {
        [self creatDatabase];
        [self openDatabase];
        NSString *sql = @"update %@ set %@";
        if (where) {
            sql = [sql stringByAppendingFormat:@" where %@",where];
        }
        NSMutableString *nameList = [[NSMutableString alloc] init];
        NSDictionary *dic = [model mj_keyValues];
        for (NSString *key in [dic allKeys]) {
            id value = dic[key];
            if (nameList.length) {
               [nameList appendFormat:@",%@ = '%@'",key,value];
            }else{
                [nameList appendFormat:@"%@ = '%@'",key,value];
            }
        }
        sql = [NSString stringWithFormat:sql,[self getTableNameToModel:[model class]],nameList];
        BOOL success = [_db executeUpdate:sql];
        NSLog(@"update status is %d",success);
        [self closeDatabase];
    }
}

/**
 通过运行时获取当前对象的所有属性的名称，以数组的形式返回

 @param class class
 @return 对应的属性
 */
- (NSArray *)getAllPropertyNames:(Class)class{
    ///存储所有的属性名称
    NSMutableArray *allNames = [[NSMutableArray alloc] init];
    
    ///存储属性的个数
    unsigned int propertyCount = 0;
    
    ///通过运行时获取当前类的属性
    objc_property_t *propertys = class_copyPropertyList(class, &propertyCount);
    
    //把属性放到数组中
    for (int i = 0; i < propertyCount; i ++) {
        ///取出第一个属性
        objc_property_t property = propertys[i];
        
        const char * propertyName = property_getName(property);
        
        [allNames addObject:[NSString stringWithUTF8String:propertyName]];
    }
    
    ///释放
    free(propertys);
    
    return allNames;
}
#pragma mark - //****************** 外部调用的方法 ******************//
/**
 插入一条数据到数据库

 @param model 需要插入model
 */
+ (void)insertToModel:(id)model{
    [[OkDataBaseManager shareDatabase] insertToModel:model];
}

/**
 插入数组model到数据库

 @param arrayModel 需要插入数组model
 */
+ (void)insertToArrayModel:(NSArray *)arrayModel{
    [[OkDataBaseManager shareDatabase ] insertToArrayModel:arrayModel];
}
    
/**
 查询数据

 @param startIndex 开始的位置
 @param count 查询多少条数据  为0或小于0 则查询全部
 @param modelClass 需要查询model的类名
 @param where 条件语句 例如 key = value and key1 = value1
 @return 数组
 */
+ (NSArray *)selectArray:(NSInteger)startIndex count:(NSInteger)count modelClass:(Class)modelClass where:(NSString *)where{
    return  [[OkDataBaseManager shareDatabase] selectArray:startIndex count:count modelClass:modelClass where:where];
}

/**
 删除数据

 @param model 需要删除的model类
 @param where 条件语句 例如 key = value and key1 = value1
 */
+ (void)deleteToModel:(id)model where:(NSString *)where{
    [[OkDataBaseManager shareDatabase] deleteToModel:model where:where];
}
/**
 更新数据
 
 @param model 需要更新的model
 @param where 条件语句 例如 key = value and key1 = value1
 */
+ (void)updataToModel:(id)model where:(NSString *)where{
    [[OkDataBaseManager shareDatabase] updataToModel:model where:where];
}
    
@end
