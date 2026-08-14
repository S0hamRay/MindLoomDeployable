import { useEffect, useState } from "react";
import { Download, Monitor } from "lucide-react";
import { Link } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PrimaryButton } from "@/components/PrimaryButton";
import { DESKTOP_AGENT_DOWNLOAD_URL, isAbsoluteUrl } from "@/lib/desktopAgent";
import { useSession } from "@/store/session";
import { cn } from "@/lib/utils";

type Availability = "checking" | "ready" | "missing";

async function probeDownload(url: string): Promise<boolean> {
  const res = await fetch(url, { method: "HEAD" });
  if (!res.ok) return false;
  const type = (res.headers.get("content-type") || "").toLowerCase();
  // SPA fallback would serve index.html instead of the zip.
  if (type.includes("text/html")) return false;
  return true;
}

export function DesktopAgentDownload({
  compact = false,
  hideInstallLink = false,
  className,
}: {
  compact?: boolean;
  hideInstallLink?: boolean;
  className?: string;
}) {
  const role = useSession((s) => s.role);
  const isAdmin = role === "admin";
  const [availability, setAvailability] = useState<Availability>(
    isAbsoluteUrl(DESKTOP_AGENT_DOWNLOAD_URL) ? "ready" : "checking",
  );

  useEffect(() => {
    if (isAbsoluteUrl(DESKTOP_AGENT_DOWNLOAD_URL)) {
      setAvailability("ready");
      return;
    }
    let cancelled = false;
    void probeDownload(DESKTOP_AGENT_DOWNLOAD_URL)
      .then((ok) => {
        if (!cancelled) setAvailability(ok ? "ready" : "missing");
      })
      .catch(() => {
        if (!cancelled) setAvailability("missing");
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const ready = availability === "ready";

  return (
    <Card className={cn(className)}>
      <CardHeader className={cn("flex-row items-start gap-3", compact && "p-4")}>
        <span className="flex size-11 items-center justify-center rounded-lg border">
          <Monitor className="size-6" />
        </span>
        <div className="min-w-0 flex-1">
          <CardTitle className="text-lg">Loom Capture for Mac</CardTitle>
          <p className="mt-1 text-sm text-muted-foreground">
            Menu-bar agent that captures allowlisted app activity on your Mac and
            uploads task summaries to Loom. macOS 13 or later.
          </p>
        </div>
      </CardHeader>
      <CardContent className={cn("space-y-3", compact && "p-4 pt-0")}>
        {availability === "checking" && (
          <p className="text-sm text-muted-foreground">Checking for a Mac download…</p>
        )}
        {availability === "missing" && (
          <p className="text-sm text-muted-foreground">
            The Mac app is not published on this site yet.
            {isAdmin
              ? " Package it on a Mac with your public web URL, then rebuild the frontend so the zip is included."
              : " Ask an administrator to publish Loom Capture."}
          </p>
        )}
        {ready && !compact && (
          <ol className="list-decimal space-y-1 pl-4 text-sm text-muted-foreground">
            <li>Download and unzip the app.</li>
            <li>
              Right-click <span className="font-medium text-foreground">Loom Capture</span> and
              choose Open (required the first time).
            </li>
            <li>Enable Accessibility when asked, quit, and reopen.</li>
            <li>Sign in with Google from the agent window.</li>
          </ol>
        )}
        <div className="flex flex-wrap gap-2">
          {ready ? (
            <PrimaryButton asChild>
              <a href={DESKTOP_AGENT_DOWNLOAD_URL} download="LoomCapture-macos.zip">
                <Download className="size-4" />
                Download for Mac
              </a>
            </PrimaryButton>
          ) : null}
          {ready && !compact && !hideInstallLink && (
            <Link
              to="/download"
              className="inline-flex h-11 items-center text-sm text-muted-foreground underline-offset-4 hover:text-foreground hover:underline"
            >
              Install notes
            </Link>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
