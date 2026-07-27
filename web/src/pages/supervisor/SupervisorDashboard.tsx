import { useEffect } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import LoadingScreen from "@/components/shared/LoadingScreen"
import PageHeader from "@/components/layout/PageHeader"
import { UserCheck, ShieldCheck, CalendarDays, ArrowRight } from "lucide-react"

export default function SupervisorDashboard() {
  const { user } = useAuthStore()
  const { pendingRequests, isLoading, loadPendingRequests } = useLeaveStore()

  useEffect(() => {
    loadPendingRequests()
  }, [])

  if (isLoading) return <LoadingScreen message="Loading pending requests" />

  return (
    <div className="page-enter space-y-5">
      <PageHeader
        title="Supervisor Dashboard"
        subtitle={user?.department_name}
        icon={<ShieldCheck className="h-5 w-5" />}
      />

      <div className="kpi border-l-4 border-l-primary">
        <div className="flex items-center gap-4">
          <div className="stat-tile">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div className="flex-1">
            <p className="kpi-value">{pendingRequests.length}</p>
            <p className="kpi-label">Pending Requests</p>
          </div>
          <Link to="/supervisor/pending">
            <Button variant="outline" className="btn-secondary text-[10px] py-2">
              Review <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </div>
      </div>

      {pendingRequests.length > 0 && (
        <div className="card-elevated">
          <div className="panel-card-header">
            <h3>Recent Pending Requests</h3>
          </div>
          <div className="panel-card-body space-y-1">
            {pendingRequests.slice(0, 5).map((req) => (
              <div
                key={req.leave_id}
                className="lift flex items-center justify-between rounded-lg px-3 py-2 border border-transparent hover:border-border hover:bg-accent/40 transition-all"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-7 w-7 items-center justify-center rounded-full bg-gradient-to-br from-primary/80 to-primary/40 text-[10px] font-bold text-[#1c1917]">
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
