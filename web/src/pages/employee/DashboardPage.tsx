import { useEffect } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import StatusBadge from "@/components/shared/StatusBadge"
import {
  Clock, History, Plus, CheckCircle, Timer, Hourglass, Inbox, CalendarDays,
} from "lucide-react"
import { formatDate, formatTime } from "@/lib/utils"

export default function EmployeeDashboard() {
  const { user } = useAuthStore()
  const { history, activeLeave, loadHistory, loadActiveLeave } = useLeaveStore()

  useEffect(() => {
    loadHistory()
    loadActiveLeave()
  }, [])

  const pendingCount = history.filter((l) => l.status === "pending").length
  const approvedCount = history.filter((l) => l.status === "approved").length
  const completedCount = history.filter((l) => l.status === "completed").length

  return (
    <div className="page-enter space-y-3">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold font-display">Welcome back, {user?.full_name?.split(" ")[0] || "User"}</h1>
          <p className="text-sm text-muted-foreground mt-1">{user?.position} &middot; {user?.department_name}</p>
        </div>
      </div>

      {/* Active leave banner */}
      {activeLeave && (
        <div className="panel-card border-l-4 border-l-primary amber-glow">
          <div className="panel-card-body flex items-center gap-3">
            <Timer className="h-6 w-6 text-primary shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground">Active Leave</p>
              <p className="text-xs text-muted-foreground truncate">Until {activeLeave.end_time} &middot; {activeLeave.reason}</p>
            </div>
            {activeLeave.out_qr_code && (
              <Link to={`/employee/qr/${activeLeave.leave_id}`}>
                <Button variant="outline" size="sm">View QR</Button>
              </Link>
            )}
          </div>
        </div>
      )}

      {/* Stat cards — indicator dots */}
      <div className="grid gap-3 sm:grid-cols-3">
        {[
          { label: "Pending", count: pendingCount, icon: Hourglass, dot: "bg-primary" },
          { label: "Approved", count: approvedCount, icon: CheckCircle, dot: "bg-success" },
          { label: "Completed", count: completedCount, icon: History, dot: "bg-muted-foreground" },
        ].map((stat, i) => (
          <div key={stat.label} className="panel-card card-hover" style={{ animationDelay: `${i * 0.1}s` }}>
            <div className="panel-card-body flex items-center gap-3">
              <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${stat.dot}`} />
              <div className="flex-1">
                <p className="text-2xl font-black text-foreground">{stat.count}</p>
                <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">{stat.label}</p>
              </div>
              <stat.icon className="h-4 w-4 text-muted-foreground/25" />
            </div>
          </div>
        ))}
      </div>

      {/* Actions */}
      <div className="flex gap-2">
        <Link to="/employee/request" className="flex-1">
          <Button className="btn-primary w-full py-3 text-[11px]" size="default">
            <Plus className="h-4 w-4" /> Request Leave
          </Button>
        </Link>
        <Link to="/employee/history" className="flex-1">
          <Button variant="outline" className="btn-secondary w-full py-3 text-[11px]" size="default">
            <History className="h-4 w-4" /> View History
          </Button>
        </Link>
      </div>

      {/* Recent requests */}
      <div className="panel-card">
        <div className="panel-card-header flex items-center justify-between">
          <h3>Recent Requests</h3>
          <Link to="/employee/history" className="text-[9px] font-semibold uppercase tracking-[0.08em] text-muted-foreground hover:text-primary transition-colors">View All</Link>
        </div>
        <div className="panel-card-body">
          {history.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-8 text-center">
              <div className="flex items-center justify-center w-12 h-12 rounded border border-border bg-muted">
                <Inbox className="h-5 w-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">No leave requests yet</p>
                <p className="text-xs text-muted-foreground">Submit your first temporary leave request to get started</p>
              </div>
              <Link to="/employee/request">
                <Button size="sm" className="btn-primary text-[10px] py-2">
                  <Plus className="h-3.5 w-3.5" /> Request Leave
                </Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-1">
              {history.slice(0, 5).map((leave, i) => (
                <Link
                  key={leave.leave_id}
                  to={`/employee/qr/${leave.leave_id}`}
                  className="card-hover flex items-center justify-between rounded px-3 py-2.5 border border-transparent hover:border-border"
                  style={{ animationDelay: `${i * 0.05}s` }}
                >
                  <div className="flex items-center gap-3">
                    <span className="flex h-7 w-7 items-center justify-center rounded bg-muted">
                      <CalendarDays className="h-3.5 w-3.5 text-muted-foreground" />
                    </span>
                    <div>
                      <p className="text-xs font-semibold text-foreground">{formatDate(leave.leave_date)}</p>
                      <p className="text-[10px] text-muted-foreground">{formatTime(leave.start_time)} - {formatTime(leave.end_time)}</p>
                    </div>
                  </div>
                  <StatusBadge status={leave.status} />
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
