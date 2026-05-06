/**
 * When the app runs inside the MGL Fleet SDK WebView (Android / iOS native),
 * native injects `window.MglFleetNative` for returning to the host app.
 */
declare global {
  interface Window {
    MglFleetNative?: {
      /** JSON string payload merged into the SDK success result. */
      completeFleetFlow(payloadJson: string): void;
      cancelFleetFlow(): void;
    };
  }
}

export function isMglFleetNativeEmbedded(): boolean {
  return typeof window !== "undefined" && !!window.MglFleetNative;
}

export function mglFleetNativeCompleteFlow(
  payload?: Record<string, unknown>,
): void {
  const json = JSON.stringify(payload ?? {});
  window.MglFleetNative?.completeFleetFlow(json);
}

export function mglFleetNativeCancelFlow(): void {
  window.MglFleetNative?.cancelFleetFlow();
}
