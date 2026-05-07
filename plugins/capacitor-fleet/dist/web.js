"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MGLFleetSdkWeb = void 0;
const core_1 = require("@capacitor/core");
class MGLFleetSdkWeb extends core_1.WebPlugin {
    async initialize(_options) {
        /* Web has no native core; callers should guard with Capacitor.isNativePlatform(). */
    }
    async presentFleetFlow(_options) {
        throw this.unavailable('MGL Fleet flow is available on iOS and Android only.');
    }
}
exports.MGLFleetSdkWeb = MGLFleetSdkWeb;
