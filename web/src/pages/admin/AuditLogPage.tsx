import { useEffect, useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import Pagination from "@/components/shared/Pagination"
import { downloadCsv } from "@/lib/download"
import { toast } from "sonner"
import api from "@/lib/api"
import { Loader2, History, Download, Search } from "lucide-react"
import { formatDateTime } from "@/lib/utils"

interface AuditEntry {
  audit_log_id: number
  actor_id: string
  actor_name: string
  actor_role: string
  action: string
  entity: string
  entity_id: string | null
  description: string | null
  ip_address: string | null
  created_at: string
}

const ACTION_COLORS: Record<string, string> = {
  create: "bg-success/15 text-success",
  update: "bg-primary/15 text-primary",
  delete: "bg-destructive/15 text-destructive",
  approve: "bg-success/15 text-success",
  reject: "bg-destructive/15 text-destructive",
  revoke: "bg-gold/15 text-gold",
}

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [search, setSearch] = useState("")
  const [exporting, setExporting] = useState(false)

  const load = async () => {
    try {
      const params: Record<string, any> = { page, limit: 25 }
      if (search) params.actor_id = search
      const res = await api.get("/admin/audit", { params })
      setLogs(res.data.data)
      setTotal(res.data.pagination?.total || 0)
    } catch {
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search])

  const handleExport = async () => {
    setExporting(true)
    try {
      const params = new URLSearchParams({ resource: "audit" })
      if (search) params.set("actor_id", search)
      await downloadCsv(`/admin/export?${params.toString()}`, "audit_log.csv")
    } catch {
      toast.error("Could not export CSV")
    }
    setExporting(false)
  }

  return (
    <div className="page-enter space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Audit Log</h1>
          <p className="text-muted-foreground">Supervisor and admin actions</p>
        </div>
        <Button variant="outline" size="sm" onClick={handleExport} disabled={exporting}>
          {exporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
          Export
        </Button>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Search by employee ID..."
          className="pl-9"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>

      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : logs.length === 0 ? (
            <div className="flex flex-col items-center gap-4 py-16 text-center">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg border border-border bg-muted">
                <History className="h-5 w-5 text-muted-foreground" />
              </div>
              <p className="text-sm text-muted-foreground">No audit entries found</p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {logs.map((log) => (
                <div key={log.audit_log_id} className="flex items-start gap-3 p-4">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-muted shrink-0">
                    <History className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <div className="flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        ACTION_COLORS[log.action] || "bg-muted text-muted-foreground"
                      }`}>
                        {log.action}
                      </span>
                      <span className="text-sm font-medium">{log.actor_name}</span>
                      <span className="text-xs text-muted-foreground">
                        {log.actor_id} · {log.actor_role}
                      </span>
                    </div>
                    <p className="mt-1 text-sm text-foreground">
                      {log.description || `${log.action} ${log.entity}${log.entity_id ? ` ${log.entity_id}` : ""}`}
                    </p>
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      {formatDateTime(log.created_at)}
                      {log.ip_address && ` · ${log.ip_address}`}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {total > 0 && (
        <Pagination
          page={page}
          limit={25}
          total={total}
          onPageChange={(p) => setPage(p)}
          onLimitChange={() => {}}
        />
      )}
    </div>
  )
}
