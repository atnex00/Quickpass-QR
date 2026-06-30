import { useEffect } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { UserCheck, ShieldCheck, CalendarDays, ArrowRight } from "lucide-react"

export default function SupervisorDashboard() {
  const { user } = useAuthStore()
  const { pendingRequests, loadPendingRequests } = useLeaveStore()

  useEffect(() => {
    loadPendingRequests()
  }, [])

  return (
    <div className="page-enter space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Supervisor Dashboard</h1>
        <p className="text-muted-foreground">{user?.department_name}</p>
      </div>

      <Card className="bg-primary text-primary-foreground">
        <CardContent className="flex items-center gap-6 p-8">
          <div className="rounded-xl bg-white/15 p-4">
            <ShieldCheck className="h-10 w-10" />
          </div>
          <div className="flex-1">
            <p className="text-4xl font-bold">{pendingRequests.length}</p>
            <p className="text-primary-foreground/70">Pending Requests</p>
          </div>
          <Link to="/supervisor/pending">
            <Button variant="secondary" className="gap-2">
              Review <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardContent className="p-6">
            <Link
              to="/supervisor/pending"
              className="flex items-center gap-4"
            >
              <div className="rounded-lg bg-orange-100 p-3">
                <ShieldCheck className="h-6 w-6 text-orange-600" />
              </div>
              <div>
                <p className="font-semibold">Review Requests</p>
                <p className="text-sm text-muted-foreground">
                  {pendingRequests.length} pending
                </p>
              </div>
            </Link>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-lg bg-secondary/20 p-3">
                <CalendarDays className="h-6 w-6 text-secondary" />
              </div>
              <div>
                <p className="font-semibold">Team Calendar</p>
                <p className="text-sm text-muted-foreground">View team schedule</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {pendingRequests.length > 0 && (
        <Card>
          <CardContent className="p-4">
            <h3 className="mb-3 font-semibold">Recent Pending Requests</h3>
            <div className="space-y-2">
              {pendingRequests.slice(0, 5).map((req) => (
                <div
                  key={req.leave_id}
                  className="flex items-center justify-between rounded-lg border p-3"
                >
                  <div className="flex items-center gap-3">
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
                      {req.employee_name.charAt(0)}
                    </div>
                    <div>
                      <p className="text-sm font-medium">{req.employee_name}</p>
                      <p className="text-xs text-muted-foreground">
                        {req.start_time} - {req.end_time}
                      </p>
                    </div>
                  </div>
                  <Link to="/supervisor/pending">
                    <Button variant="ghost" size="sm">Review</Button>
                  </Link>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
