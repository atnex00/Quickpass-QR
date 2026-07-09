import LoadingScreen from "@/components/shared/LoadingScreen"
import DashboardSkeleton from "@/components/shared/DashboardSkeleton"

export default function LoadPreviewPage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Site header bar */}
      <div className="status-bar">
        <span className="status-bar-time">
          <span className="status-bar-dot mr-2" />
          QUICKPASS
        </span>
        <span className="status-bar-user">LOADING PREVIEW</span>
      </div>

      <div className="p-8 max-w-4xl mx-auto space-y-16">
        <section>
          <div className="section-header">
            <h2>LoadingScreen — full page</h2>
            <span className="section-action">fullPage: true</span>
          </div>
          <div className="rounded border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen />
          </div>
        </section>

        <section>
          <div className="section-header">
            <h2>LoadingScreen — inline, custom message</h2>
            <span className="section-action">fullPage: false</span>
          </div>
          <div className="rounded border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen message="Validating QR code" fullPage={false} />
          </div>
        </section>

        <section>
          <div className="section-header">
            <h2>LoadingScreen — inline, short message</h2>
            <span className="section-action">fullPage: false</span>
          </div>
          <div className="rounded border border-border bg-muted/30 overflow-hidden">
            <LoadingScreen message="Saving" fullPage={false} />
          </div>
        </section>

        <section>
          <div className="section-header">
            <h2>DashboardSkeleton</h2>
            <span className="section-action">employee dashboard placeholder</span>
          </div>
          <DashboardSkeleton />
        </section>
      </div>
    </div>
  )
}
