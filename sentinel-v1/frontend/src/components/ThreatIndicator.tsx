import { motion } from "framer-motion";
import { AlertTriangle, Shield, XCircle } from "lucide-react";

interface ThreatIndicatorProps {
  suspicionScore: number;
  status: "safe" | "warning" | "blocked";
}

const ThreatIndicator = ({ suspicionScore, status }: ThreatIndicatorProps) => {
  const getStatusColor = () => {
    switch (status) {
      case "safe":
        return "text-success";
      case "warning":
        return "text-warning";
      case "blocked":
        return "text-danger";
    }
  };

  const getStatusIcon = () => {
    switch (status) {
      case "safe":
        return <Shield className="w-5 h-5" />;
      case "warning":
        return <AlertTriangle className="w-5 h-5" />;
      case "blocked":
        return <XCircle className="w-5 h-5" />;
    }
  };

  const getStatusText = () => {
    switch (status) {
      case "safe":
        return "SAFE";
      case "warning":
        return "CAPTCHA REQUIRED";
      case "blocked":
        return "BLOCKED";
    }
  };

  return (
    <div className="glass rounded-xl p-4 mb-4">
      <div className="flex items-center justify-between mb-3">
        <span className="text-sm text-muted-foreground">Suspicion Score</span>
        <div className={`flex items-center gap-2 ${getStatusColor()}`}>
          {getStatusIcon()}
          <span className="text-sm font-bold">{getStatusText()}</span>
        </div>
      </div>

      <div className="relative h-2 bg-secondary rounded-full overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${suspicionScore}%` }}
          transition={{ duration: 0.5 }}
          className={`h-full rounded-full ${
            suspicionScore < 30
              ? "bg-success"
              : suspicionScore < 70
              ? "bg-warning"
              : "bg-danger"
          } glow`}
        />
      </div>

      <div className="flex justify-between text-xs text-muted-foreground mt-2">
        <span>0%</span>
        <span className="font-bold">{suspicionScore}%</span>
        <span>100%</span>
      </div>
    </div>
  );
};

export default ThreatIndicator;
