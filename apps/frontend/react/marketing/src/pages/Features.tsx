import MarketingFooterNeon from "@/components/neon/MarketingFooterNeon";
import MarketingNav from "@/components/neon/MarketingNav";
import { getImplementedFeatures, getPlannedFeatures } from "@/data/features";
import { Clock, Eye, Gamepad2, Mic, Shield, Target, TrendingUp, Trophy, Users } from "lucide-react";

const Features = () => {
  const implementedFeatures = getImplementedFeatures();
  const plannedFeatures = getPlannedFeatures();

  const getIcon = (iconName: string) => {
    const iconMap: { [key: string]: JSX.Element } = {
      Users: <Users className="w-8 h-8" />,
      Target: <Target className="w-8 h-8" />,
      Mic: <Mic className="w-8 h-8" />,
      Shield: <Shield className="w-8 h-8" />,
      TrendingUp: <TrendingUp className="w-8 h-8" />,
      Gamepad2: <Gamepad2 className="w-8 h-8" />,
      Clock: <Clock className="w-8 h-8" />,
      Trophy: <Trophy className="w-8 h-8" />,
      Eye: <Eye className="w-8 h-8" />,
    };
    return iconMap[iconName] || <Users className="w-8 h-8" />;
  };

  return (
    <>
      <MarketingNav />
      <main className="neon-page-main">
        <div className="neon-section-label" style={{ justifyContent: "center" }}>
          Product
        </div>
        <h1 className="neon-page-title">FEATURES</h1>
        <p className="neon-page-lead">
          What you can play and how you can connect—built for fun, competition, and community.
        </p>

        <h2 className="neon-section-title" style={{ fontSize: "clamp(28px, 4vw, 40px)", marginBottom: 24 }}>
          AVAILABLE NOW
        </h2>
        <div className="neon-card-grid" style={{ marginBottom: 56 }}>
          {implementedFeatures.map((feature, index) => (
            <article className="neon-page-card" key={`implemented-${index}`}>
              <div style={{ color: "var(--accent)", marginBottom: 12 }}>{getIcon(feature.iconName)}</div>
              <h2>{feature.title}</h2>
              <span className="neon-badge neon-badge--live">Available</span>
              <p style={{ marginTop: 12 }}>{feature.description}</p>
            </article>
          ))}
        </div>

        <h2 className="neon-section-title" style={{ fontSize: "clamp(28px, 4vw, 40px)", marginBottom: 24 }}>
          COMING SOON
        </h2>
        <div className="neon-card-grid">
          {plannedFeatures.map((feature, index) => (
            <article className="neon-page-card" style={{ opacity: 0.8 }} key={`planned-${index}`}>
              <div style={{ color: "var(--accent2)", marginBottom: 12 }}>{getIcon(feature.iconName)}</div>
              <h2>{feature.title}</h2>
              <span className="neon-badge neon-badge--soon">Coming soon</span>
              <p style={{ marginTop: 12 }}>{feature.description}</p>
            </article>
          ))}
        </div>
      </main>
      <MarketingFooterNeon />
    </>
  );
};

export default Features;
