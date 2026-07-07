import { useRef, useState } from "react"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { toast } from "sonner"
import { User, Camera, Loader2 } from "lucide-react"
import PhotoCropper from "@/components/PhotoCropper"

export default function MyProfilePage() {
  const { user, updateProfilePhoto } = useAuthStore()
  const inputRef = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const [cropImage, setCropImage] = useState<string | null>(null)

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      toast.error("Only .jpg, .png, and .webp files are allowed")
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error("File must be under 5 MB")
      return
    }

    const reader = new FileReader()
    reader.onload = () => setCropImage(reader.result as string)
    reader.readAsDataURL(file)
    if (inputRef.current) inputRef.current.value = ""
  }

  const handleCrop = async (blob: Blob) => {
    setCropImage(null)
    setUploading(true)

    const file = new File([blob], "profile.jpg", { type: "image/jpeg" })
    const ok = await updateProfilePhoto(file)
    if (ok) {
      toast.success("Profile photo updated")
    } else {
      toast.error("Could not upload photo")
    }
    setUploading(false)
  }

  const handleCancelCrop = () => {
    setCropImage(null)
  }

  const role = user?.is_admin ? "Admin" : user?.is_supervisor ? "Supervisor" : user?.is_security ? "Security" : "Employee"

  return (
    <div className="page-enter mx-auto max-w-lg space-y-6">
      <div>
        <h1 className="text-2xl font-bold">My Profile</h1>
        <p className="text-muted-foreground">Your account information</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <User className="h-5 w-5" /> Profile Photo
          </CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col items-center gap-4">
          <div className="relative">
            <div className="flex h-28 w-28 items-center justify-center overflow-hidden rounded-full border-2 border-border bg-muted">
              {user?.profile_photo ? (
                <img src={user.profile_photo} alt="Profile" className="size-full object-cover" />
              ) : (
                <User className="h-12 w-12 text-muted-foreground/40" />
              )}
            </div>
            <label
              htmlFor="photo-upload"
              className="absolute -bottom-1 -right-1 flex h-9 w-9 cursor-pointer items-center justify-center rounded-full border border-border bg-card shadow-sm transition-colors hover:bg-accent"
            >
              {uploading ? (
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              ) : (
                <Camera className="h-4 w-4 text-muted-foreground" />
              )}
            </label>
            <input
              ref={inputRef}
              id="photo-upload"
              type="file"
              accept=".jpg,.jpeg,.png,.webp"
              className="hidden"
              onChange={handleFile}
              disabled={uploading}
            />
          </div>
          <p className="text-xs text-muted-foreground">JPG, PNG, or WebP &middot; max 5 MB</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <User className="h-5 w-5" /> Personal Information
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-x-6 gap-y-4 rounded-lg border bg-muted/50 p-4 text-sm">
            <div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Employee ID</span>
              <p className="mt-0.5 font-medium">{user?.employee_id}</p>
            </div>
            <div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Role</span>
              <p className="mt-0.5 font-medium">{role}</p>
            </div>
            <div className="col-span-2">
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Full Name</span>
              <p className="mt-0.5 font-medium">{user?.full_name}</p>
            </div>
            <div className="col-span-2">
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Email</span>
              <p className="mt-0.5 font-medium">{user?.email}</p>
            </div>
            <div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Position</span>
              <p className="mt-0.5 font-medium">{user?.position}</p>
            </div>
            <div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Department</span>
              <p className="mt-0.5 font-medium">{user?.department_name || "N/A"}</p>
            </div>
            <div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">Hire Date</span>
              <p className="mt-0.5 font-medium">{user?.hire_date || "N/A"}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {cropImage && (
        <PhotoCropper
          image={cropImage}
          onCrop={handleCrop}
          onCancel={handleCancelCrop}
        />
      )}
    </div>
  )
}
