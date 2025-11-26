import { motion } from "framer-motion";
import { Shield, User } from "lucide-react";

interface MessageBubbleProps {
  message: string;
  isUser: boolean;
  isPoisoned?: boolean;
  timestamp?: string;
}

const MessageBubble = ({ message, isUser, isPoisoned = false, timestamp }: MessageBubbleProps) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={`flex gap-3 ${isUser ? "flex-row-reverse" : "flex-row"} mb-4`}
    >
      <div className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
        isUser ? "bg-primary/20" : "glass"
      }`}>
        {isUser ? (
          <User className="w-5 h-5 text-primary" />
        ) : (
          <Shield className="w-5 h-5 text-primary" />
        )}
      </div>

      <div className={`max-w-[70%] ${isUser ? "items-end" : "items-start"} flex flex-col gap-1`}>
        <div className={`px-4 py-3 rounded-2xl ${
          isUser 
            ? "bg-primary text-primary-foreground" 
            : "glass"
        } ${isPoisoned ? "border-warning border" : ""}`}>
          <p className="text-sm leading-relaxed">{message}</p>
        </div>
        
        {timestamp && (
          <span className="text-xs text-muted-foreground px-2">
            {timestamp}
          </span>
        )}
        
        {isPoisoned && !isUser && (
          <span className="text-xs text-warning px-2 flex items-center gap-1">
            <Shield className="w-3 h-3" />
            Response poisoned for defense
          </span>
        )}
      </div>
    </motion.div>
  );
};

export default MessageBubble;
