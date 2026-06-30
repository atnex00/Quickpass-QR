import { useEffect, useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogDescription,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Label } from "@/components/ui/label"
import { toast } from "sonner"
import type { Employee, Department } from "@/types"
import api from "@/lib/api"
import {
  Loader2,
  Plus,
  Search,
  Shield,
  ShieldOff,
  ShieldCheck,
  UserCheck,
  UserX,
  KeyRound,
  Pencil,
  Trash2,
  CheckCircle2,
  XCircle,
} from "lucide-react"

const emptyForm = {
  employee_id: "",
  full_name: "",
  position: "",
  department_id: "",
  email: "",
  password: "",
  is_supervisor: false,
  is_admin: false,
  is_security: false,
}

export default function UserManagerPage() {
  const [employees, setEmployees] = useState<Employee[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [filterDept, setFilterDept] = useState("all")
  const [filterStatus, setFilterStatus] = useState("all")
  const [filterRole, setFilterRole] = useState("all")

  const [addOpen, setAddOpen] = useState(false)
  const [editOpen, setEditOpen] = useState(false)
  const [passwordOpen, setPasswordOpen] = useState(false)
  const [selected, setSelected] = useState<Employee | null>(null)
  const [form, setForm] = useState({ ...emptyForm })
  const [password, setPassword] = useState("")

  const loadEmployees = async () => {
    try {
      const params: Record<string, string | number | undefined> = {
        search: search || undefined,
        page,
      }
      if (filterDept !== "all") params.department_id = filterDept
      if (filterStatus !== "all") params.is_active = filterStatus === "active" ? "true" : "false"
      if (filterRole !== "all") params.role = filterRole

      const res = await api.get("/admin/employees", { params })
      setEmployees(res.data.data)
      setTotal(res.data.pagination?.total || 0)
    } catch (_) {}
    finally { setLoading(false) }
  }

  const loadDepartments = async () => {
    try {
      const res = await api.get("/admin/departments")
      setDepartments(res.data.data)
    } catch (_) {}
  }

  useEffect(() => {
    loadEmployees()
    loadDepartments()
  }, [page, search, filterDept, filterStatus, filterRole])

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await api.post("/admin/employees", form)
      toast.success("Employee created")
      setAddOpen(false)
      setForm({ ...emptyForm })
      loadEmployees()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to create")
    }
  }

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selected) return
    try {
      await api.put(`/admin/employees/${selected.employee_id}`, {
        full_name: form.full_name,
        position: form.position,
        department_id: form.department_id,
        email: form.email,
        is_supervisor: form.is_supervisor,
        is_admin: form.is_admin,
        is_security: form.is_security,
      })
      toast.success("Employee updated")
      setEditOpen(false)
      loadEmployees()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to update")
    }
  }

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selected || !password) return
    try {
      await api.put(`/admin/employees/${selected.employee_id}`, { password })
      toast.success("Password reset")
      setPasswordOpen(false)
      setPassword("")
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to reset password")
    }
  }

  const handleToggleSupervisor = async (id: string) => {
    try {
      await api.put(`/admin/employees/${id}/supervisor`)
      toast.success("Supervisor status toggled")
      loadEmployees()
    } catch (_) {
      toast.error("Failed to toggle")
    }
  }

  const handleToggleAdmin = async (id: string) => {
    try {
      await api.put(`/admin/employees/${id}/admin`)
      toast.success("Admin status toggled")
      loadEmployees()
    } catch (_) {
      toast.error("Failed to toggle")
    }
  }

  const handleDeleteEmployee = async (id: string) => {
    if (!confirm("Delete this employee and all their data? This cannot be undone.")) return
    try {
      await api.delete(`/admin/employees/${id}`)
      toast.success("Employee deleted")
      loadEmployees()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Failed to delete")
    }
  }

  const handleToggleActive = async (emp: Employee) => {
    try {
      await api.put(`/admin/employees/${emp.employee_id}/status`)
      toast.success(emp.is_active ? "Employee deactivated" : "Employee activated")
      loadEmployees()
    } catch (_) {
      toast.error("Failed to toggle status")
    }
  }

  const openEdit = (emp: Employee) => {
    setSelected(emp)
    setForm({
      ...emptyForm,
      full_name: emp.full_name,
      position: emp.position,
      department_id: emp.department_id,
      email: emp.email,
    })
    setEditOpen(true)
  }

  const openPassword = (emp: Employee) => {
    setSelected(emp)
    setPassword("")
    setPasswordOpen(true)
  }

  const pages = Math.ceil(total / 20)

  return (
    <div className="page-enter space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">User Manager</h1>
          <p className="text-muted-foreground">{total} total employees</p>
        </div>
        <Dialog open={addOpen} onOpenChange={setAddOpen}>
          <DialogTrigger asChild>
            <Button className="gap-2"><Plus className="h-4 w-4" /> Add Employee</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add Employee</DialogTitle>
              <DialogDescription>Create a new employee account</DialogDescription>
            </DialogHeader>
            <form onSubmit={handleCreate} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Employee ID (6 digits)</Label>
                  <Input
                    placeholder="000011"
                    maxLength={6}
                    value={form.employee_id}
                    onChange={(e) => setForm({ ...form, employee_id: e.target.value.replace(/\D/g, "").slice(0, 6) })}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label>Department</Label>
                  <Select
                    value={form.department_id}
                    onValueChange={(v) => setForm({ ...form, department_id: v })}
                  >
                    <SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger>
                    <SelectContent>
                      {departments.map((d) => (
                        <SelectItem key={d.department_id} value={d.department_id}>{d.department_name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="space-y-2">
                <Label>Full Name</Label>
                <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label>Position</Label>
                <Input value={form.position} onChange={(e) => setForm({ ...form, position: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label>Email</Label>
                <Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label>Password</Label>
                <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isSupervisor"
                  checked={form.is_supervisor}
                  onChange={(e) => setForm({ ...form, is_supervisor: e.target.checked })}
                  className="h-4 w-4"
                />
                <Label htmlFor="isSupervisor">Supervisor access</Label>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isAdmin"
                  checked={form.is_admin}
                  onChange={(e) => setForm({ ...form, is_admin: e.target.checked })}
                  className="h-4 w-4"
                />
                <Label htmlFor="isAdmin">Admin access</Label>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isSecurity"
                  checked={form.is_security}
                  onChange={(e) => setForm({ ...form, is_security: e.target.checked })}
                  className="h-4 w-4"
                />
                <Label htmlFor="isSecurity">Security access</Label>
              </div>
              <Button type="submit" className="w-full">Create Employee</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      { /* Filters */ }
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search by name, ID, or email..."
            className="pl-9"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
          />
        </div>
        <Select value={filterDept} onValueChange={(v) => { setFilterDept(v); setPage(1) }}>
          <SelectTrigger className="w-[160px]"><SelectValue placeholder="Department" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Departments</SelectItem>
            {departments.map((d) => (
              <SelectItem key={d.department_id} value={d.department_id}>{d.department_name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={filterStatus} onValueChange={(v) => { setFilterStatus(v); setPage(1) }}>
          <SelectTrigger className="w-[130px]"><SelectValue placeholder="Status" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="inactive">Inactive</SelectItem>
          </SelectContent>
        </Select>
        <Select value={filterRole} onValueChange={(v) => { setFilterRole(v); setPage(1) }}>
          <SelectTrigger className="w-[130px]"><SelectValue placeholder="Role" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Roles</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="supervisor">Supervisor</SelectItem>
          </SelectContent>
        </Select>
      </div>

      { /* Table */ }
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Employee</TableHead>
                <TableHead>Position</TableHead>
                <TableHead>Department</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Roles</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto" />
                  </TableCell>
                </TableRow>
              ) : employees.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-12 text-muted-foreground">
                    No employees found
                  </TableCell>
                </TableRow>
              ) : employees.map((emp) => (
                <TableRow key={emp.employee_id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-sm font-bold text-white shrink-0">
                        {emp.full_name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-medium">{emp.full_name}</p>
                        <p className="text-xs text-muted-foreground">{emp.employee_id}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{emp.position}</TableCell>
                  <TableCell className="text-muted-foreground">{emp.department_name}</TableCell>
                  <TableCell className="text-muted-foreground">{emp.email}</TableCell>
                  <TableCell>
                    <div className="flex gap-1 flex-wrap">
                      {emp.is_admin && <Badge variant="default" className="text-xs">Admin</Badge>}
                      {emp.is_security && <Badge variant="outline" className="text-xs text-emerald-600 border-emerald-300 bg-emerald-50">Security</Badge>}
                      {emp.is_supervisor && <Badge variant="secondary" className="text-xs">Supervisor</Badge>}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant={emp.is_active ? "default" : "outline"} className={emp.is_active ? "bg-emerald-100 text-emerald-700 hover:bg-emerald-100" : ""}>
                      {emp.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end gap-1">
                      <Button variant="ghost" size="icon" onClick={() => openEdit(emp)} title="Edit">
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleToggleAdmin(emp.employee_id)} title="Toggle admin">
                        {emp.is_admin ? <ShieldCheck className="h-4 w-4 text-primary" /> : <Shield className="h-4 w-4" />}
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleToggleSupervisor(emp.employee_id)} title="Toggle supervisor">
                        {emp.is_supervisor ? <UserCheck className="h-4 w-4 text-secondary" /> : <UserX className="h-4 w-4" />}
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleToggleActive(emp)} title={emp.is_active ? "Deactivate" : "Activate"}>
                        {emp.is_active ? <CheckCircle2 className="h-4 w-4 text-emerald-500" /> : <XCircle className="h-4 w-4 text-muted-foreground" />}
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => openPassword(emp)} title="Reset password">
                        <KeyRound className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleDeleteEmployee(emp.employee_id)} title="Delete employee">
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      { /* Pagination */ }
      {pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">Page {page} of {pages}</p>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>
              Previous
            </Button>
            <Button variant="outline" size="sm" disabled={page >= pages} onClick={() => setPage(page + 1)}>
              Next
            </Button>
          </div>
        </div>
      )}

      { /* Edit Dialog */ }
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Employee</DialogTitle>
            <DialogDescription>Update employee details</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleUpdate} className="space-y-4">
            <div className="space-y-2">
              <Label>Full Name</Label>
              <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
            </div>
            <div className="space-y-2">
              <Label>Position</Label>
              <Input value={form.position} onChange={(e) => setForm({ ...form, position: e.target.value })} required />
            </div>
            <div className="space-y-2">
              <Label>Department</Label>
              <Select value={form.department_id} onValueChange={(v) => setForm({ ...form, department_id: v })}>
                <SelectTrigger><SelectValue placeholder="No department" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="">No department</SelectItem>
                  {departments.map((d) => (
                    <SelectItem key={d.department_id} value={d.department_id}>{d.department_name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Email</Label>
              <Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="edit-supervisor" checked={form.is_supervisor}
                onChange={(e) => setForm({ ...form, is_supervisor: e.target.checked })} className="h-4 w-4" />
              <Label htmlFor="edit-supervisor">Supervisor access</Label>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="edit-admin" checked={form.is_admin}
                onChange={(e) => setForm({ ...form, is_admin: e.target.checked })} className="h-4 w-4" />
              <Label htmlFor="edit-admin">Admin access</Label>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="edit-security" checked={form.is_security}
                onChange={(e) => setForm({ ...form, is_security: e.target.checked })} className="h-4 w-4" />
              <Label htmlFor="edit-security">Security access</Label>
            </div>
            <Button type="submit" className="w-full">Save Changes</Button>
          </form>
        </DialogContent>
      </Dialog>

      { /* Password Reset Dialog */ }
      <Dialog open={passwordOpen} onOpenChange={setPasswordOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reset Password</DialogTitle>
            <DialogDescription>{selected?.full_name}</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleResetPassword} className="space-y-4">
            <div className="space-y-2">
              <Label>New Password</Label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter new password"
                required
                minLength={4}
              />
            </div>
            <Button type="submit" className="w-full">Reset Password</Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  )
}
