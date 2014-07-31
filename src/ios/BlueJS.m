//
//  BlueJS.m
//  Cordova Plugin for nrf51822 modules
//
//  (c) 2014 Arthur Hennequin (Karang)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "BlueJS.h"
#import <Cordova/CDV.h>

@implementation BlueJS

@synthesize manager;
@synthesize peripherals;
@synthesize activePeripheral;

CBUUID *service_uuid;
CBUUID *send_characteristic_uuid;
CBUUID *receive_characteristic_uuid;
CBUUID *disconnect_characteristic_uuid;
NSArray *characteristics;

CBCharacteristic *send_characteristic;
CBCharacteristic *disconnect_characteristic;

- (void) pluginInitialize {
    NSLog("BlueJS v0.0.1");
    NSLog("(c) 2014 Arthur Hennequin (Karang)");
    
    [super pluginInitialize];
    
    peripherals = [NSMutableArray array];
    
    // RFduino services
    service_uuid = [CBUUID UUIDWithString:@"2220"];
    receive_characteristic_uuid = [CBUUID UUIDWithString:@"2221"];
    send_characteristic_uuid = [CBUUID UUIDWithString:@"2222"];
    disconnect_characteristic_uuid = [CBUUID UUIDWithString:@"2223"];
    
    characteristics = [NSArray arrayWithObjects:send_characteristic_uuid, receive_characteristic_uuid, disconnect_characteristic_uuid, nil];
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - Plugin methods

- (void) scan:(CDVInvokedUrlCommand *)command {
    NSLog("Scan");
}

- (void) connect:(CDVInvokedUrlCommand *)command {
    NSLog("Connect");
}

- (void) disconnect:(CDVInvokedUrlCommand *)command {
    NSLog("Disconnect");
}

- (void) listenToData:(CDVInvokedUrlCommand *)command {
    NSLog("Listen to data");
}

- (void) write:(CDVInvokedUrlCommand *)command {
    NSLog("Write");
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

@end