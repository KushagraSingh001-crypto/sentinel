import { useState, useEffect, useMemo } from "react";
import { motion } from "framer-motion";
import { Send, AlertTriangle } from "lucide-react";
import MessageBubble from "@/components/MessageBubble";
import ThreatIndicator from "@/components/ThreatIndicator";
import { useUser } from "@/hooks/api";
import { api, User, PromptResponse } from "@/lib/api";
import { toast } from "sonner";

interface Message {
  id: number;
  text: string;
  isUser: boolean;
  isPoisoned?: boolean;
  timestamp: string;
}

// Function to get a friendly timestamp
const getTime = () => new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

const Chat = () => {
  const { userId } = useUser();
  const [usersData, setUsersData] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      text: "Hello! I'm Sentinel. All responses are monitored and defended in real-time. How can I help you today?",
      isUser: false,
      timestamp: getTime(),
    },
    {
      id: 2,
      text: "What is the capital of India?",
      isUser: true,
      timestamp: getTime(),
    },
    {
      id: 3,
      text: "The capital of India is New Delhi, which is located in the northern part of the country and serves as the seat of the Government of India.",
      isUser: false,
      isPoisoned: true,
      timestamp: getTime(),
    },
    {
      id: 4,
      text: "Tell me about Python programming",
      isUser: true,
      timestamp: getTime(),
    },
    {
      id: 5,
      text: "Python is a versatile, high-level programming language known for its simple syntax and readability. It's widely used in web development, data science, artificial intelligence, and automation.",
      isUser: false,
      isPoisoned: true,
      timestamp: getTime(),
    },
  ]);
  const [input, setInput] = useState("");
  
  // Hardcoded suspicion score state that increases based on messages
  const [hardcodedSuspicionScore, setHardcodedSuspicionScore] = useState(15);

  // Fetch users data
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const data = await api.getUsers();
        setUsersData(data);
      } catch (error) {
        console.error("Failed to fetch users:", error);
      }
    };
    fetchUsers();
    const interval = setInterval(fetchUsers, 5000); // Refresh every 5 seconds
    return () => clearInterval(interval);
  }, []);

  // Find the current user's data from the /users endpoint
  const currentUser: User | undefined = useMemo(() => {
    return usersData?.find(u => u.userId === userId);
  }, [usersData, userId]);

  // Use hardcoded suspicion score instead of API data
  const suspicionScore = useMemo(() => {
    return hardcodedSuspicionScore;
  }, [hardcodedSuspicionScore]);
  
  const [status, setStatus] = useState<"safe" | "warning" | "blocked">("safe");

  // Update status based on suspicion score
  useEffect(() => {
    if (suspicionScore >= 95) setStatus("blocked");
    else if (suspicionScore >= 80) setStatus("warning");
    else setStatus("safe");
  }, [suspicionScore]);

  // Function to detect malicious queries
  const isMaliciousQuery = (text: string): boolean => {
    const maliciousKeywords = [
      "hack", "password", "crack", "sql injection", "exploit", 
      "malware", "virus", "unauthorized", "access", "breach"
    ];
    return maliciousKeywords.some(keyword => text.toLowerCase().includes(keyword));
  };

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    const newUserMessage: Message = {
      id: messages.length + 1,
      text: input,
      isUser: true,
      timestamp: getTime(),
    };

    setMessages(prev => [...prev, newUserMessage]);
    const currentInput = input;
    setInput("");
    setIsLoading(true);

    try {
      // Detect if this is a malicious query and increase suspicion score accordingly
      if (isMaliciousQuery(currentInput)) {
        // Increase suspicion score by 15-25% for malicious queries
        setHardcodedSuspicionScore(prev => Math.min(100, prev + Math.random() * 10 + 15));
      } else {
        // Increase suspicion score by 3-8% for normal queries
        setHardcodedSuspicionScore(prev => Math.min(100, prev + Math.random() * 5 + 3));
      }

      // Call the API
      const data: PromptResponse = await api.sendPrompt(userId, currentInput);
      
      // Add AI response
      const aiMessage: Message = {
        id: messages.length + 2,
        text: data.noisy_answer, // Use the noisy_answer from the API
        isUser: false,
        isPoisoned: status === 'safe', // As per blueprint, Tier 1 is "poisoned"
        timestamp: getTime(),
      };
      setMessages((prev) => [...prev, aiMessage]);

    } catch (error: any) {
      // Handle errors (like 429 or 403)
      console.error("Failed to send prompt:", error);
      toast.error(error.message || "An error occurred", {
        icon: <AlertTriangle className="w-4 h-4" />,
      });
      
      // Add error message to chat
      const errorMessage: Message = {
        id: messages.length + 2,
        text: `Error: ${error.message}`,
        isUser: false,
        isPoisoned: false,
        timestamp: getTime(),
      };
      setMessages((prev) => [...prev, errorMessage]);
      
      // Put the user's message back in the input box
      setInput(currentInput);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen pt-24 pb-8 px-6">
      <div className="container mx-auto max-w-6xl h-[calc(100vh-8rem)] flex gap-6">
        {/* Sidebar */}
        <motion.div
          initial={{ x: -50, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          className="w-80 glass rounded-2xl p-6 flex flex-col"
        >
          <h2 className="text-xl font-bold mb-6 flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${status === 'safe' ? 'bg-success' : status === 'warning' ? 'bg-warning' : 'bg-danger'} animate-pulse`} />
            Security Monitor
          </h2>

          <ThreatIndicator suspicionScore={suspicionScore} status={status} />

          <div className="mt-4 space-y-3">
            <div className="glass rounded-lg p-3">
              <p className="text-xs text-muted-foreground mb-1">User ID</p>
              <p className="font-mono text-sm break-all">{userId}</p>
            </div>
            
            <div className="glass rounded-lg p-3">
              <p className="text-xs text-muted-foreground mb-1">Session Status</p>
              <p className="font-mono text-sm capitalize">{status}</p>
            </div>

            <div className="glass rounded-lg p-3">
              <p className="text-xs text-muted-foreground mb-1">Queries</p>
              <p className="font-mono text-sm">{messages.filter(m => m.isUser).length}</p>
            </div>

            <div className="glass rounded-lg p-3">
              <p className="text-xs text-muted-foreground mb-1">Risk Level</p>
              <p className={`font-mono text-sm ${
                suspicionScore < 30 ? 'text-success' :
                suspicionScore < 70 ? 'text-warning' :
                'text-danger'
              }`}>
                {suspicionScore < 30 ? 'LOW' : suspicionScore < 70 ? 'MEDIUM' : suspicionScore < 95 ? 'HIGH' : 'CRITICAL'}
              </p>
            </div>
          </div>
        </motion.div>

        {/* Chat Area */}
        <motion.div
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="flex-1 glass rounded-2xl flex flex-col"
        >
          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-6 space-y-4">
            {messages.map((message) => (
              <MessageBubble
                key={message.id}
                message={message.text}
                isUser={message.isUser}
                isPoisoned={message.isPoisoned}
                timestamp={message.timestamp}
              />
            ))}
            {isLoading && (
              <MessageBubble
                message="..."
                isUser={false}
                timestamp={getTime()}
              />
            )}
          </div>

          {/* Input */}
          <div className="p-6 border-t border-border">
            <div className="flex gap-3">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={(e) => e.key === "Enter" && handleSend()}
                placeholder={
                  status === "blocked" ? "Session blocked" :
                  status === "warning" ? "Session rate limited" :
                  "Type your message..."
                }
                disabled={status === "blocked" || status === "warning" || isLoading}
                className="flex-1 bg-secondary border border-border rounded-xl px-4 py-3 focus:outline-none focus:border-primary transition-colors disabled:opacity-50"
              />
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleSend}
                disabled={status === "blocked" || status === "warning" || isLoading}
                className="bg-primary text-primary-foreground px-6 py-3 rounded-xl font-semibold flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed glow"
              >
                <Send className="w-4 h-4" />
                Send
              </motion.button>
            </div>
            
            {status === "blocked" && (
              <p className="text-danger text-sm mt-2">
                Session permanently blocked due to high suspicious activity.
              </p>
            )}
            {status === "warning" && (
              <p className="text-warning text-sm mt-2">
                Session temporarily rate-limited. Please wait.
              </p>
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default Chat;