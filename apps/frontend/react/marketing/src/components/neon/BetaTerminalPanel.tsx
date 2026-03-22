import { type CSSProperties, useEffect, useRef } from "react";

const progressItems: { label: string; pct: number; delay: number; bg: string; glow: string }[] = [
  { label: "1v1 Matches", pct: 88, delay: 100, bg: "var(--accent)", glow: "rgba(255,45,85,0.8)" },
  { label: "Spectate Mode", pct: 31, delay: 200, bg: "var(--beta)", glow: "rgba(255,159,10,0.8)" },
  { label: "Mobile App", pct: 70, delay: 300, bg: "var(--neon-cyan)", glow: "rgba(0,245,255,0.8)" },
  { label: "Watch App", pct: 10, delay: 400, bg: "var(--accent2)", glow: "rgba(123,79,255,0.8)" },
];

export default function BetaTerminalPanel() {
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fills = panelRef.current?.querySelectorAll<HTMLElement>(".neon-progress-bar-fill");
    if (!fills?.length) return;
    const timers: number[] = [];
    fills.forEach((bar, i) => {
      const pct = progressItems[i]?.pct ?? 0;
      bar.style.width = "0%";
      timers.push(
        window.setTimeout(() => {
          bar.style.width = `${pct}%`;
        }, 500 + i * 130),
      );
    });
    return () => timers.forEach((id) => clearTimeout(id));
  }, []);

  return (
    <div className="neon-hero-right">
      <div className="neon-ring neon-ring-1" aria-hidden />
      <div className="neon-ring neon-ring-2" aria-hidden />
      <div className="neon-ring neon-ring-3" aria-hidden />
      <div className="neon-beta-panel" ref={panelRef}>
        <div className="neon-panel-body">
          <div className="neon-version-block">
            <div>
              <div className="neon-version-label">Current version</div>
              <div className="neon-version-num">v0.4.2</div>
            </div>
            <span className="neon-version-tag">unstable</span>
          </div>

          <div className="neon-progress-section">
            <div className="neon-progress-header">// beta completion</div>
            {progressItems.map((p) => (
              <div className="neon-progress-item" key={p.label}>
                <span className="neon-progress-item-label">{p.label}</span>
                <div className="neon-progress-bar-wrap">
                  <div
                    className="neon-progress-bar-fill"
                    style={
                      {
                        background: p.bg,
                        "--neon-bar-glow": p.glow,
                      } as CSSProperties
                    }
                  />
                </div>
                <span className="neon-progress-pct">{p.pct}%</span>
              </div>
            ))}
          </div>

          <div className="neon-changelog" id="changelog">
            <div className="neon-changelog-title">// recent changes</div>
            <div className="neon-changelog-item">
              <div className="neon-cl-icon neon-cl-new">★</div>
              <div className="neon-cl-text">
                <strong>New:</strong> Best-of-5 match format added
              </div>
            </div>
            <div className="neon-changelog-item">
              <div className="neon-cl-icon neon-cl-fix">!</div>
              <div className="neon-cl-text">
                <strong>Fix:</strong> Score sync lag on slow connections
              </div>
            </div>
            <div className="neon-changelog-item">
              <div className="neon-cl-icon neon-cl-new">★</div>
              <div className="neon-cl-text">
                <strong>New:</strong> Live match spectating (alpha)
              </div>
            </div>
            <div className="neon-changelog-item">
              <div className="neon-cl-icon neon-cl-soon">◷</div>
              <div className="neon-cl-text">
                <strong>Soon:</strong> Friends list & direct challenges
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
