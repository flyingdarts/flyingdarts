export default function BetaTestersNeon() {
  return (
    <section className="neon-beta-testers">
      <div className="neon-section-label">From the community</div>
      <div className="neon-section-title">BETA TESTER VOICES</div>
      <div className="neon-testers-grid">
        <div className="neon-tester-card">
          <div className="neon-tester-header">
            <div className="neon-tester-avatar" style={{ background: "rgba(232,68,90,0.15)", color: "var(--accent)" }}>
              MK
            </div>
            <div>
              <div className="neon-tester-name">Mark K.</div>
              <div className="neon-tester-role">Tester #0012 · Amateur player</div>
            </div>
          </div>
          <div className="neon-tester-quote">
            &quot;Yeah it crashed on me twice last week, but the team pushed a fix within hours. That kind of response
            time is rare. I&apos;m all in.&quot;
          </div>
        </div>
        <div className="neon-tester-card">
          <div className="neon-tester-header">
            <div
              className="neon-tester-avatar"
              style={{ background: "rgba(124,92,252,0.15)", color: "var(--accent2)" }}
            >
              SV
            </div>
            <div>
              <div className="neon-tester-name">Sandra V.</div>
              <div className="neon-tester-role">Tester #0031 · League player</div>
            </div>
          </div>
          <div className="neon-tester-quote">
            &quot;The match format is already better than anything else out there. Feels like a real game, not a
            spreadsheet with a dartboard skin.&quot;
          </div>
        </div>
        <div className="neon-tester-card">
          <div className="neon-tester-header">
            <div className="neon-tester-avatar" style={{ background: "rgba(245,166,35,0.15)", color: "var(--beta)" }}>
              RB
            </div>
            <div>
              <div className="neon-tester-name">Rik B.</div>
              <div className="neon-tester-role">Tester #0008 · Pub regular</div>
            </div>
          </div>
          <div className="neon-tester-quote">
            &quot;I reported a scoring bug on Tuesday, it was fixed by Thursday. This team actually listens. Lifetime Pro
            is a steal for early testers.&quot;
          </div>
        </div>
      </div>
    </section>
  );
}
