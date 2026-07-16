import LoadingScreen from "@/components/shared/LoadingScreen"
import DashboardSkeleton from "@/components/shared/DashboardSkeleton"

export default function LoadPreviewPage() {
  return (
    <div className="min-h-screen bg-background">
      <div className="flex h-10 items-center justify-between border-b border-border bg-card px-4">
        <div className="flex items-center gap-2">
          <span className="h-1.5 w-1.5 rounded-full bg-gold" />
          <span className="text-sm font-semibold text-primary">QUICKPASS</span>
        </div>
        <span className="text-sm text-muted-foreground">LOADING PREVIEW</span>
      </div>

      <div className="mx-auto max-w-4xl space-y-16 p-8">
        <section>
          <div className="flex items-center justify-between border-b border-border pb-3 mb-4">
            <h2 className="text-sm font-semibold">LoadingScreen — full page</h2>
            <span className="text-xs text-muted-foreground">fullPage: true</span>
          </div>
          <div className="rounded-lg border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen />
          </div>
        </section>

        <section>
          <div className="flex items-center justify-between border-b border-border pb-3 mb-4">
            <h2 className="text-sm font-semibold">LoadingScreen — inline, custom message</h2>
            <span className="text-xs text-muted-foreground">fullPage: false</span>
          </div>
          <div className="rounded-lg border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen message="Validating QR code" fullPage={false} />
          </div>
        </section>

        <section>
          <div className="flex items-center justify-between border-b border-border pb-3 mb-4">
            <h2 className="text-sm font-semibold">LoadingScreen — inline, short message</h2>
            <span className="text-xs text-muted-foreground">fullPage: false</span>
          </div>
          <div className="rounded-lg border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen message="Saving" fullPage={false} />
          </div>
        </section>

        <section>
          <div className="flex items-center justify-between border-b border-border pb-3 mb-4">
            <h2 className="text-sm font-semibold">DashboardSkeleton</h2>
            <span className="text-xs text-muted-foreground">employee dashboard placeholder</span>
          </div>
          <DashboardSkeleton />
        </section>
      </div>
    </div>
  )
}
