//
//  GRDemoViewController.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 02/07/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRDemoViewController.h"
#import "GRRequestsManager.h"
#import "FTPManagerTool.h"
@interface GRDemoViewController () <GRRequestsManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, strong) IBOutlet UITextField *hostnameTextField;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;

- (IBAction)listingButton:(id)sender;
- (IBAction)createDirectoryButton:(id)sender;
- (IBAction)deleteDirectoryButton:(id)sender;
- (IBAction)deleteFileButton:(id)sender;
- (IBAction)uploadFileButton:(id)sender;
- (IBAction)downloadFileButton:(id)sender;

@end

@implementation GRDemoViewController



//创建目录
- (IBAction)createDirectoryButton:(id)sender
{
    //例子 创建远程目录
    FTPManagerTaskObj *obj = [FTPManagerTaskObj new];

    obj.hostUrl = @"";
    obj.userName = @"";
    obj.userPwd = @"";
    obj.remotePath = @"";
    obj.taskName = @"";
    [[FTPManagerTool sharedInstance] creatRemPathTaskObj:obj block:^(GRRequestsManager *requestMan, GRRequest *request, CGFloat progress, NSString *pathStr, NSArray *listArr, NSError *error, FTPManagerType type) {
        if (type == FTPManagerTypeDidStart) {
            //开始
        }else if (type == FTPManagerTypeDidCompleteCreateDirectory){
            //完成
            NSLog(@"FTPManagerTypeDidCompleteCreateDirectory");
        }else if (type == FTPManagerTypeDidFail){
            //失败
             NSLog(@"FTPManagerTypeDidFail");
        }
    }];
}



- (IBAction)downloadFileButton:(id)sender
{
    FTPManagerTaskObj *obj = [FTPManagerTaskObj new];
    //必填参数
    obj.hostUrl = @"";
    obj.userName = @"";
    obj.userPwd = @"";
    obj.taskName = obj.remotePath = @"";
    
    [[FTPManagerTool sharedInstance]downLoadTaskObj:obj block:^(GRRequestsManager *requestMan,GRRequest *request, CGFloat progress, NSString *pathStr, NSArray *listArr, NSError *error, FTPManagerType type) {
        if(type == FTPManagerTypeDidStart) {
            NSLog(@"开启请求:requestsManager:didStartRequest:");
        }else if (type == FTPManagerTypeDidCompletePercent){
            NSLog(@"完成百分比 = %f", progress);
        }else if (type == FTPManagerTypeDidCompleteDownload || type == FTPManagerTypeDidFail){
            NSLog(@"下载完毕 删除当前任务");
            
        }
    }isReDownLoad:YES];
    
    /* 支持断点续传，支持暂停 和  继续
    //1.从操作工具取出下载器
    GRRequestsManager *requestManager  = [[FTPManagerTool sharedInstance].taskDic objectForKey:obj.taskName];
    //2.暂停
    [requestManager pause];
   // 3.继续
    [requestManager resume];
     
     */
}

- (IBAction)deleteDirectoryButton:(id)sender
{
    //类似写
}

- (IBAction)deleteFileButton:(id)sender
{
    //类似写
}

- (IBAction)uploadFileButton:(id)sender
{
    //类似写
}

- (IBAction)listingButton:(id)sender
{
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}



@end
