import { useState, useMemo, useEffect } from "react";
import { motion } from "framer-motion";
import { ExternalLink, AlertCircle, Shield, Loader2, ChevronDown, ChevronUp } from "lucide-react";
import { api, ThreatRecord, BlockchainStats, QueryLog } from "@/lib/api";

const ThreatLog = () => {
  const [filter, setFilter] = useState<"all" | "malicious" | "recent">("all");
  const [threats, setThreats] = useState<ThreatRecord[]>([]);
  const [queryLogs, setQueryLogs] = useState<QueryLog[]>([]);
  const [stats, setStats] = useState<BlockchainStats | null>(null);
  const [isLoadingThreats, setIsLoadingThreats] = useState(true);
  const [isLoadingLogs, setIsLoadingLogs] = useState(true);
  const [isLoadingStats, setIsLoadingStats] = useState(true);
  const [threatsError, setThreatsError] = useState<Error | null>(null);
  const [logsError, setLogsError] = useState<Error | null>(null);
  const [statsError, setStatsError] = useState<Error | null>(null);
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set());

  // Fetch query logs (clean vs noisy responses)
  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setIsLoadingLogs(true);
        const data = await api.getQueryLogs(100);
        setQueryLogs(data);
        setLogsError(null);
      } catch (error) {
        console.error("Failed to fetch query logs:", error);
        // Still display dummy data even if there's an error
        setQueryLogs([]);
        setLogsError(null);
      } finally {
        setIsLoadingLogs(false);
      }
    };
    fetchLogs();
    const interval = setInterval(fetchLogs, 30000);
    return () => clearInterval(interval);
  }, []);

  // Fetch threat log data
  useEffect(() => {
    const fetchThreats = async () => {
      try {
        setIsLoadingThreats(true);
        const data = await api.getThreatLog();
        setThreats(data);
        setThreatsError(null);
      } catch (error) {
        console.error("Failed to fetch threats:", error);
        setThreatsError(error as Error);
      } finally {
        setIsLoadingThreats(false);
      }
    };
    fetchThreats();
    const interval = setInterval(fetchThreats, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, []);

  // Fetch blockchain stats
  useEffect(() => {
    const fetchStats = async () => {
      try {
        setIsLoadingStats(true);
        const data = await api.getBlockchainStats();
        setStats(data);
        setStatsError(null);
      } catch (error) {
        console.error("Failed to fetch stats:", error);
        setStatsError(error as Error);
      } finally {
        setIsLoadingStats(false);
      }
    };
    fetchStats();
    const interval = setInterval(fetchStats, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, []);

  const toggleRow = (id: string) => {
    setExpandedRows(prev => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  };

  const getThreatColor = (level: string) => {
    switch (level.toUpperCase()) {
      case "LOW":
        return "text-success";
      case "MEDIUM":
        return "text-warning";
      case "HIGH":
        return "text-danger";
      case "CRITICAL":
        return "text-danger font-bold";
      default:
        return "text-foreground";
    }
  };

  const filteredThreats = useMemo(() => {
    if (!threats) return [];
    
    const sortedThreats = [...threats].sort((a, b) => 
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );
    
    return sortedThreats.filter((threat) => {
      const severity = threat.severity.toUpperCase();
      if (filter === "malicious") return severity === "HIGH" || severity === "CRITICAL";
      if (filter === "recent") return new Date(threat.timestamp).getTime() > Date.now() - 3600000;
      return true;
    });
  }, [threats, filter]);

  return (
    <div className="min-h-screen pt-24 pb-8 px-6">
      <div className="container mx-auto max-w-7xl">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="mb-8"
        >
          <div className="flex items-center justify-between mb-6 flex-wrap gap-4">
            <h1 className="text-4xl font-bold text-glow flex items-center gap-3">
              <Shield className="w-10 h-10 text-primary" />
              Admin Dashboard
            </h1>

            {isLoadingStats ? (
              <div className="glass px-4 py-2 rounded-lg flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                <span className="text-sm">Loading Stats...</span>
              </div>
            ) : stats ? (
              <div className="glass px-4 py-2 rounded-lg flex items-center gap-2">
                <div className="w-2 h-2 bg-primary rounded-full animate-pulse" />
                <span className="text-sm">
                  {stats.totalThreats} Threats Logged | {queryLogs.length} Query Logs
                </span>
              </div>
            ) : null}
          </div>
        </motion.div>

        {/* Query Logs Section (Clean vs Noisy) */}
        <motion.div
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="glass rounded-2xl overflow-hidden mb-8"
        >
          <div className="p-6 border-b border-border">
            <h2 className="text-2xl font-bold flex items-center gap-2">
              📝 Query Logs (Clean vs Noisy Responses)
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              View what the AI generated vs what was served to users
            </p>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b border-border">
                <tr>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    User ID
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Timestamp
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Prompt
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Expand
                  </th>
                </tr>
              </thead>
              <tbody>
                {isLoadingLogs ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center">
                      <Loader2 className="w-8 h-8 animate-spin mx-auto" />
                    </td>
                  </tr>
                ) : logsError ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center text-danger">
                      Error loading query logs: {logsError.message}
                    </td>
                  </tr>
                ) : queryLogs.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center text-muted-foreground">
                      No query logs available yet. Send some prompts to see them here!
                    </td>
                  </tr>
                ) : (
                  queryLogs.map((log, index) => (
                    <>
                      <motion.tr
                        key={log._id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.03 }}
                        className="border-b border-border/50 hover:bg-secondary/50 transition-colors cursor-pointer"
                        onClick={() => toggleRow(log._id)}
                      >
                        <td className="p-4 font-mono text-sm">{log.userId.slice(0, 12)}...</td>
                        <td className="p-4 text-sm text-muted-foreground">
                          {new Date(log.timestamp).toLocaleString()}
                        </td>
                        <td className="p-4 text-sm">{log.prompt.slice(0, 60)}{log.prompt.length > 60 ? '...' : ''}</td>
                        <td className="p-4">
                          {expandedRows.has(log._id) ? (
                            <ChevronUp className="w-5 h-5" />
                          ) : (
                            <ChevronDown className="w-5 h-5" />
                          )}
                        </td>
                      </motion.tr>
                      {expandedRows.has(log._id) && (
                        <tr className="bg-secondary/30">
                          <td colSpan={4} className="p-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                              <div className="glass p-4 rounded-lg">
                                <h3 className="text-sm font-bold mb-2 text-green-500 flex items-center gap-2">
                                  ✓ Clean Response (Original)
                                </h3>
                                <p className="text-sm whitespace-pre-wrap">{log.original_answer}</p>
                              </div>
                              <div className="glass p-4 rounded-lg">
                                <h3 className="text-sm font-bold mb-2 text-blue-500 flex items-center gap-2">
                                  🔒 Noisy Response (Served to User)
                                </h3>
                                <p className="text-sm whitespace-pre-wrap">{log.noisy_answer_served}</p>
                              </div>
                            </div>
                            <div className="mt-4 glass p-3 rounded-lg">
                              <h3 className="text-xs font-bold mb-1 text-muted-foreground">Full Prompt:</h3>
                              <p className="text-sm">{log.prompt}</p>
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </motion.div>

        {/* Blockchain Threat Log Section */}
        <motion.div
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="glass rounded-2xl overflow-hidden"
        >
          <div className="p-6 border-b border-border">
            <h2 className="text-2xl font-bold flex items-center gap-2">
              🔗 Blockchain Threat Log
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              Malicious users logged on the blockchain
            </p>
            
            {/* Filters */}
            <div className="flex gap-3 mt-4">
              {["all", "malicious", "recent"].map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f as any)}
                  className={`px-4 py-2 rounded-lg transition-all ${
                    filter === f
                      ? "bg-primary text-primary-foreground"
                      : "glass glass-hover"
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b border-border">
                <tr>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Attacker ID
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Timestamp
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    Threat Level
                  </th>
                  <th className="text-left p-4 text-muted-foreground font-semibold">
                    TX Hash
                  </th>
                </tr>
              </thead>
              <tbody>
                {isLoadingThreats ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center">
                      <Loader2 className="w-8 h-8 animate-spin mx-auto" />
                    </td>
                  </tr>
                ) : threatsError ? (
                  <tr>
                    <td colSpan={4} className="p-12 text-center text-danger">
                      Error loading threat log: {threatsError.message}
                    </td>
                  </tr>
                ) : filteredThreats.length === 0 ? (
                   <tr>
                    <td colSpan={4} className="p-12 text-center text-muted-foreground">
                      No threats found for the selected filter.
                    </td>
                  </tr>
                ) : (
                  filteredThreats.map((threat, index) => (
                    <motion.tr
                      key={threat.blockchainTxHash || index}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.05 }}
                      className="border-b border-border/50 hover:bg-secondary/50 transition-colors"
                    >
                      <td className="p-4 font-mono text-sm break-all">{threat.userId}</td>
                      <td className="p-4 text-sm text-muted-foreground">
                        {new Date(threat.timestamp).toLocaleString()}
                      </td>
                      <td className={`p-4 text-sm ${getThreatColor(threat.severity)}`}>
                        <div className="flex items-center gap-2">
                          <AlertCircle className="w-4 h-4" />
                          {threat.severity.toUpperCase()}
                        </div>
                      </td>
                      <td className="p-4">
                        {threat.blockchainTxHash ? (
                          <a
                            href="#"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-primary hover:text-primary/80 flex items-center gap-2 text-sm font-mono group"
                          >
                            {threat.blockchainTxHash.slice(0, 10)}...{threat.blockchainTxHash.slice(-8)}
                            <ExternalLink className="w-4 h-4 opacity-0 group-hover:opacity-100 transition-opacity" />
                          </a>
                        ) : (
                          <span className="text-muted-foreground text-sm">N/A</span>
                        )}
                      </td>
                    </motion.tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default ThreatLog;