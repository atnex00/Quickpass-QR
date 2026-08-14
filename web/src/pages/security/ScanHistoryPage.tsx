import { useEffect } from "react"
import { useNavigate } from "react-router"
import { useScanStore } from "@/stores/scanStore"
import { useAuthStore } from "@/stores/authStore"
import { Button } from "@/components/ui/button"
import { Loader2, Scan, LogOut, ArrowLeft, CheckCircle, XCircle, Clock } from "lucide-react"
import { formatDateTime } from "@/lib/utils"

export default function ScanHistoryPage() {
  const navigate = useNavigate()
  const { history, historyLoading, loadHistory } = useScanStore()
  const { user, logout } = useAuthStore()

  useEffect(() => {
    loadHistory()
  }, [])

  return (
    <div className="page-enter flex min-h-screen flex-col bg-background">
      {/* Header */}
      <header className="flex items-center justify-between border-b border-border bg-card px-6 py-3">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate("/security/scan")} aria-label="Back to scanner" className="flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground hover:bg-accent transition-colors">
            <ArrowLeft className="h-4 w-4" />
          </button>
          <img src="/logo.png" alt="ZANECO QuickPass" className="h-7 w-auto" />
          <span className="text-[10px] font-black uppercase tracking-[0.08em] text-muted-foreground/60 leading-none pt-0.5">/ History</span>
        </div>
        <div className="flex items-center gap-2">
          {user && <span className="hidden text-sm text-muted-foreground sm:block">{user.full_name}</span>}
          <Button variant="ghost" size="sm" onClick={logout}><LogOut className="h-4 w-4" /></Button>
        </div>
      </header>

      <main className="flex-1 overflow-y-auto p-6">
        <div className="mx-auto max-w-2xl space-y-4">
          {historyLoading ? (
            <div className="flex items-center justify-center py-24">
              <div className="flex flex-col items-center gap-3">
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
                <p className="text-xs font-medium text-muted-foreground">Loading scan history…</p>
              </div>
            </div>
          ) : history.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">
                <Scan className="h-6 w-6 text-muted-foreground" />
              </div>
              <div>
                <h3>No scans yet</h3>
                <p>Point your camera at a QR code to log your first gate scan</p>
              </div>
              <button onClick={() => navigate("/security/scan")} className="btn-primary">
                <Scan className="h-4 w-4" /> Scan QR
              </button>
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between">
                <h2 className="text-xs font-black uppercase tracking-[0.1em] text-muted-foreground">Recent Scans</h2>
                <span className="text-[10px] text-muted-foreground/50">{history.length} scan{history.length !== 1 ? "s" : ""}</span>
              </div>

              <div className="space-y-3">
                {history.map((log, i) => (
                  <div
                    key={log.log_id}
                    className="card-hover rounded-lg border border-border bg-card p-4"
                    style={{ animationDelay: `${i * 0.05}s` }}
                  >
                    <div className="flex items-start gap-3">
                      <div className={`flex h-10 w-10 items-center justify-center rounded-lg text-sm font-bold shrink-0 ${
                        log.is_valid
                          ? "bg-success/20 text-success"
                          : "bg-destructive/20 text-destructive"
                      }`}>
                        {log.employee_name?.charAt(0) || "?"}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <p className="font-semibold text-sm text-foreground truncate">
                              {log.employee_name || "Unknown"}
                            </p>
                            <p className="text-xs text-muted-foreground mt-0.5">
                              {log.employee_id} &middot; {log.qr_type} scan
                            </p>
                          </div>
                          <span className={`inline-flex items-center gap-1 shrink-0 rounded-full border px-2 py-0.5 text-[10px] font-semibold ${
                            log.is_valid
                              ? "border-success/40 text-success"
                              : "border-destructive/40 text-destructive"
                          }`}>
                            {log.is_valid
                              ? <><CheckCircle className="h-3 w-3" /> Valid</>
                              : <><XCircle className="h-3 w-3" /> Invalid</>
                            }
                          </span>
                        </div>
                        <div className="mt-1.5 flex items-center gap-1.5 text-[11px] text-muted-foreground/60">
                          <Clock className="h-3 w-3" />
                          {log.scan_time ? formatDateTime(log.scan_time) : ""}
                        </div>
                        {log.validation_message && (
                          <p className="mt-1 text-xs text-muted-foreground/50 italic">{log.validation_message}</p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </main>
    </div>
  )
}
