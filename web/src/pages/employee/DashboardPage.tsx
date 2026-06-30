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
    <div className="page-enter space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Welcome back, {user?.full_name?.split(" ")[0] || "User"}</h1>
          <p className="text-sm text-muted-foreground mt-1">{user?.position} &middot; {user?.department_name}</p>
        </div>
        {activeLeave && (
          <div className="flex items-center gap-2 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-2">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500" />
            </span>
            <span className="text-[10px] font-black uppercase tracking-[0.08em] text-emerald-700">On Leave</span>
          </div>
        )}
      </div>

      {/* Active leave banner */}
      {activeLeave && (
        <Card className="border-l-4 border-l-emerald-500 shadow-sm">
          <CardContent className="flex items-center gap-4 p-4">
            <Timer className="h-8 w-8 text-emerald-600" />
            <div className="flex-1">
              <p className="font-semibold text-emerald-800">Active Leave</p>
              <p className="text-sm text-emerald-600">Until {activeLeave.end_time} &middot; {activeLeave.reason}</p>
            </div>
            {activeLeave.out_qr_code && (
              <Link to={`/employee/qr/${activeLeave.leave_id}`}>
                <Button variant="outline" size="sm">View QR</Button>
              </Link>
            )}
          </CardContent>
        </Card>
      )}

      {/* Stat cards with accent bars */}
      <div className="grid gap-4 sm:grid-cols-3">
        {[
          { label: "Pending", count: pendingCount, icon: Hourglass, bar: "bg-amber-500", iconBg: "bg-amber-100", iconColor: "text-amber-600" },
          { label: "Approved", count: approvedCount, icon: CheckCircle, bar: "bg-primary", iconBg: "bg-blue-100", iconColor: "text-primary" },
          { label: "Completed", count: completedCount, icon: History, bar: "bg-emerald-500", iconBg: "bg-emerald-100", iconColor: "text-emerald-600" },
        ].map((stat, i) => (
          <Card key={stat.label} className="card-accent card-hover" style={{ animationDelay: `${i * 0.1}s` }}>
            <div className={`h-1 w-full ${stat.bar}`} />
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`rounded-xl ${stat.iconBg} ${stat.iconColor} p-3`}>
                <stat.icon className="h-6 w-6" />
              </div>
              <div>
                <p className="text-3xl font-black text-foreground">{stat.count}</p>
                <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">{stat.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Actions */}
      <div className="flex gap-3">
        <Link to="/employee/request" className="flex-1">
          <Button className="btn-primary w-full py-4" size="lg">
            <Plus className="h-5 w-5" /> Request Leave
          </Button>
        </Link>
        <Link to="/employee/history" className="flex-1">
          <Button variant="outline" className="btn-secondary w-full py-4" size="lg">
            <History className="h-5 w-5" /> View History
          </Button>
        </Link>
      </div>

      {/* Recent requests */}
      <div className="card-accent">
        <div className="h-1 w-full bg-gradient-to-r from-primary to-secondary" />
        <div className="p-5">
          <div className="section-header">
            <h3>Recent Requests</h3>
            <Link to="/employee/history" className="section-action">View All</Link>
          </div>
          {history.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">
                <Inbox className="h-6 w-6 text-muted-foreground" />
              </div>
              <div>
                <h3>No leave requests yet</h3>
                <p>Submit your first temporary leave request to get started</p>
              </div>
              <Link to="/employee/request">
                <Button size="sm" className="btn-primary">
                  <Plus className="h-4 w-4" /> Request Leave
                </Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-2">
              {history.slice(0, 5).map((leave, i) => (
                <Link
                  key={leave.leave_id}
                  to={`/employee/qr/${leave.leave_id}`}
                  className="card-hover flex items-center justify-between rounded-lg border border-border/60 p-4"
                  style={{ animationDelay: `${i * 0.05}s` }}
                >
                  <div className="flex items-center gap-4">
                    <div className="rounded-lg bg-muted p-2">
                      <CalendarDays className="h-5 w-5 text-muted-foreground" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm">{formatDate(leave.leave_date)}</p>
                      <p className="text-xs text-muted-foreground">{formatTime(leave.start_time)} - {formatTime(leave.end_time)}</p>
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
