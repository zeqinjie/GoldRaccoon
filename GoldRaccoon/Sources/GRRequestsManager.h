//
//  GRRequestsManager.h
//  GoldRaccoon
//  v1.0.1
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GRRequestsManagerProtocol.h"

/**
 Instances of this class manage a queue of requests against an FTP server.
 The different request types are:
 
  * list directory
  * create directory
  * delete directory
  * delete file
  * upload file
  * download file
 
 As soon as the requests are submitted to the GRRequestsManager, they are queued in a FIFO queue.
 The FTP Manager must be started with the startProcessingRequests method and can be shut down with the stopAndCancelAllRequests method.
 When processed, the requests are executed one at a time (max concurrency = 1).
 When no more requests are in the queue the GRRequestsManager automatically shut down.
 */
typedef NS_ENUM(NSInteger,FTPManagerType){
    //开始
     FTPManagerTypeDidStart,
    //获取列表
     FTPManagerTypeDidCompleteListing,
    //完成创建目录
     FTPManagerTypeDidCompleteCreateDirectory,
    //完成删除
     FTPManagerTypeDidCompleteDelete,
    //完成百分比
     FTPManagerTypeDidCompletePercent,
    //完成上传
     FTPManagerTypeDidCompleteUpload,
    //完成下载
     FTPManagerTypeDidCompleteDownload,
    //失败写目录
     FTPManagerTypeDidFailWritingFileAtPath,
    //错误失败
     FTPManagerTypeDidFail,
};
//监听通知
#define FTPDidFishNotifacation      @"FTPDidFishNotifacation"
@class GRRequest;
@interface GRRequestsManager : NSObject <GRRequestsManagerProtocol>

typedef void(^FTPManCompStateBlock)(GRRequestsManager *requestMan,GRRequest *request,CGFloat progress,NSString *pathStr,NSArray *listArr,NSError *error,FTPManagerType type);
/**
 Reference to the delegate object
 */

@property (nonatomic, copy) NSString *taskName;

@property (nonatomic, weak) id<GRRequestsManagerDelegate> delegate;

@property (nonatomic, copy) FTPManCompStateBlock block;


/**
 @brief Initialize a GRRequestsManager object with given hostname, username and password.
 @param hostname The hostname of the FTP service to connect to.
 @param username The username to use for connecting to the FTP service.
 @param password The password to use for connecting to the FTP service.
 @return A GRRequestsManager object.
 */
- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password;

@end
