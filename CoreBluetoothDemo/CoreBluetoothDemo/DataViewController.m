//
//  DataViewController.m
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import "DataViewController.h"

@interface DataViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *oldField;
@property (weak, nonatomic) IBOutlet UITextField *newerField;

@end

@implementation DataViewController

- (instancetype)init {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.oldField.text = self.btn.currentTitle;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)cancel:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)ok:(id)sender {
    
    NSString *value = self.newerField.text;
    if ([value hasPrefix:@"0x"]) {
        value = [value substringFromIndex:2];
        NSLog(@"%@", value);
    }
    
    if (value.length == 0) {
        [self alertWithTitle:@"新值不能为空"];
        return;
    }
    
    
    
    NSArray *array = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", @"a", @"b", @"c", @"d", @"e", @"f", @"A", @"B", @"C", @"D", @"E", @"F"];
    for (NSInteger i = 0; i < value.length; i++) {
        
        unichar ch = [value characterAtIndex:i];
        NSString *str = [NSString stringWithCharacters:&ch length:1];
        if ([array containsObject:str] == NO) {
            
            [self alertWithTitle:@"新值不能含有 0-9, a-f, A-F 以外的字符"];
            return;
        }
    }
    
    [self.newerField endEditing:YES];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSString *title = [@"0x" stringByAppendingString:value.uppercaseString];
    [self.btn setTitle:title forState:UIControlStateNormal];
}

- (void)alertWithTitle:(NSString *)title {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
