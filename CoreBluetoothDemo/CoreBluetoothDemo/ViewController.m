//
//  ViewController.m
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import "ViewController.h"
#import "JumaDeviceManager.h"
#import "DeviceViewController.h"
#import "DataViewController.h"


@interface ViewController () <JumaDeviceManagerDelegate, DeviceViewControllerDelegate>

@property (nonatomic, strong) DeviceViewController *deviceController;
@property (nonatomic, strong) DataViewController *dataController;

@property (nonatomic, copy) NSString *deviceUUID;
@property (nonatomic, copy) NSString *deviceName;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *scanBtn;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UITextField *UUIDField;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *dataButtons;

@property (nonatomic, strong) JumaDeviceManager *deviceManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (UIButton *btn in self.dataButtons) {
        btn.layer.borderColor = [UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:0.3].CGColor;
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 5;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [btn addGestureRecognizer:longPress];
    }
    
    self.scanBtn.layer.borderColor = [UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:0.3].CGColor;
    self.scanBtn.layer.borderWidth = 1;
    self.scanBtn.layer.cornerRadius = 5;
    
    self.connectBtn.layer.borderColor = [UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:0.3].CGColor;
    self.connectBtn.layer.borderWidth = 1;
    self.connectBtn.layer.cornerRadius = 5;
    
    [self.textView addObserver:self
                    forKeyPath:@"text"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
    
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress {
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        if (self.dataController == nil) {
            self.dataController = [[DataViewController alloc] init];
        }
        
        self.dataController.btn = (UIButton *)longPress.view;
        [self presentViewController:self.dataController animated:YES completion:nil];
        
        NSLog(@"%s begin", __func__);
    }
}

- (void)dealloc {
    [self.textView removeObserver:self forKeyPath:@"text"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.textView && [keyPath isEqualToString:@"text"]) {
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 1, 1)];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.deviceManager == nil) {
        
        self.deviceManager = [[JumaDeviceManager alloc] init];
        self.deviceManager.delegate = self;
    }
}

- (void)endEditing {
    
    [self.UUIDField endEditing:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self endEditing];
}

- (IBAction)scan:(id)sender {
    
    [self endEditing];
    
    if (self.deviceController == nil) {
        self.deviceController = [[DeviceViewController alloc] init];
        self.deviceController.delegate = self;
    }
    
    [self.deviceController clearDevices];
    [self presentViewController:self.deviceController animated:YES completion:nil];
    
    NSLog(@"scanning");
    self.scanBtn.enabled = NO;
    self.textView.text = [self.textView.text stringByAppendingString:@"scanning\n"];
}

- (IBAction)connect:(UIButton *)sender {
    [self endEditing];
    
    if ([sender.currentTitle isEqualToString:@"connect"]) {
        
        if (self.UUIDField.text.length == 0) {
            [self presentViewController:self.deviceController animated:YES completion:nil];
        }
        else {
            [self.deviceManager connectDevice:self.deviceUUID];
        }
    }
    else {
        [self.deviceManager disconnectDevice];
    }
}

- (IBAction)send:(UIButton *)sender {
    [self endEditing];
    
    [self.deviceManager sendData:[self dataFromHexString:sender.currentTitle]];
}

- (NSData *)dataFromHexString:(NSString *)hexString {
    
    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    }
    
    const char *chars = [hexString UTF8String];
    int i = 0, len = hexString.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return [data copy];
}

#pragma mark - DeviceViewControllerDelegate
- (void)deviceController:(DeviceViewController *)deviceController didScanDeviceWithName:(NSString *)deviceName {
    
    self.deviceName = deviceName;
    [self.deviceManager scanDeviceWithName:self.deviceName];
}

- (void)deviceController:(DeviceViewController *)deviceController didSelectDevice:(Device *)device {
    
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did select device, name : %@, uuid : %@\n", device.deviceName, device.deviceUUID]];
    
    self.UUIDField.text = device.deviceUUID;
    self.deviceUUID = device.deviceUUID;
    self.deviceName = device.deviceName;
    self.connectBtn.enabled = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - JumaDeviceManagerDelegate

- (void)deviceManager:(JumaDeviceManager *)deviceManager didUpdateState:(JumaDeviceManagerState)state {
    
    switch (state) {
        case JumaDeviceManagerStatePoweredOn:    NSLog(@"Bluetooth is powerd on");     break;
        case JumaDeviceManagerStatePoweredOff:   NSLog(@"Bluetooth is powerd off");          return;
        case JumaDeviceManagerStateUnauthorized: NSLog(@"Bluetooth is unauthorized");        return;
        case JumaDeviceManagerStateUnsupported:  NSLog(@"Bluetooth state is unsupported");   return;
        case JumaDeviceManagerStateResetting:    NSLog(@"Bluetooth is being reset");         return;
        case JumaDeviceManagerStateUnknown:      NSLog(@"Bluetooth state is unknown");       return;
    }
    
    self.scanBtn.enabled = YES;
    self.textView.text = @"Bluetooth is powered on. You can scan now.\n";
}

- (void)deviceManagerDidStopScan:(JumaDeviceManager *)deviceManager {
    
    self.scanBtn.enabled = YES;
    
    self.textView.text = [self.textView.text stringByAppendingString:@"did stop scan\n"];
}

- (void)deviceManager:(JumaDeviceManager *)deviceManager didDiscoverDevice:(NSString *)deviceUUID name:(NSString *)deviceName RSSI:(NSNumber *)RSSI {
    
    NSLog(@"did found device: %@", deviceName);
    
    self.connectBtn.enabled = YES;
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did found device: %@\n", deviceName]];
     
    [self.deviceController appendDevice:[Device deviceWithDeviceUUID:deviceUUID deviceName:deviceName RSSI:RSSI]];
}

- (void)deviceManager:(JumaDeviceManager *)deviceManager didConnectDevice:(NSString *)deviceUUID {
    
    [self.connectBtn setTitle:@"disconnect" forState:UIControlStateNormal];
    
    for (UIButton *btn in self.dataButtons) {
        btn.enabled = YES;
    }
    
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did connect device: %@\n", self.deviceName]];
    
    //    NSData *data = [@"text for test" dataUsingEncoding:NSUTF8StringEncoding];
    //    [deviceManager sendData:data];
}

- (void)deviceManager:(JumaDeviceManager *)deviceManager didFailToConnectDevice:(NSString *)deviceUUID error:(NSString *)error {
    [self.connectBtn setTitle:@"connect" forState:UIControlStateNormal];
    
    for (UIButton *btn in self.dataButtons) {
        btn.enabled = NO;
    }
    
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did fail to connect device: %@\n", self.deviceName]];
}

- (void)deviceManager:(JumaDeviceManager *)deviceManager didDisconnectDevice:(NSString *)deviceUUID byRemote:(BOOL)byRemote code:(NSInteger)code error:(NSString *)error {
    
    [self.connectBtn setTitle:@"connect" forState:UIControlStateNormal];
    for (UIButton *btn in self.dataButtons) {
        btn.enabled = NO;
    }
    
    NSString *info = [NSString stringWithFormat:@"did disconnect device: %@, error : %@\n", self.deviceName, error];
    self.textView.text = [self.textView.text stringByAppendingString:info];
    NSLog(@"did disconnect device, error : %@", error);
    
    // 如果不是手机主动断开连接就自动重连
    if (byRemote) {
        [deviceManager connectDevice:deviceUUID];
    }
}

- (void)deviceManager:(JumaDeviceManager *)deviceManager didReceiveData:(NSData *)data error:(NSString *)error {
    
    if (error) {
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did recevice value from device <%@>\n", self.deviceName]];
        
        NSLog(@"did fail to get value from device, error : %@", error);
    }
    else {
        
        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"did recevice data %@ from device <%@>\n", data, self.deviceName]];
        
        NSLog(@"did get value : %@", data);
    }
    
}

@end

