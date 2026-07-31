import { useState, useRef, useEffect, useCallback } from "react"
import { useNavigate, Link } from "react-router"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Scan, QrCode, Camera, CameraOff, Loader2, History, CheckCircle, LogOut, LayoutDashboard } from "lucide-react"
import jsQR from "jsqr"
import { toast } from "sonner"
import { useScanStore } from "@/stores/scanStore"
import { useAuthStore } from "@/stores/authStore"

type ScanState = "idle" | "detected" | "confirmed"

declare class BarcodeDetector {
  constructor(options?: { formats?: string[] })
  detect(image: HTMLVideoElement): Promise<Array<{ rawValue: string }>>
}

const hasNative = typeof window !== "undefined" && "BarcodeDetector" in window
let nativeDetector: BarcodeDetector | null = null
if (hasNative) {
  try { nativeDetector = new BarcodeDetector({ formats: ["qr_code"] }) } catch (_) {}
}

export default function ScannerPage() {
  const navigate = useNavigate()
  const { validateScan, isLoading } = useScanStore()
  const { user, logout } = useAuthStore()
  const [manualInput, setManualInput] = useState("")
  const [cameraActive, setCameraActive] = useState(false)
  const [cameraError, setCameraError] = useState<string | null>(null)
  const [scanState, setScanState] = useState<ScanState>("idle")
  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const timerRef = useRef<number | null>(null)
  const lockedRef = useRef(false)
  const detectedRef = useRef<string | null>(null)
  const detectedTimeRef = useRef<number>(0)
  const lastNoDetectRef = useRef<number>(0)

  const cleanup = useCallback(() => {
    if (timerRef.current !== null) clearTimeout(timerRef.current)
    timerRef.current = null
    lockedRef.current = false
    detectedRef.current = null
    detectedTimeRef.current = 0
    lastNoDetectRef.current = 0
    setScanState("idle")
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop())
      streamRef.current = null
    }
    if (videoRef.current) videoRef.current.srcObject = null
    setCameraActive(false)
  }, [])

  useEffect(() => cleanup, [cleanup])

  const doScan = useCallback(async (data: string) => {
    if (!data.trim()) return
    setScanState("confirmed")
    const ok = await validateScan(data.trim())
    if (ok) navigate("/security/result", { replace: true })
    else {
      const err = useScanStore.getState().error
      if (err) toast.error(err)
      navigate("/security/result", { replace: true })
    }
  }, [navigate, validateScan])

  const startCamera = useCallback(async () => {
    setCameraError(null)
    try {
      if (!navigator.mediaDevices?.getUserMedia) throw new Error("Camera API not available")
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
        audio: false,
      })
      streamRef.current = stream
      const vid = videoRef.current
      if (!vid) { cleanup(); return }
      vid.srcObject = stream
      await vid.play()
      setCameraActive(true)
      setScanState("idle")
      detectedRef.current = null
      detectedTimeRef.current = 0
      lastNoDetectRef.current = 0

      const scanW = 200, scanH = 200
      const offscreen = document.createElement("canvas")
      offscreen.width = scanW
      offscreen.height = scanH
      const octx = offscreen.getContext("2d")!

      const schedule = () => { timerRef.current = window.setTimeout(tick, 80) }

      const tick = async () => {
        if (lockedRef.current) return
        if (!vid.videoWidth || vid.videoHeight === 0) { schedule(); return }
        let raw: string | null = null
        if (nativeDetector) {
          try {
            const barcodes = await nativeDetector.detect(vid)
            if (barcodes.length > 0 && barcodes[0].rawValue) raw = barcodes[0].rawValue
          } catch (_) {}
        }
        if (!raw) {
          octx.drawImage(vid, 0, 0, scanW, scanH)
          let imageData = octx.getImageData(0, 0, scanW, scanH)
          let code = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: "attemptBoth" })
          raw = code?.data || null

          if (!raw) {
            octx.clearRect(0, 0, scanW, scanH)
            octx.save()
            octx.translate(scanW, 0)
            octx.scale(-1, 1)
            octx.drawImage(vid, 0, 0, scanW, scanH)
            octx.restore()
            imageData = octx.getImageData(0, 0, scanW, scanH)
            code = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: "attemptBoth" })
            raw = code?.data || null
          }
        }
        if (raw && !lockedRef.current) {
          if (detectedRef.current === raw) {
            if (Date.now() - detectedTimeRef.current >= 200) {
              lockedRef.current = true
              setScanState("confirmed")
              cleanup()
              doScan(raw)
              return
            }
            setScanState("detected")
          } else {
            detectedRef.current = raw
            detectedTimeRef.current = Date.now()
            lastNoDetectRef.current = 0
            setScanState("detected")
          }
        } else {
          if (detectedRef.current) {
            detectedRef.current = null
            detectedTimeRef.current = 0
            setScanState("idle")
          }
        }
        schedule()
      }
      schedule()
    } catch (err: any) {
      const name = err.name || "", msg = err.message || ""
      if (name === "NotAllowedError" || msg.includes("permission"))
        setCameraError("Camera permission denied. Allow camera access in your browser settings.")
      else if (name === "NotFoundError" || msg.includes("NotFound"))
        setCameraError("No camera found on this device.")
      else if (msg.includes("secure context") || msg.includes("HTTP"))
        setCameraError("Camera requires HTTPS — use the HTTPS link.")
      else
        setCameraError(`Camera error: ${msg}`)
      cleanup()
    }
  }, [cleanup, doScan])

  const handleManual = (e: React.FormEvent) => {
    e.preventDefault()
    if (!manualInput.trim()) return
    doScan(manualInput.trim())
  }

  const isDetected = scanState === "detected"
  const isConfirmed = scanState === "confirmed"
  const isIdle = scanState === "idle"

  return (
    <div className="page-enter flex min-h-screen flex-col bg-background app-aurora">
      <main className="relative z-[1] flex flex-1 flex-col items-center p-6">
        <div className="w-full max-w-sm space-y-4">

          <div className="mb-6 text-center">
            <h1 className="text-xl font-bold tracking-tight text-foreground sm:text-2xl">Gate Scanner</h1>
            <p className="mt-1 text-sm text-muted-foreground">Scan OUT or IN QR codes to record gate entries</p>
          </div>

          <div className="flex items-center gap-1 self-end">
            <Link to="/employee">
              <Button variant="ghost" size="sm"><LayoutDashboard className="h-4 w-4" /></Button>
            </Link>
            <Link to="/security/history">
              <Button variant="ghost" size="sm"><History className="h-4 w-4" /></Button>
            </Link>
            <Button variant="ghost" size="sm" onClick={logout}><LogOut className="h-4 w-4" /></Button>
          </div>

          {/* Scanner Card */}
          <div className="card-elevated">
            <div className="p-4">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-xs font-black uppercase tracking-[0.1em] text-muted-foreground">Camera Scanner</h2>
                {cameraActive && isIdle && (
                  <span className="flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-[10px] font-semibold text-primary">
                    <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
                    Live
                  </span>
                )}
                {isDetected && (
                  <span className="flex items-center gap-1.5 rounded-full bg-emerald-100 px-2.5 py-1 text-[10px] font-semibold text-emerald-700">
                    <CheckCircle className="h-3 w-3" /> Detected
                  </span>
                )}
                {isConfirmed && (
                  <span className="flex items-center gap-1.5 rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-semibold text-amber-700">
                    <Loader2 className="h-3 w-3 animate-spin" /> Processing
                  </span>
                )}
              </div>

              {cameraError && (
                <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
                  <p className="text-[10px] font-black uppercase tracking-[0.08em]">Camera Error</p>
                  <p className="mt-0.5">{cameraError}</p>
                </div>
              )}

              {/* Viewport */}
              <div className="relative mx-auto overflow-hidden rounded-2xl bg-black ring-1 ring-border" style={{ width: "100%", maxWidth: 300, aspectRatio: "1/1" }}>
                <video ref={videoRef} autoPlay playsInline muted className="size-full object-cover" />

                {!cameraActive && (
                  <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-3 bg-muted/95">
                    <span className="stat-tile">
                      <QrCode className="h-6 w-6" />
                    </span>
                    <div className="text-center">
                      <p className="text-sm font-medium text-foreground">Camera is off</p>
                      <p className="mt-0.5 text-xs text-muted-foreground/70">Position QR code within the frame</p>
                    </div>
                  </div>
                )}

                {cameraActive && (
                  <>
                    {(isDetected || isConfirmed) && (
                      <div className="absolute inset-0 z-20 flex items-center justify-center bg-emerald-500/15 animate-[statFadeIn_0.15s_ease]" />
                    )}
                    {isDetected && (
                      <div className="absolute inset-0 z-30 flex items-center justify-center">
                        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/20 backdrop-blur-sm">
                          <CheckCircle className="h-8 w-8 text-emerald-600" />
                        </div>
                      </div>
                    )}
                    {isConfirmed && (
                      <div className="absolute inset-0 z-30 flex items-center justify-center">
                        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-amber-500/20 backdrop-blur-sm">
                          <Loader2 className="h-8 w-8 animate-spin text-amber-600" />
                        </div>
                      </div>
                    )}
                    <div className="absolute inset-0 z-10 flex items-center justify-center pointer-events-none">
                      <div className={`relative size-48 ${cameraActive && isIdle ? "amber-border-glow" : ""}`}>
                        <div className="absolute top-0 left-0 h-8 w-8 border-t-[3px] border-l-[3px] rounded-tl-lg border-primary shadow-[0_0_8px_rgba(251,191,36,0.5)]" />
                        <div className="absolute top-0 right-0 h-8 w-8 border-t-[3px] border-r-[3px] rounded-tr-lg border-primary shadow-[0_0_8px_rgba(251,191,36,0.5)]" />
                        <div className="absolute bottom-0 left-0 h-8 w-8 border-b-[3px] border-l-[3px] rounded-bl-lg border-primary shadow-[0_0_8px_rgba(251,191,36,0.5)]" />
                        <div className="absolute bottom-0 right-0 h-8 w-8 border-b-[3px] border-r-[3px] rounded-br-lg border-primary shadow-[0_0_8px_rgba(251,191,36,0.5)]" />
                      </div>
                    </div>
                    <div className="absolute bottom-3 left-1/2 z-30 -translate-x-1/2">
                      {isIdle && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1.5 text-[11px] font-medium text-primary">
                          <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
                          Point at QR code
                        </span>
                      )}
                      {isDetected && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-success/20 px-3 py-1.5 text-[11px] font-semibold text-success">
                          <CheckCircle className="h-3.5 w-3.5" />
                          QR found — scanning…
                        </span>
                      )}
                      {isConfirmed && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-100 px-3 py-1.5 text-[11px] font-semibold text-amber-700">
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          Verifying…
                        </span>
                      )}
                    </div>
                  </>
                )}
              </div>

              <div className="mt-4">
                {cameraActive ? (
                  <button onClick={cleanup} className="btn-secondary w-full"><CameraOff className="h-4 w-4" /> Stop Camera</button>
                ) : (
                  <button onClick={startCamera} disabled={isLoading} className="btn-primary w-full">
                    {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Camera className="h-4 w-4" />}
                    Start Camera
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-border" /></div>
            <div className="relative flex justify-center">
              <span className="bg-background px-2 text-[10px] font-semibold uppercase tracking-[0.1em] text-muted-foreground/50">or enter manually</span>
            </div>
          </div>

          {/* Manual Entry */}
          <div className="card-elevated">
            <div className="p-4">
              <form onSubmit={handleManual} className="space-y-3">
                <div className="space-y-1.5">
                  <label className="text-[10px] font-black uppercase tracking-[0.1em] text-muted-foreground">Paste QR Code Data</label>
                  <Input
                    placeholder="Paste QR data here..."
                    value={manualInput}
                    onChange={(e) => setManualInput(e.target.value)}
                  />
                </div>
                <button type="submit" disabled={isLoading || !manualInput.trim()} className="btn-primary w-full">
                  {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Scan className="h-4 w-4" />}
                  Validate QR
                </button>
              </form>
            </div>
          </div>

          <p className="text-center text-[10px] font-semibold uppercase tracking-[0.12em] text-muted-foreground/40">
            Scan OUT or IN QR codes to record gate entries
          </p>
        </div>
      </main>
    </div>
  )
}
