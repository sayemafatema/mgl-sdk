"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fleetSdkPresentFleetFlow = exports.fleetSdkInitialize = void 0;
const react_native_1 = require("react-native");
const NativeFleet = react_native_1.NativeModules.MglFleetSdk ?? {};
async function fleetSdkInitialize(opts) {
    if (!NativeFleet.initialize) {
        throw new Error(`MglFleetSdk native module missing on ${react_native_1.Platform.OS}`);
    }
    await NativeFleet.initialize(opts);
}
exports.fleetSdkInitialize = fleetSdkInitialize;
async function fleetSdkPresentFleetFlow(opts) {
    if (!NativeFleet.presentFleetFlow) {
        throw new Error(`MglFleetSdk native module missing on ${react_native_1.Platform.OS}`);
    }
    return NativeFleet.presentFleetFlow(opts ?? {});
}
exports.fleetSdkPresentFleetFlow = fleetSdkPresentFleetFlow;
