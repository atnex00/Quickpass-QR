import { useEffect, useState } from "react"
import { Link } from "react-router"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card } from "@/components/ui/card"
import StatusBadge from "@/components/shared/StatusBadge"
import { formatDate, formatTime } from "@/lib/utils"
import type { LeaveStatus } from "@/types"
import { useAuthStore } from "@/stores/authStore"
import api from "@/lib/api"
import { toast } from "sonner"
import { Inbox, CalendarDays, Filter, Trash2 } from "lucide-react"

export default function LeaveHistoryPage() {
  const { history, isLoading, loadHistory } = useLeaveStore()
  const { user } = useAuthStore()
  const [filter, setFilter] = useState<string | undefined>()

  const handleDelete = async (e: React.MouseEvent, leaveId: string) => {
    e.preventDefault()
    e.stopPropagation()
    try {
      await api.delete(`/leave/${leaveId}`)
      toast.success("Leave deleted")
      loadHistory(filter)
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Could not delete")
    }
  }

  useEffect(() => {
    loadHistory(filter)
  }, [filter])

  const filters: { label: string; value: string | undefined }[] = [
    { label: "All", value: undefined },
    { label: "Pending", value: "pending" },
    { label: "Approved", value: "approved" },
    { label: "Rejected", value: "rejected" },
    { label: "Completed", value: "completed" },
  ]

  return (
    <div className="page-enter space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Leave History</h1>
        <p className="text-muted-foreground">View all your leave requests</p>
      </div>

      <div className="flex flex-wrap gap-2">
        {filters.map((f) => (
          <button
            key={f.label}
            onClick={() => setFilter(f.value)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium transition-colors ${
              filter === f.value
                ? "bg-primary text-primary-foreground"
                : "bg-muted text-muted-foreground hover:bg-accent"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
        </div>
      ) : history.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">
            <Inbox className="h-6 w-6 text-muted-foreground" />
          </div>
          <div>
            <h3>No requests found</h3>
            <p>
              {filter ? `No "${filter}" requests match your filter — try a different filter` : "Submit a leave request to see it here"}
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {history.map((leave) => (
            <Link key={leave.leave_id} to={`/employee/qr/${leave.leave_id}`}>
              <Card className="card-hover p-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-3">
                    <CalendarDays className="mt-0.5 h-5 w-5 text-muted-foreground" />
                    <div>
                      <p className="font-medium">{formatDate(leave.leave_date)}</p>
                      <p className="text-sm text-muted-foreground">
                        {formatTime(leave.start_time)} - {formatTime(leave.end_time)}
                      </p>
                      <p className="text-sm text-muted-foreground">{leave.reason}</p>
                      {leave.rejection_reason && (
                        <p className="mt-1 text-sm text-destructive">
                          Reason: {leave.rejection_reason}
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-start gap-2">
                    <StatusBadge status={leave.status} />
                    {user?.is_admin && (
                      <button
                        onClick={(e) => handleDelete(e, leave.leave_id)}
                        className="mt-0.5 text-muted-foreground hover:text-destructive transition-colors"
                        title="Delete (admin only)"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
