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
@synthesize activePeripheral;

CBUUID *service_uuid;
CBUUID *send_characteristic_uuid;
CBUUID *receive_characteristic_uuid;
CBUUID *disconnect_characteristic_uuid;
NSArray *characteristics;

CBCharacteristic *send_characteristic;
CBCharacteristic *disconnect_characteristic;

- (void) pluginInitialize {
    NSLog(@"BlueJS v0.0.1");
    NSLog(@"(c) 2014 Arthur Hennequin (Karang)");
    
    [super pluginInitialize];
    
    // RFduino services
    service_uuid = [CBUUID UUIDWithString:@"2220"];
    
    receive_characteristic_uuid = [CBUUID UUIDWithString:@"2221"];
    send_characteristic_uuid = [CBUUID UUIDWithString:@"2222"];
    disconnect_characteristic_uuid = [CBUUID UUIDWithString:@"2223"];
    
    characteristics = [NSArray arrayWithObjects:send_characteristic_uuid, receive_characteristic_uuid, disconnect_characteristic_uuid, nil];
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - Plugin methods

- (void) startScan:(CDVInvokedUrlCommand *)command {
    NSLog(@"Scan");
    
    onDiscoverCallbackId = [command.callbackId copy];
    
    NSDictionary *opt = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:service_uuid] options:opt];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopScan:(CDVInvokedUrlCommand *)command {
    NSLog(@"Stop scan");
    
    [manager stopScan];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand *)command {
    NSLog(@"Connect");
    
    NSString* uuid_string = [command.arguments objectAtIndex:0];
    CBUUID *device_uuid = [CBUUID UUIDWithString:uuid_string];
    CBPeripheral *device = [[manager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:device_uuid]] objectAtIndex:0];
    
    if (device) {
        NSLog(@"Connecting to peripheral with UUID : %@", uuid_string);

        [manager stopScan];
        
        onConnectCallbackId = [command.callbackId copy];
        [manager connectPeripheral:peripheral options:nil];
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Peripheral not found");
    }
}

- (void) disconnect:(CDVInvokedUrlCommand *)command {
    NSLog(@"Disconnect");
    
    if (activePeripheral) {
        [activePeripheral writeValue:[NSData data] forCharacteristic:disconnect_characteristic type:CBCharacteristicWriteWithoutResponse];
        
        if (activePeripheral.isConnected) {
            [manager cancelPeripheralConnection:activePeripheral];
        }
    }
    
    onConnectCallbackId = nil;
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) listenToData:(CDVInvokedUrlCommand *)command {
    NSLog(@"Listen to data");
    
    onDataCallbackId = [command.callbackId copy];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) write:(CDVInvokedUrlCommand *)command {
    NSLog(@"Write");
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Peripheral discovered");
    
    NSString *uuidString = ([peripheral identifier])?((__bridge_transfer NSString *)CFUUIDCreateString(NULL, peripheral.identifier)):@"";
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    [res setObject: uuidString forKey: @"uuid"];]
    [res setObject: [peripheral name] forKey: @"name"];
    [res setObject: RSSI forKey: @"rssi"];
    [res setObject: advertisementData forKey: @"advertisementData"];
    
    if (onDiscoverCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:onDiscoverCallbackId];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"CoreBluetooth Central Manager changed state: %d", central.state);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to peripheral");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from peripheral");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Unable to connect to peripheral");
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

@end