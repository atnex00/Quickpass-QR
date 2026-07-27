import { useEffect, useState } from "react"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card } from "@/components/ui/card"
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
import PageHeader from "@/components/layout/PageHeader"
import { CheckCircle, XCircle, Loader2, Inbox, User, Undo2, Trash2 } from "lucide-react"

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
      <PageHeader
        title="Pending Requests"
        subtitle={`${pendingRequests.length} request${pendingRequests.length !== 1 ? "s" : ""} awaiting review`}
        icon={<Inbox className="h-5 w-5" />}
      />

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : pendingRequests.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">
            <Inbox className="h-6 w-6 text-muted-foreground" />
          </div>
          <div>
            <h3>All caught up!</h3>
            <p>No pending requests awaiting your review</p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {pendingRequests.map((req) => (
            <div key={req.leave_id} className="panel-card card-hover border-l-4 border-l-primary">
              <div className="panel-card-body">
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/20 text-xs font-bold text-primary">
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
                      <span className="text-border/50">|</span>
                      <span>{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>

                    <p className="mt-1.5 text-xs text-muted-foreground/70">{req.reason}</p>

                    <div className="mt-3 flex gap-1.5">
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1 h-7 text-[10px] border-destructive text-destructive hover:bg-destructive/10"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => setRejectId(req.leave_id)}
                      >
                        <XCircle className="h-3 w-3" /> Reject
                      </Button>
                      <Button
                        size="sm"
                        className="gap-1 h-7 text-[10px] bg-primary text-primary-foreground"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleApprove(req.leave_id)}
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-3 w-3 animate-spin" />
                        ) : (
                          <CheckCircle className="h-3 w-3" />
                        )}
                        Approve
                      </Button>
                      {user?.is_admin && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="gap-1 h-7 text-[10px] border-destructive/40 text-destructive hover:bg-destructive/5"
                          disabled={actionLoading === req.leave_id}
                          onClick={() => handleDelete(req.leave_id)}
                          title="Delete (admin only)"
                        >
                          {actionLoading === req.leave_id ? (
                            <Loader2 className="h-3 w-3 animate-spin" />
                          ) : (
                            <Trash2 className="h-3 w-3" />
                          )}
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Approved / Revoke Section */}
      <div className="pt-2">
        <h2 className="text-lg font-bold font-display">Approved Leaves</h2>
        <p className="text-xs text-muted-foreground">Revoke approvals to move requests back to pending</p>
      </div>

      {approvedLeaves.length === 0 ? (
        <p className="text-xs text-muted-foreground">No approved leaves yet</p>
      ) : (
        <div className="space-y-3">
          {approvedLeaves.map((req) => (
            <div key={req.leave_id} className="panel-card border-l-4 border-l-success/60">
              <div className="panel-card-body">
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-success/20 text-xs font-bold text-success">
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
                      <span className="text-border/50">|</span>
                      <span>{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>

                    <p className="mt-1.5 text-xs text-muted-foreground/70">{req.reason}</p>

                    <div className="mt-3 flex gap-1.5">
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1 h-7 text-[10px] border-primary/40 text-primary hover:bg-primary/10"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleRevoke(req.leave_id)}
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-3 w-3 animate-spin" />
                        ) : (
                          <Undo2 className="h-3 w-3" />
                        )}
                        Revoke Approval
                      </Button>
                      {user?.is_admin && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="gap-1 h-7 text-[10px] border-destructive/40 text-destructive hover:bg-destructive/10"
                          disabled={actionLoading === req.leave_id}
                          onClick={() => handleDelete(req.leave_id)}
                        >
                          {actionLoading === req.leave_id ? (
                            <Loader2 className="h-3 w-3 animate-spin" />
                          ) : (
                            <Trash2 className="h-3 w-3" />
                          )}
                          Delete
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
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
