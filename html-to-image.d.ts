declare module 'html-to-image' {
  export function toBlob(node: HTMLElement, options?: Record<string, unknown>): Promise<Blob | null>;
}
