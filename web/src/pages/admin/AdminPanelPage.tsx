import { useEffect, useState, useCallback, useRef } from "react"
import { useNavigate, Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import api from "@/lib/api"
import {
  Loader2, Server, Database, Activity, FileText, RefreshCw, Play, ArrowLeft,
  CheckCircle, XCircle, AlertTriangle, Clock, HardDrive, Cpu,
} from "lucide-react"

interface PanelStatus {
  db: string
  uptime: number
  memory: { rss: number; heapUsed: number; heapTotal: number }
  nodeVersion: string
  env: string
  pid: number
}

interface PanelMetrics {
  totalRequests: number
  totalErrors: number
  avgResponseTime: string
  errorRate: string
}

type LogEntry = { level: number; time: number; msg: string } | string

export default function AdminPanelPage() {
  const navigate = useNavigate()
  const { user, isAuthenticated } = useAuthStore()
  const [status, setStatus] = useState<PanelStatus | null>(null)
  const [metrics, setMetrics] = useState<PanelMetrics | null>(null)
  const [logs, setLogs] = useState<string[]>([])
  const [migrateResult, setMigrateResult] = useState<any>(null)
  const [seedResult, setSeedResult] = useState<any>(null)
  const [actionLoading, setActionLoading] = useState<string | null>(null)
  const [statusLoading, setStatusLoading] = useState(true)
  const [restarting, setRestarting] = useState(false)
  const [showRestartDialog, setShowRestartDialog] = useState(false)
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const fetchStatus = useCallback(async () => {
    try {
      const [sRes, mRes, lRes] = await Promise.all([
        api.get("/admin/panel/status"),
        api.get("/admin/panel/metrics"),
        api.get("/admin/panel/logs"),
      ])
      setStatus(sRes.data.data)
      setMetrics(mRes.data.data)
      if (lRes.data.data?.lines) setLogs(lRes.data.data.lines)
    } catch {
      //
    } finally {
      setStatusLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!isAuthenticated || !user?.is_admin) {
      navigate("/login", { replace: true })
      return
    }
    fetchStatus()
    pollRef.current = setInterval(fetchStatus, 30000)
    return () => { if (pollRef.current) clearInterval(pollRef.current) }
  }, [isAuthenticated, user, navigate, fetchStatus])

  const runAction = async (action: string, url: string) => {
    setActionLoading(action)
    setMigrateResult(null)
    setSeedResult(null)
    try {
      const res = await api.post(url)
      if (action === "migrate") setMigrateResult(res.data.data)
      if (action === "seed") setSeedResult(res.data.data)
    } catch {
      if (action === "migrate") setMigrateResult(null)
      if (action === "seed") setSeedResult(null)
    } finally {
      setActionLoading(null)
      fetchStatus()
    }
  }

  const handleRestart = () => {
    setShowRestartDialog(true)
  }

  const doRestart = async () => {
    setShowRestartDialog(false)
    setRestarting(true)
    try {
      await api.post("/admin/panel/restart")
    } catch {
      //
    }
    setTimeout(() => { window.location.reload() }, 1000)
  }

  const formatUptime = (seconds: number) => {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    return `${h}h ${m}m ${s}s`
  }

  const formatBytes = (bytes: number) => {
    const mb = bytes / 1024 / 1024
    return `${mb.toFixed(1)} MB`
  }

  if (statusLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#0a0a0a]">
        <Loader2 className="h-8 w-8 animate-spin text-amber-500" />
      </div>
    )
  }

  const isBusy = actionLoading !== null

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-[#e0e0e0]">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-[#222] px-6 py-3">
        <div className="flex items-center gap-3">
          <Link to="/admin/employees" className="text-[#888] hover:text-[#e0e0e0] transition-colors">
            <ArrowLeft className="h-4 w-4" />
          </Link>
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-500/10">
              <Server className="h-4 w-4 text-amber-500" />
            </div>
            <div>
              <p className="text-sm font-bold text-[#e0e0e0]">Backend Control Panel</p>
              <p className="text-[10px] text-[#888]">{user?.full_name} · {status?.env}</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={fetchStatus} className="text-[#888] hover:text-[#e0e0e0]">
            <RefreshCw className="h-3.5 w-3.5" />
          </Button>
          {restarting && (
            <span className="flex items-center gap-1.5 rounded-full bg-amber-500/10 px-2.5 py-1 text-[10px] text-amber-400">
              <Loader2 className="h-3 w-3 animate-spin" /> Restarting...
            </span>
          )}
        </div>
      </header>

      <main className="mx-auto max-w-4xl space-y-5 p-6">
        {/* Status */}
        <Card className="border-[#222] bg-[#111]">
          <CardContent className="p-5">
            <div className="mb-3 flex items-center gap-2">
              <Activity className="h-4 w-4 text-amber-500" />
              <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">Server Status</h2>
            </div>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <div className="space-y-1">
                <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Database</p>
                <div className="flex items-center gap-1.5">
                  {status?.db === "connected" ? (
                    <CheckCircle className="h-3.5 w-3.5 text-green-400" />
                  ) : (
                    <XCircle className="h-3.5 w-3.5 text-red-400" />
                  )}
                  <span className="text-sm font-medium text-[#e0e0e0] capitalize">{status?.db}</span>
                </div>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Uptime</p>
                <div className="flex items-center gap-1.5">
                  <Clock className="h-3.5 w-3.5 text-amber-400" />
                  <span className="text-sm font-medium text-[#e0e0e0]">{status ? formatUptime(status.uptime) : "—"}</span>
                </div>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Memory</p>
                <div className="flex items-center gap-1.5">
                  <HardDrive className="h-3.5 w-3.5 text-amber-400" />
                  <span className="text-sm font-medium text-[#e0e0e0]">{status ? formatBytes(status.memory.heapUsed) : "—"}</span>
                </div>
              </div>
              <div className="space-y-1">
                <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Node</p>
                <div className="flex items-center gap-1.5">
                  <Cpu className="h-3.5 w-3.5 text-amber-400" />
                  <span className="text-sm font-medium text-[#e0e0e0]">{status?.nodeVersion || "—"}</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Metrics */}
        {metrics && (
          <Card className="border-[#222] bg-[#111]">
            <CardContent className="p-5">
              <div className="mb-3 flex items-center gap-2">
                <Activity className="h-4 w-4 text-amber-500" />
                <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">API Metrics</h2>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Requests</p>
                  <p className="text-lg font-bold text-[#e0e0e0]">{metrics.totalRequests}</p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Avg Response</p>
                  <p className="text-lg font-bold text-[#e0e0e0]">{metrics.avgResponseTime}ms</p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-[#666]">Error Rate</p>
                  <p className={`text-lg font-bold ${parseFloat(metrics.errorRate) > 5 ? "text-red-400" : "text-[#e0e0e0]"}`}>
                    {metrics.errorRate}%
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Actions row */}
        <div className="grid gap-4 sm:grid-cols-3">
          {/* Migrate */}
          <Card className="border-[#222] bg-[#111]">
            <CardContent className="p-5">
              <div className="mb-3 flex items-center gap-2">
                <Database className="h-4 w-4 text-amber-500" />
                <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">Migrations</h2>
              </div>
              <Button
                onClick={() => runAction("migrate", "/admin/panel/migrate")}
                disabled={isBusy}
                className="w-full gap-2 bg-amber-600 text-white hover:bg-amber-500 disabled:opacity-50"
                size="sm"
              >
                {actionLoading === "migrate" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                Run Pending Migrations
              </Button>
              {migrateResult && (
                <div className="mt-3 rounded border border-green-500/20 bg-green-500/5 p-2.5">
                  <p className="text-[11px] text-green-400">
                    Batch {migrateResult.batch} — {migrateResult.migrations?.length || 0} migration(s) run
                  </p>
                  {migrateResult.migrations?.length > 0 && (
                    <ul className="mt-1 space-y-0.5">
                      {migrateResult.migrations.map((m: string, i: number) => (
                        <li key={i} className="font-mono text-[10px] text-green-300/70">{m.split('/').pop()}</li>
                      ))}
                    </ul>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Seeds */}
          <Card className="border-[#222] bg-[#111]">
            <CardContent className="p-5">
              <div className="mb-3 flex items-center gap-2">
                <FileText className="h-4 w-4 text-amber-500" />
                <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">Seeds</h2>
              </div>
              <Button
                onClick={() => runAction("seed", "/admin/panel/seed")}
                disabled={isBusy}
                className="w-full gap-2 bg-amber-600 text-white hover:bg-amber-500 disabled:opacity-50"
                size="sm"
              >
                {actionLoading === "seed" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                Run Seeds
              </Button>
              {seedResult && (
                <div className="mt-3 rounded border border-green-500/20 bg-green-500/5 p-2.5">
                  <p className="text-[11px] text-green-400">{seedResult.seeds?.length || 0} seed(s) executed</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Restart */}
          <Card className="border-[#222] bg-[#111]">
            <CardContent className="p-5">
              <div className="mb-3 flex items-center gap-2">
                <RefreshCw className="h-4 w-4 text-amber-500" />
                <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">Server</h2>
              </div>
              <Button
                onClick={handleRestart}
                disabled={restarting}
                className="w-full gap-2 border border-red-500/30 bg-red-500/10 text-red-400 hover:bg-red-500/20 disabled:opacity-50"
                size="sm"
              >
                {restarting ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <AlertTriangle className="h-3.5 w-3.5" />}
                Restart Server
              </Button>
              {restarting && (
                <p className="mt-2 text-[10px] text-amber-400">Server is restarting — page will reload automatically...</p>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Logs */}
        <Card className="border-[#222] bg-[#111]">
          <CardContent className="p-5">
            <div className="mb-3 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <FileText className="h-4 w-4 text-amber-500" />
                <h2 className="text-xs font-bold uppercase tracking-[0.1em] text-[#888]">Server Logs</h2>
              </div>
              <span className="text-[10px] text-[#666]">Last 100 lines</span>
            </div>
            <div className="max-h-64 overflow-y-auto rounded border border-[#222] bg-[#080808] p-3 font-mono text-[11px] leading-relaxed">
              {logs.length === 0 ? (
                <p className="text-[#555]">No logs yet. Make some API requests first.</p>
              ) : (
                logs.map((line, i) => {
                  let parsed: any = null
                  try { parsed = JSON.parse(line) } catch { /* plain string */ }
                  const isError = parsed && parsed.level >= 50
                  const isWarn = parsed && parsed.level >= 40
                  return (
                    <div
                      key={i}
                      className={`${isError ? "text-red-400" : isWarn ? "text-amber-400" : "text-[#aaa]"}`}
                    >
                      {parsed
                        ? `[${new Date(parsed.time).toISOString().slice(11, 19)}] ${parsed.msg || parsed.msg || line}`
                        : line}
                    </div>
                  )
                })
              )}
            </div>
          </CardContent>
        </Card>
      </main>

      <Dialog open={showRestartDialog} onOpenChange={setShowRestartDialog}>
        <DialogContent className="bg-[#111] border-[#222]">
          <DialogHeader>
            <DialogTitle className="text-[#e0e0e0]">Restart Server?</DialogTitle>
            <DialogDescription className="text-[#888]">
              The backend server will restart, causing a brief downtime. Are you sure?
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setShowRestartDialog(false)}>
              Cancel
            </Button>
            <Button onClick={doRestart} className="bg-red-500/10 border border-red-500/30 text-red-400 hover:bg-red-500/20">
              {restarting ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
              Restart
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}