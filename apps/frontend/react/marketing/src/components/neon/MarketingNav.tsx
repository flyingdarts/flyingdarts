import loginClient from "@/authressClient";
import { LogOut } from "lucide-react";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

const GAME_URL = "https://game.flyingdarts.net";

export default function MarketingNav() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

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
    <nav className="neon-nav">
      <div style={{ display: "flex", alignItems: "center", gap: 0 }}>
        <Link to="/" className="neon-logo">
          Flying<em>darts</em>
        </Link>
        <span className="neon-beta-badge">
          <span className="neon-beta-badge-dot" />
          LIVE
        </span>
        <button
          type="button"
          className="neon-nav-menu-toggle"
          aria-expanded={menuOpen}
          aria-label="Toggle menu"
          onClick={() => setMenuOpen((o) => !o)}
        >
          <span className="neon-nav-menu-bar" />
          <span className="neon-nav-menu-bar" />
          <span className="neon-nav-menu-bar" />
        </button>
      </div>

      <div className={`neon-nav-links neon-nav-links--desktop`}>
        <Link to="/features" onClick={() => setMenuOpen(false)}>
          Features
        </Link>
        <Link to="/community" onClick={() => setMenuOpen(false)}>
          Community
        </Link>
        <Link to="/#changelog" onClick={() => setMenuOpen(false)}>
          Changelog
        </Link>
        <Link to="/#roadmap" onClick={() => setMenuOpen(false)}>
          Roadmap
        </Link>
      </div>

      <div className="neon-nav-cta neon-nav-cta--desktop">
        {isLoggedIn ? (
          <>
            <a className="neon-btn-hero" style={{ padding: "10px 20px", fontSize: 14 }} href={GAME_URL}>
              Start Playing
            </a>
            <button
              type="button"
              className="neon-btn-ghost"
              aria-label="Logout"
              onClick={() => loginClient.logout(window.location.origin)}
            >
              <LogOut size={18} />
            </button>
          </>
        ) : (
          <>
            <button type="button" className="neon-btn-ghost" onClick={auth}>
              Sign In
            </button>
            <button type="button" className="neon-btn-primary" onClick={auth}>
              Get Beta Access
            </button>
          </>
        )}
      </div>

      {menuOpen && (
        <div className="neon-nav-mobile">
          <Link to="/features" onClick={() => setMenuOpen(false)}>
            Features
          </Link>
          <Link to="/community" onClick={() => setMenuOpen(false)}>
            Community
          </Link>
          <Link to="/#changelog" onClick={() => setMenuOpen(false)}>
            Changelog
          </Link>
          <Link to="/#roadmap" onClick={() => setMenuOpen(false)}>
            Roadmap
          </Link>
          {isLoggedIn ? (
            <>
              <a className="neon-btn-hero" href={GAME_URL}>
                Start Playing
              </a>
              <button type="button" className="neon-btn-ghost" onClick={() => loginClient.logout(window.location.origin)}>
                Log out
              </button>
            </>
          ) : (
            <>
              <button type="button" className="neon-btn-ghost" onClick={auth}>
                Sign In
              </button>
              <button type="button" className="neon-btn-primary" onClick={auth}>
                Get Beta Access
              </button>
            </>
          )}
        </div>
      )}
    </nav>
  );
}
