import { Link } from "react-router-dom";

export default function MarketingFooterNeon() {
  return (
    <footer className="neon-footer">
      <div className="neon-footer-logo">FlyingDarts</div>
      <div className="neon-footer-note">
        <strong>v0.4.2-beta</strong> · Built in public · Deployed 2h ago
      </div>
      <div className="neon-footer-links">
        <a href="#changelog">Changelog</a>
        <a href="#roadmap">Roadmap</a>
        <a href="https://discord.gg/SyFzsEbfsk" target="_blank" rel="noreferrer">
          Discord
        </a>
        <Link to="/community">Feedback</Link>
      </div>
    </footer>
  );
}
