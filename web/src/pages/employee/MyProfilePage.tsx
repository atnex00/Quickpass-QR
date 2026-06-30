import { useState } from "react"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { toast } from "sonner"
import { Loader2, User, Save } from "lucide-react"

export default function MyProfilePage() {
  const { user, updateProfile } = useAuthStore()
  const [form, setForm] = useState({
    full_name: user?.full_name || "",
    position: user?.position || "",
    email: user?.email || "",
    password: "",
  })
  const [saving, setSaving] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)

    const payload: any = {}
    if (form.full_name !== user?.full_name) payload.full_name = form.full_name
    if (form.position !== user?.position) payload.position = form.position
    if (form.email !== user?.email) payload.email = form.email
    if (form.password) payload.password = form.password

    if (Object.keys(payload).length === 0) {
      toast.error("No changes to save")
      setSaving(false)
      return
    }

    const ok = await updateProfile(payload)
    if (ok) {
      toast.success("Profile updated")
      setForm((f) => ({ ...f, password: "" }))
    } else {
      toast.error("Could not update profile")
    }
    setSaving(false)
  }

  return (
    <div className="page-enter mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-bold">My Profile</h1>
        <p className="text-muted-foreground">Manage your account details</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <User className="h-5 w-5" /> Personal Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="mb-6 grid grid-cols-2 gap-4 rounded-lg border bg-muted/50 p-4 text-sm">
            <div>
              <span className="text-muted-foreground">Employee ID</span>
              <p className="font-medium">{user?.employee_id}</p>
            </div>
            <div>
              <span className="text-muted-foreground">Department</span>
              <p className="font-medium">{user?.department_name || "N/A"}</p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name</Label>
              <Input
                id="full_name"
                value={form.full_name}
                onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="position">Position</Label>
              <Input
                id="position"
                value={form.position}
                onChange={(e) => setForm({ ...form, position: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">New Password (leave blank to keep current)</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter new password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </div>
            <Button type="submit" className="w-full gap-2" disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
              Save Changes
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
