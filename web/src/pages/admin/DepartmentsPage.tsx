import { useEffect, useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog"
import { Badge } from "@/components/ui/badge"
import type { Department } from "@/types"
import api from "@/lib/api"
import { Building2, Loader2, Plus, Trash2 } from "lucide-react"
import { toast } from "sonner"

export default function DepartmentsPage() {
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [addOpen, setAddOpen] = useState(false)
  const [form, setForm] = useState({ department_id: "", department_name: "", department_code: "", head_of_department: "" })
  const [saving, setSaving] = useState(false)
  const [confirmId, setConfirmId] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    api.get("/admin/departments")
      .then((res) => setDepartments(res.data.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.department_id || !form.department_name) return
    setSaving(true)
    try {
      await api.post("/admin/departments", form)
      toast.success("Department created")
      setAddOpen(false)
      setForm({ department_id: "", department_name: "", department_code: "", head_of_department: "" })
      load()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to create")
    }
    setSaving(false)
  }

  const handleDelete = async (id: string) => {
    try {
      await api.delete(`/admin/departments/${id}`)
      toast.success("Department deleted")
      setConfirmId(null)
      load()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to delete")
      setConfirmId(null)
    }
  }

  return (
    <div className="page-enter space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Departments</h1>
          <p className="text-muted-foreground">{departments.length} departments</p>
        </div>
        <Button className="gap-2" onClick={() => setAddOpen(true)}>
          <Plus className="h-4 w-4" /> Add Department
        </Button>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : departments.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">
            <Building2 className="h-6 w-6 text-muted-foreground" />
          </div>
          <div>
            <h3>No departments</h3>
            <p>Create your first department to organize your organization</p>
          </div>
          <Button className="btn-primary" onClick={() => setAddOpen(true)}>
            <Plus className="h-4 w-4" /> Add Department
          </Button>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {departments.map((dept) => (
            <Card key={dept.department_id} className="card-hover relative group">
              <CardContent className="p-6">
                <div className="flex items-start gap-4">
                  <div className="rounded-lg bg-primary/10 p-3">
                    <Building2 className="h-6 w-6 text-primary" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold">{dept.department_name}</h3>
                    <p className="text-sm text-muted-foreground">{dept.department_code}</p>
                    {dept.head_of_department && (
                      <p className="mt-2 text-sm">
                        <span className="text-muted-foreground">Head: </span>
                        <span className="font-medium">{dept.head_of_department}</span>
                      </p>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="absolute top-2 right-2 text-muted-foreground hover:text-destructive opacity-0 group-hover:opacity-100 transition-opacity"
                    onClick={() => setConfirmId(dept.department_id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Add Dialog */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Department</DialogTitle>
            <DialogDescription>Create a new department</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="space-y-2">
              <Label>Department ID</Label>
              <Input
                placeholder="DEP-004"
                value={form.department_id}
                onChange={(e) => setForm({ ...form, department_id: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label>Department Name</Label>
              <Input
                placeholder="e.g. Finance"
                value={form.department_name}
                onChange={(e) => setForm({ ...form, department_name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label>Code (optional)</Label>
              <Input
                placeholder="e.g. FIN"
                value={form.department_code}
                onChange={(e) => setForm({ ...form, department_code: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label>Head of Department (optional)</Label>
              <Input
                placeholder="Full name"
                value={form.head_of_department}
                onChange={(e) => setForm({ ...form, head_of_department: e.target.value })}
              />
            </div>
            <Button type="submit" className="w-full" disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : "Create Department"}
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirm */}
      <Dialog open={!!confirmId} onOpenChange={(o) => { if (!o) setConfirmId(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Department</DialogTitle>
            <DialogDescription>
              This action cannot be undone. Employees in this department must be reassigned first.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setConfirmId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={() => confirmId && handleDelete(confirmId)}>
              Delete
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
