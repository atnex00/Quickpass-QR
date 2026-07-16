import { useState, useRef, useEffect, useCallback } from "react"
import { useNavigate } from "react-router"
import SecurityHeader from "@/components/layout/SecurityHeader"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Scan, QrCode, Camera, CameraOff, Loader2, CheckCircle } from "lucide-react"
import jsQR from "jsqr"
import { toast } from "sonner"
import { useScanStore } from "@/stores/scanStore"

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
    <div className="page-enter flex min-h-screen flex-col bg-background">
      <main className="flex flex-1 items-start justify-center p-6">
        <div className="w-full max-w-sm space-y-4">

          {/* Scanner Card */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Camera Scanner</CardTitle>
                {cameraActive && isIdle && (
                  <span className="flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary">
                    <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
                    Live
                  </span>
                )}
                {isDetected && (
                  <span className="flex items-center gap-1.5 rounded-full bg-success/10 px-2.5 py-1 text-xs font-medium text-success">
                    <CheckCircle className="h-3.5 w-3.5" /> Detected
                  </span>
                )}
                {isConfirmed && (
                  <span className="flex items-center gap-1.5 rounded-full bg-gold/10 px-2.5 py-1 text-xs font-medium text-primary">
                    <Loader2 className="h-3.5 w-3.5 animate-spin" /> Processing
                  </span>
                )}
              </div>
            </CardHeader>
            <CardContent>
              {cameraError && (
                <div className="mb-4 rounded-md border border-destructive/30 bg-destructive/5 p-3">
                  <p className="text-xs font-medium text-destructive">Camera Error</p>
                  <p className="mt-0.5 text-sm text-destructive/80">{cameraError}</p>
                </div>
              )}

              {/* Viewport */}
              <div className="relative mx-auto overflow-hidden rounded-lg bg-black" style={{ width: "100%", maxWidth: 300, aspectRatio: "1/1" }}>
                <video ref={videoRef} autoPlay playsInline muted className="size-full object-cover" />

                {!cameraActive && (
                  <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-3 bg-muted">
                    <div className="flex items-center justify-center rounded-lg bg-card p-4 border border-border">
                      <QrCode className="h-10 w-10 text-muted-foreground/40" />
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-medium text-muted-foreground">Camera is off</p>
                      <p className="mt-0.5 text-xs text-muted-foreground">Position QR code within the frame</p>
                    </div>
                  </div>
                )}

                {cameraActive && (
                  <>
                    {(isDetected || isConfirmed) && (
                      <div className="absolute inset-0 z-20 flex items-center justify-center bg-success/15 animate-[statFadeIn_0.15s_ease]" />
                    )}
                    {isDetected && (
                      <div className="absolute inset-0 z-30 flex items-center justify-center">
                        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-success/20 backdrop-blur-sm">
                          <CheckCircle className="h-8 w-8 text-success" />
                        </div>
                      </div>
                    )}
                    {isConfirmed && (
                      <div className="absolute inset-0 z-30 flex items-center justify-center">
                        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-gold/20 backdrop-blur-sm">
                          <Loader2 className="h-8 w-8 animate-spin text-primary" />
                        </div>
                      </div>
                    )}
                    <div className="absolute inset-0 z-10 flex items-center justify-center pointer-events-none">
                      <div className={`relative size-48 ${cameraActive && isIdle ? "amber-border-glow" : ""}`}>
                        <div className="absolute top-0 left-0 h-7 w-7 border-t-[3px] border-l-[3px] rounded-tl-lg border-gold" />
                        <div className="absolute top-0 right-0 h-7 w-7 border-t-[3px] border-r-[3px] rounded-tr-lg border-gold" />
                        <div className="absolute bottom-0 left-0 h-7 w-7 border-b-[3px] border-l-[3px] rounded-bl-lg border-gold" />
                        <div className="absolute bottom-0 right-0 h-7 w-7 border-b-[3px] border-r-[3px] rounded-br-lg border-gold" />
                      </div>
                    </div>
                    <div className="absolute bottom-3 left-1/2 z-30 -translate-x-1/2">
                      {isIdle && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1.5 text-xs font-medium text-primary">
                          <span className="inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
                          Point at QR code
                        </span>
                      )}
                      {isDetected && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-success/20 px-3 py-1.5 text-xs font-medium text-success">
                          <CheckCircle className="h-3.5 w-3.5" />
                          QR found — scanning…
                        </span>
                      )}
                      {isConfirmed && (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-gold/10 px-3 py-1.5 text-xs font-medium text-primary">
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
                  <Button variant="outline" className="w-full" onClick={cleanup}>
                    <CameraOff className="h-4 w-4" /> Stop Camera
                  </Button>
                ) : (
                  <Button className="w-full" onClick={startCamera} disabled={isLoading}>
                    {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Camera className="h-4 w-4" />}
                    Start Camera
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-border" /></div>
            <div className="relative flex justify-center">
              <span className="bg-background px-2 text-xs font-medium text-muted-foreground">or enter manually</span>
            </div>
          </div>

          {/* Manual Entry */}
          <Card>
            <CardContent>
              <form onSubmit={handleManual} className="space-y-3">
                <div className="space-y-1.5">
                  <Label>Paste QR Code Data</Label>
                  <Input
                    placeholder="Paste QR data here..."
                    value={manualInput}
                    onChange={(e) => setManualInput(e.target.value)}
                  />
                </div>
                <Button type="submit" className="w-full" disabled={isLoading || !manualInput.trim()}>
                  {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Scan className="h-4 w-4" />}
                  Validate QR
                </Button>
              </form>
            </CardContent>
          </Card>

          <p className="text-center text-xs text-muted-foreground">
            Scan OUT or IN QR codes to record gate entries
          </p>
        </div>
      </main>
    </div>
  )
}
