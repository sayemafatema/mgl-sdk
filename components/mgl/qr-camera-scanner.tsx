'use client';

import { useEffect, useRef } from 'react';
import jsQR from 'jsqr';

type QrCameraScannerProps = {
  active: boolean;
  onScan: (text: string) => void;
  onCameraError?: (message: string) => void;
  className?: string;
};

export function QrCameraScanner({ active, onScan, onCameraError, className }: QrCameraScannerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const rafRef = useRef(0);
  const doneRef = useRef(false);
  const onScanRef = useRef(onScan);
  onScanRef.current = onScan;

  useEffect(() => {
    if (!active || typeof window === 'undefined') return;
    doneRef.current = false;
    let detector: BarcodeDetector | null = null;
    let frameCount = 0;

    const stopTracks = () => {
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
      const v = videoRef.current;
      if (v) v.srcObject = null;
    };

    const start = async () => {
      if (!navigator.mediaDevices?.getUserMedia) {
        onCameraError?.('Camera not supported in this browser.');
        return;
      }
      try {
        if ('BarcodeDetector' in window) {
          detector = new BarcodeDetector({ formats: ['qr_code'] });
        }
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: { ideal: 'environment' } },
          audio: false,
        });
        streamRef.current = stream;
        const v = videoRef.current;
        if (!v) {
          stopTracks();
          return;
        }
        v.srcObject = stream;
        v.playsInline = true;
        v.muted = true;
        await v.play();

        const tick = async () => {
          if (!active || doneRef.current) return;
          const video = videoRef.current;
          const canvas = canvasRef.current;
          if (!video || !canvas || video.readyState < 2) {
            rafRef.current = requestAnimationFrame(() => void tick());
            return;
          }

          frameCount += 1;
          if (!detector && frameCount % 3 !== 0) {
            rafRef.current = requestAnimationFrame(() => void tick());
            return;
          }

          const ctx = canvas.getContext('2d', { willReadFrequently: true });
          if (!ctx) {
            rafRef.current = requestAnimationFrame(() => void tick());
            return;
          }

          const w = video.videoWidth;
          const h = video.videoHeight;
          if (w > 0 && h > 0) {
            canvas.width = w;
            canvas.height = h;
            ctx.drawImage(video, 0, 0, w, h);
          }

          try {
            if (detector) {
              const codes = await detector.detect(video);
              const raw = codes[0]?.rawValue;
              if (raw) {
                doneRef.current = true;
                onScanRef.current(raw);
                stopTracks();
                return;
              }
            } else {
              const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
              const code = jsQR(imageData.data, imageData.width, imageData.height, {
                inversionAttempts: 'dontInvert',
              });
              if (code?.data) {
                doneRef.current = true;
                onScanRef.current(code.data);
                stopTracks();
                return;
              }
            }
          } catch {
            /* next frame */
          }
          rafRef.current = requestAnimationFrame(() => void tick());
        };

        rafRef.current = requestAnimationFrame(() => void tick());
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        onCameraError?.(msg.includes('Permission') ? 'Camera permission denied.' : `Camera error: ${msg}`);
      }
    };

    void start();

    return () => {
      doneRef.current = true;
      cancelAnimationFrame(rafRef.current);
      stopTracks();
    };
  }, [active, onCameraError]);

  if (!active) return null;

  return (
    <div className={`relative overflow-hidden rounded-2xl bg-black ${className ?? ''}`}>
      <video ref={videoRef} className="h-full w-full object-cover" playsInline muted />
      <canvas ref={canvasRef} className="hidden" aria-hidden />
      <div className="pointer-events-none absolute inset-4 rounded-lg border-2 border-white/40" />
      <div className="pointer-events-none absolute top-1/3 left-0 right-0 h-px bg-gradient-to-b from-green-400/80 to-transparent" />
    </div>
  );
}
