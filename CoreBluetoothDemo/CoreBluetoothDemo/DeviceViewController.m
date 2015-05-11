//
//  DeviceViewController.m
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import "DeviceViewController.h"

@implementation Device

- (instancetype)initWithDeviceUUID:(NSString *)deviceUUID deviceName:(NSString *)deviceName RSSI:(NSNumber *)RSSI {
    if (self = [super init]) {
        self.deviceUUID = deviceUUID;
        self.deviceName = deviceName;
        self.RSSI = RSSI;
    }
    return self;
}

+ (instancetype)deviceWithDeviceUUID:(NSString *)deviceUUID deviceName:(NSString *)deviceName RSSI:(NSNumber *)RSSI {
    return [[self alloc] initWithDeviceUUID:deviceUUID deviceName:deviceName RSSI:RSSI];
}

@end






@interface DeviceViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITextField *nameField;

@property (nonatomic, strong) NSMutableArray *devices;

@end

@implementation DeviceViewController

- (IBAction)start:(id)sender {
    
    [self.devices removeAllObjects];
    
    if ([self.delegate respondsToSelector:@selector(deviceController:didScanDeviceWithName:)]) {
        [self.delegate deviceController:self didScanDeviceWithName:self.nameField.text];
    }
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (instancetype)init {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

- (NSMutableArray *)devices {
    if (_devices == nil) {
        _devices = [NSMutableArray array];
    }
    return _devices;
}

- (void)appendDevice:(Device *)device {
    
    [self.devices addObject:device];
    [self.tableView reloadData];
}

- (void)clearDevices {
    [self.devices removeAllObjects];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning {
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    Device *device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"name : %@, RSSI : %.2f", device.deviceName, device.RSSI.doubleValue];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@", device.deviceUUID];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    
    return cell;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.delegate respondsToSelector:@selector(deviceController:didSelectDevice:)]) {
        [self.delegate deviceController:self
                        didSelectDevice:[self.devices objectAtIndex:indexPath.row]];
    }
}

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
