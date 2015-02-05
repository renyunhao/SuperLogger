//
//  SuperLogerListViewTableViewController.m
//  LogToFileDemo
//
//  Created by YourtionGuo on 12/23/14.
//  Copyright (c) 2014 GYX. All rights reserved.
//

#import "SuperLogerListView.h"
#import "SuperLogger.h"
#import <MessageUI/MessageUI.h>
#import "SuperLoggerPreviewView.h"

@interface SuperLogerListView ()<UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
@property(strong,nonatomic) NSArray *fileList;
@property (strong) UINavigationBar* navigationBar;
@property (strong, nonatomic) NSString *tempFilename;
@end

@implementation SuperLogerListView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)layoutNavigationBar
{
    self.navigationBar.frame = CGRectMake(0, self.tableView.contentOffset.y, self.tableView.frame.size.width, self.topLayoutGuide.length + 44);
    self.tableView.contentInset = UIEdgeInsetsMake(self.navigationBar.frame.size.height, 0, 0, 0);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self layoutNavigationBar];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutNavigationBar];
}

- (void)loadView
{
    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    self.tableView = [[UITableView alloc]initWithFrame:applicationFrame];
    self.view.backgroundColor=[UIColor whiteColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle* myBundle;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SuperLogger" ofType:@"bundle"];
    myBundle = [NSBundle bundleWithPath:path];
    
    self.fileList = [[SuperLogger sharedInstance]getLogList];
    self.navigationItem.title = NSLocalizedStringFromTableInBundle( @"SL_LogList", @"SLLocalizable", myBundle, @"Log file list");
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_navigationBar];
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
    UIBarButtonItem *backBtn=[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle( @"SL_Back", @"SLLocalizable",myBundle, @"Back") style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    [self.navigationItem setLeftBarButtonItem:backBtn];
    UIBarButtonItem *cleanBtn=[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle( @"SL_Clean",@"SLLocalizable", myBundle, @"Clean") style:UIBarButtonItemStylePlain target:self action:@selector(clean)];
    [self.navigationItem setRightBarButtonItem:cleanBtn];
}

-(void)done
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)clean
{
    [[SuperLogger sharedInstance]cleanLogs];
    self.fileList = nil;
    self.fileList = [[SuperLogger sharedInstance]getLogList];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fileList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]init];
    cell.textLabel.text = self.fileList[indexPath.row];
    if ([[SuperLogger sharedInstance] isStaredWithFilename:self.fileList[indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _tempFilename = [_fileList objectAtIndex:indexPath.row];
    [self exportTapped:self];
}

- (void)exportTapped:(id)sender
{
    
    NSBundle* myBundle;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SuperLogger" ofType:@"bundle"];
    myBundle = [NSBundle bundleWithPath:path];
    
    NSString *isStar = [[SuperLogger sharedInstance] isStaredWithFilename:_tempFilename] ? NSLocalizedStringFromTableInBundle( @"SL_Unstar", @"SLLocalizable", myBundle,@"Unstar"): NSLocalizedStringFromTableInBundle( @"SL_Star", @"SLLocalizable", myBundle, @"Star");
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:_tempFilename
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle( @"SL_Cancel", @"SLLocalizable", myBundle, @"Cancel")
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:isStar ,NSLocalizedStringFromTableInBundle( @"SL_Preview", @"SLLocalizable",myBundle, @"Preview"),NSLocalizedStringFromTableInBundle( @"SL_SendViaMail", @"SLLocalizable", myBundle, @"Send via Email"), NSLocalizedStringFromTableInBundle( @"SL_Delete", @"SLLocalizable",myBundle, @"Delete"), nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex ==  0) {
        [[SuperLogger sharedInstance]starWithFilename:_tempFilename];
        self.fileList = nil;
        self.fileList = [[SuperLogger sharedInstance]getLogList];
        [self.tableView reloadData];
    }
    else if (buttonIndex ==  1) {
        SuperLoggerPreviewView *pre = [[SuperLoggerPreviewView alloc]init];
        pre.logData = [[SuperLogger sharedInstance] getDataWithFilename:_tempFilename];
        pre.logFilename = _tempFilename;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self presentViewController:pre animated:YES completion:nil];
        });
    }
    else if (buttonIndex == 2) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            SuperLogger *logger = [SuperLogger sharedInstance];
            NSData *tempData = [logger getDataWithFilename:_tempFilename];
            if (tempData != nil) {
                MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                [picker setSubject:logger.mailTitle];
                [picker setToRecipients:logger.mailRecipients];
                [picker addAttachmentData:tempData mimeType:@"application/text" fileName:_tempFilename];
                [picker setToRecipients:[NSArray array]];
                [picker setMessageBody:logger.mailContect isHTML:NO];
                [picker setMailComposeDelegate:self];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    @try {
                        [self presentViewController:picker animated:YES completion:nil];
                    }
                    @catch (NSException * e)
                    { NSLog(@"Exception: %@", e); }
                });
            }
        }];
    }
    else if (buttonIndex == 3) {
        [[SuperLogger sharedInstance]deleteLogWithFilename:_tempFilename];
        self.fileList = nil;
        self.fileList = [[SuperLogger sharedInstance]getLogList];
        [self.tableView reloadData];
    }
    
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
