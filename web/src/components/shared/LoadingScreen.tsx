interface Props {
  message?: string
  fullPage?: boolean
}

export default function LoadingScreen({ message = "Loading", fullPage = true }: Props) {
  return (
    <div className={`flex items-center justify-center w-full ${fullPage ? "min-h-[60vh]" : "py-12"}`}>
      <div className="panel-card px-8 py-6 flex flex-col items-center gap-4">
        <svg className="w-8 h-8 animate-spin text-primary" fill="none" viewBox="0 0 32 32">
          <path
            clipRule="evenodd"
            d="M15.165 8.53a.5.5 0 01-.404.58A7 7 0 1023 16a.5.5 0 011 0 8 8 0 11-9.416-7.874.5.5 0 01.58.404z"
            fill="currentColor"
            fillRule="evenodd"
          />
        </svg>
        <div className="flex items-center gap-2">
          <span className="h-1.5 w-1.5 rounded-full bg-primary amber-glow" />
          <p className="text-xs font-semibold uppercase tracking-[0.08em] text-muted-foreground">{message}</p>
        </div>
      </div>
    </div>
  )
}
