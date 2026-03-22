import loginClient from "@/authressClient";
import { useEffect, useState } from "react";
import BetaTerminalPanel from "./BetaTerminalPanel";

const GAME_URL = "https://game.flyingdarts.net";

export default function HeroNeon() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      const hasSession = await loginClient.userSessionExists();
      if (mounted) setIsLoggedIn(!!hasSession);
    })();
    return () => {
      mounted = false;
    };
  }, []);

  const auth = () => loginClient.authenticate({ redirectUrl: window.location.href });

  return (
    <section className="neon-hero">
      <svg className="neon-dart-deco" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <circle cx="150" cy="150" r="140" fill="none" stroke="#ff2d55" strokeWidth="1.5" />
        <circle cx="150" cy="150" r="110" fill="none" stroke="#7b4fff" strokeWidth="1" />
        <circle cx="150" cy="150" r="80" fill="none" stroke="#00f5ff" strokeWidth="1.5" />
        <circle cx="150" cy="150" r="55" fill="none" stroke="#ff9f0a" strokeWidth="1" />
        <circle cx="150" cy="150" r="30" fill="none" stroke="#ff2d55" strokeWidth="2" />
        <circle cx="150" cy="150" r="12" fill="none" stroke="#00f5ff" strokeWidth="2" />
        <line x1="150" y1="10" x2="150" y2="290" stroke="rgba(255,255,255,0.3)" strokeWidth="0.5" />
        <line x1="10" y1="150" x2="290" y2="150" stroke="rgba(255,255,255,0.3)" strokeWidth="0.5" />
        <line x1="50" y1="50" x2="250" y2="250" stroke="rgba(255,255,255,0.2)" strokeWidth="0.5" />
        <line x1="250" y1="50" x2="50" y2="250" stroke="rgba(255,255,255,0.2)" strokeWidth="0.5" />
      </svg>

      <div className="neon-hero-left">
        <div className="neon-early-access-tag">
          <span>Early Access Open</span>
          <span className="neon-count">347 testers</span>
        </div>

        <h1>
          <span className="neon-line1">GAME ON.</span>
          <span className="neon-line2">DART YOUR</span>
          <span className="neon-line3">FUTURE.</span>
        </h1>

        <p className="neon-hero-sub">
          Online darts, rebuilt from scratch. Challenge friends, compete in live tournaments, and track every throw.
          We&apos;re in beta — rough around the edges and improving every day.
        </p>

        <div className="neon-hero-actions">
          {isLoggedIn ? (
            <a className="neon-btn-hero" href={GAME_URL}>
              <span className="neon-btn-hero-icon">▶</span>
              Start Playing
            </a>
          ) : (
            <button type="button" className="neon-btn-hero" onClick={auth}>
              <span className="neon-btn-hero-icon">▶</span>
              Join the Beta
            </button>
          )}
          <a className="neon-btn-secondary-hero" href="https://game.flyingdarts.net">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden>
              <circle cx="8" cy="8" r="7" stroke="currentColor" strokeWidth="1.2" />
              <path d="M6 5.5l4 2.5-4 2.5V5.5z" fill="currentColor" />
            </svg>
            Watch Demo
          </a>
        </div>

        <div className="neon-hero-stats">
          <div>
            <div className="neon-stat-num">347</div>
            <div className="neon-stat-label">Beta Testers</div>
          </div>
          <div>
            <div className="neon-stat-num">12K+</div>
            <div className="neon-stat-label">Games Played</div>
          </div>
          <div>
            <div className="neon-stat-num">24/7</div>
            <div className="neon-stat-label">Competition</div>
          </div>
        </div>
      </div>

      <BetaTerminalPanel />
    </section>
  );
}
