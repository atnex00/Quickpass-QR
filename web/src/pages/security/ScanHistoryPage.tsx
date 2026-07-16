import { useEffect } from "react"
import SecurityHeader from "@/components/layout/SecurityHeader"
import { useScanStore } from "@/stores/scanStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Loader2, CheckCircle, XCircle, Clock } from "lucide-react"
import { formatDateTime } from "@/lib/utils"

export default function ScanHistoryPage() {
  const { history, historyLoading, loadHistory } = useScanStore()

  useEffect(() => {
    loadHistory()
  }, [])

  return (
    <div className="page-enter flex min-h-screen flex-col bg-background">
      <main className="flex-1 overflow-y-auto p-6">
        <div className="mx-auto max-w-2xl space-y-4">
          {historyLoading ? (
            <div className="flex items-center justify-center py-24">
              <div className="flex flex-col items-center gap-3">
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
                <p className="text-sm text-muted-foreground">Loading scan history</p>
              </div>
            </div>
          ) : history.length === 0 ? (
            <div className="flex flex-col items-center gap-4 py-16 text-center">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg border border-border bg-muted">
                <Clock className="h-5 w-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-base font-semibold text-foreground">No scan history</p>
                <p className="text-sm text-muted-foreground">Scan QR codes to record gate entries</p>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              {history.map((log) => (
                <Card key={log.log_id}>
                  <CardContent className="flex items-center justify-between p-4">
                    <div className="flex items-center gap-3">
                      <div className={`flex h-9 w-9 items-center justify-center rounded-lg ${
                        log.is_valid ? "bg-success/15" : "bg-destructive/15"
                      }`}>
                        {log.is_valid
                          ? <CheckCircle className="h-4 w-4 text-success" />
                          : <XCircle className="h-4 w-4 text-destructive" />
                        }
                      </div>
                      <div>
                        <p className="text-sm font-medium text-foreground">
                          {log.qr_type} Scan
                          {log.employee_name && (
                            <span className="text-muted-foreground"> — {log.employee_name}</span>
                          )}
                        </p>
                        <p className="text-xs text-muted-foreground">{formatDateTime(log.scan_time)}</p>
                      </div>
                    </div>
                    <Badge variant={log.is_valid ? "approved" : "rejected"}>
                      {log.is_valid ? "Valid" : "Invalid"}
                    </Badge>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
