export default function DashboardSkeleton() {
  return (
    <div className="page-enter space-y-3">
      <div className="h-8 w-64 rounded bg-muted animate-pulse" />
      <div className="h-4 w-48 rounded bg-muted animate-pulse" />

      <div className="h-16 rounded border border-border bg-card p-4 animate-pulse">
        <div className="flex items-center gap-3">
          <div className="h-6 w-6 rounded-full bg-muted" />
          <div className="flex-1 space-y-1.5">
            <div className="h-3 w-32 rounded bg-muted" />
            <div className="h-2.5 w-56 rounded bg-muted" />
          </div>
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="rounded border border-border bg-card p-4 animate-pulse" style={{ animationDelay: `${i * 0.1}s` }}>
            <div className="flex items-center gap-3">
              <div className="h-2.5 w-2.5 rounded-full bg-muted" />
              <div className="flex-1 space-y-1.5">
                <div className="h-7 w-12 rounded bg-muted" />
                <div className="h-2.5 w-16 rounded bg-muted" />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        <div className="flex-1 h-10 rounded-lg bg-muted animate-pulse" />
        <div className="flex-1 h-10 rounded-lg bg-muted animate-pulse" />
      </div>

      <div className="rounded border border-border bg-card animate-pulse">
        <div className="border-b border-border/50 px-4 py-3">
          <div className="h-3 w-28 rounded bg-muted" />
        </div>
        <div className="p-4 space-y-2">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="flex items-center gap-3 px-3 py-2.5">
              <div className="h-7 w-7 rounded bg-muted" />
              <div className="flex-1 space-y-1">
                <div className="h-3 w-28 rounded bg-muted" />
                <div className="h-2.5 w-36 rounded bg-muted" />
              </div>
              <div className="h-5 w-16 rounded-full bg-muted" />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
