import { useEffect, useState } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import StatusBadge from "@/components/shared/StatusBadge"
import DashboardSkeleton from "@/components/shared/DashboardSkeleton"
import {
  Clock, History, Plus, CheckCircle, Hourglass, Inbox, CalendarDays, Timer,
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
    <div className="page-enter space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Welcome back, {user?.full_name?.split(" ")[0] || "User"}</h1>
        <p className="text-sm text-muted-foreground mt-1">{user?.position} &middot; {user?.department_name}</p>
      </div>

      {/* Active leave banner */}
      {activeLeave && (
        <Card className="border-l-4 border-l-primary">
          <CardContent className="flex items-center gap-3">
            <Timer className="h-5 w-5 text-primary shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground">Active Leave</p>
              <p className="text-xs text-muted-foreground truncate">Until {activeLeave.end_time} &middot; {activeLeave.reason}</p>
            </div>
            {activeLeave.out_qr_code && (
              <Link to={`/employee/qr/${activeLeave.leave_id}`}>
                <Button variant="outline" size="sm">View QR</Button>
              </Link>
            )}
          </CardContent>
        </Card>
      )}

      {/* Stat cards */}
      <div className="grid gap-3 sm:grid-cols-3">
        {[
          { label: "Pending", count: pendingCount, icon: Hourglass, dot: "bg-primary" },
          { label: "Approved", count: approvedCount, icon: CheckCircle, dot: "bg-success" },
          { label: "Completed", count: completedCount, icon: History, dot: "bg-muted-foreground" },
        ].map((stat) => (
          <Card key={stat.label} className="transition-colors hover:border-border">
            <CardContent className="flex items-center gap-3">
              <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${stat.dot}`} />
              <div className="flex-1">
                <p className="text-2xl font-bold text-foreground">{stat.count}</p>
                <p className="text-xs font-medium text-muted-foreground">{stat.label}</p>
              </div>
              <stat.icon className="h-4 w-4 text-muted-foreground/25" />
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Actions */}
      <div className="flex gap-2">
        <Link to="/employee/request" className="flex-1">
          <Button className="w-full">
            <Plus className="h-4 w-4" /> Request Leave
          </Button>
        </Link>
        <Link to="/employee/history" className="flex-1">
          <Button variant="outline" className="w-full">
            <History className="h-4 w-4" /> View History
          </Button>
        </Link>
      </div>

      {/* Recent requests */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Recent Requests</CardTitle>
          <Link to="/employee/history" className="text-xs font-medium text-muted-foreground hover:text-primary transition-colors">View All</Link>
        </CardHeader>
        <CardContent>
          {history.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-8 text-center">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg border border-border bg-muted">
                <Inbox className="h-5 w-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">No leave requests yet</p>
                <p className="text-sm text-muted-foreground">Submit your first request to get started</p>
              </div>
              <Link to="/employee/request">
                <Button size="sm">
                  <Plus className="h-3.5 w-3.5" /> Request Leave
                </Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-1">
              {history.slice(0, 5).map((leave) => (
                <Link
                  key={leave.leave_id}
                  to={`/employee/qr/${leave.leave_id}`}
                  className="flex items-center justify-between rounded-md px-3 py-2.5 transition-colors hover:bg-accent"
                >
                  <div className="flex items-center gap-3">
                    <span className="flex h-8 w-8 items-center justify-center rounded-md bg-muted">
                      <CalendarDays className="h-4 w-4 text-muted-foreground" />
                    </span>
                    <div>
                      <p className="text-sm font-medium text-foreground">{formatDate(leave.leave_date)}</p>
                      <p className="text-xs text-muted-foreground">{formatTime(leave.start_time)} - {formatTime(leave.end_time)}</p>
                    </div>
                  </div>
                  <StatusBadge status={leave.status} />
                </Link>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
