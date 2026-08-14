/** Download URL for the packaged macOS capture agent. */

const DEFAULT_DOWNLOAD_PATH = "/downloads/LoomCapture-macos.zip";

export const DESKTOP_AGENT_DOWNLOAD_URL: string = (() => {
  const baked = import.meta.env.VITE_DESKTOP_AGENT_DOWNLOAD_URL?.trim();
  return baked || DEFAULT_DOWNLOAD_PATH;
})();

export function isAbsoluteUrl(value: string): boolean {
  return /^https?:\/\//i.test(value);
}
