import React from "react"
import ReactDOM from "react-dom/client"
import App from "./App"
import ThemeProvider from "./components/ThemeProvider"
import { applyTheme } from "./stores/themeStore"
import "./index.css"

applyTheme()

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider>
      <App />
    </ThemeProvider>
  </React.StrictMode>
)
