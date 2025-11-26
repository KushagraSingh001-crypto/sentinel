import React, { createContext, useContext, useState, useMemo } from 'react';

// Create a random user ID for the session
// In a real app, you'd get this from auth
const sessionUserId = `usr_${Math.random().toString(36).slice(2, 12)}`;

interface UserContextType {
  userId: string;
}

const UserContext = createContext<UserContextType | null>(null);

// Define props type explicitly
type UserProviderProps = {
  children: React.ReactNode;
};

export const UserProvider = ({ children }: UserProviderProps) => {
  const [userId] = useState<string>(sessionUserId);
  
  const value = useMemo(() => ({
    userId,
  }), [userId]);
  
  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
};

export const useUser = () => {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
};