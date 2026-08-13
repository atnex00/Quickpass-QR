import { useEffect, useState, useRef } from "react"
import { useParams } from "react-router"
import QrDisplay from "@/components/shared/QrDisplay"
import { formatDate, formatTime } from "@/lib/utils"
import type { LeaveRequest } from "@/types"
import api from "@/lib/api"
import { Loader2, ArrowLeft, RefreshCw, QrCode } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useNavigate } from "react-router"

const POLL_INTERVAL = 5000

export default function QrDisplayPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [leave, setLeave] = useState<LeaveRequest | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const fetchLeave = (showLoading = true) => {
    if (!id) return
    if (showLoading) setLoading(true)
    setError(null)
    api.get(`/leave/${id}`)
      .then((res) => {
        setLeave(res.data.data)
        const l = res.data.data as LeaveRequest
        if (l.status === "completed" || l.is_expired) {
          if (pollRef.current) clearInterval(pollRef.current)
        }
      })
      .catch((err) => {
        const msg = err.response?.data?.message || err.message || "Could not load leave request"
        setError(msg)
      })
      .finally(() => { if (showLoading) setLoading(false) })
  }

  useEffect(() => {
    fetchLeave()

    pollRef.current = setInterval(() => fetchLeave(false), POLL_INTERVAL)

    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [id])

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="page-enter space-y-4">
        <Button variant="ghost" onClick={() => navigate(-1)}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Back
        </Button>
        <div className="flex flex-col items-center gap-4 py-12 text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded border border-destructive/30 bg-destructive/5">
            <QrCode className="h-7 w-7 text-destructive/60" />
          </div>
          <div>
            <p className="text-base font-semibold text-foreground">Could not load this pass</p>
            <p className="text-sm text-muted-foreground mt-1">{error}</p>
          </div>
          <Button variant="outline" size="sm" className="gap-1.5" onClick={() => fetchLeave(true)}>
            <RefreshCw className="h-3.5 w-3.5" /> Try again
          </Button>
        </div>
      </div>
    )
  }

  if (!leave) {
    return (
      <div className="page-enter space-y-4">
        <Button variant="ghost" onClick={() => navigate(-1)}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Back
        </Button>
        <p className="text-center text-muted-foreground py-12">Leave request not found</p>
      </div>
    )
  }

  const dateStr = leave.leave_date.split('T')[0]

  return (
    <div className="page-enter mx-auto max-w-lg space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold">Gate Pass</h1>
          <p className="text-muted-foreground">{formatDate(dateStr)}</p>
        </div>
      </div>

      <div className="panel-card">
        <div className="panel-card-header">
          <h3>Leave Details</h3>
        </div>
        <div className="panel-card-body space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-muted-foreground">Date</span>
            <span className="font-medium">{formatDate(dateStr)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Time</span>
            <span className="font-medium">{formatTime(leave.start_time)} - {formatTime(leave.end_time)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Reason</span>
            <span className="font-medium">{leave.reason}</span>
          </div>
        </div>
      </div>

      {leave.out_qr_code && (
        <QrDisplay
          qrData={leave.out_qr_code}
          qrImageUrl={leave.out_qr_image}
          label="EXIT PASS"
          color="blue"
          date={dateStr}
          time={leave.start_time}
          scanTime={leave.out_scan_time}
          employeeName={leave.employee_name}
          employeePosition={leave.employee_position}
          isOut={true}
        />
      )}

      {leave.in_qr_code && (
        <QrDisplay
          qrData={leave.in_qr_code}
          qrImageUrl={leave.in_qr_image}
          label="ENTRY PASS"
          color="green"
          date={dateStr}
          time={leave.end_time}
          scanTime={leave.in_scan_time}
          employeeName={leave.employee_name}
          employeePosition={leave.employee_position}
          isOut={false}
        />
      )}

      {!leave.out_qr_code && (
        <div className="panel-card">
          <div className="panel-card-body flex flex-col items-center gap-3 py-12 text-center text-muted-foreground">
            <QrCode className="h-16 w-16 text-muted-foreground/30" />
            <p className="text-base font-medium text-foreground">QR codes not available yet</p>
            <p className="text-sm">QR codes appear once a supervisor approves your request</p>
          </div>
        </div>
      )}

      <p className="text-center text-xs text-muted-foreground">
        QR codes are valid ±15 minutes from scheduled time
      </p>
    </div>
  )
}
