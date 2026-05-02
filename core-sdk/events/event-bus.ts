export type EventCallback<T = unknown> = (payload: T) => void;

/** Framework-agnostic pub/sub — event names are strings (use FleetSDKEvent for docs). */
export class FleetEventBus {
  private listeners = new Map<string, Set<EventCallback>>();

  on(event: string, cb: EventCallback): void {
    let set = this.listeners.get(event);
    if (!set) {
      set = new Set();
      this.listeners.set(event, set);
    }
    set.add(cb);
  }

  off(event: string, cb: EventCallback): void {
    this.listeners.get(event)?.delete(cb);
  }

  emit(event: string, payload?: unknown): void {
    const set = this.listeners.get(event);
    if (!set) return;
    for (const cb of set) {
      cb(payload);
    }
  }
}
