import { Capacitor } from '@capacitor/core';
import { openMglFleetNativeFlow } from '@mgl/capacitor-fleet-sdk';

const log = document.getElementById('log');
function line(msg: string) {
  if (log) log.textContent += `${msg}\n`;
}

document.getElementById('open')?.addEventListener('click', async () => {
  if (log) log.textContent = '';
  line(`platform=${Capacitor.getPlatform()} native=${Capacitor.isNativePlatform()}`);
  try {
    const result = await openMglFleetNativeFlow({
      initialize: {
        apiBaseUrl: 'https://api.example.com',
        useMock: true,
      },
      present: { correlationId: 'cap-demo' },
    });
    line(`done: ${JSON.stringify(result)}`);
  } catch (e) {
    line(`error: ${e}`);
  }
});
