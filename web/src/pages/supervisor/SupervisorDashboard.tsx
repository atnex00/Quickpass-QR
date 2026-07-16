import { useEffect } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import LoadingScreen from "@/components/shared/LoadingScreen"
import { UserCheck, ShieldCheck, CalendarDays, ArrowRight } from "lucide-react"

export default function SupervisorDashboard() {
  const { user } = useAuthStore()
  const { pendingRequests, isLoading, loadPendingRequests } = useLeaveStore()

  useEffect(() => {
    loadPendingRequests()
  }, [])

  if (isLoading) return <LoadingScreen message="Loading pending requests" />

  return (
    <div className="page-enter space-y-3">
      <div>
        <h1 className="text-2xl font-bold font-display">Supervisor Dashboard</h1>
        <p className="text-sm text-muted-foreground">{user?.department_name}</p>
      </div>

      <div className="panel-card border-l-4 border-l-primary">
        <div className="panel-card-body flex items-center gap-4">
          <div className="flex h-10 w-10 items-center justify-center rounded bg-primary/15">
            <ShieldCheck className="h-5 w-5 text-primary" />
          </div>
          <div className="flex-1">
            <p className="text-3xl font-black text-foreground">{pendingRequests.length}</p>
            <p className="text-[11px] font-semibold text-muted-foreground">Pending Requests</p>
          </div>
          <Link to="/supervisor/pending">
            <Button variant="outline" className="btn-secondary text-[10px] py-2">
              Review <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </div>
      </div>

      {pendingRequests.length > 0 && (
        <div className="panel-card">
          <div className="panel-card-header">
            <h3>Recent Pending Requests</h3>
          </div>
          <div className="panel-card-body space-y-1">
            {pendingRequests.slice(0, 5).map((req) => (
              <div
                key={req.leave_id}
                className="flex items-center justify-between rounded px-3 py-2 border border-transparent hover:border-border transition-all"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/20 text-[10px] font-bold text-primary">
                    {req.employee_name.charAt(0)}
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-foreground">{req.employee_name}</p>
                    <p className="text-[10px] text-muted-foreground">
                      {req.start_time} - {req.end_time}
                    </p>
                  </div>
                </div>
                <Link to="/supervisor/pending">
                  <Button variant="ghost" size="sm" className="text-[10px] h-7">Review</Button>
                </Link>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
