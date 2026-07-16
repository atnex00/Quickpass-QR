import { useEffect, useState } from "react"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import StatusBadge from "@/components/shared/StatusBadge"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { toast } from "sonner"
import { formatDate, formatTime } from "@/lib/utils"
import { useAuthStore } from "@/stores/authStore"
import api from "@/lib/api"
import { CheckCircle, XCircle, Loader2, Inbox, Undo2, Trash2 } from "lucide-react"

export default function PendingRequestsPage() {
  const {
    pendingRequests, isLoading, loadPendingRequests,
    approvedLeaves, loadApprovedLeaves,
    approveLeave, rejectLeave, revokeApproval,
  } = useLeaveStore()
  const [rejectId, setRejectId] = useState<string | null>(null)
  const [rejectReason, setRejectReason] = useState("")
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  useEffect(() => {
    loadPendingRequests()
    loadApprovedLeaves()
  }, [])

  const handleApprove = async (leaveId: string) => {
    setActionLoading(leaveId)
    const ok = await approveLeave(leaveId)
    if (ok) toast.success("Leave approved")
    else toast.error("Could not approve — try again")
    setActionLoading(null)
    loadApprovedLeaves()
  }

  const handleReject = async () => {
    if (!rejectId || !rejectReason.trim()) return
    setActionLoading(rejectId)
    const ok = await rejectLeave(rejectId, rejectReason.trim())
    if (ok) toast.success("Leave rejected")
    else toast.error("Could not reject — try again")
    setActionLoading(null)
    setRejectId(null)
    setRejectReason("")
  }

  const handleRevoke = async (leaveId: string) => {
    setActionLoading(leaveId)
    const ok = await revokeApproval(leaveId)
    if (ok) {
      toast.success("Approval revoked — request moved back to pending")
      loadPendingRequests()
    } else {
      toast.error("Could not revoke")
    }
    setActionLoading(null)
  }

  const handleDelete = async (leaveId: string) => {
    setActionLoading(leaveId)
    try {
      await api.delete(`/leave/${leaveId}`)
      toast.success("Leave record deleted")
      loadApprovedLeaves()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Could not delete")
    }
    setActionLoading(null)
  }

  const { user } = useAuthStore()

  return (
    <div className="page-enter space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Pending Requests</h1>
        <p className="text-sm text-muted-foreground">
          {pendingRequests.length} request{pendingRequests.length !== 1 ? "s" : ""} awaiting review
        </p>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
        </div>
      ) : pendingRequests.length === 0 ? (
        <div className="flex flex-col items-center gap-4 py-16 text-center">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg border border-border bg-muted">
            <Inbox className="h-5 w-5 text-muted-foreground" />
          </div>
          <div>
            <p className="text-base font-semibold text-foreground">All caught up!</p>
            <p className="text-sm text-muted-foreground">No pending requests awaiting your review</p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {pendingRequests.map((req) => (
            <Card key={req.leave_id} className="border-l-4 border-l-primary">
              <CardContent>
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/15 text-sm font-semibold text-primary">
                    {req.employee_name.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="text-sm font-semibold text-foreground">{req.employee_name}</h3>
                        {req.employee_position && (
                          <p className="text-xs text-muted-foreground">{req.employee_position}</p>
                        )}
                      </div>
                      <StatusBadge status={req.status} />
                    </div>

                    <div className="mt-2 flex gap-3 text-xs text-muted-foreground">
                      <span>{formatDate(req.leave_date)}</span>
                      <span className="text-border">|</span>
                      <span>{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>

                    <p className="mt-1.5 text-xs text-muted-foreground">{req.reason}</p>

                    <div className="mt-3 flex gap-1.5">
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1 border-destructive text-destructive hover:bg-destructive/10"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => setRejectId(req.leave_id)}
                      >
                        <XCircle className="h-3.5 w-3.5" /> Reject
                      </Button>
                      <Button
                        size="sm"
                        className="gap-1"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleApprove(req.leave_id)}
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <CheckCircle className="h-3.5 w-3.5" />
                        )}
                        Approve
                      </Button>
                      {user?.is_admin && (
                        <Button
                          variant="outline"
                          size="icon"
                          className="h-8 w-8 border-destructive/40 text-destructive hover:bg-destructive/10"
                          disabled={actionLoading === req.leave_id}
                          onClick={() => handleDelete(req.leave_id)}
                          title="Delete (admin only)"
                        >
                          {actionLoading === req.leave_id ? (
                            <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          ) : (
                            <Trash2 className="h-3.5 w-3.5" />
                          )}
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Approved / Revoke Section */}
      <div className="pt-2">
        <h2 className="text-lg font-semibold">Approved Leaves</h2>
        <p className="text-sm text-muted-foreground">Revoke approvals to move requests back to pending</p>
      </div>

      {approvedLeaves.length === 0 ? (
        <p className="text-sm text-muted-foreground">No approved leaves yet</p>
      ) : (
        <div className="space-y-3">
          {approvedLeaves.map((req) => (
            <Card key={req.leave_id} className="border-l-4 border-l-success/60">
              <CardContent>
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-success/15 text-sm font-semibold text-success">
                    {req.employee_name.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="text-sm font-semibold text-foreground">{req.employee_name}</h3>
                        {req.employee_position && (
                          <p className="text-xs text-muted-foreground">{req.employee_position}</p>
                        )}
                      </div>
                      <StatusBadge status={req.status} />
                    </div>

                    <div className="mt-2 flex gap-3 text-xs text-muted-foreground">
                      <span>{formatDate(req.leave_date)}</span>
                      <span className="text-border">|</span>
                      <span>{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>

                    <p className="mt-1.5 text-xs text-muted-foreground">{req.reason}</p>

                    <div className="mt-3 flex gap-1.5">
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1 border-primary/40 text-primary hover:bg-primary/10"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleRevoke(req.leave_id)}
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <Undo2 className="h-3.5 w-3.5" />
                        )}
                        Revoke Approval
                      </Button>
                      {user?.is_admin && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="gap-1 border-destructive/40 text-destructive hover:bg-destructive/10"
                          disabled={actionLoading === req.leave_id}
                          onClick={() => handleDelete(req.leave_id)}
                        >
                          {actionLoading === req.leave_id ? (
                            <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          ) : (
                            <Trash2 className="h-3.5 w-3.5" />
                          )}
                          Delete
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Reject Dialog */}
      <Dialog open={!!rejectId} onOpenChange={(o) => { if (!o) setRejectId(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Leave Request</DialogTitle>
            <DialogDescription>Explain why this request is being declined</DialogDescription>
          </DialogHeader>
          <Textarea
            placeholder="Enter rejection reason..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            rows={3}
          />
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setRejectId(null); setRejectReason("") }}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleReject}
              disabled={!rejectReason.trim() || actionLoading === rejectId}
            >
              {actionLoading === rejectId ? <Loader2 className="h-4 w-4 animate-spin" /> : "Reject"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
