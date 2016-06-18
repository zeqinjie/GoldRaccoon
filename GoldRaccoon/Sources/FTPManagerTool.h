//
//  FTPManagerTool.h
//  Yanfang
//
//  Created by zhengzeqin on 16/3/28.
//  Copyright © 2016年 com.injoinow. All rights reserved.
/*
    注意
    1.不同的任务操作 taskName 一定不同 否则会cancel 前一个任务操作，
    2.同时注意任务操作成功后要销毁改任务
 */

#import <Foundation/Foundation.h>
#import "GRRequestsManager.h"
#import "GRRequest.h"



@interface FTPManagerTaskObj : NSObject
//服务器地址
@property (copy, nonatomic) NSString *hostUrl;
//用户名称
@property (copy, nonatomic) NSString *userName;
//用户密码
@property (copy, nonatomic) NSString *userPwd;
//远程目录
@property (copy, nonatomic) NSString *remotePath;
//本地目录
@property (copy, nonatomic) NSString *localPath;
//任务名称 标记 注意每个请求任务名称不一样
@property (copy, nonatomic) NSString *taskName;
@end

@interface FTPManagerTool : NSObject
//任务操作集合
@property (strong, nonatomic) NSMutableDictionary<NSString *,GRRequestsManager *> *taskDic;

/**
 *  配置操作
 *
 *  @param hostUrl 服务器名
 *  @param name    用户名
 *  @param pwd     用户密码

 */
+ (instancetype)sharedInstance;
/**
 *  下载操作
 *
 *  @param remotePath 远程目录
 *  @param localPath  本地目录
 *  @param isReDownLoad 无论如何是否重新下载 默认是否
 *  @param block      回调
 */
- (void)downLoadTaskObj:(FTPManagerTaskObj *)obj
                  block:(FTPManCompStateBlock)block
           isReDownLoad:(BOOL)isReDownLoad;
/**
 *  上传操作
 *
 *  @param remotePath 远程目录
 *  @param localPath  本地目录
 *  @param block      回调
 */
- (void)upLoadTaskObj:(FTPManagerTaskObj *)obj
                block:(FTPManCompStateBlock)block;

/**
 *  创建远程目录
 *
 *  @param remotePath 远程目录
 *  @param block      回调
 */
- (void)creatRemPathTaskObj:(FTPManagerTaskObj *)obj
                      block:(FTPManCompStateBlock)block;



@end
