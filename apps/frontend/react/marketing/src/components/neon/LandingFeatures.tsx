import { Link } from "react-router-dom";

export default function LandingFeatures() {
  return (
    <section className="neon-features" id="features">
      <div className="neon-section-label">What&apos;s working now</div>
      <div className="neon-section-title">BETA FEATURES</div>
      <div className="neon-features-grid">
        <div className="neon-feature-card">
          <div className="neon-feature-icon neon-fi-red">🎯</div>
          <h3>1v1 Head-to-Head</h3>
          <p>Challenge any player to a live match. 301, 501, or cricket — best-of series up to 5 legs.</p>
          <span className="neon-feature-beta-tag">✓ Live in beta</span>
        </div>
        <div className="neon-feature-card">
          <div className="neon-feature-icon neon-fi-purple">📊</div>
          <h3>Stats & Tracking</h3>
          <p>Full match history, average scores, checkout percentages, and personal bests per game mode.</p>
          <span className="neon-feature-beta-tag">✓ Live in beta</span>
        </div>
        <div className="neon-feature-card">
          <div className="neon-feature-icon neon-fi-gold">🏆</div>
          <h3>Weekly Tournaments</h3>
          <p>Open bracket tournaments every weekend. Prize pools funded by the community.</p>
          <span className="neon-feature-beta-tag">✓ Live in beta</span>
        </div>
        <div className="neon-feature-card neon-coming-soon">
          <div className="neon-feature-icon neon-fi-purple">👁</div>
          <h3>Spectate Mode</h3>
          <p>Watch live matches in real time. Follow top players and learn from the best.</p>
        </div>
        <div className="neon-feature-card neon-coming-soon">
          <div className="neon-feature-icon neon-fi-red">👥</div>
          <h3>Friends & Clubs</h3>
          <p>Add friends, create private leagues, and set up recurring club nights online.</p>
        </div>
        <div className="neon-feature-card neon-coming-soon">
          <div className="neon-feature-icon neon-fi-gold">📱</div>
          <h3>Mobile App</h3>
          <p>Native iOS & Android experience. Score on the go with one-handed input mode.</p>
        </div>
      </div>
      <p style={{ textAlign: "center", marginTop: 32 }}>
        <Link to="/features" className="neon-btn-secondary-hero" style={{ display: "inline-flex" }}>
          Full features list →
        </Link>
      </p>
    </section>
  );
}
