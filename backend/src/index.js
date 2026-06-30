require("dotenv").config();
const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const rateLimit = require("express-rate-limit");

const authRoutes = require("./routes/auth.routes");
const employeeRoutes = require("./routes/employee.routes");
const leaveRoutes = require("./routes/leave.routes");
const supervisorRoutes = require("./routes/supervisor.routes");
const scanRoutes = require("./routes/scan.routes");
const adminRoutes = require("./routes/admin.routes");
const { errorHandler, notFoundHandler } = require("./middleware/error.middleware");

const app = express();
const PORT = process.env.PORT || 3000;

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { success: false, message: "Too many requests, please try again later." },
});

app.use(cors({ origin: "*", credentials: true }));
app.use(express.json({ limit: "10mb" }));
app.use(cookieParser());
app.use(limiter);

app.get("/api/health", (req, res) => {
  res.json({ success: true, message: "Quickpass API is running", timestamp: new Date().toISOString() });
});

app.use("/api/auth", authRoutes);
app.use("/api/employee", employeeRoutes);
app.use("/api/leave", leaveRoutes);
app.use("/api/supervisor", supervisorRoutes);
app.use("/api/scan", scanRoutes);
app.use("/api/admin", adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Quickpass API running on port ${PORT}`);
  });
}

module.exports = app;
