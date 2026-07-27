import { useState, useCallback } from "react"
import Cropper, { type Area } from "react-easy-crop"
import { Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"

interface PhotoCropperProps {
  image: string
  onCrop: (blob: Blob) => void
  onCancel: () => void
}

function createImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.crossOrigin = "anonymous"
    img.onload = () => resolve(img)
    img.onerror = reject
    img.src = url
  })
}

async function getCroppedBlob(imageUrl: string, pixelCrop: Area): Promise<Blob> {
  const image = await createImage(imageUrl)
  const canvas = document.createElement("canvas")
  const ctx = canvas.getContext("2d")!

  canvas.width = pixelCrop.width
  canvas.height = pixelCrop.height

  ctx.drawImage(
    image,
    pixelCrop.x, pixelCrop.y, pixelCrop.width, pixelCrop.height,
    0, 0, pixelCrop.width, pixelCrop.height
  )

  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) resolve(blob)
      else reject(new Error("Canvas toBlob failed"))
    }, "image/jpeg", 0.9)
  })
}

export default function PhotoCropper({ image, onCrop, onCancel }: PhotoCropperProps) {
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedPixels, setCroppedPixels] = useState<Area | null>(null)
  const [saving, setSaving] = useState(false)

  const onCropComplete = useCallback((_: Area, croppedAreaPixels: Area) => {
    setCroppedPixels(croppedAreaPixels)
  }, [])

  const handleSave = async () => {
    if (!croppedPixels) return
    setSaving(true)
    try {
      const blob = await getCroppedBlob(image, croppedPixels)
      onCrop(blob)
    } catch {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black">
      <div className="flex items-center justify-between px-4 py-3">
        <button
          onClick={onCancel}
          className="text-sm font-semibold text-white/80 transition-colors hover:text-white"
        >
          Cancel
        </button>
        <span className="text-sm font-semibold text-white">Crop Photo</span>
        <Button
          onClick={handleSave}
          disabled={saving}
          className="h-8 gap-1.5 px-3 text-xs"
        >
          {saving && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
          Save
        </Button>
      </div>

      <div className="relative flex-1">
        <Cropper
          image={image}
          crop={crop}
          zoom={zoom}
          aspect={1}
          cropShape="round"
          showGrid={false}
          onCropChange={setCrop}
          onZoomChange={setZoom}
          onCropComplete={onCropComplete}
        />
      </div>

      <div className="flex items-center gap-3 px-4 py-4">
        <span className="text-[11px] font-semibold text-white/50">Zoom</span>
        <input
          type="range"
          min={1}
          max={3}
          step={0.05}
          value={zoom}
          onChange={(e) => setZoom(Number(e.target.value))}
          className="h-1 w-full cursor-pointer appearance-none rounded-full bg-white/20 accent-amber-500 [&::-webkit-slider-thumb]:h-3.5 [&::-webkit-slider-thumb]:w-3.5 [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-amber-500"
        />
      </div>
    </div>
  )
}
