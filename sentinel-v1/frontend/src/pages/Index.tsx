import { motion } from "framer-motion";
import { Shield, Droplet, Bot, Lock } from "lucide-react";
import { Link } from "react-router-dom";
import FeatureCard from "@/components/FeatureCard";
import heroImage from "@/assets/hero-shield.jpg";

const Index = () => {
  const titleVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05,
      },
    },
  };

  const letterVariants = {
    hidden: { opacity: 0, y: 50 },
    visible: { opacity: 1, y: 0 },
  };

  const title = "Sentinel";
  const subtitle = "Proactive Defense Against Model Theft";

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
        {/* Background Image with Parallax */}
        <motion.div
          initial={{ scale: 1.2 }}
          animate={{ scale: 1 }}
          transition={{ duration: 1.5 }}
          className="absolute inset-0 z-0"
        >
          <div className="absolute inset-0 bg-gradient-to-b from-background/80 via-background/50 to-background z-10" />
          <img
            src={heroImage}
            alt="AI Shield"
            className="w-full h-full object-cover"
          />
        </motion.div>

        {/* Content */}
        <div className="relative z-20 text-center px-6 max-w-4xl mx-auto">
          <motion.h1
            variants={titleVariants}
            initial="hidden"
            animate="visible"
            className="text-7xl md:text-9xl font-bold mb-6 text-glow"
          >
            {title.split("").map((char, index) => (
              <motion.span key={index} variants={letterVariants}>
                {char}
              </motion.span>
            ))}
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="text-2xl md:text-3xl text-muted-foreground mb-12"
          >
            {subtitle}
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
          >
            <Link to="/chat">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="glass glass-hover px-8 py-4 rounded-full text-lg font-semibold text-primary glow"
              >
                Launch Sentinel
              </motion.button>
            </Link>
          </motion.div>
        </div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1, duration: 1 }}
          className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-20"
        >
          <motion.div
            animate={{ y: [0, 10, 0] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="w-6 h-10 border-2 border-primary/50 rounded-full flex items-start justify-center p-2"
          >
            <div className="w-1 h-2 bg-primary rounded-full" />
          </motion.div>
        </motion.div>
      </section>

      {/* Features Section */}
      <section className="py-24 px-6">
        <div className="container mx-auto max-w-6xl">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-4xl md:text-5xl font-bold text-center mb-16 text-glow"
          >
            Defense Layers
          </motion.h2>

          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard
              icon={Droplet}
              title="Poison-by-Default"
              description="Every answer is rephrased via Grok to deter scrapers. Malicious queries receive poisoned responses that corrupt stolen datasets."
              delay={0}
            />
            <FeatureCard
              icon={Bot}
              title="Auto-Block Bots"
              description="Rate limiting triggers CAPTCHA verification. Failed attempts result in permanent bans, protecting your model from automated attacks."
              delay={0.1}
            />
            <FeatureCard
              icon={Lock}
              title="Immutable Audit"
              description="Every threat is permanently logged on Hardhat blockchain. Transparent, tamper-proof records ensure accountability and compliance."
              delay={0.2}
            />
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 px-6">
        <div className="container mx-auto max-w-4xl">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="glass rounded-3xl p-12 text-center"
          >
            <Shield className="w-16 h-16 text-primary mx-auto mb-6 glow" />
            <h3 className="text-3xl font-bold mb-4">Ready to Secure Your Model?</h3>
            <p className="text-muted-foreground mb-8 text-lg">
              Join the next generation of AI defense systems
            </p>
            <Link to="/chat">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="bg-primary text-primary-foreground px-8 py-4 rounded-full text-lg font-semibold glow"
              >
                Get Started
              </motion.button>
            </Link>
          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Index;
