import { useEffect, useState } from "react"
import { useParams } from "react-router"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import QrDisplay from "@/components/shared/QrDisplay"
import { formatDate, formatTime } from "@/lib/utils"
import type { LeaveRequest } from "@/types"
import api from "@/lib/api"
import { Loader2, ArrowLeft } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useNavigate } from "react-router"

export default function QrDisplayPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [leave, setLeave] = useState<LeaveRequest | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!id) return
    api.get(`/leave/${id}`)
      .then((res) => setLeave(res.data.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [id])

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!leave) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => navigate(-1)}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Back
        </Button>
        <p className="text-center text-muted-foreground">Leave request not found</p>
      </div>
    )
  }

  const dateStr = leave.leave_date.split('T')[0]

  return (
    <div className="page-enter mx-auto max-w-lg space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold">Gate Pass</h1>
          <p className="text-muted-foreground">{formatDate(dateStr)}</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Leave Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
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
        </CardContent>
      </Card>

      {leave.out_qr_code && (
        <QrDisplay
          qrData={leave.out_qr_code}
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
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-12 text-center text-muted-foreground">
            <QrCode className="h-16 w-16" />
            <p className="text-base font-medium text-foreground">QR codes not available yet</p>
            <p className="text-sm">QR codes appear once a supervisor approves your request</p>
          </CardContent>
        </Card>
      )}

      <p className="text-center text-xs text-muted-foreground">
        QR codes are valid ±15 minutes from scheduled time
      </p>
    </div>
  )
}

function QrCode(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="6" height="6"/>
      <rect x="15" y="3" width="6" height="6"/>
      <rect x="3" y="15" width="6" height="6"/>
      <line x1="21" y1="15" x2="21" y2="21"/>
      <line x1="15" y1="21" x2="21" y2="21"/>
      <line x1="15" y1="15" x2="15" y2="17"/>
      <line x1="17" y1="15" x2="17" y2="19"/>
      <line x1="19" y1="17" x2="19" y2="21"/>
    </svg>
  )
}
