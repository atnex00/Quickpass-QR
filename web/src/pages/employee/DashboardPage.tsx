import { useEffect, useState } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Button } from "@/components/ui/button"
import StatusBadge from "@/components/shared/StatusBadge"
import DashboardSkeleton from "@/components/shared/DashboardSkeleton"
import {
  History, Plus, CheckCircle, Timer, Hourglass, Inbox, CalendarDays,
} from "lucide-react"
import { formatDate, formatTime } from "@/lib/utils"

export default function EmployeeDashboard() {
  const { user } = useAuthStore()
  const { history, activeLeave, loadHistory, loadActiveLeave } = useLeaveStore()
  const [initialLoading, setInitialLoading] = useState(true)

  useEffect(() => {
    Promise.all([loadHistory(), loadActiveLeave()]).finally(() => setInitialLoading(false))
  }, [])

  if (initialLoading) return <DashboardSkeleton />

  const pendingCount = history.filter((l) => l.status === "pending").length
  const approvedCount = history.filter((l) => l.status === "approved").length
  const completedCount = history.filter((l) => l.status === "completed").length

  return (
    <div className="page-enter space-y-5">
      <div className="mb-2">
        <h1 className="text-xl font-bold tracking-tight text-foreground sm:text-2xl">
          Welcome back, {user?.full_name?.split(" ")[0] || "User"}
        </h1>
        <p className="mt-0.5 text-sm text-muted-foreground">
          {user?.position} · {user?.department_name}
        </p>
      </div>

      {/* Active leave banner */}
      {activeLeave && (
        <div className="card-elevated border-l-4 border-l-primary amber-glow p-4">
          <div className="flex items-center gap-3">
            <span className="stat-tile">
              <Timer className="h-5 w-5" />
            </span>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground">Active Leave</p>
              <p className="text-xs text-muted-foreground truncate">Until {activeLeave.end_time} · {activeLeave.reason}</p>
            </div>
            {activeLeave.out_qr_code && (
              <Link to={`/employee/qr/${activeLeave.leave_id}`}>
                <Button variant="outline" size="sm">View QR</Button>
              </Link>
            )}
          </div>
        </div>
      )}

      {/* Stat cards */}
      <div className="grid gap-3 sm:grid-cols-3">
        {[
          { label: "Pending", count: pendingCount, icon: Hourglass },
          { label: "Approved", count: approvedCount, icon: CheckCircle },
          { label: "Completed", count: completedCount, icon: History },
        ].map((stat, i) => (
          <div key={stat.label} className="kpi lift" style={{ animationDelay: `${i * 0.1}s` }}>
            <div className="flex items-start justify-between">
              <span className="stat-tile">
                <stat.icon className="h-5 w-5" />
              </span>
            </div>
            <p className="kpi-value mt-3">{stat.count}</p>
            <p className="kpi-label mt-1">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Actions */}
      <div className="flex gap-2">
        <Link to="/employee/request" className="flex-1">
          <button className="btn-gradient w-full py-3 text-[11px]" type="button">
            <Plus className="h-4 w-4" /> Request Leave
          </button>
        </Link>
        <Link to="/employee/history" className="flex-1">
          <Button variant="outline" className="btn-secondary w-full py-3 text-[11px]" size="default">
            <History className="h-4 w-4" /> View History
          </Button>
        </Link>
      </div>

      {/* Recent requests */}
      <div>
        <div className="section-title">Recent Requests</div>
        <div className="card-elevated">
          <div className="panel-card-body">
            {history.length === 0 ? (
              <div className="flex flex-col items-center gap-3 py-8 text-center">
                <div className="flex items-center justify-center w-12 h-12 rounded-xl border border-border bg-muted">
                  <Inbox className="h-5 w-5 text-muted-foreground" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-foreground">No leave requests yet</p>
                  <p className="text-xs text-muted-foreground">Submit your first temporary leave request to get started</p>
                </div>
                <Link to="/employee/request">
                  <button className="btn-gradient text-[10px] py-2 px-4" type="button">
                    <Plus className="h-3.5 w-3.5" /> Request Leave
                  </button>
                </Link>
              </div>
            ) : (
              <div className="space-y-1">
                {history.slice(0, 5).map((leave, i) => (
                  <Link
                    key={leave.leave_id}
                    to={`/employee/qr/${leave.leave_id}`}
                    className="lift flex items-center justify-between rounded-lg px-3 py-2.5 border border-transparent hover:border-border hover:bg-accent/40"
                    style={{ animationDelay: `${i * 0.05}s` }}
                  >
                    <div className="flex items-center gap-3">
                      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-muted">
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
                <div className="pt-1 text-right">
                  <Link to="/employee/history" className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground hover:text-primary transition-colors">View All →</Link>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
