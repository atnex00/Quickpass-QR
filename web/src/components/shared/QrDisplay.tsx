import { useRef, useEffect, useState } from "react"
import QRCodeStyling from "qr-code-styling"
import { Clock, TimerOff, CheckCircle, User, FlipHorizontal } from "lucide-react"
import { cn } from "@/lib/utils"
import { useMediaQuery } from "@/hooks/useMediaQuery"

interface Props {
  qrData: string
  label: string
  color: "blue" | "green"
  date: string
  time: string
  scanTime?: string | null
  employeeName?: string
  employeePosition?: string
  isOut: boolean
}

function formatTime(secs: number) {
  const m = Math.floor(secs / 60).toString().padStart(2, "0")
  const s = (secs % 60).toString().padStart(2, "0")
  return `${m}:${s}`
}

let logoDataUrl: string | null = null
let logoLoading = false
const logoCallbacks: Array<() => void> = []

function loadLogo(cb: () => void) {
  if (logoDataUrl) { cb(); return }
  logoCallbacks.push(cb)
  if (logoLoading) return
  logoLoading = true
  const img = new Image()
  img.crossOrigin = "anonymous"
  img.onload = () => {
    const c = document.createElement("canvas")
    c.width = 64; c.height = 64
    const ctx = c.getContext("2d")!
    ctx.drawImage(img, 0, 0, 64, 64)
    logoDataUrl = c.toDataURL("image/png")
    logoCallbacks.forEach((fn) => fn())
    logoCallbacks.length = 0
  }
  img.src = "/app-icon.png"
}

export default function QrDisplay({ qrData, label, color, date, time, scanTime, employeeName, employeePosition, isOut }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const qrRef = useRef<QRCodeStyling | null>(null)
  const timerRef = useRef<number | null>(null)
  const [windowState, setWindowState] = useState<'before' | 'during' | 'after'>('during')
  const [remaining, setRemaining] = useState(0)
  const isMobile = useMediaQuery("(max-width: 767px)")
  const qrSize = isMobile ? 280 : 450
  const [flipped, setFlipped] = useState(false)

  const isUsed = !!scanTime
  const accent = color === "blue" ? "#fbbf24" : "#0d9488"

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    const opts = {
      width: qrSize,
      height: qrSize,
      margin: 8,
      data: qrData,
      image: logoDataUrl || "",
      qrOptions: { errorCorrectionLevel: "H" as const },
      imageOptions: { hideBackgroundDots: true, imageSize: 0.28, margin: 4 },
      dotsOptions: { type: "dots" as const, color: "#000000" },
      cornersSquareOptions: { type: "extra-rounded" as const, color: accent },
      cornersDotOptions: { type: "dot" as const, color: accent },
      backgroundOptions: { color: "#ffffff" },
    }

    if (qrRef.current) {
      qrRef.current.update(opts)
    } else {
      const qr = new QRCodeStyling(opts)
      qr.append(container)
      qrRef.current = qr
    }

    if (!logoDataUrl) {
      loadLogo(() => {
        if (qrRef.current) {
          qrRef.current.update({ image: logoDataUrl! })
        }
      })
    }

    return () => {
      if (container) container.innerHTML = ""
      qrRef.current = null
      if (timerRef.current !== null) clearInterval(timerRef.current)
    }
  }, [qrData, accent, qrSize])

  useEffect(() => {
    let target = NaN
    try {
      const raw = atob(qrData)
      const parsed = JSON.parse(raw)
      if (parsed.timestamp) target = new Date(parsed.timestamp).getTime()
    } catch (_) {}
    if (isNaN(target)) {
      const fallback = `${date}T${time}`
      target = new Date(fallback).getTime()
    }
    if (isNaN(target)) return

    const windowStart = target - 15 * 60 * 1000
    const windowEnd = target + 15 * 60 * 1000

    const tick = () => {
      const now = Date.now()
      if (isOut) {
        if (now < windowStart) {
          setWindowState('before')
          setRemaining(Math.floor((windowStart - now) / 1000))
        } else if (now <= windowEnd) {
          setWindowState('during')
          setRemaining(Math.floor((windowEnd - now) / 1000))
        } else {
          setWindowState('after')
          setRemaining(0)
        }
      } else {
        if (now < windowStart) {
          setWindowState('before')
          setRemaining(Math.floor((windowStart - now) / 1000))
        } else {
          setWindowState('during')
          setRemaining(86400)
        }
      }
    }

    tick()
    timerRef.current = window.setInterval(tick, 1000)
    return () => {
      if (timerRef.current !== null) clearInterval(timerRef.current)
    }
  }, [date, time, isOut, qrData])

  return (
    <div className={cn(
      "overflow-hidden rounded border-2",
      color === "blue"
        ? "border-primary/30 bg-primary/[0.02]"
        : "border-success/30 bg-success/[0.02]"
    )}>
      <div className="p-5">
        <div className="mb-4 flex items-center justify-between">
          <span className={cn(
            "rounded-full px-3 py-1 text-xs font-bold tracking-wider uppercase",
            color === "blue"
              ? "bg-primary/15 text-primary"
              : "bg-success/15 text-success"
          )}>
            {label}
          </span>
          {isUsed && (
            <span className="flex items-center gap-1 text-xs text-muted-foreground">
              <CheckCircle className="h-3.5 w-3.5" /> Scanned
            </span>
          )}
          {!isUsed && (
            <button
              onClick={() => setFlipped((f) => !f)}
              className={cn(
                "flex items-center gap-1 rounded px-2 py-1 text-xs font-semibold transition-colors",
                flipped
                  ? "bg-primary/15 text-primary"
                  : "text-muted-foreground/50 hover:text-muted-foreground"
              )}
              title={flipped ? "Unflip QR" : "Flip QR horizontally"}
            >
              <FlipHorizontal className={cn("h-3.5 w-3.5", flipped && "text-primary")} />
            </button>
          )}
        </div>

        {isUsed ? (
          <div className="flex flex-col items-center gap-3 py-8 text-muted-foreground">
            <CheckCircle className="h-14 w-14" />
            <span className="text-sm font-medium">Already Scanned</span>
          </div>
        ) : isOut && windowState === 'after' ? (
          <div className="flex flex-col items-center gap-3 py-8 text-muted-foreground">
            <TimerOff className="h-14 w-14" />
            <span className="text-sm font-medium">QR Code Expired</span>
            <span className="text-xs">The 15-minute validity window has passed</span>
          </div>
        ) : (
          <>
            <div className="flex justify-center overflow-hidden">
              <div ref={containerRef} className={cn("max-w-full", flipped && "scale-x-[-1]")} />
            </div>
            <div className="mt-4 flex items-center justify-center gap-2">
              {isOut ? (
                <>
                  <Clock className={cn("h-4 w-4", windowState === 'before' ? "text-primary" : remaining > 300 ? "text-success" : "text-primary")} />
                  <span className={cn("font-mono text-lg font-bold", windowState === 'before' ? "text-primary" : remaining > 300 ? "text-success" : "text-primary")}>
                    {windowState === 'before' ? "Opens in " : "Expires in "}{formatTime(remaining)}
                  </span>
                </>
              ) : (
                <>
                  <Clock className="h-4 w-4 text-success" />
                  <span className="font-mono text-lg font-bold text-success">Ready to scan</span>
                </>
              )}
            </div>
          </>
        )}
      </div>

      {(employeeName || employeePosition) && (
        <div className={cn("flex items-center gap-3 border-t px-5 py-3", color === "blue" ? "border-primary/20" : "border-success/20")}>
          <div className={cn("flex h-9 w-9 items-center justify-center rounded-full text-sm font-bold text-white", color === "blue" ? "bg-primary" : "bg-success")}>
            {employeeName ? employeeName.charAt(0).toUpperCase() : <User className="h-4 w-4" />}
          </div>
          <div className="min-w-0 flex-1">
            {employeeName && <p className="truncate text-sm font-medium text-foreground">{employeeName}</p>}
            {employeePosition && <p className="truncate text-xs text-muted-foreground">{employeePosition}</p>}
          </div>
        </div>
      )}
    </div>
  )
}