//
//  FTPManagerTool.m
//  Yanfang
//
//  Created by zhengzeqin on 16/3/28.
//  Copyright © 2016年 com.injoinow. All rights reserved.
//

// 缓存主目录
#define MPCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FTPCache"]

// 保存文件名
#define MPFileName(url) [[url componentsSeparatedByString:@"/"] lastObject]


// 文件的存放路径（caches）
#define MPFileFullpath(url) [MPCachesDirectory stringByAppendingPathComponent:MPFileName(url)]

#import "FTPManagerTool.h"
#define WS(weakSelf) __weak __typeof(&*self)weakSelf = self;
@implementation FTPManagerTaskObj



@end

@interface FTPManagerTool()


@end

@implementation FTPManagerTool


+ (instancetype)sharedInstance{
    static FTPManagerTool *tool;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        tool = [[FTPManagerTool alloc]init];
        tool.taskDic = [NSMutableDictionary dictionary];
    });
    return tool;
}



- (void)dealloc{
    NSLog(@"tool dealloc");
}


#pragma mark - function

- (void)downLoadTaskObj:(FTPManagerTaskObj *)obj
                  block:(FTPManCompStateBlock)block
           isReDownLoad:(BOOL)isReDownLoad{
    
    if (!obj.localPath.length) {
        obj.localPath = [self urlForRemotePath:obj.remotePath];
    }
    
    if (!obj.taskName.length) {
        obj.taskName = obj.remotePath;
    }
    
    if (isReDownLoad) {
        [self deleteFileAtPath:obj.localPath];
    }
    GRRequestsManager *requestManager = [[GRRequestsManager alloc]initWithHostname:obj.hostUrl user:obj.userName password:obj.userPwd];
    requestManager.taskName = obj.taskName;
    //    [self isExistenced:obj.taskName];
    [self.taskDic setObject:requestManager forKey:obj.taskName];
    WS(mv);
    [requestManager addRequestForDownloadFileAtRemotePath:obj.remotePath toLocalPath:obj.localPath];
    requestManager.block = ^(GRRequestsManager *requestMan,GRRequest *request,CGFloat progress,NSString *pathStr,NSArray *listArr,NSError *error,FTPManagerType type){
        block(requestMan,request,progress,pathStr,listArr,error,type);
        if (type == FTPManagerTypeDidCompleteDownload || type == FTPManagerTypeDidFail) {
            [mv.taskDic removeObjectForKey:obj.taskName];
        }
    };
    [requestManager startProcessingRequests];
    
}

- (void)upLoadTaskObj:(FTPManagerTaskObj *)obj
                block:(FTPManCompStateBlock)block{
    if (!obj.taskName.length) {
        obj.taskName = obj.remotePath;
    }
    GRRequestsManager *requestManager = [[GRRequestsManager alloc]initWithHostname:obj.hostUrl user:obj.userName password:obj.userPwd];
    requestManager.taskName = obj.taskName;
    //    [self isExistenced:obj.taskName];
    [self.taskDic setObject:requestManager forKey:obj.taskName];
    [requestManager addRequestForUploadFileAtLocalPath:obj.localPath toRemotePath:obj.remotePath];
    WS(mv);
    requestManager.block = ^(GRRequestsManager *requestMan,GRRequest *request,CGFloat progress,NSString *pathStr,NSArray *listArr,NSError *error,FTPManagerType type){
        block(requestMan,request,progress,pathStr,listArr,error,type);
        if (type == FTPManagerTypeDidCompleteUpload || type == FTPManagerTypeDidFail) {
            [mv.taskDic removeObjectForKey:obj.taskName];
        }
    };
    [requestManager startProcessingRequests];
}

- (void)creatRemPathTaskObj:(FTPManagerTaskObj *)obj
                      block:(FTPManCompStateBlock)block{
    if (!obj.taskName.length) {
        obj.taskName = obj.remotePath;
    }
    GRRequestsManager *requestManager = [[GRRequestsManager alloc]initWithHostname:obj.hostUrl user:obj.userName password:obj.userPwd];
    requestManager.taskName = obj.taskName;
    //    [self isExistenced:obj.taskName];
    [self.taskDic setObject:requestManager forKey:obj.taskName];
    [requestManager addRequestForCreateDirectoryAtPath:obj.remotePath];
    WS(mv);
    requestManager.block = ^(GRRequestsManager *requestMan,GRRequest *request,CGFloat progress,NSString *pathStr,NSArray *listArr,NSError *error,FTPManagerType type){
        block(requestMan,request,progress,pathStr,listArr,error,type);
        if (type == FTPManagerTypeDidCompleteCreateDirectory || type == FTPManagerTypeDidFail) {
            [mv.taskDic removeObjectForKey:obj.taskName];
        }
    };
    [requestManager startProcessingRequests];
}


- (void)isExistenced:(NSString *)str{
    BOOL isExistenced = [self.taskDic.allKeys containsObject:str];
    NSAssert(!isExistenced, @"已经存在该KEY");
}

//返回本地存储地址
- (NSString *)urlForRemotePath:(NSString *)remotePath{
    
    if (!remotePath) {
        NSLog(@"ftp 远程下载路径不能为空!");
        return nil;
    }
    //获取文件名
    NSString *fileName = [[remotePath componentsSeparatedByString:@"/"] lastObject];
    //缓存文件目录 (Library/Caches/FtpCache)
    NSString *cachesDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FtpCache"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachesDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"创建文件缓存路径错误 = %@",error);
            return nil;
        } else {
            NSLog(@"创建文件缓存路径成功");
        }
    }
    //获取文件缓存路径
    NSString *filePath = [cachesDirectory stringByAppendingPathComponent:fileName];
    
    return filePath;
}

//清空文件
- (void)deleteFileAtPath:(NSString *)delelteFilePath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager removeItemAtPath:delelteFilePath error:&error] != YES){
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    }else{
        NSLog(@"delete file");
    }
}
@end
